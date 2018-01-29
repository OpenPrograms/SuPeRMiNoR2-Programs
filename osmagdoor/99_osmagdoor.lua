os = require("os")
local function startup()
  os.execute("/usr/bin/osd.lua")
end

status, perror = pcall(startup)
if status == false then
  print("Unknown error starting osmagdoor!")
  print(perror)
end
