local version = "0.1.2"

local autopid = {} --Library 

local pid = require("pid")
local component = require("component")
local superlib = require("superlib")
local shell = require("shell")

controllers = {}

turbines = 0
reactors = 0

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

  loadedControllers[#loadedControllers + 1] = cid

  assert(loadfile(file, "t",env))()

  return pid.new(controller, cid, true)
end

function autopid.scan()
  for address, type in component.list() do
    if type == "br_turbine" then
      turbines = turbines + 1
      loadFile("/usr/autopid/turbine.apid", "turbine"..tostring(turbines), address, type)
    end 

    if type == "br_reactor" then
      reactors = reactors + 1
      loadFile("/usr/autopid/reactor.apid", "reactor"..tostring(reactors), address, type)
    end
  end
  controllers = pid.dump()
end

function autopid.shutdown()
  for _, controller in pairs(controllers) do
    controller.shutdown()
    pid.remove(controller.id)
  end
end

function autopid.dump()
  return controllers
end

return autopid
