local utils = require("utils.parsing")
local ArgType, parse_args, Comparison = utils.ArgType, utils.parse_args, utils.Comparison
local Weapon = require("moveset").Weapon

---@class IfSpiritGauge : Check
---@field comparison Comparison
local IfSpiritGauge = {}
IfSpiritGauge.__index = IfSpiritGauge

---@return IfSpiritGauge?, string? error
function IfSpiritGauge.parse(parser)
  ---@type IfSpiritGauge
  local res = setmetatable({
    enabled = true,
    comparison = Comparison.new(),
  } --[[@as IfSpiritGauge]], IfSpiritGauge)

  local error = parse_args(parser, {
    { type = ArgType.COMPARISON, target = { res, "comparison" } },
  })

  if error then return nil, error end

  return res
end

function IfSpiritGauge:name()
  return "IfSpiritGauge"
end

function IfSpiritGauge:description()
  return "Checks the level of the spirit gauge against the provided value."
end

function IfSpiritGauge:enable()
  self.enabled = true
end

function IfSpiritGauge:disable()
  self.enabled = false
end

function IfSpiritGauge:check(state)
  if not state.game.weapon_type == Weapon.LongSword then return false end
  local aura_level = state.game.weapon_handling:call("get_AuraLevel")
  return self.comparison:check(aura_level)
end

function IfSpiritGauge:__tostring()
  return string.format("IfSpiritGauge(%s)", self.comparison)
end

return IfSpiritGauge
