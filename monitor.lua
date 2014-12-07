--Made by SuPeRMiNoR2
version = 0.9

--config
startup_delay = 2 --How long to wait after startup before clearing the screen
scale = 1 --Screen scale, 1 does not affect it, 2 doubles the size
banner = "SuPeR Power Monitoring Systems v"..version --Banner
id = 1 --ID (Not in use yet, will be for networked monitoring)
display_precision = 1
display_units = false
 
component = require("component")
term = require("term")
file = require("filesystem")
 
gpu = component.gpu
 
--loading area
print("Checking for config files")
 
if file.exists("conf/scale") then
print("Loading config file scale")
f = io.open("conf/scale")
scale = f:read()
f:close()
end
 
if file.exists("conf/banner") then
print("Loading config file banner")
f = io.open("conf/banner")
banner = f:read()
f:close()
end
 
if file.exists("conf/id") then
print("Loading config file id")
f = io.open("conf/id")
id = f:read()
f:close()
end
 
if file.exists("conf/startup_delay") then
print("Loading config file startup_delay")
f = io.open("conf/startup_delay")
startup_delay = f:read()
f:close()
end
 
print("Loaded all config files")
 
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
 
function nround(what, precision)
   return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
end
 
function pgen(stored, capacity)
  tmp = stored / capacity
  tmp = tmp * 100
  tmp = nround(tmp, display_precision)
  return tmp.."%"
end

function pad(str, len)
    char = " "
    if char == nil then char = ' ' end
    return str .. string.rep(char, len - #str)
end

function percent_gen_db(powerdb, uid)
return pgen(powerdb[uid]["stored"], powerdb[uid]["capacity"])
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
print("Applying scale of " .. scale)
w, h = gpu.maxResolution()
gpu.setResolution(w / scale, h / scale)
 
print("Scanning for energy storage units")
mlist, total_capacity, total_units = scan()

print("Found ".. total_units .. " storage unit[s]")
print("Total capacity detected: "..total_capacity)
print("Press ctrl + alt + c to close the program")
print("Waiting startup delay of: "..startup_delay)
os.sleep(startup_delay + 0)
 
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
		powerdb = getPower()
	end
	 
	term.clear()
	text_buffer = ""

	buffer(banner)
	buffer("Currently monitoring ".. total_units .. " units")
	buffer("")
	buffer("Total".. ": ".. percent_gen_db(powerdb, "total") .." [".. powerdb["total"]["capacity"] .. "/" .. powerdb["total"]["stored"] .."]")
	buffer("")
	 
	for lid in pairs(powerdb) do
		if lid ~= "total" then
			first_half = pad("#"..lid.. ": ".. percent_gen_db(powerdb, lid), 10)
			middle = pad(" [".. powerdb[lid]["capacity"] .. "/" .. powerdb[lid]["stored"] .. "] ", 30)
			second_half = " ["..powerdb[lid]["name"].."]"

			if display_units == false then output = first_half .. second_half end
			if display_units == true then output = first_half .. middle .. second_half end

			buffer(output)
		end
	end
	print(text_buffer)
	os.sleep(0.2)
end