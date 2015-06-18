internet = require("internet")
component = require("component")
superlib = require("superlib")
term = require("term")
stargate = component.

url = "https://raw.githubusercontent.com/CaitlynMainer/StargateList/master/Gates.txt"

function download(durl)
  local buff = ""
  for chunk in internet.request(durl) do buff = buff .. chunk end
  return buff
end

function parsegates()
  local gates = {}
  local raw = download(url)

  local raw = superlib.split(raw, "\n")

  for _,i in pairs(raw) do
    
    local tempgate = superlib.split(i, ",")
    table.insert(gates, {name=tempgate[1], address=tempgate[2]})
  end

  return gates
end

gates = {}
gates = parsegates()
table.

superlib.clearMenu()
for _,gate in pairs(gates) do
superlib.addItem(gate.name, gate.address)
end

tod = superlib.runMenu()
term.clear()