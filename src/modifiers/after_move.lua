local utils = require("utils.parsing")
local ArgType, parse_args = utils.ArgType, utils.parse_args

---@class AfterMove : Check
---@field category integer
---@field index integer
local AfterMove = {}
AfterMove.__index = AfterMove

---@return AfterMove?, string? error
function AfterMove.parse(parser)
  ---@type AfterMove
  local res = setmetatable({
    enabled = true,
    category = -1,
    index = -1,
  } --[[@as AfterMove]], AfterMove)

  local error = parse_args(parser, {
    { type = ArgType.INTEGER, target = { res, "category" } },
    { type = ArgType.INTEGER, target = { res, "index" } },
  })

  if error then return nil, error end

  return res, nil
end

function AfterMove:name()
  return "AfterMove"
end

function AfterMove:description()
  return "Only perform the swap this modifier is applied to after a specific move."
end

function AfterMove:enable()
  self.enabled = true
end

function AfterMove:disable()
  self.enabled = false
end

function AfterMove:check(state)
  local len = #state.actions
  if len == 0 then return false end
  local prev = state.actions[len]
  return prev[1] == self.category and prev[2] == self.index
end

function AfterMove:__tostring()
  return string.format("AfterMove(%d, %d)", self.category, self.index)
end

return AfterMove
