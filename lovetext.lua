local lovetext = {}
lovetext.__index = lovetext
local instances = {}

local lg_print = love.graphics.print
local setColour = love.graphics.setColor
local draw = love.graphics.draw

-- options
local useCanvas
local drawBounds
local defaultFont

function lovetext.setup(opts)
    opts = opts or {}
    lovetext.clear()
    useCanvas = opts.useCanvas ~= false
    drawBounds = opts.drawBounds or false
    defaultFont = opts.defaultFont
end

local effects = {
    shake = function(letter, i)
        letter.x = math.sin(letter.t * 10 + i)
        letter.y = math.cos(letter.t * 10 + i)
    end,
    wave = function(letter, i)
        letter.y = math.sin(letter.t*5 + i) * 2
    end,
}

local colours = {
    default = {1, 1, 1},

    white = {1, 1, 1},
    black = {0, 0, 0},

    red = {1, 0, 0},
    orange = {1, 0.5, 0},
    yellow = {1, 1, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    purple = {0.5, 0, 1}, 
}

local fonts = {}
local macros = {}

local waveSettings = {
    speed = 5,
    intensity = 2,
}

local shakeSettings = {
    speed = 20,
    intensity = 1,
}

local function find(tbl, val)
    for i, v in pairs(tbl) do
        if val == v then
            return i
        end
    end
end

local function update(self, dt)
    for i, letter in ipairs(self.parsed) do
        letter.t = letter.t + dt
        for j, tag in pairs(letter.effects) do tag(letter, i) end
    end
end

-- Readies the segment during the text parsing process
local function parseSegment(text, effects, font, colour)
    local seg = {
        text = text,
        effects = effects,
        font = font,
        colour = colour or colours.default,
    }
    return seg
end

-- Split every letter once the parsing process has been completed
local function explodeSegments(segments)
    local letters = {}
    for _, seg in ipairs(segments) do
        for i = 1, #seg.text do
            local char = seg.text:sub(i, i)
            table.insert(letters, {
                char = char,
                effects = seg.effects,
                font = seg.font,
                colour = seg.colour,

                t = 0,
                x = 0,
                y = 0,
            })
        end
    end
    return letters
end

local function checkTag(stack, tag, closing)
    if tag then
        if closing == "/" then
            table.remove(stack, find(stack, tag))
        else -- open new tag
            table.insert(stack, tag)
        end
    end
    return stack
end

-- Splits the raw text into several tables based on tags
local function parseText(text, font)
    local segments = {}
    local effectStack = {}
    local fontStack = {}
    local colourStack = {}

    local i = 1
    while i <= #text do
        local sub
        local begin, fin, closing, tag = text:find("<(/?)([^>]+)>", i)
        if begin then

            local font = fontStack[#fontStack] or font
            local colour = colourStack[#colourStack]
            local sub = text:sub(i, begin-1)
            table.insert(segments, parseSegment(sub, {unpack(effectStack)}, font, colour))

            effectStack = checkTag(effectStack, effects[tag], closing)
            fontStack = checkTag(fontStack, fonts[tag], closing)
            colourStack = checkTag(colourStack, colours[tag], closing)
            
            local macro = macros[tag]
            if macro then
                for _, tag in ipairs(macro) do
                    effectStack = checkTag(effectStack, effects[tag], closing)
                    fontStack = checkTag(fontStack, fonts[tag], closing)
                    colourStack = checkTag(colourStack, colours[tag], closing)
                end
            end

            text = text:sub(1, begin - 1) .. text:sub(fin + 1)
            i = begin

        else -- no more tags
            sub = text:sub(i)
            table.insert(segments, parseSegment(sub, {}, font))
            break
        end
    end
    return explodeSegments(segments)
end

local function drawText(self, x, y, chars, mode)
    local cursor = {x = x, y = y}
    local base = self.font:getBaseline()

    for i, letter in ipairs(self.parsed) do
        local w = letter.font:getWidth(letter.char)
        local h = letter.font:getHeight()
        local offset = base - letter.font:getBaseline()

        if letter.char == "\n" or cursor.x + w > self.limit + x then
            cursor.x = x
            cursor.y = cursor.y + self.font:getHeight()
        end

        -- Draw the letter
        if letter.colour then setColour(letter.colour) end
        if (#letter.effects == 0 and mode ~= 'dynamic') or (#letter.effects > 0 and mode ~= 'static') then
            lg_print(letter.char, letter.font, cursor.x + letter.x, cursor.y + letter.y + offset)
        end
        
        if drawBounds then
            setColour(1, 0, 0)
            love.graphics.rectangle("line", cursor.x + letter.x, cursor.y + letter.y + offset, w, h)
        end

        setColour(colours.default)
        cursor.x = cursor.x + w
    end
end

--Create a new effect tag.
--Can also be used to modify an existing effect tag.
function lovetext.newEffect(tag, effect)
    effects[tag] = effect
end

--Create a new font tag.
--Can also be used to modify an existing font tag.
function lovetext.newFont(tag, font)
    fonts[tag] = font
end

--Create a new colour tag.
--Can also be used to modify an existing colour tag.
function lovetext.newColour(tag, value)
    colours[tag] = value
end

-- Register a macro that can combine color, font, and effects
function lovetext.newMacro(tag, opts)
    macros[tag] = opts
end

--Creates a new text object to be used with lovetext.
function lovetext.new(text, font, limit)
    local obj = setmetatable({}, lovetext)
    obj.canvas = useCanvas and love.graphics.newCanvas() or nil
    obj.font = font or defaultFont or love.graphics.getFont()
    obj.parsed = parseText(text, obj.font)
    obj.raw = text
    obj.limit = limit or math.huge
    obj.update = update

    table.insert(instances, obj)
    return obj
end

--Sends more text to an existing lovetext object.
function lovetext:send(text)
    if type(text) == "number" and text < 0 then
        self.raw = self.raw:sub(1, text-1)
    else
        self.raw = self.raw .. text
    end
    self.parsed = parseText(self.raw, self.font)
end

--Update all instances of lovetext simultaneously.
--Alternatively, can update certain instances with text:update() 
function lovetext.update(dt)
    for i, inst in ipairs(instances) do
        inst:update(dt)
    end
end

--Draw a lovetext object.
function lovetext:draw(x, y, chars)
    x,y = x or 0, y or 0
    chars = math.floor(chars or #self.parsed)
    local cursor = {x = x, y = y}

    local mode = "both"
    if useCanvas then
        mode = "dynamic"
        if self.renderedChars ~= chars then
            self.canvas:renderTo(function()
                love.graphics.clear()
                drawText(self, x, y, chars, "static")
            end)
        end
        draw(self.canvas)
    end
    drawText(self, x, y, chars, mode)
    self.renderedChars = chars
end

--Release a lovetext instance from the instance list.
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

lovetext.setup()
return lovetext