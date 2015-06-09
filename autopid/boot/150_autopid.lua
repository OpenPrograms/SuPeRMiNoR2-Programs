autopid = require("autopidlib")
fs = require("filesystem")

configlocation = "/etc/autopid_autostart.txt"

if fs.exists(configlocation) == false then
  f = io.open(configlocation, "w")
  f.write("false")
  f.close()
end

config = io.open(configlocation, "r")

status = config:read()
config:close()

if status == "true" then 
  if pcall(autopid.scan) then
    print("[autopid] done")
  else
    print("[autopid] crashed while scanning")
  end
end