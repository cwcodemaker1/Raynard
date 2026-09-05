local root="https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/"
local function get(path)
    local ok,result=pcall(function() return game:HttpGet(root..path) end)
    if not ok or type(result)~="string" or result=="" then error("Raynard download failed: "..path.." | "..tostring(result),0) end
    return result
end
local manifestSource=get("manifest.luau")
local manifestChunk=loadstring(manifestSource)
if not manifestChunk then error("Raynard manifest compile failed",0) end
local manifest=manifestChunk()
local canFiles=typeof(isfolder)=="function" and typeof(makefolder)=="function" and typeof(writefile)=="function" and typeof(readfile)=="function"
if canFiles then
    if not isfolder("Rayward") then makefolder("Rayward") end
    if not isfolder("Rayward/src") then makefolder("Rayward/src") end
    writefile("Rayward/parser.luau",get("parser.luau"))
    writefile("Rayward/manifest.luau",manifestSource)
    for _,name in ipairs(manifest.Files) do writefile("Rayward/src/"..name,get((manifest.SourceDirectory or "src/")..name)) end
    return loadstring(readfile("Rayward/parser.luau"))()
end
return loadstring(get("parser.luau"))()
