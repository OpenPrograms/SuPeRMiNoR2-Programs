--And so it begins.
component = require("component")
ser = require("serialization")

if component.isAvailable("modem") == false then
  print("This program requires a network modem to be installed.")
  break
end

