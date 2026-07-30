---! Moveset Manager
---! Defines a standard structure for action swap mods.

local settings = {
  enabled = true,
  debug = true,
}

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

---@enum Modifier
---Flags indicating motion modifiers
local Modifier = {
  Final = 1 << 0,
}
local modifier_name = {}
for name, index in pairs(Modifier) do
  modifier_name[index] = name
end

---@alias Category integer
---@alias Index integer
---@alias Modifiers integer

---@alias Action [Category, Index, Modifiers]

---@class Moveset
---@field name string
---@field weapon Weapon
---@field swaps table<Category, table<Index, Action>>
local Moveset = {}
Moveset.__index = Moveset

---@param name string
---@param weapon Weapon
---@param swaps table<Category, table<Index, Action>>
---@return Moveset
function Moveset.new(name, weapon, swaps)
  return setmetatable({
    name = name,
    weapon = weapon,
    swaps = swaps
  }, Moveset)
end

---Returns the parsed moveset or nil and an error message
---@param file_content string
---@return Moveset?, string? error
function Moveset.parse(file_content)
  local res = { name = nil, weapon = nil, swaps = {} }

  ---@type table<Index, Action>?
  local category = nil

  for line in string.gmatch(file_content, '[^\r\n]+') do
    -- Skip comments
    if string.sub(line, 1, 1) == "!" then goto continue end

    -- Parse name
    if not res.name then
      res.name = line
      goto continue
    end

    -- Parse weapon
    if not res.weapon then
      local stripped = string.gsub(line, '%s+', '')
      local weapon = Weapon[stripped]
      if not weapon then
        return nil, string.format("Failed to parse weapon '%s'", line)
      end
      res.weapon = weapon
      goto continue
    end

    -- Parse category
    if string.sub(line, 1, 1) == '#' then
      local stripped = string.gsub(line, '^#%s*(.-)%s*$', '%1')
      local category_id = tonumber(stripped, 10)
      if not res.swaps[category_id] then
        res.swaps[category_id] = {}
      end
      category = res.swaps[category_id]
      goto continue
    end

    -- Parse swap
    local swap_parse_fail = function()
      return nil,
          string.format(
            "Invalid swap '%s'. Swaps should be of the form '<from_index> <category> <index> (modifiers)'.",
            line
          )
    end

    local tokens = {}
    for str in string.gmatch(line, "[^%s]+") do
      tokens[#tokens + 1] = str
    end

    local numbers = {}
    for i = 1, 3, 1 do
      local num = tonumber(tokens[i])
      if not num then return swap_parse_fail() end
      numbers[#numbers + 1] = num
    end

    local modifiers = 0
    for i = 4, #tokens, 1 do
      local modifier = Modifier[tokens[i]]
      if not modifier then
        return nil, string.format("Unrecognized modifier '%s'.", tokens[i])
      end
      modifiers = modifiers | modifier
    end

    category[numbers[1]] = { numbers[2], numbers[3], modifiers }

    ::continue::
  end

  if not res.name then
    return nil, "Invalid moveset file, missing name."
  end

  if not res.weapon then
    return nil, "Invalid moveset file, missing weapon."
  end

  return setmetatable(res, Moveset), nil
end

---@param category Category
---@param index Index
---@return Action?
function Moveset:get_swap(category, index)
  if self.swaps[category] then
    return self.swaps[category][index]
  end
end

---@class WeaponMovesets
---@field movesets Moveset[]
---@field active integer?

---@class Manager
---@field weapons table<Weapon, WeaponMovesets>
---@field errors string[]
local Manager = {}
Manager.__index = Manager

---@return Manager
function Manager.new()
  return setmetatable({ weapons = {}, errors = {} }, Manager)
end

function Manager:clear()
  self.weapons = {}
  self.errors = {}
end

function Manager:load_movesets()
  ---@type string[]
  local paths = fs.glob([[.*\.moveswap]])
  for _, path in ipairs(paths) do
    local success, moveset, error = pcall(Moveset.parse, fs.read(path))
    if not success then
      self.errors[#self.errors + 1] = string.format("[%s] Unknown error.", path)
      goto continue
    end
    if error then
      self.errors[#self.errors + 1] = string.format("[%s] %s", path, error)
      goto continue
    end
    self:register(moveset --[[@as Moveset]])
    ::continue::
  end
end

---@param moveset Moveset
---@return boolean success
function Manager:register(moveset)
  if not self.weapons[moveset.weapon] then
    self.weapons[moveset.weapon] = { movesets = {}, active = nil }
  end
  local tbl = self.weapons[moveset.weapon]

  -- Check for duplicate moveset names
  for name, _ in pairs(tbl) do
    if name == moveset.name then
      self.errors[#self.errors + 1] = string.format("Tried to register moveset '%s' twice", moveset.name)
      return false
    end
  end

  tbl.movesets[#tbl.movesets + 1] = moveset

  return true
end

function Manager:draw_ui()
  if #self.errors > 0 then
    imgui.text("Error: " .. self.errors[#self.errors])
  end

  for weapon, tbl in pairs(self.weapons) do
    ---@type string[]
    local names = { "Vanilla" }
    for _, mv in ipairs(tbl.movesets) do
      names[#names + 1] = mv.name
    end

    local changed, selection = imgui.combo(weapon_name[weapon], (tbl.active or 0) + 1, names)
    if changed then
      print(selection)
      if selection == 1 then
        tbl.active = nil
      else
        tbl.active = selection - 1
      end
    end
  end
end

local manager = Manager.new()
manager:load_movesets()

local hunter_type = sdk.find_type_definition("app.HunterCharacter")
local change_action_req_method = hunter_type and
    hunter_type:get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)")

local action_id_type = sdk.find_type_definition("ace.ACTION_ID") --[[@as RETypeDefinition]]

local hunter_character = nil
local weapon_type = nil
local current_action = nil
local actions = {}

local modifiers = {
  final = false,
}

if change_action_req_method then
  sdk.hook(change_action_req_method, function(args)
    if not settings.enabled then return end

    if modifiers.final then
      modifiers.final = false
      return
    end

    if not hunter_character then
      hunter_character = sdk.to_managed_object(args[2])
    end
    if hunter_character then
      weapon_type = hunter_character:call("get_WeaponType") --[[@as integer]]

      local action_id = args[4]
      local category = sdk.get_native_field(action_id, action_id_type, "_Category")
      local index = sdk.get_native_field(action_id, action_id_type, "_Index")
      current_action = { category = category, index = index }

      local tbl = manager.weapons[weapon_type]
      if tbl and tbl.active then
        local moveset = tbl.movesets[tbl.active]
        local action = moveset:get_swap(category, index)
        if action then
          modifiers.final = action[3] & Modifier.Final
          sdk.set_native_field(action_id, action_id_type, "_Category", action[1])
          sdk.set_native_field(action_id, action_id_type, "_Index", action[2])
          hunter_character:call(
            "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
            args[3], action_id, args[5])
          return sdk.PreHookResult.SKIP_ORIGINAL
        end
      end
    end
  end)
end

re.on_draw_ui(function()
  if imgui.tree_node("Moveset Manager") then
    _, settings.enabled = imgui.checkbox("Enable", settings.enabled)
    imgui.begin_disabled(not settings.enabled)

    if imgui.button("Reload") then
      ---@type table<Weapon, string>
      local active = {}
      for id, sets in pairs(manager.weapons) do
        if sets.active then
          active[id] = sets.movesets[sets.active].name
        end
      end
      manager:clear()
      manager:load_movesets()
      for weapon, name in pairs(active) do
        for i, mv in ipairs(manager.weapons[weapon].movesets) do
          if mv.name == name then
            manager.weapons[weapon].active = i
            break
          end
        end
      end
    end

    local success, err = pcall(manager.draw_ui, manager)
    if not success then
      imgui.text("Failed to render manager: " .. err)
    end

    _, settings.debug = imgui.checkbox("Enable debug", settings.debug)
    if settings.debug then
      if weapon_type then
        imgui.text("Weapon: " .. tostring(weapon_type))
      end
      if current_action then
        imgui.separator()

        if #actions == 0 or actions[#actions].category ~= current_action.category or actions[#actions].index ~= current_action.index then
          actions[#actions + 1] = current_action
        end

        for i = #actions, math.max(1, #actions - 10), -1 do
          local action = actions[i]
          imgui.text(string.format("%d: %d", action.category, action.index))
        end
      end
    end

    imgui.end_disabled()
    imgui.tree_pop()
  end
end)
