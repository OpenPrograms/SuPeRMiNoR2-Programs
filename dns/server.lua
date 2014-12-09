fs = require("filesystem")
serial = require("serialization")
component = require("component")
event = require("event")
modem = component.modem
dns_table = {}
 
function decode(data)
status, result = pcall(serial.unserialize, data)
if status then
 return result
else
 return false
end
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

if fs.exists("/dns-table") then
tmp = decode(read_file("/dns-table"))
if tmp ~= false then dns_table = tmp end
end

function _lookup(name)
return dns_table[name]
end

function lookup(name)
result, addr = pcall(_lookup, name)
if result then return addr else return false end
end

function register(name, addr)
dns_table[name] = addr
f = io.open("/dns-table", "w")
f:write(encode(dns_table))
f:close()
end

function send(addr, data)
modem.send(addr, 43, encode(data))
end

--------------------------------------------

modem.open(42)
while true do
e, _, address, port, distance, message = event.pull("modem_message") 
message = decode(message)
if message ~= false then

if message.action == "register" then
  print("Registering "..message.name.." to "..address)
  register(message.name, address)
end

if message.action == "lookup" then
 n = lookup(message.name)
 print(address.. " Looked up "..message.name)
 send(address, {action="lookup", response=n})
end

end
end