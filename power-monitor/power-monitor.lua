--SuPeRMiNoR2, 2015
--Source  https://github.com/OpenPrograms/SuPeRMiNoR2-Programs/tree/master/power-monitor
--License https://github.com/OpenPrograms/SuPeRMiNoR2-Programs/blob/master/LICENSE.txt

local version = "1.5.9"
local supported_config_version = "0.7"
local default_config_url = "https://raw.githubusercontent.com/OpenPrograms/SuPeRMiNoR2-Programs/master/power-monitor/power-monitor.config"
local config_path = "/etc/power-monitor.config"

local component = require("component")
local term = require("term")
local fs = require("filesystem")
local gpu = component.gpu
local wget = loadfile("/bin/wget.lua")
local superlib = require("superlib")
local autopid = require("autopidlib")

term.clear()
print("Loading SuPeRMiNoR2's power-monitor version "..version)

if not component.isAvailable("internet") then
  error("This program requires an internet card to run.")
  return
end

pad = superlib.pad
round = superlib.round
comma = superlib.format_comma
pretty = superlib.pretty

local internet = require("internet")

print("Checking for updates...")
superlib_version = superlib.getVersion()
versions = superlib.checkVersions()

if versions == nil then 
  print("Error checking versions.")
else
  if versions["superlib"] ~= superlib_version then 
    print("An update is available for superlib")
    os.sleep(2) 
  end
  if versions["powermonitor"] ~= version then 
    print("An update is available for power-monitor")
    os.sleep(2) 
  end
end

if fs.exists(config_path) == false then
  print("Downloading config file to "..config_path)
  result = superlib.downloadFile(default_config_url, config_path)
  if result == false then 
    error("Error downloading the config file")
  end
end

local config = loadfile(config_path)()

if config.config_version ~= supported_config_version then 
  print("Warning, The configuration file has a unsupported version number.")
  print("You should save your old settings and delete the config file.")
  print("The new version will be downloaded on next startup.")
  print("If you do not do this, the program may not work.")
  print("Waiting 10 seconds...")
  os.sleep(10)
end

--States
local glasses_connected = false

local function percent_gen_db(powerdb, uid)
  storedPower = powerdb[uid]["stored"]
  powerCapacity = powerdb[uid]["capacity"]
  return superlib.pgen(storedPower, powerCapacity, config.display_precision) .. "%"
end

local function readCapacity(proxy, ltype)
  capacity = 0
   
  if ltype == 1 then --For IC2
    capacity = proxy.getCapacity()
  end
   
  if ltype == 2 then --For TE and older mek blocks
    capacity = proxy.getMaxEnergyStored()
  end

  if ltype == 3 then --For newer mekanism blocks
  	capacity = proxy.getMaxEnergy()
  end

  return capacity
end

local function readStored(proxy, ltype)
  stored = 0
   
  if ltype == 1 then
    stored = proxy.getStored()
  end
   
  if ltype == 2 then
    stored = proxy.getEnergyStored()
  end

  if ltype == 3 then
  	stored = proxy.getStored()
  end

  return stored
end

local function getPower()
  local total_stored = 0
  local powerdb = {}

  for uid in pairs(mlist) do
    proxy = mlist[uid]["proxy"]
    ltype = mlist[uid]["type"]
    lname = mlist[uid]["name"]
    c = mlist[uid]["capacity"]
    -- c, s = readPower(proxy, ltype) --Switching to reading just stored, and useing the db for max capacity (Will slow down updates of capacitor max energy changes)
    s = readStored(proxy, ltype)
    if s > c then --Stupid IC2 Bug, full ic2 blocks read over their capacity sometimes
        s = c
    end
    total_stored = total_stored + s
    powerdb[uid] = {capacity=c, stored=s, name=lname}
  end  
  --powerdb["total"] = {capacity=total_capacity, stored=total_stored}
  return powerdb, total_stored
end

