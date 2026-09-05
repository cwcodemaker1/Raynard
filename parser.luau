local DEFAULT_ROOT="https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/"
local env=_G
pcall(function() if typeof(getgenv)=="function" then env=getgenv() end end)
local config=type(env.RaynardParserConfig)=="table" and env.RaynardParserConfig or {}
local root=tostring(config.Root or DEFAULT_ROOT)
if string.sub(root,-1)~="/" then root..="/" end
local localRoot=tostring(config.LocalRoot or "Rayward/")
if string.sub(localRoot,-1)~="/" then localRoot..="/" end
local function compile(source,name)
    if typeof(loadstring)~="function" then return nil,"loadstring unavailable" end
    local ok,chunk,err=pcall(loadstring,source,name)
    if ok and chunk then return chunk end
    local ok2,chunk2,err2=pcall(loadstring,source)
    if ok2 and chunk2 then return chunk2 end
    return nil,tostring(err2 or err or chunk)
end
local function http(path)
    local ok,result=pcall(function() return game:HttpGet(root..path) end)
    if not ok then return nil,tostring(result) end
    if type(result)~="string" or result=="" then return nil,"empty response" end
    return result
end
local function localText(path)
    if typeof(isfile)~="function" or typeof(readfile)~="function" then return nil end
    local full=localRoot..path
    local ok,exists=pcall(isfile,full)
    if not ok or not exists then return nil end
    local readOk,result=pcall(readfile,full)
    if readOk and type(result)=="string" and result~="" then return result end
    return nil
end
local manifest=config.Manifest
if type(manifest)~="table" then
    local source=localText("manifest.luau") or http("manifest.luau")
    if not source then error("Raynard manifest unavailable",0) end
    local chunk,compileError=compile(source,"@Raynard/manifest.luau")
    if not chunk then error("Raynard manifest compile failed: "..tostring(compileError),0) end
    local ok,result=pcall(chunk)
    if not ok or type(result)~="table" then error("Raynard manifest runtime failed: "..tostring(result),0) end
    manifest=result
end
if type(manifest.Files)~="table" then error("Raynard manifest Files missing",0) end
local dir=tostring(manifest.SourceDirectory or "src/")
if dir~="" and string.sub(dir,-1)~="/" then dir..="/" end
local pieces={}
for _,name in ipairs(manifest.Files) do
    name=tostring(name)
    local supplied=type(config.Sources)=="table" and config.Sources[name] or nil
    local source=type(supplied)=="string" and supplied or localText(dir..name)
    if not source then
        local remoteError
        source,remoteError=http(dir..name)
        if not source then error("Raynard source unavailable: "..name.." | "..tostring(remoteError),0) end
    end
    pieces[#pieces+1]=source
end
local combined=table.concat(pieces,"\n")
local chunk,compileError=compile(combined,"@Raynard/combined.luau")
if not chunk then error("Raynard compile failed: "..tostring(compileError),0) end
local ok,library=pcall(chunk)
if not ok then error("Raynard runtime failed: "..tostring(library),0) end
if type(library)~="table" then error("Raynard did not return a library table",0) end
library.Parser={Root=root,LocalRoot=localRoot,Manifest=manifest,FragmentCount=#manifest.Files}
return library
