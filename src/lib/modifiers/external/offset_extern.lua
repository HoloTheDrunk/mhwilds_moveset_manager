local Logger = require("lib.utils.logger")

local parsing = require("lib.utils.parsing")
local ArgType, parse_args = parsing.ArgType, parsing.parse_args

---@class OffsetExtern : Effect
---@field mod string
---@field attrib string
---@field value number
local OffsetExtern = {}
OffsetExtern.__index = OffsetExtern

---@return OffsetExtern?, string? error
function OffsetExtern.parse(parser)
  ---@type OffsetExtern
  local res = setmetatable({
    enabled = true,
    is_effect = true,
    mod = "",
    attrib = "",
    value = 0,
  } --[[@as OffsetExtern]], OffsetExtern)

  local error = parse_args(parser, {
    { type = ArgType.IDENTIFIER, target = { res, "mod" } },
    { type = ArgType.IDENTIFIER, target = { res, "attrib" } },
    { type = ArgType.NUMBER,     target = { res, "value" } },
  })

  if error then return nil, error end

  return res, nil
end

function OffsetExtern:name()
  return "OffsetExtern"
end

function OffsetExtern:description()
  return "Offsets the desired attribute's value by an amount."
end

function OffsetExtern:enable()
  self.enabled = true
end

function OffsetExtern:disable()
  self.enabled = false
end

function OffsetExtern:on_swap(state)
  local mod = state.external[self.mod]
  if not mod then
    Logger:log("warn", string.format("Missing mod '%s' required by the current moveset.", self.mod), "IfAttrib")
    return
  end
  local value = mod.attributes[self.attrib] or 0
  mod.attributes[self.attrib] = value + self.value
end

function OffsetExtern:__tostring()
  return string.format("OffsetExtern(%s, %s, %s)", self.mod, self.attrib, self.value)
end

return OffsetExtern
