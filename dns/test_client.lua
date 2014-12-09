dns = require("dns")

print("Registering Test")
dns.register("Test")

print("Looking up Test")
print(dns.lookup("Test"))