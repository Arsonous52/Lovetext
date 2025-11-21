# What is Lovetext?

This is a lightweight text engine for Love2D which renders animated and formatted text using inline tags, mainly intended on being used for Lovepotion.

# Example

```lua
lovetext = require('lovetext')

function love.load()
    text = lovetext.new("Who says text can't be <wave>animated?</wave>")
end

function love.update(dt)
    lovetext.update(dt)
end

function love.draw()
    text:draw()
end
```

![til](demonstration.gif)

### 1. [How To Use](#how-to-use)
### 2. [Updating Lovetext Objects](#updating-lovetext-objects)  
### 3. [Using Tags](#using-tags)  
### 4. [Configuration](#configuration)  
### 5. [Customisation](#customisation)  
### 6. [Cleaning Up](#cleaning-up)

# How To Use:

After importing Lovetext through the following:

```lua
lovetext = require('path/to/lovetext')
```

You can immediately begin creating text objects through the following:

```lua
text = lovetext.new("your text", font, limit)
```

You can send additional text to an existing Lovetext object using the following function:

```lua
text:send("additional text") -- appends text
text:send(-4) -- removes last 4 letters
```
> `send()` automatically **re-parses tags** for the inserted text.

Once your text objects are ready, you can render them through:


```lua
text:draw(x, y, chars)
text:draw(20, 400, 5) -- renders the first 5 visible characters at {x20, y400}
```
> This can produce mid-word line breaks (wrapping currently works on a per-letter basis).

> Tags are still parsed, even if the content they apply to is partially drawn.

`chars` are useful for:

- typewriter effects

- dynamic dialogue

- gradually revealing or hiding text

# Updating Lovetext Objects
> [!IMPORTANT]
> If you don’t call update, text still renders, but all animated effects freeze!

Lovetext uses per-letter timers to drive animations.

Update the timers for all existing text objects using:

```lua
lovetext.update(dt)
```

You can also update a single object using:

```lua
text:update(dt)
```

Every letter starts with a timer of `t = 0`, and on each update its timer increases by `dt`.

# Using Tags

Lovetext tags are very simple, and have been designed to behave similarly to HTML tags.

To make text shake, you would simply open the tag with `<shake>`, then type the text you would like to shake. When finished, type `</shake>` and all text within the tags will shake.

The default tags include:

- Effects: `<shake>` `<wave>`

- Colours: `<default>` `<white>` `<black>` `<red>` `<orange>` `<yellow>` `<green>` `<blue>` `<purple>`

## Tag Precedence & Stacking Rules

### Effects stack
If multiple effect tags are active at once (e.g. <shake><wave>text</wave></shake>),
all their effect functions run every update in no particular order.

### Colours and fonts override
If multiple colour/font tags overlap, only the most recent (innermost) tag applies.

Example:

`"<red> hello <blue> world </blue> </red>"` -> “hello” is red, “world” is blue.

### Custom tags with the same name

If you create a new effect named "shake" -> it replaces the default shake effect.

If you create a colour named "shake" -> it changes colour but keeps the effect.

# Configuration

When initialising Lovetext, you can call the `setup()` function, which allows you to modify how Lovetext behaves.

```lua
lovetext.setup({useCanvas = false})
```

## useCanvas
`default = true`

If enabled, Lovetext caches static text into a canvas.

Text without active effects or animations only needs to be drawn once, improving performance, especially for long paragraphs.

When disabled, Lovetext re-renders every letter each frame.

> [!NOTE]
> You may need to disable canvases if they render incorrectly.

## drawBounds
`default = false`

If enabled, draws red boxes around each letter's bounds, useful for debugging letter positions and spacing.

## defaultFont
`default = nil`

If set, new Lovetext objects use this font when none is provided; otherwise, they default to `love.graphics.getFont()`.

# Customisation

## What a letter looks like internally

Each visible character becomes a **letter object** with the following fields:

```lua
letter = {
    char    = "a",       -- Character
    x       = 0,         -- x offset
    y       = 0,         -- y offset
    t       = 0,         -- Timer
    font    = <Font>,    -- Active font for this letter
    colour  = {r,g,b,a}, -- Active color for this letter
    effects = {},        -- List of effect functions applied
}
```

## Registering Custom Tags
Besides the defaults, Lovetext also supports custom tags of various types:

```lua
lovetext.newColour(tag, rgba)   -- table
lovetext.newFont(tag, font)     -- font object
lovetext.newEffect(tag, effect) -- function
lovetext.newMacro(tag, macro)   -- table
```

Custom effect functions receive:

```lua
function effect(letter, index)
    -- modify letter.x, letter.y, letter.colour, etc
end
```

Macros are custom tags that let you combine multiple existing tags (colors, fonts, or effects) into a single “super tag” for convenience.
```lua
lovetext.newMacro("warning", {
    "yellow",
    "shake"
})
```

# Cleaning Up

If your project creates many text objects, you should release ones you no longer need. This can be done through the following functions:

```lua
text:release()
```
This will release the called object from the list of instances.

```lua
lovetext.clear()
```
This will clear all of the currently registered Lovetext objects.