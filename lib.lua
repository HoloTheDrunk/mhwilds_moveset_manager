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

---@class M_Base
---@field enabled boolean

---@class M_Final : M_Base

---@class M_AfterMove : M_Base
---@field category integer
---@field index integer

---@class M_AfterSwap : M_Base
---@field id integer

---@class Modifiers
---@field final? M_Final
---@field after_move? M_AfterMove
---@field after_swap? M_AfterSwap

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
---@param prev_move Action
---@param prev_swap integer?
---@return Swap?
function Moveset:get_swap(category, index, prev_move, prev_swap)
  for _, swap in ipairs(self.swaps) do
    local from, modifiers = swap.from, swap.modifiers

    repeat
      if from[1] ~= category or from[2] ~= index then
        break
      end

      if modifiers.after_move and modifiers.after_move.enabled
          and (modifiers.after_move.category ~= prev_move[1]
            or modifiers.after_move.index ~= prev_move[2])
      then
        break
      end

      if prev_swap and modifiers.after_swap
          and modifiers.after_swap.enabled
          and modifiers.after_swap.id ~= prev_swap
      then
        break
      end

      return swap
    until true
  end
end

function Moveset:__tostring()
  local first_line = true
  local swaps_str = ""
  for _, swap in pairs(self.swaps) do
    local id, from, to, modifiers = swap.id, swap.from, swap.to, swap.modifiers
    if first_line then
      first_line = false
    else
      swaps_str = swaps_str .. "\n" .. (" "):rep(9)
    end
    swaps_str = swaps_str .. string.format("%s: %d %d => %d %d", id == -1 and "_" or id, from[1], from[2], to[1], to[2])
    if modifiers.after_move then
      swaps_str = swaps_str ..
          string.format(" | AfterMove(%d, %d)", modifiers.after_move.category, modifiers.after_move.index)
    end
    if modifiers.after_swap then
      swaps_str = swaps_str ..
          string.format(" | AfterSwap(%d)", modifiers.after_swap.id)
    end
    if modifiers.final then swaps_str = swaps_str .. " | Final" end
  end

  local description = ""
  first_line = true
  for line in self.description:gmatch("[^\n]+") do
    if first_line then
      description = line
      first_line = false
    else
      description = description .. "\n" .. (" "):rep(15) .. line
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
