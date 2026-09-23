local utils = require("utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class Gravity : Effect
---@field factor number
local Gravity = {}
Gravity.__index = Gravity

---@return Gravity?, string? error
function Gravity.parse(parser)
  ---@type Gravity
  local res = setmetatable({
    enabled = true,
    factor = 1.,
  } --[[@as Gravity]], Gravity)

  local error = parse_args(parser, {
    { type = ArgType.NUMBER, target = { res, "factor" } },
  })

  if error then return nil, error end

  return res, nil
end

function Gravity:name()
  return "Gravity"
end

function Gravity:description()
  return "Changes gravity during the swap this modifier is applied to."
end

function Gravity:enable()
  self.enabled = true
end

function Gravity:disable()
  self.enabled = false
end

function Gravity:apply(state)
  if self.factor ~= self.factor then self.factor = 1. end
  state.game.hunter_character:call("set_Gravity2", -9.81 * self.factor)
end

function Gravity:__tostring()
  return string.format("Gravity(%s)", self.factor)
end

return Gravity
