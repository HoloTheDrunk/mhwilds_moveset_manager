local Logger = require("lib.utils.logger")

local parsing = require("lib.utils.parsing")
local ArgType, parse_args, Comparison = parsing.ArgType, parsing.parse_args, parsing.Comparison

---@class IfExtern : Check
---@field mod string
---@field attrib string
---@field comparison Comparison
local IfExtern = {}
IfExtern.__index = IfExtern

---@return IfExtern?, string? error
function IfExtern.parse(parser)
  ---@type IfExtern
  local res = setmetatable({
    enabled = true,
    mod = "",
    attrib = "",
    comparison = Comparison.new(),
  } --[[@as IfExtern]], IfExtern)

  local error = parse_args(parser, {
    { type = ArgType.IDENTIFIER, target = { res, "mod" } },
    { type = ArgType.IDENTIFIER, target = { res, "attrib" } },
    { type = ArgType.COMPARISON, target = { res, "comparison" } },
  })

  if error then return nil, error end

  return res
end

function IfExtern:name()
  return "IfExtern"
end

function IfExtern:description()
  return "Checks the external value."
end

function IfExtern:enable()
  self.enabled = true
end

function IfExtern:disable()
  self.enabled = false
end

function IfExtern:check(state)
  local mod = state.external[self.mod]
  if not mod then
    Logger:log("warn", string.format("Missing mod '%s' required by the current moveset.", self.mod), "IfExtern")
    return false
  end
  local value = mod.attributes[self.attrib]
  if not value then return false end
  return self.comparison:check(value)
end

function IfExtern:__tostring()
  return string.format("IfExtern(%s, %s, %s)", self.mod, self.attrib, self.comparison)
end

return IfExtern
