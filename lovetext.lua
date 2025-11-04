--[[-----------------------------------------------------------------------------------------------

<shake> => makes each character wobble.
<wave> => the text moves in a sine wave.
<[colour]> => sets text colour. check the colour table for defaults, lovetext.newColourTag() to create new

-----------------------------------------------------------------------------------------------]]--

local lovetext = {}
lovetext.__index = lovetext
local instances = {}

local print = love.graphics.print
local setColour = love.graphics.setColor

local colours = {
    default = {1, 1, 1},

    white = {1, 1, 1},
    black = {0, 0, 0},

    red = {1, 0, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    
    yellow = {1, 1, 0},
    orange = {1, 0.5, 0},
    purple = {0.5, 0, 1}
}

local waveSettings = {
    speed = 5,
    amplitude = 2,
}

local shakeSettings = {
    speed = 20,
    intensity = 1,
}

local function update(self, dt)
    local t = love.timer.getTime()
    for i, seg in ipairs(self.parsed) do

        for j, tag in ipairs(seg.tags) do

            if tag == "shake" then
                seg.mx = math.sin(t * shakeSettings.speed + i) * shakeSettings.intensity
                seg.my = math.cos(t * shakeSettings.speed + i) * shakeSettings.intensity
            elseif tag == "wave" then
                seg.my = math.sin(t*waveSettings.speed + i) * waveSettings.amplitude
            end

        end
    end
end

-- Readies the segment during the text parsing process
local function parseSegment(tags, text, font, colour)
    local seg = {
        tags = tags or {"text"},
        text = text,
        font = font,
        colour = colour or colours.default,
        mx = 0,
        my = 0,
    }
    return seg
end

-- Split every letter once the parsing process has been completed
local function explodeSegments(segments)
    local exploded = {}
    for _, seg in ipairs(segments) do
        for i = 1, #seg.text do
            local char = seg.text:sub(i, i)
            table.insert(exploded, {
                tags = seg.tags,
                text = char,
                font = seg.font,
                colour = seg.colour,
                mx = seg.mx,
                my = seg.my,
            })
        end
    end
    return exploded
end

-- Splits the raw text into several tables based on tags
local function parseText(text, font)
    font = font or love.graphics.getFont()
    local segments = {}
    local stack = {}
    local i = 1

    while i <= #text do
        local tagStart, tagEnd, closing, tagName = text:find("<(/?)([%w_]+)>", i)
        if tagStart then

            if tagStart > i then
                local sub = text:sub(i, tagStart-1)
                table.insert(segments, parseSegment({unpack(stack)}, sub, font))
            end
            i = tagEnd + 1

            if closing == "/" then -- Pop stack
                
                if stack[#stack] == tagName then
                    table.remove(stack)
                else
                    error("mismatched closing tag </" .. tagName .. ">")
                end

            else
                table.insert(stack, tagName) -- Push stack
            end

        else -- No more tags

            local sub = text:sub(i)
            table.insert(segments, parseSegment(nil, sub, font))
            break

        end
    end

    segments = explodeSegments(segments)
    return segments
end

--Create a new colour tag.
--Can also be used to modify an existing colour tag.
---@param tag string The tag of the new colour.
---@param value table The RGB values of the new colour.
function lovetext.newColourTag(tag, value)
    colours[tag] = value
end

--Creates a new text object to be used with lovetext.
---@param text string The text to display.
---@param font love.Font|nil Font to use. **Default:** love.graphics.getFont()
---@return table The new text object.
function lovetext.new(text, font)
    local obj = setmetatable({}, lovetext)
    obj.parsed = parseText(text, font)
    obj.raw = text
    obj.update = update

    table.insert(instances, obj)
    return obj
end

--Sends more text to an existing lovetext object.
---@param text string The text to add.
function lovetext:send(text)
    local newText = self.raw .. text
    self.parsed = parseText(newText)
    self.raw = newText
end

--Update all instances of lovetext simultaneously.
--Alternatively, can update certain instances with text:update() 
---@param dt number The delta time to update the text with.
function lovetext.update(dt)
    for i, inst in ipairs(instances) do
        inst:update(dt)
    end
end

--Draw a lovetext object.
---@param self table The lovetext object to draw.
---@param x number The X coordinate to draw the text object at.
---@param y number The Y coordinate to draw the text object at.
---@param chars number The number of characters to draw.
function lovetext:draw(x, y, chars)
    x,y = x or 0, y or 0
    chars = chars or #self.parsed
    chars = math.floor(chars)
    local cursor = {x = x, y = y}

    local count = 0
    for i, seg in ipairs(self.parsed) do
        count = count + 1
        if count > chars then break end

        if seg.text == "\n" then
            cursor.x = x
            cursor.y = cursor.y + seg.font:getHeight()
        end

        for j, tag in ipairs(seg.tags) do
            if colours[tag] then
                setColour(colours[tag])
            end
        end

        local w = seg.font:getWidth(seg.text)
        print(seg.text, cursor.x + seg.mx, cursor.y + seg.my)
        setColour(colours.default)

        cursor.x = cursor.x + w
    end
end

--Release a lovetext instance from the instance list.
--This must be done manually in order to free up resources.
function lovetext:release()
    for i, inst in ipairs(instances) do
        if inst == self then
            table.remove(instances, i)
            break
        end
    end
end

--Release all lovetext instances.
function lovetext.clear()
    instances = {}
end

return lovetext