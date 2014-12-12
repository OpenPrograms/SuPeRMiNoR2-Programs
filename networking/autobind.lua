function loaddns()
	dns = require("dns")
	return dns
end

result, dns = pcall(loaddns)
if result then
	fs = require("filesystem")
	if fs.exists("/etc/hostname") then
		f = io.open("/etc/hostname")
		hostname = f:read()
		f:close()
		dns.register(hostname)
		print("Registering to dns server as: "..hostname)
	end
else
	print("DNS Autobind encountered an error loading the dns library")
end