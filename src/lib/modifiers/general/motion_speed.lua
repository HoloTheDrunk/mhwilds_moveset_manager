local utils = require("lib.utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class MotionSpeed : Effect
---@field multiplier number
local MotionSpeed = {}
MotionSpeed.__index = MotionSpeed

---@return MotionSpeed?, string? error
function MotionSpeed.parse(parser)
  ---@type MotionSpeed
  local res = setmetatable({
    enabled = true,
    is_effect = true,
    multiplier = 1.,
  } --[[@as MotionSpeed]], MotionSpeed)

  local error = parse_args(parser, {
    { type = ArgType.NUMBER, target = { res, "multiplier" } },
  })

  if error then return nil, error end

  return res
end

function MotionSpeed:name()
  return "MotionSpeed"
end

function MotionSpeed:description()
  return "Changes the player's motion speed during the swap this modifier is applied to."
end

function MotionSpeed:enable()
  self.enabled = true
end

function MotionSpeed:disable()
  self.enabled = false
end

function MotionSpeed:on_swap(state)
  if self.multiplier ~= self.multiplier then self.multiplier = 1 end
  -- Adding this tiny offset seems to prevent the game from locking up mysteriously
  state.game.hunter_character:call("set_ActionMotionSpeed", self.multiplier + 0.0001)
end

function MotionSpeed:__tostring()
  return string.format("MotionSpeed(%s)", self.multiplier)
end

return MotionSpeed
