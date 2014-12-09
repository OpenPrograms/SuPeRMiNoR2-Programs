network = require("network")
fs = require("filesystem")
serial = require("serialization")
string = require("string")
event = require("event")
result = false
debug = false

--May need to split files into sections to get larger files across.
 
function _decode(data)
result = serial.unserialize(data)
return result
end
 
function decode(data)
status = pcall(serial.unserialize, data)
if status then
 return result
else
 return false
end
end
 
function encode(data)
return serial.serialize(data)
end

function encodeFile(path)
good = false
data = nil
if fs.exists(path) then
 f = fs.open(path)
 data = f:read()
 f:close()
 good = true
end
if good then return data else return false end
end

function getMessage()
while true do
a, b, c, r, p, j, k, l = event.pull()
print("Got event [debug]")
print(a, b, c, r, p, j, k, l)

if a == "tcp" and b == "message" then --network api is bugged, and this wont be triggered atm
result = _decode(r)
return result
end

if a == "network_message" then
print("Got data from server using bypass method. *Unsafe*, talk to magik about fixing")
c = string.sub(c, 5)
--[[
f = fs.open("/debug.txt", "w")
f:write(c)
f:close()
]]--
return _decode(c)
end

end
end

function getFile(channel, serverpath, path)
msg = {action="get", data=serverpath}
print("Requesting file "..serverpath)
network.tcp.send(channel, encode(msg))
msg = getMessage()

if msg.action == "get" then
print("Writing file "..path)
f = fs.open(path, "w")
f:write(msg.data)
f:close()
end
end

server = "FileServer"
server_addr = false
payload = "areyoustillthere"
 
print("File Client Starting...")
print("Sending ping to: "..server)
ping_id = network.icmp.ping(server, payload)

while true do
e, addr, id, rpayload = event.pull("ping_reply")
if id == ping_id and rpayload == payload then
print("Server replied to ping.")
server_addr = addr
break
else
print("Server ping failed.")
end
end

print("Starting TCP Connection.")
network.tcp.open(server, 80)
os.sleep(0.5)
--network.tcp.open(server, 80) --Bug fix? It won't work the first time

while true do 
  a, b, c, r, p = event.pull("tcp")
  if b == "connection" then
    tcp = c
    server_addr = r
    print("TCP Connection Sucessful.")
    break
  end
end

print("Getting list of files.")
network.tcp.send(tcp, encode({action="list"}))
msg = getMessage()
print("Downloading all files")

for i, name in pairs(msg["data"]) do
realname = fs.concat("/dl", name)
getFile(tcp, name, realname)
os.sleep(1)
end

print("Goodbye")