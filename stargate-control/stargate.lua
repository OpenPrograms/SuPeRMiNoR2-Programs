local component = require("component")
local term = require("term")
local superlib = require("superlib")
local keyboard = require("keyboard")

if component.isAvailable("abstract_bus") == false then
	error("This program requires an abstact bus card.")
end
ab = component.abstract_bus

menu = {}
menu["1"] = "DEsoapd"
menu["2"] = "dsadagsd"
menu["3"] = "dsafsadg453"

function rendermenu(mt)
term.clear()
for i, o in pairs(mt) do
	print(" "..i.."  ("..o..")")
end
end

function updatemenu(mt, sel)
term.setCursor(1, sel)
term.write("["..sel.."] ("..mt[sel]..")")
end

function menuloop(mt)
rendermenu(mt)
sel = 1
updatemenu(mt, sel)

while true do
	e, r, t, key = event.pull("key_down")

	if key == keyboard.keys.up then
		sel = sel + 1
		if sel > #menu then
			sel = 1
		end
	end
	if key == keyboard.keys.down then
		sel = sel - 1
		if sel < 1 then
			sel = #menu
		end
	end
	if key == keyboard.keys.enter then
		return mt[sel]
	end

	updatemenu(mt, sel)

	end
end