local component = require("component")
local term = require("term")
local superlib = require("superlib")
local keyboard = require("keyboard")
local event = require("event")
local serial = require("serialization")

if component.isAvailable("abstract_bus") == false then
  error("This program requires an abstact bus card.")
end
ab = component.abstract_bus
lastmenu = false

t = superlib.download("http://superminor2.net/mc/stargates.lua")
_, menu = decode(t)

function dial(addr)
  ab.send(0xFFFF, {action="dial", address=addr})
end

function rendermenu(mt)
  term.clear()
  for i=1, #mt do
    print(" "..i.."  "..mt[i]["name"].." ("..mt[i]["addr"]..")")
  end
end

function updatemenu(mt, sel)
  if lastmenu ~= false then
    term.setCursor(1, lastmenu)
    term.clearLine()
    term.write(" "..lastmenu.."  "..mt[lastmenu]["name"].." ("..mt[lastmenu]["addr"]..")")
  end
  term.setCursor(1, sel)
  term.clearLine()
  term.write("["..sel.."] "..mt[sel]["name"].."("..mt[sel]["addr"]..")")
end

function menuloop(mt)
  rendermenu(mt)
  sel = 1
  updatemenu(mt, sel)

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

while true do
  addr = menuloop(menu)
  term.clear()
  print("You selected "..addr)
  if addr ~= false then
    dial(addr)
  end
  os.sleep(0.5)

end