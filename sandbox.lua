lovetext = require('lovetext')
local calls = 0

function love.load()
    love.graphics.setFont(love.graphics.newFont(15))

    text = lovetext.new("I'm just some plain old text.")
    wave = lovetext.new("I'm feeling pretty <wave>wavy.</wave>")
    shak = lovetext.new("And I'm feeling pretty <shake>shaky...</shake>")
    colr = lovetext.new("<red>My</red> <orange>colour</orange> <yellow>is</yellow> <green>so</green> <blue>very</blue> <purple>varied!</purple>")

    mult = lovetext.new("I'm combining <shake>shaky</shake> and <wave>wavy</wave> text")
    writ = lovetext.new("<shake>Oh yeah! I like this library a lot!</shake>")

end

function love.update(dt)
    lovetext.update(dt)
end

function love.gamepadpressed(_, button)
    if button == 'start' then
        love.event.quit()
    end
end

function love.draw(screen)
    if screen ~= 'bottom' then
        text:draw(0, 0)
        wave:draw(0, 25)
        shak:draw(0, 50)
        colr:draw(0, 75)
        mult:draw(0, 100)
        writ:draw(0, 125, math.floor(love.timer.getTime() * 10))

        calls = love.graphics.getStats().drawcalls
    end
    
    if screen == 'bottom' then
        love.graphics.print(love.timer.getFPS() .. " | " .. love.timer.getTime())
        love.graphics.print("draw calls:" .. calls, 0, 20)
    end
end