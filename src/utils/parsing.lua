local lexerlib = require("lexer")
local Token = lexerlib.Token

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

---@enum ArgType
local ArgType = {
  INTEGER = 0,
  NUMBER = 1,
  IDENTIFIER = 2,
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

local builders = {
  [ArgType.INTEGER] = build_integer_arg_sequence,
  [ArgType.NUMBER] = build_number_arg_sequence,
  [ArgType.IDENTIFIER] = build_identifier_arg_sequence,
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
  ArgType = ArgType,
  process = {
    ["not"] = process_not,
    number = process_number,
    number_decimals = process_number_decimals,
    identifier = process_identifier,
  },
  parse_args = parse_args,
}
