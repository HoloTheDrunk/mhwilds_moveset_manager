local utils = require("utils.parsing")
local ArgType, parse_args, Comparison = utils.ArgType, utils.parse_args, utils.Comparison

---@class CheckRenkiGauge : Modifier
---@field comparison Comparison
---@field value number
local CheckRenkiGauge = {}
CheckRenkiGauge.__index = CheckRenkiGauge

---@return CheckRenkiGauge?, string? error
function CheckRenkiGauge.parse(parser)
  ---@type CheckRenkiGauge
  local res = {
    enabled = true,
    comparison = Comparison["="],
    value = 1.,
  }

  local error = parse_args(parser, {
    { type = ArgType.COMPARISON, target = { res, "comparison" } },
    { type = ArgType.NUMBER,     target = { res, "value" } },
  })

  if error then return nil, error end

  -- if not res.comparison then
  --   return nil, debug.traceback("[CheckRenkiGauge] Missing comparison.")
  -- end

  return res, nil
end

function CheckRenkiGauge:name()
  return "CheckRenkiGauge"
end

function CheckRenkiGauge:description()
  return "Checks the level of the renki gauge against the provided value."
end

function CheckRenkiGauge:enable()
  self.enabled = true
end

function CheckRenkiGauge:disable()
  self.enabled = false
end

return CheckRenkiGauge
