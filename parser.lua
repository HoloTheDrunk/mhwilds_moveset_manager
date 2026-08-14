local lib = require("lib")
local Moveset, Weapon = lib.Moveset, lib.Weapon

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

---@alias ProcessingFunc fun(lexer: Lexer, tok: LexedToken, dst: string, field: string): string?
---@alias ProcessingTarget {dst: string, field: string}

---@param sequence { tok: Token, process?: [ProcessingTarget, ProcessingFunc] }[]
---@return string? err
function Parser:parse_sequence(sequence)
  for position, step in ipairs(sequence) do
    local tmp = self.lexer:next()

    -- Error generation
    if not tmp or tmp.tok ~= step.tok then
      local err = string.format("Invalid swap syntax. Expected '%s'", lexer_lib.tok_name[step.tok])
      if not tmp then return err .. "." end
      if tmp.tok ~= step.tok then
        err = err .. string.format(" in position %d, got '%s'.", position, self.lexer:from_span(tmp.span))
      end
      return debug.traceback(err)
    end

    if step.process then
      local target = step.process[1]
      local fn = step.process[2]
      local err = fn(self.lexer, tmp, target[1], target[2])
      if err then return err end
    end
  end
end

---@type ProcessingFunc
local function process_number(lexer, tok, dst, field)
  local str = lexer:from_span(tok.span) --[[@as string]]
  dst[field] = tonumber(str, 10)
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

---@return string?, string? error
function Parser:parse_description()
  ---@type string[]
  local lines = {}
  while true do
    local peeked = self.lexer:peek()
    if not peeked then return nil, "Unexpected EOF." end

    if peeked.tok == Token["="] then break end
    if peeked.tok == Token["!"] then
      self.lexer:skip_line()
      goto continue
    end

    lines[#lines + 1] = self.lexer:line():trim()
    ::continue::
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

-- cat ind => cat ind | mod | mod | mod
---@return Swap[]? swaps, string? error
function Parser:parse_swaps()
  local swaps = {}
  local ids = {}
  while self.lexer:peek() do
    if self.lexer:peek().tok == Token["!"] then
      self.lexer:skip_line()
      goto continue
    end
    local res, err = self:parse_swap()
    if not res then return nil, err end
    if ids[res.id] then
      return nil, string.format("Duplicate swap id: %d.", res.id)
    end
    ids[res.id] = true
    swaps[#swaps + 1] = res
    ::continue::
  end
  return swaps
end

---@return Swap?, string? err
function Parser:parse_swap()
  local data = {
    id = 0,
    from_1 = 0,
    from_2 = 0,
    to_1 = 0,
    to_2 = 0,
  }

  local err = self:parse_sequence({
    { tok = Token.NUMBER, process = { { data, "id" }, process_number } },
    { tok = Token[":"] },
    { tok = Token.NUMBER, process = { { data, "from_1" }, process_number } },
    { tok = Token.NUMBER, process = { { data, "from_2" }, process_number } },
    { tok = Token["="] },
    { tok = Token[">"] },
    { tok = Token.NUMBER, process = { { data, "to_1" }, process_number } },
    { tok = Token.NUMBER, process = { { data, "to_2" }, process_number } },
  })
  if err then return nil, err end

  ---@type Modifiers
  local modifiers = {}
  while true do
    local peeked = self.lexer:peek()
    if not peeked or peeked.tok ~= Token["|"] then break end
    self.lexer:next()
    local error = self:parse_modifier(modifiers)
    if error then return nil, string.format("Swap %d: %s", data.id, error) end
  end

  return { id = data.id, from = { data.from_1, data.from_2 }, to = { data.to_1, data.to_2 }, modifiers = modifiers }
end

---@param modifiers Modifiers
---@return string? err
function Parser:parse_modifier(modifiers)
  local name = self.lexer:next()
  if not name then
    return string.format("Unexpected EOF while parsing modifier.", name)
  end
  if name.tok ~= Token.IDENTIFIER then
    return string.format(
      "Expected IDENTIFIER as modifier name, got '%s' ('%s').",
      self.lexer:from_span(name.span), lexer_lib.tok_name[name.tok]
    )
  end
  local lower = self.lexer:from_span(name.span):gsub("([a-z])([A-Z])", "%1_%2"):lower()
  local parse_fn = ({
    final = self.parse_modifier_final,
    after_swap = self.parse_modifier_after_swap,
    after_move = self.parse_modifier_after_move,
  })[lower]
  if not parse_fn then return string.format("Unrecognized modifier '%s'.", self.lexer:from_span(name.span)) end

  local res, error = parse_fn(self)
  if not res then return string.format("Modifier '%s': %s", self.lexer:from_span(name.span), error) end

  modifiers[lower] = res
end

---@return M_Final
function Parser:parse_modifier_final()
  return { enabled = true }
end

---@return M_AfterSwap?, string? error
function Parser:parse_modifier_after_swap()
  ---@type M_AfterSwap
  local res = {
    enabled = true,
    id = -1
  }

  local error = self:parse_sequence({
    { tok = Token["("] },
    { tok = Token.NUMBER, process = { { res, "id" }, process_number } },
    { tok = Token[")"] },
  })

  if error then return nil, error end

  return res
end

---@return M_AfterMove?, string? error
function Parser:parse_modifier_after_move()
  ---@type M_AfterMove
  local res = {
    enabled = true,
    category = -1,
    index = -1,
  }

  local error = self:parse_sequence({
    { tok = Token["("] },
    { tok = Token.NUMBER, process = { { res, "category" }, process_number } },
    { tok = Token[","] },
    { tok = Token.NUMBER, process = { { res, "index" }, process_number } },
    { tok = Token[")"] },
  })

  if error then return nil, error end

  return res
end

local mv, err = Parser.new([[
name: My Moveset
author: Me
weapon: Hammer
!weapon: Longsword
----
!Ignored line
Switches Big Bang I and Overhead Smash I around.
Not very useful.
====
0: 2 6 => 2 37 | Final
1: 2 37 => 2 6 | AfterMove(1, 2) | Final
2: 2 6 => 2 38 | Final | AfterSwap(1)
]]):parse()

if not mv then
  print(err)
else
  print(tostring(mv))
end
