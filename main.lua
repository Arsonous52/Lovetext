--[[==================================================================

    This is a sandbox meant for testing lovetext live as you type!

==================================================================]]--
lovetext = require("lovetext")

local input
local text

local function updateText()
    text = lovetext.new(input, text.font, text.limit)
end

function love.load()
    input = "<shake>Shaky Text</shake>"
    text = lovetext.new(input, nil, 400)
    love.keyboard.setTextInput(true)
end

function love.update(dt)
    lovetext.update(dt)
end

function love.textinput(t)
    input = input .. t
    updateText()
end

function love.keypressed(key)
    if key == "backspace" then
        input = input:sub(1, -2)
        updateText()
    end
end

function love.draw()
    local input = input
    if math.floor(love.timer.getTime()*2)%2 == 0 then
        input = input .. "_"
    end

    love.graphics.print("input", 10, 10)
    love.graphics.rectangle('line', 10, 30, 400, 80)
    love.graphics.printf(input, 10, 30, 400)

    love.graphics.print("output", 10, 120)
    love.graphics.rectangle('line', 10, 140, 400, 80)

    text:draw(10, 140)
end