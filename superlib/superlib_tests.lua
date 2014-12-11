superlib = require("superlib")
 
for i in pairs(superlib) do print(i) end

print(superlib.download("http://superminor2.net/test.txt"))
print(superlib.downloadFile("http://superminor2.net/test.txt", "test.txt"))