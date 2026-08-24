---! Moveset Manager
---! Defines a standard structure for action swap mods.

local moveset_lib = require("moveset")
local Weapon, weapon_name = moveset_lib.Weapon, moveset_lib.weapon_name

local Parser = require("parser")

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
    local moveset, error = Parser.new(fs.read(path)):parse()
    if not moveset then
      self.errors[#self.errors + 1] = string.format("[%s] %s", path, error)
      goto continue
    end
    self:register(moveset --[[@as Moveset]])
    ::continue::
  end
end

function Manager:load_config()
  local config = json.load_file("moveset_manager_config.json")
  if not config then return end
  for wp_name, name in pairs(config) do
    local wp = Weapon[wp_name]
    if not wp then
      self.errors[#self.errors + 1] = string.format("Unknown weapon name '%s'.", wp_name)
      return
    end
    local mvs = self.weapons[wp]
    for i, mv in ipairs(mvs.movesets) do
      if mv.name == name then
        mvs.active = i
        break
      end
    end
  end
end

function Manager:save_config()
  local active_movesets = {}
  for weapon, mvs in pairs(self.weapons) do
    if not mvs.active then goto continue end
    active_movesets[weapon_name[weapon]] = mvs.movesets[mvs.active].name
    ::continue::
  end
  if not json.dump_file("moveset_manager_config.json", active_movesets) then
    self.errors[#self.errors + 1] = "Failed to write config."
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

return Manager
