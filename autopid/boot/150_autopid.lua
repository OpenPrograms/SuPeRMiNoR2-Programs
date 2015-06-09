autopid = require("autopidlib")

configlocation = "/etc/autopid_autostart.txt"

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