local component = require("component")
local event = require("event")
local os = require("os")
local serialization = require("serialization")
local filesystem = require("filesystem")
local keyboard = require("keyboard")
local string = require("string")
local math = require("math")
local term = require("term")

local superlib = require("superlib")

dbfile = "/authdb.dat"

writer = component.os_cardwriter

function loadDB()
	if filesystem.exists(dbfile) == false then
		ldb = {pairs = {}, registered = {}, new = {}}
	else
		f = filesystem.open(dbfile, "rb")
		rdb = f:read(filesystem.size(dbfile))
		ldb = serialization.unserialize(rdb)
		f:close()
	end
	return ldb
end

function saveDB(ldb)
	f = io.open(dbfile, "wb")
	f:write(serialization.serialize(ldb))
	f:close()
end

rdb = loadDB()
saveDB(rdb)

local function openDoor(door)
	if door.isOpen() == false then
		door.toggle()
	end
end

local function closeDoor(door)
	if door.isOpen() == true then
		door.toggle()
	end
end

local function toggleDoor(doorad)
	door = component.proxy(doorad)
	openDoor(door)
	os.sleep(2)
	closeDoor()
end

local function checkCard(UUID)
	db = loadDB()
	for i in ipairs(db["registered"]) do
		if db["registered"][i]["uuid"] == UUID then
			return true, db["registered"]["username"]
		end
	end
	return false
end

local function getUser(msg)
	io.write(msg)
	return io.read()
end

local function makeCode(l)
    local s = ""
    for i = 1, l do
        s = s .. string.char(math.random(32, 126))
    end
    return s
end

local function registerCard()
	db = loadDB()
	print("Registering new card.")
	cardcode = makeCode(10)
	title = getUser("Enter the title for the card: ")
	writer.write(cardcode, title, true)
	table.insert(db["new"], cardcode)
	print("The card will be registered to the user who swipes it next.")
	saveDB(db)
	os.sleep(1)
end

local function registerDoor()
	db = loadDB()
	freeDoors = {}
	freeMags = {}

	for address, ctype in component.list() do
		if ctype == "os_door" then
			reg = false
			for raddr in ipairs(db["pairs"]) do
				if address == db["pairs"][raddr]["door"] then
					reg = true
				end
			end
			if not reg then 
				table.insert(freeDoors, address) 
			end
		end

		if ctype == "os_magreader" then
			reg = false
			for raddr in ipairs(db["pairs"]) do
				if address == db["pairs"][raddr]["mag"] then
					reg = true
				end
			end
			if not reg then 
				table.insert(freeMags, address) 
			end
		end
	end

	print("")
	superlib.clearMenu()
	for i, d in ipairs(freeDoors) do
		superlib.addItem("Door ", d)
	end
	superlib.addItem("Cancel", "c")
	door = superlib.runMenu("Please select the door uuid you want to add.")
	print(door)
	os.sleep(1)

	if door ~= "c" then
		superlib.clearMenu()
		for i, d in ipairs(freeMags) do
			superlib.addItem("Reader ", d)
		end
		superlib.addItem("Cancel", "c")
		mag = superlib.runMenu("Please select the mag reader uuid you want to pair to the door.")

		if mag ~= "c" then
			name = getUser("Enter the name for this pair: ")
			table.insert(db["pairs"], {door=door, mag=mag, name=name})
		end
	end
	saveDB(db)
end

function check(maddr, paddr, dooraddr, doordb)
	if maddr == paddr then 
		print("Opening Door "..doordb["name"]) 
		toggleDoor(dooraddr)
	end
	if maddr ~= paddr then print("Invalid Door") end
end

function auth(_,addr, playerName, data, UUID, locked)
	db = loadDB()

	for i in ipairs(db["new"]) do --Check for first swipe of newly registered card, and get its UUID
		if db["new"][i] == data then
			table.insert(db["registered"], {username=playerName, uuid=UUID})
			print("Registered card ".. UUID .. " to user ".. playerName)
			table.remove(db["new"], i)
			saveDB(db)
		end
	end

	allowed, username = checkCard(UUID)
	if allowed then
		for u, d in ipairs(db["pairs"]) do
			check(addr, d["mag"], d["door"], d)
		end
	end	
end

local function menus() 
	term.clear()

	print("Super Security System [Beta]")
	superlib.clearMenu()
	superlib.addItem("Register a card", "r")
	superlib.addItem("Register a door", "d")

	key = superlib.runMenu()

	if key == "r" then
		registerCard()
	elseif key == "d" then
		registerDoor()
	end
end

function main()
	event.ignore("magData", auth)
	event.listen("magData", auth)
	while true do
		menus()
	end
end
main()
