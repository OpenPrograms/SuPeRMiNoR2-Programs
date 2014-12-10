fs = require("filesystem")
serial = require("serialization")
component = require("component")
dns = require("dns")
modem = component.modem
result = false

function decode(data)
status, result = pcall(serial.unserialize, data)
return status, result
end

function buildArray(input)
  local arr = {}
  for v in input do
    arr[#arr + 1] = v
  end
  return arr
end

function encode(data)
return serial.serialize(data)
end

function decodeFile(path)
good = false
data = nil
if fs.exists(path) then
 f = open(path)
 data = f:read()
 f:close()
 good = true
end
if good then return data else return false end
end

function send(addr, port, data)
modem.send(addr, port, encode(data))
end

function broadcast(port, data)
modem.broadcast(port, encode(data))
end

print("File Server Starting...")
dns.register("FileServer")
modem.open(80)

while true do
  --a, b, c, r, p = event.pull("modem_")
  e, _, address, port, distance, message = event.pull("modem_message")
  result, msg = decode(message)
  if result then
    if msg.action == "list" then
      print("Client on channel: "..c.." requested list")
      tmp_list = fs.list("/share")
      tmp_list = buildArray(tmp_list)
      tmp_list = {action="list", data=tmp_list}
      send(addres, 81, tmp_list)
    end
  end

  if msg.action == "get" then
    print("Client on channel: "..c.." requested get "..msg.data)
    realfile = fs.concat("/share", msg.data)
    if fs.exists(realfile) then
       f = io.open(realfile)
       print("Reading file")
       tmp = f:read("*all")
       f:close()
       tmp = {action="get", data=tmp}
       print("Sending file")
       send(address, 81, tmp)
       print("Done")
    else 
      print("Error: file does not exist.") 
    end
  end

end