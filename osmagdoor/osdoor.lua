local component = require("component")
local event = require("event")
local os = require("os")
local serialization = require("serialization")
local filesystem = require("filesystem")
local keyboard = require("keyboard")
local string = require("string")
local math = require("math")

local superlib = require("superlib")

dbfile = "authdb.dat"

writer = component.os_cardwriter

if not filesystem.exists() then
	db = {"pairs" = {}, "registered" = {}, "new" = {}}
else
	f = io.open(dbfile, "r")
	rdb = f:read()
	db = serialization.unserialize(rdb)
	f:close()
end

local function saveDB()
	f = io.open(dbfile, "w")
	f:write(serialization.serialize(db))
	f:close()
end
saveDB()

local function openDoor(door)
	if door.isopen() == false then
		door.toggle()
	end
end

local function closeDoor(door)
	if door.isopen() then
		door.toggle()
	end
end

local function toggleDoor(door)
	door = component.proxy(door)
	openDoor(door)
	os.sleep(5)
	closeDoor(door)
end

local function checkCard(UUID)
	for i in ipairs(db["registered"]) do
		if db["registered"][i] == UUID then
			return true
		end
	end
	return false
end

local function getUser(msg)
	io.write(msg)
	return io.read()

local function registerCard()
	print("Registering new card.")
	cardcode = makeCode(10)
	title = getUser("Enter the title for the card: ")
	writer.write(cardcode, title, true)
	table.insert(db["new"], cardcode)
	print("The card will be registered to the user who swipes it next.")
	os.sleep(1)
end

local function registerDoor()
	--present all available (not registered) doors and readers
end

local function auth(_,addr, playerName, data, UUID, locked)
	for i in ipairs(db["new"]) do --Check for first swipe of newly registered card, and get its UUID
		if db["new"][i] == data then
			table.insert(db["registered"], {"username" = playerName, "uuid" = UUID})
			print("Registered card ".. UUID .. " to user ".. playerName)
			table.remove(db["new"][i])
			saveDB()
		end
	end

	if checkCard(UUID) then
		for u in ipairs(db["pairs"]) do
			if addr == db["pairs"][u]["mag"] then
				toggleDoor(db["pairs"][u]["door"])
			end
		end
	end
end

local function makeCode(l)
        local s = ""
        for i = 1, l do
            s = s .. string.char(math.random(32, 126))
        return s
end

local function actionKeys() --change to superlib menu
	_, uuid, _, _keyid, user = event.pull("key_down")
	key = keyboard.keys[keyid]

	print("Press")
	if key == "r" then
		registerCard()
	elseif key == "d" then
		registerDoor()
	end

function main()
	event.listen("magData", auth)
	while true do
		actionKeys()
	end
end
