m = {}

function m.makeCode()
    local l = 10
    local s = ""
    for i = 1, l do
        s = s .. string.char(math.random(97, 122))
    end
    return s
end

return m