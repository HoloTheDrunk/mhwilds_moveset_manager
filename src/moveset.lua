local data = require("data")
local Weapon, weapon_name = data.Weapon, data.weapon_name

-- TODO: add these as modifiers

---@class Attribute

---@class ValueAttribute : Attribute
---@field _value boolean
---@field comparison Comparison

---@class Sharpness : ValueAttribute
---@field _sharpness boolean
---@field level SharpnessLevel

---@class Ammo : ValueAttribute
---@field _ammo boolean
---@field type AmmoType
---@field capacity? integer
---@field loaded? integer
---@field pouch? integer
---@field total? integer

---@class GaugeCharge : ValueAttribute
---@field _gauge boolean
---@field fill number Between 0 and 1

---@class SpiritGauge : ValueAttribute
---@field _spirit_gauge boolean
---@field level integer

---@class ToggleAttribute : Attribute
---@field _toggle boolean

-- Insect Glaive
---@class Extract : ToggleAttribute
---@field _extract boolean
---@field color ExtractColor

-- Dual Blades
---@class DemonMode : ToggleAttribute
---@field _demon_mode boolean

---@class ArchdemonMode : ToggleAttribute
---@field _archdemon_mode boolean

-- Switch Axe
---@class SwordMode : ToggleAttribute
---@field _sword_mode boolean

-- Charge Blade
---@class ShieldCharged : ToggleAttribute
---@field _shield_charged boolean

---@class AxeCharged : ToggleAttribute
---@field _axe_charged boolean

---@class SwordCharged : ToggleAttribute
---@field _sword_charged boolean

-- Long Sword
-- TODO: .addAuraLevel .consumeAuraLevel

---@alias Category integer
---@alias Index integer

---@alias Action [Category, Index]

---@class Modifiers
---@field checks Check[]
---@field effects Effect[]
---@field final? Final

---@class Swap
---@field id integer
---@field from Action
---@field to Action
---@field modifiers Modifiers

---@class Moveset
---@field name string
---@field weapon Weapon
---@field swaps Swap[]
---@field description string?
local Moveset = {}
Moveset.__index = Moveset

---@param name string
---@param weapon Weapon
---@param swaps Swap[]
---@param description string?
---@return Moveset
function Moveset.new(name, weapon, swaps, description)
  return setmetatable({
    name = name,
    weapon = weapon,
    swaps = swaps,
    description = description,
  }, Moveset)
end

---@param category Category
---@param index Index
---@param state ModState
---@return Swap?
function Moveset:get_swap(category, index, state)
  for _, swap in ipairs(self.swaps) do
    if swap.from[1] == category and swap.from[2] == index then
      local valid = true

      for _, check in ipairs(swap.modifiers.checks) do
        if check.enabled and not check:check(state) then
          log.warn(string.format("[%s] rejected swap %d", check:name(), swap.id))
          valid = false
          break
        end
      end

      if valid then
        return swap
      end
    end
  end
end

function Moveset:__tostring()
  local first_line = true
  local swaps_str = ""
  for _, swap in pairs(self.swaps) do
    local id, from, to = swap.id, swap.from, swap.to
    if first_line then
      first_line = false
    else
      swaps_str = swaps_str .. "\n" .. (" "):rep(9)
    end
    swaps_str = swaps_str .. string.format("%s: %d %d => %d %d", id == -1 and "_" or id, from[1], from[2], to[1], to[2])

    local function concat_modifier(modifier)
      if modifier.__tostring then
        swaps_str = swaps_str .. " | " .. tostring(modifier)
      else
        local name = modifier:name()
        if not name then
          name = "|ERROR|"
        end
        swaps_str = swaps_str .. string.format("[%s]", name)
      end
    end

    for name, modifier in pairs(swap.modifiers) do
      -- Avoid modifier categories
      if name ~= "checks" and name ~= "effects" then
        concat_modifier(modifier)
      end
    end
    for _, check in ipairs(swap.modifiers.checks) do
      concat_modifier(check)
    end
    for _, effect in ipairs(swap.modifiers.effects) do
      concat_modifier(effect)
    end
  end

  local description = ""
  if self.description then
    first_line = true
    for line in self.description:gmatch("[^\n]+") do
      if first_line then
        description = line
        first_line = false
      else
        description = description .. "\n" .. (" "):rep(15) .. line
      end
    end
  end
  return string.format([[Moveset {
  name: %s,
  weapon: %d (%s),
  swaps: %s,
  description: %s
}]], self.name, self.weapon, weapon_name[self.weapon], swaps_str, description)
end

return {
  Weapon = Weapon,
  weapon_name = weapon_name,
  Moveset = Moveset,
}