local function scan()
  local unit_id = 1
  mlist = {}
  slist = {rfmeter={}}
  total_capacity = 0
  for address, ctype in component.list() do
    for sindex, stype in pairs(supported_types) do --Section for standard power storage blocks.
      if stype["id"] == ctype then
        t = component.proxy(address)
        ltype = stype["type"]
        name = stype["name"]
        c = readCapacity(t, ltype)
        mlist[unit_id] = {address=address, proxy=t, type=ltype, name=name, capacity=c} --New feature: Store max capacity in database to avoid reading it each loop.
                                                                              --This will slow down updating of things like capacitors which can change their size.
        unit_id = unit_id + 1
        total_capacity = total_capacity + c
      end
    end
    if ctype == "glasses" and glasses_connected == false then --Section for Open Glasses
      print("Detected glasses block, loading")
      glasses = component.proxy(address)
      glasses.removeAll()
      glasses_text = glasses.addTextLabel()
      glasses_text.setText("Loading...")
      glasses_connected = true
      glasses_text.setColor(.37, .83, .03)
      glasses_text.setScale(1)
      glasses_text.setPosition(config.glasses_xoffset, config.glasses_yoffset)
      glasses_text.setText("Loading...")
    end

    if ctype == "rfmeter" then
    	t = component.proxy(address)
    	name = t.getName()
    	if name == "" then
    		name = "Meter #" .. #slist["rfmeter"] + 1
    	end
    	table.insert(slist["rfmeter"], {proxy=t, name=name})
    end

  end
  total_units = unit_id - 1
  return mlist, total_capacity, total_units
end

local function buffer(text)
  text_buffer = text_buffer .. text .. "\n"
end

local function calculate_rate(last, current)
  rate = current - last
  if config.estimate_ticks == true then
    ticks_per_loop = config.loop_speed * config.ticks_scaler
    rate = rate / ticks_per_loop
    rate = superlib.round(rate, 0)
  end
  return tostring(rate)
end  

supported_types = {
{id="tile_thermalexpansion_cell_basic_name", type=2, name="Leadstone Cell"}, 
{id="tile_thermalexpansion_cell_hardened_name", type=2, name="Hardened Cell"},
{id="tile_thermalexpansion_cell_reinforced_name", type=2, name="Redstone Cell"},
{id="tile_thermalexpansion_cell_resonant_name", type=2, name="Resonant Cell"},
{id="mfsu", type=1, name="MFSU"},
{id="mfe", type=1, name="MFE"},
{id="cesu", type=1, name="CESU"},
{id="batbox", type=1, name="BatBox"},
{id="capacitor_bank", type=2, name="Capacitor Bank"},
{id="basic_energy_cube", type=3, name="Basic Energy Cube"},
{id="advanced_energy_cube", type=3, name="Advanced Energy Cube"},
{id="elite_energy_cube", type=3, name="Elite Enegy Cube"},
{id="ultimate_energy_cube", type=3, name="Ultimate Energy Cube"},
{id="creative_energy_cube", type=3, name="Creative Energy Cube"},
{id="induction_matrix", type=2, name="Induction Matrix"}
}
 
--Program
term.clear()
print("SuPeRMiNoR2's Power Monitor version: "..version)
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
  os.sleep(1)
end

print("Found ".. total_units .. " storage unit[s]")
print("Total capacity detected: "..pretty(total_capacity))
print("Press ctrl + alt + c to close the program")
print("Waiting startup delay of: "..config.startup_delay)
os.sleep(tonumber(config.startup_delay))

total_last_amount = false
total_rate = 0

