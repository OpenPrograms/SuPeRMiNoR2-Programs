local superlib = require("superlib")
local term = require("term")
local keyboard = require("keyboard")
local event = require("event")
local m = {}

lastmenu = false

menu = {}

function rendermenu(mt)
	term.clear()
	for i=1, #mt do
		print(" "..i.."  ("..mt[i]["name"]..")")
	end
end

function updatemenu(mt, sel)
	if lastmenu ~= false then
		term.setCursor(1, lastmenu)
		term.clearLine()
		term.write(" "..lastmenu.."  ("..mt[lastmenu]["name"]..")")
	end
	term.setCursor(1, sel)
	term.clearLine()
	term.write("["..sel.."] ("..mt[sel]["name"]..")")
end

function m.addItem(name, data)
	menu[#menu + 1] = {name=name, data=data}
end

function m.getSelection()
	rendermenu(menu)
	sel = 1
	updatemenu(menu, sel)

	while true do
		e, r, t, key = event.pull("key_down")

		if key == keyboard.keys.down then
			lastmenu = sel
			sel = sel + 1
			if sel > #menu then
				sel = 1
			end
		end
		if key == keyboard.keys.up then
			lastmenu = sel
			sel = sel - 1
			if sel < 1 then
				sel = #menu
			end
		end
		if key == keyboard.keys.enter then
			return mt[sel]["addr"]
		end
		if key == keyboard.keys.q then
			return false
		end
		updatemenu(mt, sel)
	end
end