local function startup()
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
    print("[autopid] Scanning for machines...")
    if pcall(autopid.scan) then
      print("[autopid] Done.")
    else
      print("[autopid] crashed while scanning")
    end
  end
end

status, perror = pcall(startup())
if status == false then
  print("[autopid] Unknown error while running the startup script!")
  print(perror)
end
