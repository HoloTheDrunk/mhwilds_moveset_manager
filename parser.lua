local lib = require("lib")
local Moveset, Weapon, weapon_name = lib.Moveset, lib.Weapon, lib.weapon_name

local lexer_lib = require("lexer")
local Lexer, Token = lexer_lib.Lexer, lexer_lib.Token

---@param str string
---@return string
function string.trim(str)
  return str:match([[^%s*(.-)%s*$]])
end

---@class Parser
---@field lexer Lexer
local Parser = {}
Parser.__index = Parser

---@param input string
function Parser.new(input)
  return setmetatable({
    lexer = Lexer.new(input)
  }, Parser)
end

---@param input string
local function collect_tokens(input)
  print(input)
  print(("-"):rep(10))
  local lexer = Lexer.new(input)
  local tok = lexer:next()
  while tok do
    print(lexer.input:sub(tok.span[1], tok.span[2]))
    tok = lexer:next()
  end
end

---@return Moveset?, string? error
function Parser:parse()
  self.lexer:reset()

  local metadata, err = self:parse_metadata()
  if not metadata then return nil, err end

  local description = nil
  if self.lexer:next().tok == Token["-"] then
    self.lexer:skip_line()
    description, err = self:parse_description()
    if not description then return nil, err end
  end

  local swaps = nil
  if self.lexer:next().tok == Token["="] then
    self.lexer:skip_line()
    swaps, err = self:parse_swaps()
    if not swaps then return nil, err end
  end

  local mv_name = string.format("%s - %s", metadata.name, metadata.author)
  return Moveset.new(mv_name, metadata.weapon, swaps or {}, description), nil
end

-- cat ind => cat ind | mod | mod | mod
---@return table<Category, table<Index, [Category, Index, Modifiers]>>? swaps, string? error
function Parser:parse_swaps()
  local swaps = {}
  while self.lexer:peek() do
    local res, err = self:parse_swap()
    if not res then return nil, err end
    if not swaps[res.from[1]] then
      swaps[res.from[1]] = {}
    end
    -- TODO: change swap storage to a simple indexed list
    -- Runtime cost will be slightly higher but it is what it is.
    if not swaps[res.from[1]][res.from[2]] then
      swaps[res.from[1]][res.from[2]] = { res.to[1], res.to[2], res.modifiers }
    end
  end
  return swaps
end

---@return { id: integer, from: [Category, Index], to: [Category, Index], modifiers: Modifiers }?, string? err
function Parser:parse_swap()
  local data = {
    id = 0,
    from_1 = 0,
    from_2 = 0,
    to_1 = 0,
    to_2 = 0,
  }

  for _, check in ipairs({
    { name = "id",     tok = Token.NUMBER },
    { tok = Token[":"] },
    { name = "from_1", tok = Token.NUMBER },
    { name = "from_2", tok = Token.NUMBER },
    { tok = Token["="] },
    { tok = Token[">"] },
    { name = "to_1",   tok = Token.NUMBER },
    { name = "to_2",   tok = Token.NUMBER },
  }) do
    local tmp = self.lexer:next()

    -- Error generation
    if not tmp or tmp.tok ~= check.tok then
      local err = string.format("Invalid swap syntax. Expected '%s'", lexer_lib.tok_name[check.tok])
      if not tmp then return nil, err .. "." end
      if tmp.tok ~= check.tok then
        if check.name then
          err = err .. string.format(" in position '%s'", check.name)
        end
        err = err .. string.format(", got '%s'.", self.lexer:from_span(tmp.span))
      end
      return nil, err
    end

    if check.name and data[check.name] then
      local str = self.lexer:from_span(tmp.span) --[[@as string]]
      data[check.name] = tonumber(str, 10)
    end
  end

  -- Parse modifier
  ---@type Modifiers
  local modifiers = {}
  while true do
    local peeked = self.lexer:peek()
    if not peeked or peeked.tok ~= Token["|"] then break end
    self.lexer:next()
    local name = self.lexer:next()
    if not name then
      return nil, string.format("Unexpected EOF while parsing modifier.", name)
    end
    if name.tok ~= Token.IDENTIFIER then
      return nil, string.format(
        "Expected IDENTIFIER as modifier name, got '%s' ('%s').",
        self.lexer:from_span(name.span), lexer_lib.tok_name[name.tok]
      )
    end
    local lower = self.lexer:from_span(name.span):lower()
    local parse_fn = ({
      ---@return M_Final
      final = function() return { enabled = true } end,
      ---@return M_After?, string? err
      after = function()
        local tmp = self.lexer:next()
        if not tmp or tmp.tok ~= Token["("] then
          return nil, "Invalid 'After' modifier syntax, expected '('."
        end

        local id = self.lexer:next()
        if not id or id.tok ~= Token.NUMBER then
          return nil, "Invalid 'After' modifier syntax, expected swap ID number."
        end

        tmp = self.lexer:next()
        if not tmp or tmp.tok ~= Token[")"] then
          return nil, "Invalid 'After' modifier syntax, expected ')'."
        end

        local id_text = self.lexer:from_span(id.span) --[[@as string]]
        local parsed_id = tonumber(id_text, 10)

        return { enabled = true, prev_id = parsed_id }
      end
    })[lower]
    if not parse_fn then return nil, string.format("Unrecognized modifier '%s'.", self.lexer:from_span(name.span)) end
    local res, err = parse_fn()
    if not res then return nil, err end
    modifiers[lower] = res
  end

  return { id = data.id, from = { data.from_1, data.from_2 }, to = { data.to_1, data.to_2 }, modifiers = modifiers }
