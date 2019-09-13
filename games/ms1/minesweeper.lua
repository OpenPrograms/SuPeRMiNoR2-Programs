--Very Beta Minesweeper
--Based off of http://pastebin.com/WJuZjJzr
local version = "0.2"

local math = require("math")
local computer = require("computer")
local component = require("component")
local string = require("string")
local term = require("term")
local event = require("event")
local gpu = component.gpu

local w, h = gpu.maxResolution()
w = w / 2
h = h / 2
gpu.setResolution(w, h)

difficulty = 0.05

local colors = {white=0xFFFFFF, green=0x00FF00, yellow=0xFFCC00, red=0xFF0000, lightGray=0xCCCCCC, black=0x000000}

colors["defaultBG"] = gpu.getBackground()
colors["defaultFG"] = gpu.getForeground()

math.randomseed(computer.freeMemory() + computer.uptime() + computer.totalMemory())
start = computer.uptime()

function printCentered(text)
textl = string.len(text)
middle = w - textl
starting_point = middle / 2
cx, cy = term.getCursor()
term.setCursor(starting_point, cy)
print(text)
end

term.clear()
printCentered("SuPeRMiNoR2's Minesweeper")
printCentered("Alpha Version")
os.sleep(2)

function click(x, y)
  if g[x][y] ~= 1 then
    return
  end

  local sum = 0
  clears = clears-1
  g[x][y] = 0
  for i=math.max(1,x-1),math.min(w,x+1) do
    for j=math.max(1,y-1),math.min(h,y+1) do
      if math.abs(g[i][j]) == 2 then
        sum = sum+1
      end
    end
  end
  
  term.setCursor(x, y)
  if sum > 0 then
    local color
    if sum == 1 then
      color = colors.green
    elseif sum == 2 then
      color = colors.yellow
    else
      color = colors.red
    end
    gpu.setForeground(color)
    term.write(string.format("%d",sum))
  else
    term.write(" ")
    for i=math.max(1,x-1),math.min(w,x+1) do
      for j=math.max(1,y-1),math.min(h,y+1) do
        if (i ~= x) or (j ~= y) then
          click(i, j)
        end
      end
    end
  end
end

function game()
  g = {}
  minepos = {}
  mines = 0
  clears = 0
  start = computer.uptime()

  gpu.setForeground(colors.white)
  gpu.setBackground(colors.lightGray)
  term.clear()

  for i=1,w do
    g[i] = {}
    for j=1,h do
      --term.setCursor(i,j)
      g[i][j] = 1
      --term.write("#")
    end
  end

  mines = math.floor(w*h*difficulty)
  clears = w*h-mines
  print("Generating random mine positions.")
  for n=1,mines do
    repeat
      i = math.floor(math.random()*w)+1
      j = math.floor(math.random()*h)+1
    until (g[i][j] == 1)
    g[i][j] = 2
  end
  print("Done, starting game.")
  gpu.fill(1, 1, w, h, "#")
  os.sleep(1)
  gpu.setBackground(colors.black)
  
  while clears > 0 do
    local e, _, x, y, lr, user = event.pull("touch")
      if g[x][y] == 2 then
        gpu.setForeground(colors.red)
        term.setCursor(x, y)
        term.write("X")
        os.sleep(1)
        for i=1,w do
          for j=1,h do
            if g[i][j] == 2 then
              term.setCursor(i, j)
              term.write("X")
            end
          end
        end
        -- Game Over Section
        local e = event.pull() --Wait for any input
        break
      end
    click(x,y)
    os.sleep(0)
  end

  if clears == 0 then
    start = computer.uptime()-start
    term.clear()
    gpu.setForeground(colors.green)
    print("Well done!")
    print("Time: "..time(start))
    for i=1,w do
      for j=1,h do
        term.setCursor(i, j)
        if g[i][j] == 2 then
          term.write("O")
        else
          term.write(" ")
        end
      end
    end
    gpu.setForeground(colors.yellow)
    term.setCursor(w/2-4, h/2+1)
    term.write(" Well done! ")
    term.setCursor(1, 1)
    term.write("Time: "..time(start))
  else
    gpu.setForeground(colors.red)
    term.clear()
    print("You lost!")
    print("Press any key to continue...")
    local e = event.pull()
    e = event.pull()
  end
end

function time(s)
  return string.format("%ds",s)
end

-- Program starts
print("Hold Ctrl+Alt+C to terminate if stuck")
os.sleep(1)
while true do
  game()
  gpu.setForeground(colors.defaultFG)
  gpu.setBackground(colors.defaultBG)
  term.clear()
  print("New game? [y/n]: ")
  k = term.read()
  if k ~= "y\n" then
    break
  end
end
