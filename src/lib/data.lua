---@param enum table
---@return table reverse
local function reverse_enum(enum)
  local names = {}
  for name, index in pairs(enum) do
    names[index] = name
  end
  return names
end

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
---@type table<Weapon, string>
local weapon_name = reverse_enum(Weapon)

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
---@type table<AmmoType, string>
local ammo_name = reverse_enum(AmmoType)

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
---@type table<SharpnessLevel, string>
local sharpness_name = reverse_enum(SharpnessLevel)

---@enum ExtractColor
local ExtractColor = {
  Red = 0,
  White = 1,
  Orange = 2
}
---@type table<ExtractColor, string>
local extract_name = reverse_enum(ExtractColor)

return {
  Weapon = Weapon,
  weapon_name = weapon_name,
  AmmoType = AmmoType,
  ammo_name = ammo_name,
  SharpnessLevel = SharpnessLevel,
  sharpness_name = sharpness_name,
  ExtractColor = ExtractColor,
  extract_name = extract_name,
}
