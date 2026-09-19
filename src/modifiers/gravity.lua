local utils = require("utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class Gravity : Modifier
---@field g2 number
local Gravity = {}
Gravity.__index = Gravity

---@return Gravity?, string? error
function Gravity.parse(parser)
  ---@type Gravity
  local res = {
    enabled = true,
    g2 = 1.,
  }

  local error = parse_args(parser, {
    { type = ArgType.NUMBER, target = { res, "g2" } },
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

return Gravity
