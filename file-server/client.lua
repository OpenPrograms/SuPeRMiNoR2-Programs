fs = require("filesystem")
serial = require("serialization")
string = require("string")
event = require("event")
component = require("component")
dns = require("dns")
modem = component.modem

debug = false

--May need to split files into sections to get larger files across.
 
function decode(data)
status, result = pcall(serial.unserialize, data)
return status, result
end
 
function encode(data)
return serial.serialize(data)
end

function decodeFile(path)
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

function send(addr, port, data)
addr = addr or server_addr
port = port or 80
modem.send(addr, port, encode(data))
end

function broadcast(port, data)
modem.broadcast(port, encode(data))
end

function getMessage()
  while true do
    modem.open(81)
    print("wating for server message")
    e, localAddress, address, port, distance, message = event.pull(5, "modem_message")
    modem.close(81)
    print("Got data from server.")
    return decode(message)
  end
end

function getFile(serverpath, path)
  msg = {action="get", data=serverpath}
  print("Requesting file "..serverpath)
  send(msg)
  result, msg = getMessage()

  if result then
    if msg.action == "get" then
      print("Writing file "..path)
      f = fs.open(path, "w")
      f:write(msg.data)
      f:close()
    end
  end
end

server = "FileServer"
server_addr = false
 
print("File Client Starting...")
print("Trying to resolve "..server)
server_addr = dns.lookup(server)
print("Server address "..server_addr)

print("Getting list of files.")
send({action="list"})
result, msg = getMessage()
print("Downloading all files")

if result then
  for i, name in pairs(msg["data"]) do
  realname = fs.concat("/dl", name)
  getFile(tcp, name, realname)
  os.sleep(1)
  end
end

print("Goodbye")