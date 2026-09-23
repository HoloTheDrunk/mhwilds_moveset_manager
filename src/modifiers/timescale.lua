local utils = require("utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class Timescale : Effect
---@field ts number
local Timescale = {}
Timescale.__index = Timescale

---@return Timescale?, string? error
function Timescale.parse(parser)
  ---@type Timescale
  local res = setmetatable({
    enabled = true,
    ts = 1.,
  } --[[@as Timescale]], Timescale)

  local error = parse_args(parser, {
    { type = ArgType.NUMBER, target = { res, "ts" } },
  })

  if error then return nil, error end

  return res
end

function Timescale:name()
  return "Timescale"
end

function Timescale:description()
  return "Changes the player's timescale during the swap this modifier is applied to."
end

function Timescale:enable()
  self.enabled = true
end

function Timescale:disable()
  self.enabled = false
end

function Timescale:apply(state)
  if self.ts ~= self.ts then self.ts = 1 end
  state.game.player
      :call("get_Controller")
      :call("get_GameObject")
  -- Adding this tiny offset seems to prevent the game from locking up mysteriously
      :call("set_TimeScale", self.ts and state.effects.timescale + 0.0001 or 1.)
end

function Timescale:__tostring()
  return string.format("Timescale(%s)", self.ts)
end

return Timescale
