--Made by SuPeRMiNoR2
version = "1.4.7"
supported_config_version = "0.1"

local component = require("component")
local term = require("term")
local fs = require("filesystem")
local superlib = require("superlib")
local gpu = component.gpu

if not component.isAvailable("internet") then
  io.stderr:write("This program requires an internet card to run.")
  return
end

local internet = require("internet")
print("Checking for updates...")
superlib_version = superlib.getVersion()
versions = superlib.checkVersions()

print(versions)
os.sleep(2)
versions()

if versions == nil then print("Error checking versions.") end
if versions ~= nil then
  if versions["superlib"] ~= superlib_version then print("An update is available for superlib") os.sleep(2) end
  if versions["power-monitor"] ~= version then print("An update is available for power-monitor") os.sleep(2) end
end

if fs.exists("/usr/power-monitor.config") == false then
  print("Downloading config file to /usr/power-monitor.config")
  result = superlib.downloadFile("https://raw.githubusercontent.com/OpenPrograms/SuPeRMiNoR2-Programs/master/power-monitor/power-monitor.config", "/usr/power-monitor.config")
  if result == false then 
    io.stderr:write("Error downloading the config file")
  end
end

local config = loadfile("/usr/power-monitor.config")()

--states
glasses_connected = false


function percent_gen_db(powerdb, uid)
  return superlib.pgen(powerdb[uid]["stored"], powerdb[uid]["capacity"], config.display_precision) .. "%"
end

function readPower(proxy, ltype)
  capacity = 0
  stored = 0
   
  if ltype == 1 then
      capacity = proxy.getCapacity()
      stored = proxy.getStored()
  end
   
  if ltype == 2 then
      capacity = proxy.getMaxEnergyStored()
      stored = proxy.getEnergyStored()
  end

  return capacity, stored
end

function getPower()
  total_stored = 0
  powerdb = {}
  for uid in pairs(mlist) do
      proxy = mlist[uid]["proxy"]
      ltype = mlist[uid]["type"]
      lname = mlist[uid]["name"]
      c, s = readPower(proxy, ltype)
      if s > c then --Stupid IC2 Bug, full ic2 blocks read over their capacity sometimes
          s = c
      end
      total_stored = total_stored + s
      powerdb[uid] = {capacity=c, stored=s, name=lname}
  end  
  powerdb["total"] = {capacity=total_capacity, stored=total_stored}
  return powerdb
end

function scan()
    unit_id = 1
    mlist = {}
    total_capacity = 0
    for address, ctype in component.list() do
        for stype in pairs(supported_types) do
            if stype == ctype then
                t = component.proxy(address)
                ltype = supported_types[stype]["type"]
                name = supported_types[stype]["name"]
                mlist[unit_id] = {address=address, proxy=t, type=ltype, name=name}
                unit_id = unit_id + 1
                c, s = readPower(t, ltype)
                total_capacity = total_capacity + c
            end
        end
        if ctype == "glasses" and glasses_connected == false then
            print("Detected glasses block, loading")
            glasses = component.proxy(address)
            glasses.removeAll()
            glasses_text = glasses.addTextLabel()
            glasses_text.setText("Loading.")
            --os.sleep(0.8)
            glasses_connected = true
            glasses_text.setColor(.37, .83, .03)
            glasses_text.setText("Loading..")
            --os.sleep(0.8)
            glasses_text.setPosition(2, 2)
            glasses_text.setText("Loading...")
            --os.sleep(0.8)
            glasses_text.setScale(1)
            glasses_text.setText("Loading....")
            --os.sleep(1)
            --print(glasses.getBindPlayers())
        end
    end
    total_units = unit_id - 1
    return mlist, total_capacity, total_units
end

function buffer(text)
    text_buffer = text_buffer .. text .. "\n"
end

supported_types = {tile_thermalexpansion_cell_basic_name={type=2, name="Leadstone Cell"}, 
tile_thermalexpansion_cell_hardened_name={type=2, name="Hardened Cell"}, 
tile_thermalexpansion_cell_reinforced_name={type=2, name="Redstone Cell"}, 
tile_thermalexpansion_cell_resonant_name={type=2, name="Resonant Cell"}, 
mfsu={type=1, name="MFSU"}, mfe={type=1, name="MFE"}, cesu={type=1, 
name="CESU"}, batbox={type=1, name="BatBox"}, capacitor_bank={type=2, name="Capacitor Bank"}}  
 
--Program
term.clear()
print("Applying scale of " .. config.scale)
w, h = gpu.maxResolution()
gpu.setResolution(w / config.scale, h / config.scale)
 
print("Scanning for energy storage units")
if glasses_connected then
    glasses_text.setText("Scanning.")
end
mlist, total_capacity, total_units = scan()

if glasses_connected then
    glasses_text.setText("Found "..total_units)
end

print("Found ".. total_units .. " storage unit[s]")
print("Total capacity detected: "..total_capacity)
print("Press ctrl + alt + c to close the program")
print("Waiting startup delay of: "..config.startup_delay)
os.sleep(config.startup_delay + 0)
 
loops = 0
while true do
  loops = loops + 1
  if loops == 50 then
    loops = 0
    scan()
  end

  success, powerdb = pcall(getPower)
  if success == false then
    scan()
    powerdb = {total= {stored=1, capacity=1}}
  end
   
  term.clear()
  text_buffer = ""

  total = superlib.pgen(powerdb["total"]["stored"], powerdb["total"]["capacity"], 2)

  if glasses_connected then
    if total > 50 then glasses_text.setColor(.37, .83, .03) glasses_text.setScale(1) end
    if total <= 50 and total > 25 then glasses_text.setColor(0.93,0.91,0.09) glasses_text.setScale(1.5) end
    if total <= 25 then glasses_text.setColor(0.96,0.07,0.09,1) glasses_text.setScale(2) end
    glasses_text.setText("["..total_units.."] "..total.."%")
  end

  if config.banner ~= false then
    buffer(config.banner)
  end
  buffer("Currently monitoring ".. total_units .. " units")
  buffer("")
  buffer("Total".. ": ".. percent_gen_db(powerdb, "total") .." [".. powerdb["total"]["stored"] .. "/" .. powerdb["total"]["capacity"] .."]")
  buffer("")
   
  for lid in pairs(powerdb) do
    if lid ~= "total" then
      first_half = superlib.pad("#"..lid.. ": ".. percent_gen_db(powerdb, lid), 10)
      middle = superlib.pad(" [".. powerdb[lid]["stored"] .. "/" .. powerdb[lid]["capacity"] .. "] ", 30)
      second_half = " ["..powerdb[lid]["name"].."]"

      if config.display_units == false then output = first_half .. second_half end
      if config.display_units == true then output = first_half .. middle .. second_half end

      buffer(output)
    end
  end
  print(text_buffer)
  os.sleep(0.2)
end