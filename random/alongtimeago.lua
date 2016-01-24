--Taken from https://github.com/alekso56/ComputercraftLua/tree/master/treasure/dan200/alongtimeago
local component = require("component")
local gpu = component.gpu

local m1 = loadfile("/usr/movies/1.lua")
m1()

local function iterator()
	return coroutine.wrap( function()
		for line in string.gmatch( filmText, "([^\n]*)\n") do
			coroutine.yield(line)
		end
		return false
	end )
end

term.clear()
local it = iterator()

local bFinished = false
while not bFinished do
	-- Read the frame header
	local holdLine = it()
	if not holdLine then
		bFinished = true
		break
	end

	-- Get this every frame incase the monitor resizes	
	local w,h = gpu.getResolution()
	local startX = math.floor( (w - 65) / 2 )
	local startY = math.floor( (h - 14) / 2 )

	-- Print the frame
	term.clear()
	for n=1,13 do
		local line = it()
		if line then
			term.setCursor(startX, startY + n)
			term.write( line )
		else
			bFinished = true
			break
		end
	end

	-- Hold the frame
	local hold = tonumber(holdLine) or 1
	local delay = (hold * 0.05) - 0.01
	os.sleep( delay )
end
