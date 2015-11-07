local component = require("component")
local event = require("event")
local os = require("os")
local serialization = require("serialization")
local filesystem = require("filesystem")

dbfile = "authdb.dat"

if not filesystem.exists() then
	db = {"pairs" = [], "allowed_cards"= []}
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
	openDoor(door)
	os.sleep(5)
	closeDoor(door)
end

