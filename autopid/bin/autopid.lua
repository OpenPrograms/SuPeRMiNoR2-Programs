local version = "0.1.2.1"

local pid = require("pid")
local component = require("component")
local superlib = require("superlib")
local shell = require("shell")
local autopid = require("autopidlib")

turbines = 0
reactors = 0

local function main(parameters, options)
  if options.scan or options.s then
    print("Scanning for machines.")
    autopid.scan()

  elseif options.shutdown then
    print("Searching for machines to shutdown")
    autopid.shutdown()

  elseif options.restart or options.r then
    print("Stopping and restarting.")
    autopid.shutdown()
    autopid.scan()
    print("Done.")

  elseif options.debug then
    --operation "debug" displays the given controllers
    --runMonitor(loadedControllers, loadedIDs)
    t = 1
  end

  else then
    print(autopid.help)
  end
  
end

--parseing parameters and executing main function
local parameters, options = shell.parse(...)
return main(parameters, options)
