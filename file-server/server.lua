network = require("network")
fs = require("filesystem")
serial = require("serialization")
result = false

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

function encodeFile(path)
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

print("File Server Starting...")
network.tcp.listen(80)

while true do
  a, b, c, r, p = event.pull("tcp")
  if b == "connection" then
    print("Client Connected on channel: "..c)
  end
  if b == "message" then
    --print("Received message on channel: "..c.. " ["..r.."]")
    result = _decode(r)
    if result ~= false then
      --print("Valid Data")
      action = result["action"]
      if action == "list" then
        print("Client on channel: "..c.." requested list")
        tmp_list = fs.list("/share")
        tmp_list = buildArray(tmp_list)
        tmp_list = {action="list", data=tmp_list}
        tmp_list = encode(tmp_list)
        network.tcp.send(c, tmp_list)
     end
     if action == "get" then
       print("Client on channel: "..c.." requested get "..result.data)
       realfile = fs.concat("/share", result.data)
       if fs.exists(realfile) then
       f = io.open(realfile)
       print("Reading file")
       tmp = f:read("*all")
       f:close()
       tmp = {action="get", data=tmp}
       print("Sending file")
       network.tcp.send(c, encode(tmp))
       print("Done")
       else print("Error: file does not exist.") end
     end
    end
  end
end