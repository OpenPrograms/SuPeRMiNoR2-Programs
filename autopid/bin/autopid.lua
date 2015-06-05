local version = "0.1.1.2"

local pid = require("pid")
local component = require("component")
local superlib = require("superlib")
local shell=require("shell")

local parameters, options = shell.parse(...)

loadedControllers = {}

versions = superlib.checkVersions()

turbines = 0
reactors = 0

if versions.autopid ~= version then
  print("There is an update availible for autopid!")
  sleep(2)
end

local function loadFile(file, cid, address, type)
  local controller={}
  local env=setmetatable({},{
    __index=function(_,k)
      local value=controller[k]
      if value~=nil then
        return value
      end
      return _ENV[k]
    end,
    __newindex=controller,
  })
  
  controller.autopid = true
  controller.address = address
  controller.id = cid
  controller.log = log
  controller.type = type

  loadedControllers[loadedControllers + 1] = cid

  assert(loadfile(file, "t",env))()

  return pid.new(controller, cid, true)
end

local function scan()
  for address, type in component.list() do
    if type == "br_turbine" then
      turbines = turbines + 1
      print("Detected turbine #"..tostring(turbines).." address: "..address)
      loadFile("/usr/autopid/turbine.apid", "turbine"..tostring(turbines), address, type)
    end 

    if type == "br_reactor" then
      reactors = reactors + 1
      print("Detected reactor #"..tostring(reactors).." address: "..address)
      loadFile("/usr/autopid/reactor.apid", "reactor"..tostring(reactors), address, type)
    end
  end
end

local function main(parameters, options)
  if #parameters == 0 then
    print([[
Usage: autopid [option] files or ids...
  option     what it does
  [none]       shows this
  --scan       scans and starts all controllers
  --shutdown      removes everything from pid and stops it
]])
    return
  end
  
  local pidObjects={}

  for _,name in ipairs(loadedControllers) do
    local pcontroller = pid.get(id)
    pidObjects[#pidObjects + 1] = pcontroller
    print(pcontroller.id)
  end
  
  if options.scan then
    scan()

  elseif options.shutdown then
    for _, controller in ipairs(pidObjects) do
      controller:stop()
      controller.shutdown()
      pid.remove(controller.id)
    end

  elseif options.debug then
    --operation "debug" displays the given controllers
    --runMonitor(loadedControllers, loadedIDs)
    t = 1
  end
end

--parseing parameters and executing main function
return main(parameters, options)
