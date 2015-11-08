local component = require("component")
local event = require("event")
local os = require("os")
local serialization = require("serialization")
local filesystem = require("filesystem")
local term = require("term")
local superlib = require("superlib")

dbfile = "/authdb.dat"
logfile = "/authlog.txt"

closeList = {}

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

local function log(logdata)
    f = io.open(logfile, "a")
    f:write(logdata.."\n")
    f:close()
end

local function openDoor(door)
    if door.isOpen() == false then
        door.toggle()
    end
end

local function closeDoor(doorad)
    doorad = table.remove(closeList, 1)
    door = component.proxy(doorad)
    if door.isOpen() == true then
        door.toggle()
    end
end

local function toggleDoor(doorad)
    door = component.proxy(doorad)
    openDoor(door)
    table.insert(closeList, doorad)
    event.timer(3, closeDoor)
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

function check(maddr, paddr, dooraddr, doordb, username)
    if maddr == paddr then 
        log("Door ".. doordb["name"] .. " Opened by " .. username .. "'s card")
        toggleDoor(dooraddr)
    end
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
            check(addr, d["mag"], d["door"], d, username)
        end
    end 
end

print("OSd (OpenSecuritydoorDaemon) starting up...")
print("Registering event handlers")
event.listen("magData", auth)
print("Event listeners registered")
print("Do not run this program again, untill the next restart of this computer.")
print("if you do, you will have multiple handlers running.")