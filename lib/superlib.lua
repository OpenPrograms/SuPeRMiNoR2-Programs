local version = "0.4"

local m = {}

local component = require("component")
if not component.isAvailable("internet") then
  io.stderr:write("This program requires an internet card to run.")
  return
end
local internet = require("internet")
local wget = loadfile("/bin/wget.lua")

local function downloadRaw(url)
  local sContent = ""
  local result, response = pcall(internet.request, url)
  if not result then
    return nil
  end
    for chunk in response do
      sContent = sContent..chunk
    end
  return sContent
end

local function downloadFile(url, path)
  return wget("-fq",url,path)
end

function m.getVersion()
  return version
end

function m.checkVersions()
  response = downloadRaw("https://raw.githubusercontent.com/OpenPrograms/SuPeRMiNoR2-Programs/master/versions.lua")
  if response ~= nil then 
    versions = loadstring(response)()
  end
  return response
end

function m.downloadFile(url, path)
local success, response = pcall(downloadFile, url, path)
  if not success then
    return nil
  end
  return response
end

function m.download(url)
  local success, response = pcall(downloadRaw, url)
  if not success then
    return nil
  end
  return response
end

function m.round(what, precision)
   return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
end

function m.pgen(stored, capacity, precision)
  tmp = stored / capacity
  tmp = tmp * 100
  tmp = m.round(tmp, precision)
  return tmp
end

function m.pad(str, len)
  char = " "
  if char == nil then char = ' ' end
  return str .. string.rep(char, len - #str)
end

function oldround(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

return m