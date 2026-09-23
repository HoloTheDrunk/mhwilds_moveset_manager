local modifier_lib = require("modifiers")

---@enum Weapon
local Weapon = {
  GreatSword = 0,
  SwordAndShield = 1,
  DualBlades = 2,
  LongSword = 3,
  Hammer = 4,
  HuntingHorn = 5,
  Lance = 6,
  Gunlance = 7,
  SwitchAxe = 8,
  ChargeBlade = 9,
  InsectGlaive = 10,
  Bow = 11,
  HeavyBowgun = 12,
  LightBowgun = 13,
}
local weapon_name = {}
for name, index in pairs(Weapon) do
  weapon_name[index] = name
end

---@enum AmmoType
local AmmoType = {
  Current = 0,
  Normal = 1,
  Pierce = 2,
  Spread = 3,
  Flaming = 4,
  Water = 5,
  Thunder = 6,
  Freeze = 7,
  Dragon = 8,
  Paralysis = 9,
  Sleep = 10,
  Poison = 11,
  Exhaust = 12,
  Sticky = 13,
  Cluster = 14,
  Wyvern = 15,
  Slicing = 16,
  Tranq = 17,
  Recover = 18,
  Demon = 19,
  Armor = 20,
}

-- -@alias Comparison "=" | "!=" | ">" | ">=" | "<" | "<="

---@enum SharpnessLevel
local SharpnessLevel = {
  Red = 0,
  Orange = 1,
  Yellow = 2,
  Green = 3,
  Blue = 4,
  White = 5,
  Purple = 6,
  Cyan = 7, -- Would be funny
}

---@enum ExtractColor
local ExtractColor = {
  Red = 0,
  White = 1,
  Orange = 2
}

-- Attribute start

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


-- Attribute end
-- Modifiers start

---@class M_Base
---@field enabled boolean

-- Long Sword
-- TODO: .addAuraLevel .consumeAuraLevel

---@class M_AuraIncrease : M_Base
---@field _aura_increase boolean

---@class M_AuraDecrease : M_Base
---@field _aura_decrease boolean

---@class Modifiers
---@field checks Check[]
---@field effects Effect[]
---@field final? Final

-- Modifiers end

---@alias Category integer
---@alias Index integer

---@alias Action [Category, Index]

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
      for _, check in ipairs(swap.modifiers.checks) do
        if check.enabled then
          check:check(state)
        end
      end

      return swap
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
