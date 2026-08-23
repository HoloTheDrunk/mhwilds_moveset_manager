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
  ["_"] = 10,
  ["."] = 11,
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

---@class Scope
---@field tok_index integer

---@class Lexer
---@field input string Text data to be lexed.
---@field private index integer Cursor position in the input.
---@field tokens LexedToken[] Lexed tokens so far.
---@field private _tok_index integer
---@field private _buf string?
---@field private _scopes Scope[]
local Lexer = {}
Lexer.__index = Lexer

---@param input string Text data to be lexed.
---@return Lexer
function Lexer.new(input)
  return setmetatable({
    input = input,
    index = 1,
    tokens = {},
    _tok_index = 0,
    _scopes = {}
  }, Lexer)
end

function Lexer:reset()
  self.index = 1
  self.tokens = {}
  self._tok_index = 0
  self._scopes = {}
end

function Lexer:begin_scope()
  self._scopes[#self._scopes + 1] = { tok_index = self._tok_index }
end

function Lexer:cancel_scope()
  if #self._scopes == 0 then return end
  self._tok_index = self._scopes[#self._scopes].tok_index
  self._scopes[#self._scopes] = nil
end

function Lexer:end_scope()
  if #self._scopes == 0 then return end
  self._scopes[#self._scopes] = nil
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
  self._tok_index = #self.tokens
  while is_whitespace(self.input:sub(self.index, self.index)) do
    self.index = self.index + 1
  end
end

---@return boolean EOF
function Lexer:skip_line()
  self._tok_index = #self.tokens
  local s, e = self.input:find("\n", self.index)
  self.index = e and e + 1 or #self.input + 1
  return s == nil
end

---@return LexedToken?
function Lexer:next()
  local peeked = self:peek()
  if peeked then
    self._tok_index = self._tok_index + 1
  end

  return peeked
end

---@return string
function Lexer:line()
  if self._tok_index < #self.tokens then
    self.index = self.tokens[#self.tokens].span[1]
    self._tok_index = #self.tokens
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
  if self.index > #self.input then return end

  if self._tok_index < #self.tokens then
    return self.tokens[self._tok_index + 1]
  end

  self:_skip_whitespace()

  self.index = self.index - 1
  self:_read()

  local tok = Token[self._buf]

  if tok and tok < Token.MAX_TOK then
    self.tokens[#self.tokens + 1] = { tok = tok, span = { self.index, self.index } }
    self.index = self.index + 1
  elseif is_alpha(self._buf) then
    self.tokens[#self.tokens + 1] = self:_lex_identifier()
  elseif is_number(self._buf) then
    self.tokens[#self.tokens + 1] = self:_lex_number()
  end

  return self.tokens[#self.tokens]
end

return { Lexer = Lexer, Token = Token, tok_name = tok_name }
