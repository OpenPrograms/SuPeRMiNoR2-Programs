local version = "0.1.1"
fs = require("filesystem")
serial = require("serialization")
component = require("component")
event = require("event")
modem = component.modem
tunnel = component.tunnel

function decode(data)
status, result = pcall(serial.unserialize, data)
return status, result
end
 
function encode(data)
return serial.serialize(data)
end

function send(addr, port, data)
modem.send(addr, port, encode(data))
end

function broadcast(port, data)
modem.broadcast(port, encode(data))
end

function tsend(data)
tunnel.send(encode(data))
end

print("Starting J&S tunnel server version "..version)
print("Opening ports")
for i=40,45 do modem.open(i) end
print("Tunnel server started")


while true do
  e, _, address, port, distance, message = event.pull("modem_message")
  --result, message = decode(message)
  result = true
  if result then
    if port == 0 then
      print("Received message on tunnel "..message)
      if message.broadcast then
        broadcast(message.port, message)
      else
        send(message.to, message.port, message)
      end
    end

    if port ~= 0 then
      print("Received message on modem "..message)
      if message.tunnel then
        print("Forwarding")
        message.from = address       
        message.port = port
        message.tunneled = true
        tsend(message)
      end
    end
  end
end