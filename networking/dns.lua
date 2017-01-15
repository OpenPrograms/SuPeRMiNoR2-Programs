local m = {}
m.dns_table = {}
m.rdns = {}
fs = require("filesystem")
serial = require("serialization")
component = require("component")
event = require("event")
modem = component.modem

function decode(data)
status, result = pcall(serial.unserialize, data)
return status, result
end
 
function encode(data)
return serial.serialize(data)
end
 
function write_file(path, data)
f = fs.open(path, "w")
f:write(data)
f:close()
end

function read_file(path)
f = io.open(path)
t = f:read("*all")
f:close()
return t
end

function _lookup(name)
return m.dns_table[name]
end

function _reverse(name)
return m.rdns[name]
end

function reverse(name)
result, addr = pcall(_lookup, name)
if result then return addr else return false end
end

function lookup(name)
result, addr = pcall(_lookup, name)
if result then return addr else return false end
end

function register(name, addr)
m.dns_table[name] = addr
m.rdns[addr] = name
f = io.open("/dns-table", "w")
f:write(encode(m.dns_table))
f:close()
end

function send(addr, data)
modem.send(addr, 43, encode(data))
end

function csend(addr, data)
modem.send(addr, 42, encode(data))
end

function cbroadcast(data)
modem.broadcast(42, encode(data))
end

m.dns_addr = false

function m.get(port, timeout)
  --Is this even tested? Bitch it might not be
  timeout = timeout or 5
  modem.open(port)
  e, _, address, _port_, distance, message = event.pull(timeout, "modem_message")
  modem.close(port)
  if e ~= nil then
    result = true
  else
    result = false
  end

  r, data = decode(message)

  return result, address, message, r, data
end

function m.send(port, data, tunnel)
  tunnel = tunnel or true
    if tunnel then
        --add a decode here, and add the port to the data going out
        modem.broadcast(100, data) --I might work on making the tunnel stuff more advanced, so it wont need broadcasts
        --That would make it more complicated, and easier to break though.
    end
    modem.send(port, data)
end
    
function m.lookup(name)
  found = false
  found_name = nil
  modem.open(43)
  cbroadcast({action="lookup", name=name, tunnel=true, broadcast=true})
  e, _, address, port, distance, message = event.pull(5, "modem_message") 
  modem.close(43)
  result, message = decode(message)
  if result then
    if message.action == "lookup" then
     found = true
     found_name = message.response
    end
  end
  return found, found_name
end

function m.register(name)
  cbroadcast({action="register", name=name, tunnel=true, broadcast=true})
  -- result, addr, m, dr, de = m.get(43)
  -- if dr then
  --   if de.name == name then
  --     return true
  --   end
  -- end
  -- return false
end
end

function m.server()
  print("Starting DNS Server")
  if fs.exists("dsad/dns-table") then
    result, tmp = decode(read_file("/dns-table"))
    if result and tmp ~= false then
      print("Loaded dns table from file")
      print(tmp)
      m.dns_table = tmp 
    end
  end

  modem.open(42)

  while true do
    e, _, address, port, distance, message = event.pull("modem_message")
    result, message = decode(message)
    if result then
      if message.action == "register" then
        print("Registering "..message.name.." to "..address)
        register(message.name, address)
        send(address, {action="register", name=message.name})
      end

      if message.action == "lookup" then
        n = lookup(message.name)
        print(address.. " Looked up "..message.name)
        send(address, {action="lookup", response=n})
      end

      if message.action == "reverse" then
        n = lookup(message.name)
        print(address.. " Reverse looked up "..message.name)
        send(address, {action="reverse", response=n})
      end 

    end

  end
end

return m
