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
tmp = encode(data)
--[[
l = len(tmp)
data = {}
parts = 1
if l > 8000 then
 if l / 2 < 8000 then
  parts = 2
  data[1] = string.sub(tmp, 1, 8000)
  data[2] = string.sub(tmp, 8001)
 end
end
]]--
modem.send(addr, port, tmp)
end

function broadcast(port, data)
modem.broadcast(port, encode(data))
end

file_table = {}
function scanDir(path)
  for item in fs.list(path) do
    --print(item)
    if fs.isDirectory(item) then
      scanDir(fs.concat(path, item))
    else
      file_table[#file_table + 1] = string.sub(fs.concat(path, item), 7)
    end
  end
end

print("Building file table")
scanDir("/share")
print("Done")

print("File Server Starting...")
dns.register("FileServer")
modem.open(80)

while true do
  --a, b, c, r, p = event.pull("modem_")
  e, _, address, port, distance, message = event.pull("modem_message")
  result, msg = decode(message)
  if result then

    if msg.action == "ping" then
      print("Client "..address.." sent ping")
      tmp_list = {action="ping"}
      send(address, 81, tmp_list)
    end

    if msg.action == "list" then
      print("Client "..address.." requested list")
      --tmp_list = fs.list("/share")
      --tmp_list = buildArray(tmp_list)
      send(address, 81, {action="list", data=file_table})
    end

    if msg.action == "get" then
      print("Client "..address.." requested get "..msg.data)
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
end