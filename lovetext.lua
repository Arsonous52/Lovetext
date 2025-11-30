local lovetext = {}
lovetext.__index = lovetext
local instances = {}

local getFont = love.graphics.getFont
local draw = love.graphics.draw
local newText = love.graphics.newTextBatch or love.graphics.newText -- Use newTextBatch if on Love 12

-- variables
local SIN_COS_TABLE_SIZE = 60
local sinTable = {}
for i = 0, SIN_COS_TABLE_SIZE-1 do
    sinTable[i] = math.sin(i / SIN_COS_TABLE_SIZE * 2*math.pi)
end

local cosTable = {}
for i = 0, SIN_COS_TABLE_SIZE-1 do
    cosTable[i] = math.cos(i / SIN_COS_TABLE_SIZE * 2*math.pi)
end

local effects = {
    shake = function(letter, i)
        local angle = letter.t * 10 + i
        local frac = (angle / (2 * math.pi)) % 1
        local id = math.floor(frac * SIN_COS_TABLE_SIZE)
        letter.x = sinTable[id]
        letter.y = cosTable[id]
    end,
    wave = function(letter, i)
        local angle = letter.t * 5 + i
        local frac = (angle / (2 * math.pi)) % 1
        local id = math.floor(frac * SIN_COS_TABLE_SIZE)
        letter.y = cosTable[id] * 2
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

local function findFromTop(tbl, val)
    if not tbl then return end
    for i = #tbl, 1, -1 do
        if tbl[i] == val then
            return i
        end
    end
end

local function update(self, dt)
    for i, letter in ipairs(self.letters) do
        if #letter.effects > 0 then
            letter.t = letter.t + dt
            for _, tag in ipairs(letter.effects) do tag(letter, i) end
        end
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
    local cx, cy = 0, 0
    local letters = {}
    for _, seg in ipairs(segments) do
        if seg.text and seg.text ~= "" then
            for i = 1, #seg.text do
                local char = seg.text:sub(i, i)
                local letter = {
                    char = char,
                    effects = {unpack(seg.effects)},
                    font = seg.font,
                    width = seg.font:getWidth(char),
                    height = seg.font:getHeight(),
                    base = seg.font:getBaseline(),
                    colour = seg.colour,

                    t = 0,
                    baseX = 0,
                    baseY = 0,
                    x = 0,
                    y = 0,
                }
                if char == "\n" then letter.width = 0 end
                table.insert(letters, letter)
            end
        end
    end
    return letters
end

local function checkTag(stack, tag, closing)
    if tag then
        if closing == "/" then
            local id = findFromTop(stack, tag)
            if id then table.remove(stack, id) end
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

            local currentFont = fontStack[#fontStack] or font
            local currentColour = colourStack[#colourStack]
            local sub = text:sub(i, begin-1)
            if #sub > 0 then table.insert(segments, parseSegment(sub, {unpack(effectStack)}, currentFont, currentColour)) end

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

            i = fin + 1

        else -- no more tags
            sub = text:sub(i)
            table.insert(segments, parseSegment(sub, {}, font))
            break
        end
    end
    return explodeSegments(segments)
end

local function getTextBatchForFont(self, font, mode)
    local key = font
    local batch = self[mode.."TextBatches"][key]
    if not batch then
        batch = newText(font)
        self[mode.."TextBatches"][key] = batch
    end
    return batch
end

local function computeLetterLayout(self)
    local cx, cy = 0, 0
    for i, letter in ipairs(self.letters) do
        letter.baseX, letter.baseY = cx, cy
        if letter.char == "\n" or cx + letter.width > self.limit then
            cx = 0
            cy = cy + self.lineHeight
        else
            cx = cx + letter.width
        end
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
--Can also be used to modify existing macro tags.
function lovetext.newMacro(tag, opts)
    macros[tag] = opts
end

--Creates a new text object to be used with lovetext.
function lovetext.new(text, font, limit)
    local obj = setmetatable({}, lovetext)
    obj.font = font or getFont()
    obj.lineHeight = obj.font:getHeight()
    obj.letters = parseText(text, obj.font)
    obj.raw = text
    obj.limit = limit or math.huge
    obj.staticTextBatches = {}
    obj.dynamicTextBatches = {}
    obj.update = update
    obj.dirty = true
    computeLetterLayout(obj)

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
    self.letters = parseText(self.raw, self.font)
    self.dirty = true
    computeLetterLayout(self)
end

--Update all instances of lovetext simultaneously.
--Alternatively, can update certain instances with text:update() 
function lovetext.update(dt)
    for i, inst in ipairs(instances) do
        inst:update(dt)
    end
end

local function drawText(self, chars, mode)
    local base = self.font:getBaseline()

    for i, letter in ipairs(self.letters) do
        if i > chars then return end
        if (#letter.effects > 0 and mode == 'dynamic') or (#letter.effects == 0 and mode == 'static') then
            local offset = base - letter.base
            local batch = getTextBatchForFont(self, letter.font, mode)
            batch:add({letter.colour, letter.char}, letter.baseX + letter.x, letter.baseY + letter.y + offset)
        end
    end
end

--Draw a lovetext object.
function lovetext:draw(x, y, chars)
    x,y = x or 0, y or 0
    chars = math.floor(chars or #self.letters)

    if self.renderedChars ~= chars then self.dirty = true end

    if self.dirty then  
        for _, batch in pairs(self.staticTextBatches) do batch:clear() end
        drawText(self, chars, "static")
        self.dirty = false
        self.renderedChars = chars
    end
    for _, batch in pairs(self.dynamicTextBatches) do batch:clear() end
    drawText(self, chars, "dynamic")

    -- draw all batches
    for _, batch in pairs(self.staticTextBatches) do draw(batch, x, y) end
    for _, batch in pairs(self.dynamicTextBatches) do draw(batch, x, y) end
end

--Release a lovetext instance from the instance list.
function lovetext:release()
    for i, inst in ipairs(instances) do
        if inst == self then
            table.remove(instances, i)
            for i, batch in ipairs(self.staticTextBatches) do
                batch:release()
            end
            for i, batch in ipairs(self.dynamicTextBatches) do
                batch:release()
            end
            break
        end
    end
end

--Release all lovetext instances.
function lovetext.clear()
    local toRemove = {}
    for inst in pairs(instances) do
        table.insert(toRemove, inst)
    end
    for _, inst in ipairs(toRemove) do
        inst:release()
    end
end

return lovetext