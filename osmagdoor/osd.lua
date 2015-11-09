local component = require("component")
local event = require("event")
local os = require("os")
local serialization = require("serialization")
local filesystem = require("filesystem")
local term = require("term")
local superlib = require("superlib")
local osmag = require("osmag")

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

function updateDB()
    db = loadDB()
    print("Database updater scanning for things that need to be fixed...")

    for i, pair in ipairs(db["pairs"]) do
        if not pair["password"] then 
            newpass = osmag.makeCode()
            db["pairs"][i]["password"] = newpass
            doorc = component.proxy(pair["door"])
            doorc.setPassword(newpass)
            print("[DBUpdate] Added password to door "..pair["name"])
        end
    end
    print("Database update complete.")
    saveDB(db)
end

function log(logdata)
    f = io.open(logfile, "a")
    f:write(logdata)
    f:close()
end

local function openDoor(door, pass)
    if door.isOpen() == false then
        door.toggle(pass)
    end
end

local function closeDoor()
    doorad = table.remove(closeList, 1)
    door = component.proxy(doorad["addr"])
    if door.isOpen() == true then
        door.toggle(doorad["password"])
    end
end

local function toggleDoor(doordb)
    pass = doordb["password"]
    door = component.proxy(doordb["door"])
    openDoor(door, pass)
    table.insert(closeList, {addr=doordb["addr"], password=doordb["password"]})
    event.timer(3, closeDoor)
end

local function checkCard(UUID, carddata)
    db = loadDB()

    if carddata["t"] == "temp" then 
        currenttime = os.time()
        if currenttime > carddata["e"] then
            return false
        end
    end

    for i in ipairs(db["registered"]) do
        if db["registered"][i]["uuid"] == UUID then
            return true, db["registered"]["username"]
        end
    end
    return false
end

function check(maddr, d, username)
    if maddr == d["mag"] then 
        toggleDoor(d)
        log("Door ".. d["name"] .. " Opened by " .. username .. " card")
    end
end

function auth(_,addr, playerName, data, UUID, locked)
    db = loadDB()

    carddata = serialization.unserialize(data)
    for i, d in ipairs(db["new"]) do --Check for first swipe of newly registered card, and get its UUID
        if d["code"] == carddata["code"] then
            table.insert(db["registered"], {username=playerName, uuid=UUID, title=d["title"]})
            print("Registered card ".. UUID .. " to user ".. playerName)
            table.remove(db["new"], i)
            saveDB(db)
        end
    end

    allowed, username = checkCard(UUID, carddata)
    if allowed then
        for u, d in ipairs(db["pairs"]) do
            check(addr, d, username)
        end
    end 
end

print("OSd (OpenSecuritydoorDaemon) starting up...")
updateDB()
print("Registering event handlers")
event.listen("magData", auth)
print("Event listeners registered")
print("Do not run this program again, untill the next restart of this computer.")
print("if you do, you will have multiple handlers running.")