while true do
  text_buffer = ""

  controllers = autopid.dump()

  success, powerdb, total_stored = pcall(getPower)
  if success == false then
    mlist, total_capacity, total_units = scan()
    powerdb, total_stored = getPower()
  end

  if total_units == 0 then
    total = 0
  else
    total = superlib.pgen(total_stored, total_capacity, 2)
  end

  if total_last_amount == false then
    total_last_amount = total_stored
  end

  total_rate = calculate_rate(total_last_amount, total_stored)
  total_last_amount = total_stored

  if glasses_connected then
    if 
      total > 50 then glasses_text.setColor(.37, .83, .03) --glasses_text.setScale(1) 
    end
    if 
      total <= 50 and total > 25 then glasses_text.setColor(0.93,0.91,0.09) --glasses_text.setScale(1.5) 
    end
    if 
      total <= 25 then glasses_text.setColor(0.96,0.07,0.09,1) --glasses_text.setScale(2)
    end
    glasses_buffer = "["..total_units.."] " .. total.."% ~" .. pretty(total_rate) .. "/t"

    if config.glasses_banner ~= false then
      glasses_buffer = config.glasses_banner .. glasses_buffer
    end
    glasses_text.setText(glasses_buffer)
  end

  if config.banner ~= false then
    buffer(config.banner)
  end

  term.clear()

  buffer("Currently monitoring ".. total_units .. " units")

  print(text_buffer) text_buffer = ""

  total_reactor_rate = 0
  total_turbine_rate = 0

  reactordata = {{"ID", "Active", "Core", "Control", "Steam Gen"}}
  turbinedata = {{"ID", "Active", "Coils", "Speed", "Energy Gen", "Steam", "Inductor Status"}}

    for cid, cobj in pairs(controllers) do
        local status = cobj.status
        if cobj.type == "br_reactor" and status.activeCooling then
            table.insert(reactordata, {string.sub(cid, 8) , status.active, pad(round(status.fuelTemperature),4) .. "°C", 
              round(status.controlRodLevel) .. "%", pad(round(status.rate), 5).. "mB/t"})
            total_reactor_rate = total_reactor_rate + status.rate
        end
        if cobj.type == "br_turbine" then
            table.insert(turbinedata, {string.sub(cid, 8), status.active, status.inductor, round(status.rotorSpeed, 0) .. " RPM",
              pad(pretty(status.energyProduced), 5) .. " RF/t", status.enoughSteam, status.inductor_msg})
            total_turbine_rate = total_turbine_rate + status.energyProduced
        end
    end

    rfmeterdata = {{"Name", "Average Flow", "Total Counter"}}
    for oid, oob in pairs(slist["rfmeter"]) do
        table.insert(rfmeterdata, {oob.name, oob.proxy.getAvg() .. " RF/t", oob.proxy.getCounterValue() .. "RF"})
    end

    if #reactordata > 1 then
        print(string.format("Reactors Total: %s mB/t", round(total_reactor_rate, 0)))
        superlib.rendertable(reactordata)
        print("")
    end

    if #turbinedata > 1 then
        print(string.format("\nTurbine Total: %s RF/t", pretty(total_turbine_rate)))
        superlib.rendertable(turbinedata)
        print("")
    end

    if #rfmeterdata > 1 then
        print("RF Meters")
        superlib.rendertable(rfmeterdata)
        print("")
    end

    buffer("Total".. ": ".. total .." [".. pretty(total_stored) .. "/" .. pretty(total_capacity) .."] Rate: ~".. pretty(total_rate).."/t")
  
    for lid in pairs(powerdb) do
        first_half = superlib.pad("#"..lid.. ": ".. percent_gen_db(powerdb, lid), 10)
        middle = superlib.pad(" [".. powerdb[lid]["stored"] .. "/" .. powerdb[lid]["capacity"] .. "] ", 30)
        second_half = " ["..powerdb[lid]["name"].."]"

        if config.display_units == false then output = first_half .. second_half end
        if config.display_units == true then output = first_half .. middle .. second_half end

        buffer(output)
    end

  print(text_buffer)

  if total_units == 0 then
    os.sleep(10)
  else
    os.sleep(config.loop_speed)
  end

end
