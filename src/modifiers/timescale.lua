local utils = require("utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class Timescale : Modifier
---@field ts number
local Timescale = {}
Timescale.__index = Timescale

---@return Timescale?, string? error
function Timescale.parse(parser)
  ---@type Timescale
  local res = {
    enabled = true,
    ts = 1.,
  }

  local error = parse_args(parser, {
    { type = ArgType.NUMBER, target = { res, "ts" } },
  })

  if error then return nil, error end

  return res, nil
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

return Timescale
