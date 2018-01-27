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
local osmag = require("osmag")

dbfile = "/authdb.dat"
logfile = "/authlog.txt"

writer = component.os_cardwriter

local function log(logdata)
    f = io.open(logfile, "a")
    f:write(logdata.."\n")
    f:close()
end

local function checkCard(UUID)
    db = osmag.loadDB()
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

local function registerCard()
    db = osmag.loadDB()
    term.clear()
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    superlib.addItem("Full Access Card", "full")
    superlib.addItem("Temporary Card", "temp")
    choice = superlib.runMenu("Select new card type")
    if choice ~= "c" then
        cardcode = osmag.makeCode()
        carddata = {code=cardcode}
        term.clear()
        title = getUser("Enter the name of the user who will use this card: ")
        if choice == "full" then
            carddata["type"] = "full"
        elseif choice == "temp" then
            carddata["type"] = "temp"
            ctime = os.time()
            days = getUser("Enter the amount of minecraft days you want the card to last: ")
            days = tonumber(days)
            extratime = days * 86400
            expiretime = ctime + extratime
            carddata["expire"] = expiretime
        end

        cardstring = serialization.serialize(carddata)
        print("Writing data to card...")
        writer.write(cardstring, title, true)
        print("Adding card to database...")
        table.insert(db["new"], {code=cardcode, title=title, type=carddata["type"], expire=expiretime})
        print("Saving database....")
        osmag.saveDB(db)
        os.sleep(1)
    end
end


local function findNewGID(db)
    last = 0
    for i, d in ipairs(db["groups"]) do
        if last < d["gid"] then
            last = d["gid"]
        end
    end
    last = last + 1
    return last
end

local function lookupGID(db, gid)
    for i, d in ipairs(db["groups"]) do
        if gid == d["gid"] then
            return d["name"]
        end
    end
    return "Error"
end    

function registerDoor(ddb)
    freeDoors = {}
    freeMags = {}

    for address, ctype in component.list() do
        if ctype == "os_door" or ctype == "os_doorcontroller" then
            reg = false
            for raddr in ipairs(ddb["pairs"]) do
                if address == ddb["pairs"][raddr]["door"] then
                    reg = true
                end
            end
            if not reg then 
                table.insert(freeDoors, address) 
            end
        end

        if ctype == "os_magreader" then
            reg = false
            for raddr in ipairs(ddb["pairs"]) do
                if address == ddb["pairs"][raddr]["mag"] then
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
        superlib.addItem("Door: "..d, d)
    end
    superlib.addItem("Cancel", "c")
    door = superlib.runMenu("Please select the door uuid you want to add.")

    if door ~= "c" then
        superlib.clearMenu()
        for i, d in ipairs(freeMags) do
            superlib.addItem("Reader: "..d, d)
        end
        superlib.addItem("Cancel", "c")
        mag = superlib.runMenu("Please select the mag reader uuid you want to pair to the door.")

        if mag ~= "c" then
            term.clear()
            name = getUser("Enter a name for this pair: ")
            print("Generating door password.")
            newpass = osmag.makeCode()
            doorc = component.proxy(door)
            print("Setting door password.")
            success, msg = doorc.setPassword(newpass)
            if msg == nil then
                msg = success
            end
            if msg == "Password set" then
                print("Door password set successfully.")
                table.insert(ddb["pairs"], {door=door, mag=mag, name=name, password=newpass, gid=1})
                return ddb
                os.sleep(1)
            else
                print("Failed to set door password, please break the door[s] and replace them to clear the password.")
                os.sleep(2)
            end
        end
    end
end

local function removeDoor(ldb)
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    for i, d in ipairs(ldb["pairs"]) do
        superlib.addItem(d["name"], i)
    end
    door = superlib.runMenu("Please select the door you want to remove.")
    if door ~= "c" then
        
    end
    osmag.saveDB(ldb)
end

local function removeCard()
    ldb = osmag.loadDB()
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    for i, d in ipairs(ldb["registered"]) do
        superlib.addItem(d["title"] .. " (" .. d["uuid"]..")", i)
    end
    card = superlib.runMenu("Please select the card you want to remove.")
    if card ~= "c" then
        table.remove(ldb["registered"], card)
    end
    osmag.saveDB(ldb)