end

---@return string?, string? error
function Parser:parse_description()
  ---@type string[]
  local lines = {}
  while true do
    local peeked = self.lexer:peek()
    if not peeked then return nil, "Unexpected EOF." end

    if peeked.tok == Token["="] then break end
    if peeked.tok == Token["!"] then self.lexer:skip_line() end

    lines[#lines + 1] = self.lexer:line():trim()
  end
  local description = nil
  for _, line in ipairs(lines) do
    if #line == 0 then goto continue end

    if description then
      description = description .. "\n" .. line
    else
      description = line
    end
    ::continue::
  end
  return description
end

---@return {name: string, author: string, weapon: Weapon}?, string? error
function Parser:parse_metadata()
  local metadata = {
    name = nil,
    author = nil,
    weapon = nil,
  }

  while true do
    local tok = self.lexer:next()
    if not tok then break end

    -- End of metadata section
    if tok.tok == Token["-"] or tok.tok == Token["="] then break end

    -- Comment
    if tok.tok == Token["!"] then
      self.lexer:skip_line()
      goto continue
    end

    -- Metadata definition is the only option left.
    if tok.tok ~= Token.IDENTIFIER then
      return nil, string.format(
        "Unexpected token '%s' ('%s') in metadata section.",
        self.lexer:from_span(tok.span), lexer_lib.tok_name[tok.tok]
      )
    end

    -- Metadata definitions always need a separating colon.
    local peek = self.lexer:peek()
    if not peek or peek.tok ~= Token[":"] then
      return nil, "Expected ':'."
    end
    -- Skip colon
    self.lexer:next()

    local lower = self.lexer:from_span(tok.span):lower():trim()
    local parse_fn = ({
      name = function() metadata.name = self.lexer:line():trim() end,
      author = function() metadata.author = self.lexer:line():trim() end,
      weapon = function()
        local wp_name = self.lexer:line():trim()
        local wp = Weapon[wp_name]
        if not wp then return "Invalid weapon name" end
        metadata.weapon = wp
      end
    })[lower]
    local err = parse_fn()
    if err then
      return nil, err
    end

    ::continue::
  end

  if not metadata.name then
    return nil, "Missing 'name' field in metadata section."
  end

  if not metadata.author then
    return nil, "Missing 'author' field in metadata section."
  end

  if not metadata.weapon then
    return nil, "Missing 'weapon' field in metadata section."
  end

  return metadata
end

-- collect_tokens([[
-- My Moveset - Holo the Drunk
-- Hammer
-- # 2
-- 6 2 37 Final
-- 37 2 6 Final
-- ]])

local mv, err = Parser.new([[
name: My Moveset
author: Me
weapon: Hammer
----
Switches Big Bang I and Overhead Smash I around.
Not very useful.
====
0: 2 6 => 2 37 | Final
1: 2 37 => 2 6 | Final
]]):parse()

if not mv then
  print(err)
else
  print(tostring(mv))
end
