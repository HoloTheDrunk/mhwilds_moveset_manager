---@enum Token
local Token = {
  ["("] = 1,
  [")"] = 2,
  [","] = 3,
  [":"] = 4,
  ["#"] = 5,
  ["!"] = 6,
  ["-"] = 7,
  ["="] = 8,
  [">"] = 8,
  ["|"] = 9,
  MAX_TOK = 100,
  IDENTIFIER = 101,
  NUMBER = 102,
  NEWLINE = 103,
  EOF = 104,
  OTHER = 200,
}

local tok_name = {}
for tok, i in pairs(Token) do
  tok_name[i] = tok
end

---@param char string
---@return boolean
local function is_alpha(char)
  return #char == 1 and char >= "a" and char <= "z" or char >= "A" and char <= "Z"
end

---@param char string
---@return boolean
local function is_number(char)
  return #char == 1 and char >= "0" and char <= "9"
end

---@param char string
---@return boolean
local function is_whitespace(char)
  return #char == 1
      and char == " " or char == "\n" or char == "\r" or char == "\t"
end

---@class LexedToken
---@field tok Token
---@field span [integer, integer]

---@class Lexer
---@field input string Text data to be lexed.
---@field private index integer Cursor position in the input.
---@field tokens LexedToken[] Lexed tokens so far.
---@field private _peeked LexedToken? Temporary cache for the :peek calls.
---@field private _buf string?
local Lexer = {}
Lexer.__index = Lexer

---@param input string Text data to be lexed.
---@return Lexer
function Lexer.new(input)
  return setmetatable({
    input = input,
    index = 1,
    tokens = {},
    peeked = nil,
  }, Lexer)
end

function Lexer:reset()
  self.index = 1
  self.tokens = {}
  self._peeked = nil
end

---@param span [integer, integer]
---@return string?
function Lexer:from_span(span)
  if span[1] < 1 or span[1] > #self.input
      or span[2] < 1 or span[2] > #self.input then
    return
  end

  return self.input:sub(span[1], span[2])
end

---@private
---@return nil
function Lexer:_skip_whitespace()
  while is_whitespace(self.input:sub(self.index, self.index)) do
    self.index = self.index + 1
  end
  self._peeked = nil
end

---@return boolean EOF
function Lexer:skip_line()
  local s, e = self.input:find("\n", self.index)
  if not s then return true end
  self.index = e and e + 1 or #self.input
  self._peeked = nil
  return false
end

---@return LexedToken?
function Lexer:next()
  local peeked = self:peek()
  if peeked then
    -- print(self.input:sub(peeked.span[1], peeked.span[2]))
    -- print(string.format("tok: '%s', span: [%d, %d] => '%s'",
    --   tok_name[peeked.tok], peeked.span[1], peeked.span[2],
    --   self.input:sub(peeked.span[1], peeked.span[2])
    -- ))
    self.tokens[#self.tokens + 1] = peeked
    self._peeked = nil
    return self:last()
  end

  return nil
end

---@return string
function Lexer:line()
  if self._peeked then
    self.index = self._peeked.span[1]
    self._peeked = nil
  end
  local start = self.index
  local _, e = self.input:find("\n", self.index)
  self.index = e and e + 1 or #self.input + 1
  return self.input:sub(start, e)
end

---@private
---@return LexedToken?
function Lexer:_lex_identifier()
  local start = self.index
  self:_read()
  while is_alpha(self._buf) or is_number(self._buf) do
    self:_read()
  end
  self._buf = ""
  return { tok = Token.IDENTIFIER, span = { start, self.index - 1 } }
end

---@private
---@return LexedToken?
function Lexer:_lex_number()
  local start = self.index
  self:_read()
  while is_number(self._buf) do
    self:_read()
  end
  self._buf = ""
  return { tok = Token.NUMBER, span = { start, self.index - 1 } }
end

---@return LexedToken?
function Lexer:last()
  return self.tokens[#self.tokens]
end

---@return string char
function Lexer:_read()
  self.index = self.index + 1
  self._buf = self.input:sub(self.index, self.index)
  return self._buf
end

---@return LexedToken?
function Lexer:peek()
  if self._peeked then
    return self._peeked
  end

  self:_skip_whitespace()

  self.index = self.index - 1
  self:_read()

  local tok = Token[self._buf]

  if tok and tok < Token.MAX_TOK then
    self._peeked = { tok = tok, span = { self.index, self.index } }
    self.index = self.index + 1
  elseif is_alpha(self._buf) then
    self._peeked = self:_lex_identifier()
  elseif is_number(self._buf) then
    self._peeked = self:_lex_number()
  end

  return self._peeked
end

return { Lexer = Lexer, Token = Token, tok_name = tok_name }