end

local function clearCards()
    ldb = osmag.loadDB()
    term.clear()
    print("Clearing all unregistered cards...")
    for c, d in pairs(ldb["new"]) do
        print("Removing card: "..d["title"])
        table.remove(ldb["new"], c)
    end
    osmag.saveDB(ldb)
    os.sleep(1)
end

function doorEditor(db)
    term.clear()
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    superlib.addItem("Add a new door", "d")
    for i, d in ipairs(db["pairs"]) do
        superlib.addItem(d["name"] .. ", Current Group: " .. lookupGID(db, d["gid"]), i)
    end
    c = superlib.runMenu("[Door Editor] Select an option")
    if c == "c" then
        return db
    elseif c == "d" then
    	db = registerDoor(db)
    	return db
    else
    	superlib.clearMenu()
    	superlib.addItem("Cancel", "c")
    	superlib.addItem("Change group", "g")
    	superlib.addItem("Rename door", "r")
    	superlib.addItem("Delete door", "d")
    	nc = superlib.runMenu("[Door: ".. db["pairs"][c]["name"] .. "]")

    	if nc == "c" then
    		return db
    	elseif nc == "g" then
	        superlib.clearMenu()
	        for g, d in ipairs(db["groups"]) do
	            superlib.addItem(d["name"], g)
	        end
	        term.clear()
	        cg = superlib.runMenu("[Door: ".. db["pairs"][c]["name"] .. "] Select new group (Current Group: ".. lookupGID(db, db["pairs"][c]["gid"]).. ")")
	        db["pairs"][c]["gid"] = db["groups"][cg]["gid"]
        	return db
        elseif nc == "r" then
        	term.clear()
        	local name = getUser("Enter the new name for this door: ")
        	db["pairs"][c]["name"] = name
        	return db
        elseif nc == "d" then
       		m.tryToDeleteDoor(db["pairs"][c]["address"], db["pairs"][c]["password"])
	        table.remove(db["pairs"], c)
	        return db
	    end
    end
end 

function cardEditor(db)
    db = osmag.loadDB()
    term.clear()
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    return db
end 


function groupEditor(db)
    term.clear()
    superlib.clearMenu()
    superlib.addItem("Cancel", "c")
    superlib.addItem("Add new group", "g")
    for i, d in ipairs(db["groups"]) do
        superlib.addItem(d["name"] .. " (" .. d["gid"] .. ")", i)
    end
    c = superlib.runMenu("Group Editor")
    if c == "c" then
        return db
    elseif c == "g" then
        term.clear()
        newname = getUser("Enter a name for the new group: ")
        newgid = findNewGID(db)
        table.insert(ldb["groups"], {gid = newgid, name = newname})
        return db
    else
        term.clear()
        superlib.clearMenu()
        superlib.addItem("Cancel", "c")
        superlib.addItem("Rename Group", "r")
        superlib.addItem("Delete Group", "d")
        e = superlib.runMenu("Edit Group: "..db["groups"][c]["name"])
        if e == "c" then
            return db
        elseif e == "d" then
            if db["groups"][c]["gid"] == 1 then
                term.clear()
                print("Sorry, you can't remove the default group")
                os.sleep(1)
                return db
            end
            table.remove(db["groups"], c)
            return db
        elseif e == "r" then
            term.clear()
            newname = getUser("Please enter the new group name: ")
            db["groups"][c]["name"] = newname
            return db
        end
    end  
end 


local function menus()
	local db = osmag.loadDB() 
    superlib.clearMenu()
    superlib.addItem("Exit", "e")
    superlib.addItem("Door Editor", "d")
    superlib.addItem("Card Editor", "c")
    superlib.addItem("Group Editor", "g")
    key = superlib.runMenu("OpenSecurity Door Controller")

    if key == "e" then
    	osmag.saveDB(db)
        return "exit"
    elseif key == "d" then
        db = doorEditor(db)
    elseif key == "c" then
        db = cardEditor(db)
    elseif key == "g" then
        db = groupEditor(db)
    end
    osmag.saveDB(db)
end

function main()
    term.clear()
    while true do
        r = menus()
        if r == "exit" then
            term.clear()
            break
        end
    end
end
main()
