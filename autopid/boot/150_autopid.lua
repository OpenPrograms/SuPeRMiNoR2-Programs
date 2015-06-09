autopid = require("autopidlib")

configlocation = "/etc/autopid_autostart.txt"

config = io.open(configlocation, "r")

status = config:read()
config:close()

if status == "true" then 
  autopid.scan()
end