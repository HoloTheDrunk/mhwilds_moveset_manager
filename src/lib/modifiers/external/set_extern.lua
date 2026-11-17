local Logger = require("lib.utils.logger")

local parsing = require("lib.utils.parsing")
local ArgType, parse_args = parsing.ArgType, parsing.parse_args

---@class SetExtern : Effect
---@field mod string
---@field attrib string
---@field value number
local SetExtern = {}
SetExtern.__index = SetExtern

---@return SetExtern?, string? error
function SetExtern.parse(parser)
  ---@type SetExtern
  local res = setmetatable({
    enabled = true,
    is_effect = true,
    mod = "",
    attrib = "",
    value = 0,
  } --[[@as SetExtern]], SetExtern)

  local error = parse_args(parser, {
    { type = ArgType.IDENTIFIER, target = { res, "mod" } },
    { type = ArgType.IDENTIFIER, target = { res, "attrib" } },
    { type = ArgType.NUMBER,     target = { res, "value" } },
  })

  if error then return nil, error end

  return res, nil
end

function SetExtern:name()
  return "SetExtern"
end

function SetExtern:description()
  return "Sets the desired attribute's value."
end

function SetExtern:enable()
  self.enabled = true
end

function SetExtern:disable()
  self.enabled = false
end

function SetExtern:on_swap(state)
  local mod = state.external[self.mod]
  if not mod then
    Logger:log("warn", string.format("Missing mod '%s' required by the current moveset.", self.mod), self:name())
    return
  end
  mod.attributes[self.attrib] = self.value
end

function SetExtern:__tostring()
  return string.format("SetExtern(%s, %s, %s)", self.mod, self.attrib, self.value)
end

return SetExtern
