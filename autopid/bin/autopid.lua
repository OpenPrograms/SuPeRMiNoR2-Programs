local version = "0.0.2"

pid = require("pid")
component = require("component")
superlib = require("superlib")

versions = superlib.checkVersions()
if versions.autopid ~= version then
  print("There is an update availible for autopid!")
  sleep(2)
end

function log(message)
  print("["..id.."] "..message)
end

local function loadFile(file, cid, address, type)
  local controller={}
  --custom environment
  --reading: 1. controller, 2. _ENV
  --writing: controller only
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
  --load and execute the file
  controller.autopid = true
  controller.address = address
  controller.id = cid
  controller.log = log
  assert(loadfile(file, "t",env))()
  --initialize the controller

  return pid.new(controller, cid, true)
end

turbines = 0
reactors = 0

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