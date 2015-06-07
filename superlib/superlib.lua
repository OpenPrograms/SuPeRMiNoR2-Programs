local version = "0.4.6"
local m = {}

local component = require("component")
if not component.isAvailable("internet") then
  error("This program requires an internet card to run.")
  return
end

local serial = require("serialization")
local internet = require("internet")
local term = require("term")
local keyboard = require("keyboard")
local event = require("event")
local wget = loadfile("/bin/wget.lua")
local string = require("string")

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

function m.getVersion() --For getting the version of superlib without making an internet request
  return version
end

function m.checkVersions()
  response = downloadFile("https://raw.githubusercontent.com/OpenPrograms/SuPeRMiNoR2-Programs/master/versions.lua", "/tmp/versions.lua")
  versions = loadfile("/tmp/versions.lua")() --The () are needed
  return versions, version
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

function m.percent_gen(stored, capacity, precision)
  tmp = stored / capacity
  tmp = tmp * 100
  tmp = m.round(tmp, precision)
  return tmp
end

m.pgen = m.percent_gen --Compat

function m.pad(str, len)
  str = tostring(str)
  char = " "
  if char == nil then char = ' ' end
  return str .. string.rep(char, len - #str)
end

function m.decode(data)
  status, result = pcall(serial.unserialize, data)
  return status, result
end
 
function m.encode(data)
  return serial.serialize(data)
end

function m.split(str,sep)
    local array = {}
    local reg = string.format("([^%s]+)",sep)
    for mem in string.gmatch(str,reg) do
        table.insert(array, mem)
    end
    return array
end

--Menu Section
lastmenu = false
menu = {}

function rendermenu(mt)
  term.clear()
  for i=1, #mt do
    print(" "..i.."  "..mt[i]["name"].." ("..mt[i]["addr"]..")")
  end
end

function updatemenu(mt, sel)
  if lastmenu ~= false then
    term.setCursor(1, lastmenu)
    term.clearLine()
    term.write(" "..lastmenu.."  "..mt[lastmenu]["name"].." ("..mt[lastmenu]["addr"]..")")
  end
  term.setCursor(1, sel)
  term.clearLine()
  term.write("["..sel.."] "..mt[sel]["name"].." ("..mt[sel]["addr"]..")")
end

function m.addItem(name, data)
  menu[#menu + 1] = {name=name, addr=data}
end

function m.clearMenu()
  menu = {}
end

function m.runMenu()
  rendermenu(menu)
  sel = 1
  updatemenu(menu, sel)

  while true do
    e, r, t, key = event.pull("key_down")

    if key == keyboard.keys.down then
      lastmenu = sel
      sel = sel + 1
      if sel > #menu then
        sel = 1
      end
    end
    if key == keyboard.keys.up then
      lastmenu = sel
      sel = sel - 1
      if sel < 1 then
        sel = #menu
      end
    end
    if key == keyboard.keys.enter then
      return menu[sel]["addr"]
    end
    if key == keyboard.keys.q then
      return false
    end
    updatemenu(menu, sel)
  end
end
--------------------------

return m