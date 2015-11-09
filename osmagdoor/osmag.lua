m = {}

function m.makeCode()
	local l = 32
	local s = ""
    for i = 1, l do
        s = s .. string.char(math.random(32, 126))
    end
    return s
end