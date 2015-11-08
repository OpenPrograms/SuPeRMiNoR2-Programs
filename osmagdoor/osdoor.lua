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
logfile = "/authlog.txt"

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

closeList = {}
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
    term.clear()
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

    superlib.clearMenu()
    for i, d in ipairs(freeDoors) do
        superlib.addItem("Door ", d)
    end
    superlib.addItem("Cancel", "c")
    door = superlib.runMenu("Please select the door uuid you want to add.")

    if door ~= "c" then
        superlib.clearMenu()
        for i, d in ipairs(freeMags) do
            superlib.addItem("Reader ", d)
        end
        superlib.addItem("Cancel", "c")
        mag = superlib.runMenu("Please select the mag reader uuid you want to pair to the door.")

        if mag ~= "c" then
            term.clear()
            name = getUser("Enter a name for this pair: ")
            table.insert(db["pairs"], {door=door, mag=mag, name=name})
        end
    end
    saveDB(db)
end

local function removeDoor()

end

local function removeCard()

end

local function clearCards()
    fdb = loadDB()
    for c in db["new"] do
        table.remove(db["new"], c)
    end

end

function check(maddr, paddr, dooraddr, doordb, username)
    if maddr == paddr then 
        log("Door ".. doordb.name .. " Opened by " .. username .. "'s card")
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

local function menus() 
    superlib.clearMenu()
    superlib.addItem("Register a card", "r")
    superlib.addItem("Register a door", "d")
    superlib.addItem("Remove a door", "rd")
    superlib.addItem("Remove a card", "rc")
    superlib.addItem("Clear waiting cards", "cc")
    key = superlib.runMenu("Super Security System [Beta]")

    if key == "r" then
        registerCard()
    elseif key == "d" then
        registerDoor()
    elseif key == "rd" then
        removeDoor()
    elseif key == "rc" then
        removeCard()
    elseif key == "cc" then
        clearCards()
    end
end

function main()
    print("OSMagDoor Starting Up")
    event.ignore("magData", auth)
    event.listen("magData", auth)
    print("Event listeners registered")
    print("For your information, this interface is only needed for adding new doors")
    print("And adding new cards (and deleting both of those)")
    print("You can shut this program down, and the event will keep running, and doors will still open")
    print("Because of this, you need to restart the computer before starting this program again")
    print("If you fail to do this, you will have multiple event listeners running, and you do not want that.")
    os.sleep(5)
    term.clear()
    
    while true do
        menus()
    end
end
main()
