local utils = require("utils.parsing")
local ArgType, parse_args, Comparison = utils.ArgType, utils.parse_args, utils.Comparison

---@class IfRenkiGauge : Check
---@field comparison Comparison
local IfRenkiGauge = {}
IfRenkiGauge.__index = IfRenkiGauge

---@return IfRenkiGauge?, string? error
function IfRenkiGauge.parse(parser)
  ---@type IfRenkiGauge
  local res = setmetatable({
    enabled = true,
    comparison = Comparison.new(),
  } --[[@as IfRenkiGauge]], IfRenkiGauge)

  local error = parse_args(parser, {
    { type = ArgType.COMPARISON, target = { res, "comparison" } },
  })

  if error then return nil, error end

  return res
end

function IfRenkiGauge:name()
  return "IfRenkiGauge"
end

function IfRenkiGauge:description()
  return "Checks the level of the renki gauge against the provided value."
end

function IfRenkiGauge:enable()
  self.enabled = true
end

function IfRenkiGauge:disable()
  self.enabled = false
end

function IfRenkiGauge:check(state)
  -- TODO:
end

function IfRenkiGauge:__tostring()
  return string.format("IfRenkiGauge(%s)", self.comparison)
end

return IfRenkiGauge
