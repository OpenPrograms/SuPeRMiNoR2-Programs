pid = require("pid")
component = require("component")

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
  print("Injecting address: "..address)
  controller.address = address

  assert(loadfile(file, "t",env))()
  --initialize the controller

  return pid.new(controller, cid, true)
end

turbines = 0
reactors = 0

for address, type in component.list() do

if type == "br_turbine" then do
  turbines = turbines + 1
  print("Detected turbine #"..tostring(turbines).." address: "..address)
  loadFile("/usr/autopid/turbine.pid", "turbine"..tostring(turbines), address, type)
end 
end

if type == "br_reactor" then do
  reactors = reactors + 1
  print("Detected reactor #"..tostring(reactors).." address: "..address)
  loadFile("/usr/autopid/reactor.pid", "reactor"..tostring(reactors), address, type)
end
end

end