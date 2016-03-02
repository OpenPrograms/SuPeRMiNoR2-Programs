local version = "0.1.2"

local autopid = {} --Library 

local pid = require("pid")
local component = require("component")
local superlib = require("superlib")
local shell = require("shell")

local controllers = {}

local turbines = 0
local reactors = 0

autopid.help = [[
Usage: autopid [option] [file or id to operate on]

Machine startup / shutdown:
  -s, --scan       scans and starts all controllers
  --shutdown       removes everything from pid and stops it
  -r, --restart    deactivate all, remove from pid, then scan again. (add new things?)

Miscellaneous:
  --help           Show this help message and exit
]]

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
  controllers = pid.registry()
end

function autopid.shutdown()
  for _, controller in pairs(controllers) do
    controller.shutdown()
    pid.remove(controller, true)
  end
end

function autopid.dump()
  return controllers
end

return autopid
