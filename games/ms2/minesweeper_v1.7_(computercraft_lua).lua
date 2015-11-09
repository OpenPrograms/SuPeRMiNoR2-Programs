local displays={}
local termOption
if term.isColor() then
  displays[1]={wrap=nil,side=nil,name="Terminal"}
  termOption=true
end

for _,side in pairs(rs.getSides()) do
  if peripheral.getType(side)=="monitor" then
    local wrap=peripheral.wrap(side)
    if wrap.isColor() then
      local disp={wrap=wrap,side=side, name="Monitor ("..side..")"}
      displays[#displays+1]=disp
    end
  end
end

function writeCentered(text,line,clearFirst,fg,bg,padChar)
  local w=term.getSize()
  fg=fg or colors.white
  bg=bg or colors.black
  local x=math.floor((w-#text)/2)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  
  if padChar then
     text=string.rep(padChar,x)..text
     text=text..string.rep(padChar,w-#text)
     term.setCursorPos(1,line)
  else
     term.setCursorPos(x+1,line)
     if clearFirst then term.clearLine() end
  end
  term.write(text)
  return x+1
end

if #displays==0 then
  print("Minesweep requires an advanced computer or monitor!")
  return
end
local redirected=false

local function exitnow(forced)
  if redirected then term.restore() end
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  local w,h=term.getSize()
  term.setCursorPos(1,h)
  if forced then
    print("terminated")
    error()
  else
    term.scroll(1)
    print("Thanks for playing!")
  end
   
end

local function doSimpleMenu(title, list)
  term.clear()
  local selected=1
  writeCentered(title,1)
  local done=false
  buttonPos={}
  while not done do
    for i=1,#list do
      local text=list[i].name
      local fg, bg
      if i==selected then
        fg=colors.black
        bg=colors.white
        text="["..text.."]"
      else
        fg=colors.white
        bg=colors.black
        text=" "..text.." "
      end   
      buttonPos[i]=writeCentered(text,4+i,false, fg,bg)+1
    end
  
    while true do
      local e={os.pullEventRaw()}
      if e[1]=="terminate" then
        exitnow(true)
      elseif e[1]=="key" then
        if e[2]==keys.up then
          selected=selected-1
          if selected==0 then selected=#list end
          break
        elseif e[2]==keys.down then
          selected=selected+1
          if selected>#list then selected=1 end
          break
        elseif e[2]==keys.enter then
          done=true
          break
        end
      elseif e[1]=="mouse_click" or e[1]=="monitor_touch" then
        if e[4]>4 and e[4]<=4+#list then
          local i=e[4]-4
          if e[3]>=buttonPos[i] and e[3]<buttonPos[i]+#list[i].name then
            selected=i
            done=true
            break
          end
        end
      end          
    end
  end
  return selected
end

local activeDisplay=1
if #displays>1 then
  activeDisplay=doSimpleMenu("Select the display to play on:",displays) 
end

if displays[activeDisplay].wrap then
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.setCursorPos(1,19)
  term.scroll(1)
  print("Playing Minesweep on "..displays[activeDisplay].side.." monitor...")  
  term.redirect(displays[activeDisplay].wrap)
  redirected=true
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  displays[activeDisplay].wrap.setTextScale(.5)
end

local difLevels={
  { name="easy", width=6, height=6,mines=6},
  { name="medium", width=15, height=8,mines=15},
  { name="hard", width=30,height=17,mines=60},
}

local w,h=term.getSize()
if w<20 then
  difLevels[3]=nil
end

local level=doSimpleMenu("difficulty",difLevels)
local level=difLevels[level]

local field={}

local function forEachValidNeighbor(x,y,func)
  for y2=math.max(y-1,1),math.min(y+1,level.height) do
    for x2=math.max(x-1,1),math.min(x+1,level.width) do
      if x~=x2 or y~=y2 then
        func(x2,y2)      
      end
    end
  end
end

local function genField()
  for y=1,level.height do
    field[y]={}
    for x=1,level.width do
      field[y][x]={mine=false,count=0,revealed=false,flag=false}
    end
  end
  

  for i=1,level.mines do
    local x, y
    repeat
      x,y=math.random(1,level.width),math.random(level.height)
    until field[y][x].mine==false
    field[y][x].mine=true
    forEachValidNeighbor(x,y,function(x,y) field[y][x].count=field[y][x].count+1 end)
  end
end

local xoff,yoff=math.floor((w-level.width)/2), math.floor((h-level.height+2)/2)

local mineColor, mineColorBg=colors.black,colors.red
local flagColor=colors.red
local unrevealedColorB=colors.lightGray
local flagWrong=colors.black
local flagWrongBg=colors.red
local screenBg=colors.gray
local infoBarColor=colors.yellow
local infoBarBG=colors.blue
local winColor, winColorBG, loseColor, loseColorBG=colors.green,colors.lightGray, colors.red, colors.lightGray

if not term.isColor() then
  mineColor, mineColorBg=colors.white,colors.black
  flagColor=colors.black
  unrevealedColorB=colors.white
  flagWrong=colors.white
  flagWrongBg=colors.black
  screenBg=colors.black
  infoBarColor=colors.white
  infoBarBG=colors.black
  winColor, winColorBG, loseColor, loseColorBG=colors.white, colors.black, colors.white, colors.black
end

local numColors = {
  colors.lightBlue,
  colors.green,
  colors.red,
  colors.blue,
  colors.magenta,
  colors.cyan,
  colors.pink,
  colors.purple,
}
  
local function getNumColor(n)
  if n>0 and term.isColor() then
    return numColors[n]
  end
  return colors.white
end

local function drawTile(x,y)
  term.setCursorPos(xoff+x,yoff+y)
  if field[y][x].revealed then
    if field[y][x].mine then
      if field[y][x].flag then
        term.setTextColor(mineColorBg)
        term.setBackgroundColor(mineColor)
      else
        term.setTextColor(mineColor)
        term.setBackgroundColor(mineColorBg)
      end
      term.write("X")
    else
      local n=field[y][x].count
      if field[y][x].flag==true then
        term.setBackgroundColor(flagWrongBg)
        term.setTextColor(flagWrong)
        term.write("?")
      else
        term.setTextColor(getNumColor(n))
        term.setBackgroundColor(colors.black)
        if n==0 then
          term.write(" ")
        else
          term.write(string.char(string.byte("0")+field[y][x].count))
        end
      end
    end
  elseif field[y][x].flag==true then
    term.setTextColor(flagColor)
    term.setBackgroundColor(unrevealedColorB)
    term.write("?")
  else
    term.setTextColor(colors.black)
    term.setBackgroundColor(unrevealedColorB)
    term.write(" ")
  end
end



function drawGrid()
  for y=1,level.height do
    for x=1,level.width do  
      drawTile(x,y)
    end
  end
end

local clickMode=1
local gameover
local revealToWin

local buttonOffset

local function drawButtons()
  local text="new quit "
  if clickMode==1 then
    text=text.."flag"
  else
    text=text.."show"
  end
  
  buttonOffset=writeCentered(text,1,true,infoBarColor,infoBarBG)
end


local function reveal(x,y)
  local revealStack={{x,y}}
  local visited={}
  visited[x+y*level.width]=true
  while #revealStack>0 do
    x,y=unpack(table.remove(revealStack,1))
    
    if not field[y][x].revealed and not field[y][x].flag then
      revealToWin=revealToWin-1
      field[y][x].revealed=true
      drawTile(x,y)
      if field[y][x].count==0 then
        forEachValidNeighbor(x,y,
          function(x,y) 
            if not visited[x+y*level.width] and (field[y][x].revealed or field[y][x].flag)==false then
              revealStack[#revealStack+1]={x,y} 
            end
          end
        )
      end
    end
  end
end

--declared here, so drawBar can see it
local seconds=0
local numMinesLeft=0

local function drawInfoBar(message,fg,bg)
  fg=fg or infoBarColor
  bg=bg or infoBarBG
  
  local text
  if message then
    text="["..message.."]"
  else
    text=string.format("[ %2d/%2d  %3ds ]",numMinesLeft,level.mines,seconds)
  end

  writeCentered(text,2,false,fg,bg,"-")
    
end

local function confirm(text)
  writeCentered(text,1,true,infoBarColor,infoBarBG)
  local x=writeCentered("[ yes no ]",2,true,infoBarColor,infoBarBG,"-")+2
  local res  
  while true do
    local e={os.pullEvent()}
    if e[1]=="mouse_click" or e[1]=="monitor_touch" then
      if e[4]==2 then
        local cx=e[3]-x+1
        if cx>0 and cx<4 then
          res=true
          break
        elseif cx>4 and cx<7 then
          res=false
          break
        end
      end
    end
  end
  drawButtons()
  drawInfoBar()
  return res
end

--length of a real second, in units of os.time()
local timeSecond=1/50

function runGame()
  while true do
    term.setTextColor(colors.white)
    term.setBackgroundColor(screenBg)  
    term.clear()
    drawInfoBar()

    genField()
    drawGrid()
    revealToWin=level.width*level.height-level.mines
    numMinesLeft=level.mines

    drawButtons()

    gameover=nil
    local startTime=nil
    local alarmTime=nil
    local secondAlarm=nil
    seconds=0

    while true do
      local e={os.pullEventRaw()}
      if e[1]=="terminate" then
        exitnow(true)
      elseif e[1]=="alarm" and e[2]==secondAlarm then
        seconds=seconds+1
        drawInfoBar()
        alarmTime=(alarmTime+timeSecond)%24
        secondAlarm=os.setAlarm(alarmTime)
      elseif e[1]=="mouse_click" or e[1]=="monitor_touch" then
        local clickModeX=clickMode

        if e[1]=="mouse_click" and e[2]~=1 then
          --use button to determine action
          clickModeX=e[2]
        end

        --determine target tile
        local x,y=e[3],e[4]
        if x>xoff and x<=xoff+level.width and y>yoff and y<=yoff+level.height then
          --clicked field!
          x,y=x-xoff,y-yoff
          local tile=field[y][x]
          if clickModeX==1 then
            --reveal, unless flagged?
            if tile.revealed then
              --count flags around
              local count=0
              forEachValidNeighbor(x,y,function(x,y) if not field[y][x].revealed and field[y][x].flag then count=count+1 end end)
              if count==tile.count then
                forEachValidNeighbor(x,y,
                  function(x,y) 
                    if field[y][x].revealed==false and field[y][x].flag==false then 
                      if field[y][x].mine then 
                        gameover="lose" 
                      else 
                        reveal(x,y)
                      end 
                    drawTile(x,y) 
                    end 
                  end)
                if gameover then break end
              end
            elseif tile.flag==false then
              if startTime==nil then
                startTime=os.time()
                alarmTime=startTime+timeSecond
                secondAlarm=os.setAlarm(alarmTime)
              end
              reveal(x,y)
              if tile.mine then
                gameover="lose"
                break
              end
            end
          elseif clickModeX==2 then
            --toggle flag
            if tile.revealed==false then
              if tile.flag then
                numMinesLeft=numMinesLeft+1
              else
                numMinesLeft=numMinesLeft-1
              end
              drawInfoBar()
              tile.flag=not tile.flag
              drawTile(x,y)          
            else
              --flag all tiles if the surrounding unrevealed count equals mine count
              local count=0
              forEachValidNeighbor(x,y,
                function(x,y) 
                  if not field[y][x].revealed then 
                    count=count+1 
                  end 
                end)
              if count==field[y][x].count then
                forEachValidNeighbor(x,y,
                  function(x,y)
                    if not field[y][x].revealed and not field[y][x].flag then
                      field[y][x].flag=true
                      numMinesLeft=numMinesLeft-1
                      drawTile(x,y)
                    end
                  end)
                drawInfoBar()
              end
            end          
          end
        else
          --not a tile, check menu
          if y==1 then
            x=x-buttonOffset+1
            if x>0 and x<4 then
              --new
              if confirm("Start new game?") then
                gameover="new"
                break
              end
            elseif x>4 and x<9 then
              --quit
              if confirm("Exit minesweep?") then
                gameover="quit"
                break
              end
            elseif x>9 and x<14 then
              clickMode=clickMode==1 and 2 or 1
              drawButtons()
            end
          end
        end
      else
        --any other event
      end
      if revealToWin==0 then
        gameover="win"
        break
      end
    end
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    if gameover=="quit" then
      break
    end
    if gameover~="new" then

      drawInfoBar("You "..gameover.."!",gameover=="win" and winColor or loseColor, gameover=="win" and winColorBG or loseColorBG)
      term.setTextColor(colors.white)
      for y=1,level.height do
        for x=1,level.width do
          if field[y][x].mine and not field[y][x].revealed then
            field[y][x].revealed=true
            drawTile(x,y)
          elseif field[y][x].mine==false and field[y][x].flag then
            field[y][x].revealed=true
            drawTile(x,y)
          end
        end
      end

      os.startTimer(5)
      while ({os.pullEvent()})[1]=="alarm" do
        --skip alarm so it doesn't override within a second from the game timer events
      end

      drawInfoBar()

      if not confirm("Play Again?") then
        break
      end
    end  
  end
end

local ok, err=pcall(runGame)

term.setTextColor(colors.white)
term.setBackgroundColor(colors.black)
term.clear()

if not ok then
  print(err)
end

exitnow()