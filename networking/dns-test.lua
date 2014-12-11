dns = require("dns")
name = "__dns__"

print("Registering "..name)
dns.register(name)
print("Looking up "..name)
result, addr = dns.lookup(name)
if result then
	print("Found "..addr.." for "..name)
else
	print("Error")
end