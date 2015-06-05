local version = "0.1.2.1"

local pid = require("pid")
local component = require("component")
local superlib = require("superlib")
local shell = require("shell")
local autopid = require("autopidlib")

loadedControllers = {}

versions = superlib.checkVersions()

turbines = 0
reactors = 0

if versions.autopid ~= version then
  print("There is an update availible for autopid!")
  sleep(2)
end

local function main(parameters, options)
  if #options == 0 then
    print([[
Usage: autopid [option] files or ids...
  option     what it does
  [none]       shows this
  --scan (-s)      scans and starts all controllers
  --shutdown      removes everything from pid and stops it
]])
  end
  
  if options.scan or options.s then
    print("Scanning for machines.")
    autopid.scan()

  elseif options.shutdown then
    print("Searching for machines to shutdown")
    autopid.shutdown()

  elseif options.debug then
    --operation "debug" displays the given controllers
    --runMonitor(loadedControllers, loadedIDs)
    t = 1
  end
end

--parseing parameters and executing main function
local parameters, options = shell.parse(...)
return main(parameters, options)
