local lexerlib = require("lexer")
local Token = lexerlib.Token

---@enum ComparisonType
local ComparisonType = {
  ["="] = 0,
  [">"] = 1,
  [">="] = 2,
  ["<"] = 3,
  ["<="] = 4,
}

---@class Comparison
---@field type ComparisonType
---@field value number
local Comparison = {}
Comparison.__index = Comparison

---@param type? ComparisonType Defaults to '='
---@param value? number Defaults to 0
function Comparison.new(type, value)
  return setmetatable({
    type = type or ComparisonType["="],
    value = value or 0,
  }, Comparison)
end

---@param value number
---@return boolean
function Comparison:check(value)
  local ret = false
  if self.type == ComparisonType[">"] or self.type == ComparisonType[">="] then
    ret = ret or value > self.value
  elseif self.type == ComparisonType["<"] or self.type == ComparisonType["<="] then
    ret = ret or value < self.value
  end
  if self.type == ComparisonType["="] or self.type == ComparisonType[">="] or self.type == ComparisonType["<="] then
    ret = ret or value == self.value
  end
  return ret
end

---@type ProcessingFunc
local function process_not(lexer, tok, dst, field)
  if lexer:from_span(tok.span) ~= "not" then return end
  dst[field] = not dst[field]
end

---@type ProcessingFunc
local function process_number(lexer, tok, dst, field)
  local str = lexer:from_span(tok.span) --[[@as string]]
  dst[field] = tonumber(str, 10)
end

---@type ProcessingFunc
local function process_number_decimals(lexer, tok, dst, field)
  local str = lexer:from_span(tok.span) --[[@as string]]
  local num = tonumber(str) --[[@as number]]
  if num == 0 then return end
  local exp = math.floor(math.log(num, 10))
  local dec = num / (10 ^ (exp + 1))
  dst[field] = dst[field] + dec
end

---@type ProcessingFunc
local function process_identifier(lexer, tok, dst, field)
  dst[field] = lexer:from_span(tok.span)
end

---@type ProcessingFunc
local function process_comparison(_, tok, dst, field)
  ---@type Comparison
  local comparison = dst[field]
  if tok == Token["="] then
    if comparison.type == ComparisonType[">"] then
      comparison.type = ComparisonType[">="]
    elseif comparison.type == ComparisonType["<"] then
      comparison.type = ComparisonType["<="]
    end
  elseif tok == Token[">"] then
    comparison.type = ComparisonType[">"]
  elseif tok == Token["<"] then
    comparison.type = ComparisonType["<"]
  end
end

---@enum ArgType
local ArgType = {
  INTEGER = 0,
  NUMBER = 1,
  IDENTIFIER = 2,
  COMPARISON = 3,
}

---@alias ModifierArgDef { name?: string, type: ArgType, target: ProcessingTarget }
---@alias ModifierArgs ModifierArgDef[]

---@param target ProcessingTarget
---@return Sequence
local function build_integer_arg_sequence(target)
  return { { tok = Token.NUMBER, process = { target, process_number } } }
end

---@param target ProcessingTarget
---@return Sequence
local function build_number_arg_sequence(target)
  return {
    { tok = Token.NUMBER, process = { target, process_number } },
    {
      optional = {
        { tok = Token["."] },
        { tok = Token.NUMBER, process = { target, process_number_decimals } },
      }
    }
  }
end

---@param target ProcessingTarget
---@return Sequence
local function build_identifier_arg_sequence(target)
  return {
    { tok = Token.IDENTIFIER, process = { target, process_identifier } },
  }
end

---@param target ProcessingTarget
---@return Sequence
local function build_comparison_arg_sequence(target)
  ---@type Comparison
  local comparison = target[1][target[2]]
  return {
    {
      choices = {
        { tok = Token["="], process = { target, process_comparison } },
        { tok = Token[">"], process = { target, process_comparison } },
        { tok = Token["<"], process = { target, process_comparison } },
      },
    },
    {
      optional = {
        { tok = Token["="], process = { target, process_comparison } }
      }
    },
    -- NOTE: Only works because it's at the end of the table.
    -- Unpacking in the middle of a table literal only unpacks the first value.
    table.unpack(build_number_arg_sequence({ comparison, "value" }))
  }
end

local builders = {
  [ArgType.INTEGER] = build_integer_arg_sequence,
  [ArgType.NUMBER] = build_number_arg_sequence,
  [ArgType.IDENTIFIER] = build_identifier_arg_sequence,
  [ArgType.COMPARISON] = build_comparison_arg_sequence,
}

---@param parser Parser
---@param args ModifierArgs
---@return string? error
local function parse_args(parser, args)
  local steps = {
    { tok = Token["("] },
  }

  for i, arg in ipairs(args) do
    if i > 1 then
      steps[#steps + 1] = { tok = Token[","] }
    end
    for _, step in ipairs(builders[arg.type](arg.target)) do
      steps[#steps + 1] = step
    end
  end

  steps[#steps + 1] = { tok = Token[")"] }

  return parser:parse_sequence(steps)
end

return {
  ComparisonType = ComparisonType,
  Comparison = Comparison,
  ArgType = ArgType,
  process = {
    ["not"] = process_not,
    number = process_number,
    number_decimals = process_number_decimals,
    identifier = process_identifier,
  },
  parse_args = parse_args,
}
