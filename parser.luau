local DEFAULT_ROOT = "https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/"

local FILES = {
    "core.luau",
    "window.luau",
    "control.luau",
    "controlcolor.luau",
    "framework.luau",
    "inputs.luau",
    "data.luau",
    "visual.luau",
    "advanced.luau",
    "feat.luau",
}

local env = _G
pcall(function()
    if typeof(getgenv) == "function" then
        env = getgenv()
    end
end)

local config = type(env.RaynardParserConfig) == "table"
    and env.RaynardParserConfig
    or {}

local root = tostring(config.Root or DEFAULT_ROOT)
if string.sub(root, -1) ~= "/" then
    root ..= "/"
end

local files = type(config.Files) == "table"
    and config.Files
    or FILES

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok then
        return nil, tostring(result)
    end

    if type(result) ~= "string" or result == "" then
        return nil, "empty response"
    end

    return result
end

local function getFragment(fileName)
    -- First try files directly in the repository root.
    local source, rootError = httpGet(root .. fileName)
    if source then
        return source, root .. fileName
    end

    -- Also support keeping the fragments inside /src/.
    local srcSource, srcError = httpGet(root .. "src/" .. fileName)
    if srcSource then
        return srcSource, root .. "src/" .. fileName
    end

    return nil,
        "could not load "
        .. fileName
        .. " | root: "
        .. tostring(rootError)
        .. " | src: "
        .. tostring(srcError)
end

local function compile(source, chunkName)
    if typeof(loadstring) ~= "function" then
        return nil, "loadstring is unavailable"
    end

    -- Try executor implementations that support a chunk name.
    local okNamed, namedChunk, namedError = pcall(
        loadstring,
        source,
        chunkName
    )

    if okNamed and typeof(namedChunk) == "function" then
        return namedChunk
    end

    -- Fallback for executors whose loadstring only accepts one argument.
    local okPlain, plainChunk, plainError = pcall(
        loadstring,
        source
    )

    if okPlain and typeof(plainChunk) == "function" then
        return plainChunk
    end

    return nil, tostring(plainError or namedError or plainChunk or namedChunk)
end

local pieces = {}
local loadedFrom = {}

for index, fileName in ipairs(files) do
    fileName = tostring(fileName)

    local suppliedSource =
        type(config.Sources) == "table"
        and config.Sources[fileName]
        or nil

    local source
    local location
    local loadError

    if type(suppliedSource) == "string" then
        source = suppliedSource
        location = "RaynardParserConfig.Sources[" .. fileName .. "]"
    else
        source, location = getFragment(fileName)
        if not source then
            loadError = location
        end
    end

    if not source then
        error(
            string.format(
                "[Raynard Parser] fragment %d/%d failed: %s\n%s",
                index,
                #files,
                fileName,
                tostring(loadError)
            ),
            0
        )
    end

    -- Strip UTF-8 BOM if one was accidentally saved by an editor.
    if string.sub(source, 1, 3) == "\239\187\191" then
        source = string.sub(source, 4)
    end

    pieces[#pieces + 1] = string.format(
        "\n--[[ RAYNARD FRAGMENT %02d: %s ]]\n%s\n",
        index,
        fileName,
        source
    )

    loadedFrom[#loadedFrom + 1] = {
        File = fileName,
        Location = location,
    }
end

local combinedSource = table.concat(pieces, "\n")

local chunk, compileError = compile(
    combinedSource,
    "@Raynard/combined.luau"
)

if not chunk then
    error(
        "[Raynard Parser] combined source failed to compile: "
        .. tostring(compileError),
        0
    )
end

local ran, Raynard = pcall(chunk)

if not ran then
    error(
        "[Raynard Parser] combined Raynard runtime failed: "
        .. tostring(Raynard),
        0
    )
end

-- Raynard may be a table with __call or a plain callable function depending
-- on the framework version. Do not reject either valid form.
local resultType = typeof(Raynard)
local isCallableTable = false

if resultType == "table" then
    local mt = getmetatable(Raynard)
    isCallableTable = mt ~= nil and typeof(mt.__call) == "function"
end

if resultType ~= "function" and resultType ~= "table" then
    error(
        "[Raynard Parser] combined source returned "
        .. resultType
        .. " instead of the Raynard library",
        0
    )
end

-- Add parser diagnostics when Raynard is a table.
if resultType == "table" then
    Raynard.Parser = {
        Root = root,
        Files = files,
        LoadedFrom = loadedFrom,
        FragmentCount = #files,
        CombinedBytes = #combinedSource,
        Callable = isCallableTable,
    }
end

return Raynard
