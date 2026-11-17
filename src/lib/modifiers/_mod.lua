---@alias ModifierCategory table<string, Modifier>

---@class ModifierLib
---@field special ModifierCategory
---@field general ModifierCategory
---@field external ModifierCategory
---@field weapon_specific table<Weapon, ModifierCategory>
local ModifierLib = {
  special = require("lib.modifiers.special._mod"),
  general = require("lib.modifiers.general._mod"),
  external = require("lib.modifiers.external._mod"),
  weapon = require("lib.modifiers.weapon._mod"),
} --[[@as ModifierLib]]

---@param name string
---@return Modifier?
function ModifierLib:get(name)
  local special = self.special[name]
  if special then return special end

  local general = self.general[name]
  if general then return general end

  local external = self.external[name]
  if external then return external end

  for _, weapon_category in pairs(self.weapon) do
    local weapon = weapon_category[name]
    if weapon then return weapon end
  end

  return nil
end

return ModifierLib
