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

---@class M_After : M_Base
---@field prev_id integer

---@class Modifiers
---@field final? M_Final
---@field after? M_After

---@alias Category integer
---@alias Index integer

---@alias Action [Category, Index, Modifiers]

---@class Moveset
---@field name string
---@field weapon Weapon
---@field swaps table<Category, table<Index, Action>>
---@field description string?
local Moveset = {}
Moveset.__index = Moveset

---@param name string
---@param weapon Weapon
---@param swaps table<Category, table<Index, Action>>
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

-- ---Returns the parsed moveset or nil and an error message
-- ---@param file_content string
-- ---@return Moveset?, string? error
-- function Moveset.parse(file_content)
--   local res = { name = nil, weapon = nil, swaps = {} }
--
--   ---@type table<Index, Action>?
--   local category = nil
--
--   for line in string.gmatch(file_content, '[^\r\n]+') do
--     -- Skip comments
--     if string.sub(line, 1, 1) == "!" then goto continue end
--
--     -- Parse name
--     if not res.name then
--       res.name = line
--       goto continue
--     end
--
--     -- Parse weapon
--     if not res.weapon then
--       local stripped = string.gsub(line, '%s+', '')
--       local weapon = Weapon[stripped]
--       if not weapon then
--         return nil, string.format("Failed to parse weapon '%s'", line)
--       end
--       res.weapon = weapon
--       goto continue
--     end
--
--     -- Parse category
--     if string.sub(line, 1, 1) == '#' then
--       local stripped = string.gsub(line, '^#%s*(.-)%s*$', '%1')
--       local category_id = tonumber(stripped, 10)
--       if not res.swaps[category_id] then
--         res.swaps[category_id] = {}
--       end
--       category = res.swaps[category_id]
--       goto continue
--     end
--
--     -- Parse swap
--     local swap_parse_fail = function()
--       return nil,
--           string.format(
--             "Invalid swap '%s'. Swaps should be of the form '<from_index> <category> <index> (modifiers)'.",
--             line
--           )
--     end
--
--     local tokens = {}
--     for str in string.gmatch(line, "[^%s]+") do
--       tokens[#tokens + 1] = str
--     end
--
--     local numbers = {}
--     for i = 1, 3, 1 do
--       local num = tonumber(tokens[i])
--       if not num then return swap_parse_fail() end
--       numbers[#numbers + 1] = num
--     end
--
--     local modifiers = 0
--     for i = 4, #tokens, 1 do
--       local modifier = Modifier[tokens[i]]
--       if not modifier then
--         return nil, string.format("Unrecognized modifier '%s'.", tokens[i])
--       end
--       modifiers = modifiers | modifier
--     end
--
--     category[numbers[1]] = { numbers[2], numbers[3], modifiers }
--
--     ::continue::
--   end
--
--   if not res.name then
--     return nil, "Invalid moveset file, missing name."
--   end
--
--   if not res.weapon then
--     return nil, "Invalid moveset file, missing weapon."
--   end
--
--   return setmetatable(res, Moveset), nil
-- end

---@param category Category
---@param index Index
---@return Action?
function Moveset:get_swap(category, index)
  if self.swaps[category] then
    return self.swaps[category][index]
  end
end

function Moveset:__tostring()
  local first_line = true
  local swaps_str = ""
  for category, swaps in pairs(self.swaps) do
    for index, new in pairs(swaps) do
      local cat, ind, modifiers = new[1], new[2], new[3]
      if first_line then
        first_line = false
      else
        swaps_str = swaps_str .. "\n" .. (" "):rep(9)
      end
      swaps_str = swaps_str .. string.format("%d %d => %d %d", category, index, cat, ind)
      if modifiers.after then swaps_str = swaps_str .. string.format(" | After(%d)", modifiers.after.prev_id) end
      if modifiers.final then swaps_str = swaps_str .. " | Final" end
    end
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
  Modifier = Modifier,
}
