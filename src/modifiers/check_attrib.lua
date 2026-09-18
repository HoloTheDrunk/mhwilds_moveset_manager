local oop = require("utils.oop")
local Modifier = require("modifiers.modifier")
local lexerlib = require("lexer")
local Token = lexerlib.Token

---@class CheckAttrib : ChildOf<Modifier>
local CheckAttrib = oop.inherit(Modifier)

function CheckAttrib.new()
  return setmetatable(CheckAttrib.super().new(), CheckAttrib)
end

---@param parser Parser
---@return string? err
function CheckAttrib:parse(parser)
  return parser:parse_sequence({
    { tok = Token.IDENTIFIER }
  })
end

return CheckAttrib
