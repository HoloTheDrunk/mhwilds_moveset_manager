---@type MovesetManagerState
local state = nil
---@class Attributes
---@field dodges number
local attributes = nil

local max_dodges = 5

---@return boolean initialized
local function init()
  if not state and MovesetManagerState then
    -- Cast at the end just to shut up the LSP diagnostic while developing this
    -- alongside the Moveset Manager mod.
    -- Not needed if you're developing your own mod and only using the provided
    -- `.d.lua` file.
    state = MovesetManagerState --[[@as MovesetManagerState]]
    MovesetManagerState.external["ex_dodge"] = { attributes = { dodges = 2 } }
    attributes = state.external["ex_dodge"].attributes
  end
  return MovesetManagerState ~= nil
end

sdk.hook(
  sdk.find_type_definition("app.cEnemyStockDamage")
  :get_method("stockDamageDetail") --[[@as REMethodDefinition]],
  function()
    -- local hit_info = sdk.to_managed_object(args[3])
    attributes.dodges = math.min(attributes.dodges + .1, max_dodges)
  end
)

re.on_frame(function()
  if not init() then return end

  for i = 1, math.floor(attributes.dodges) do
    if i > max_dodges then break end -- Infinite loop protection
    draw.filled_rect(55 * (i + 1), 50, 50, 50, 0xffff0000)
  end
end)

re.on_draw_ui(function()
  if not imgui.tree_node("EX Dodge") then return end

  imgui.text("Example mod to illustrate Moveset Manager mod integration.")
  if attributes then
    imgui.text(string.format("Dodges: %.2f", tostring(attributes.dodges)))
  end

  imgui.tree_pop()
end)
