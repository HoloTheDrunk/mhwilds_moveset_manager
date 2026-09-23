local Manager = require("moveset_manager")

---@class GameState
---@field player_mgr REManagedObject
---@field player? REManagedObject
---@field hunter_character? REManagedObject
---@field weapon_type? integer
---@field weapon_handling? REManagedObject
local GameState = {}
GameState.__index = GameState
function GameState.new()
  return setmetatable({
    player_mgr = sdk.get_managed_singleton("app.PlayerManager") --[[@as REManagedObject]]
  } --[[@as GameState]], GameState)
end

---@return boolean success false if something failed to get initialized
function GameState:init()
  if not self.player then
    self.player = self.player_mgr:call("getMasterPlayer")
  end
  if not self.player then return false end

  if not self.hunter_character then
    self.hunter_character = self.player:call("get_Character")
  end
  if not self.hunter_character then return false end

  return self:update_weapon()
end

---@return boolean success
function GameState:update_weapon()
  ---@type boolean, integer?
  local _, new_weapon_type = pcall(self.hunter_character.call, self.hunter_character, "get_WeaponType")
  if not new_weapon_type then return false end
  if self.weapon_type ~= new_weapon_type then
    self.weapon_type = new_weapon_type
    self.weapon_handling = self.hunter_character:call("get_WeaponHandling")
    if not self.weapon_handling then return false end
  end
  return true
end

---@class Control
---@field final boolean
local Control = {}
Control.__index = Control
function Control.new()
  return setmetatable({
    final = false,
  } --[[@as Control]], Control)
end

---@class ModSettings
---@field enabled boolean
---@field debug boolean

---@class ModState
---@field settings ModSettings
---@field game GameState
---@field manager Manager
---@field control Control
---@field actions Action[]
---@field swaps integer[]
---@field prev_swap? Swap
local ModState = {}
ModState.__index = ModState
---@return ModState
function ModState.new()
  local manager = Manager.new()
  manager:load_movesets()
  manager:load_config()

  return setmetatable(
    {
      settings = {
        enabled = true,
        debug = true,
      },
      game = GameState.new(),
      manager = manager,
      control = Control.new(),
      actions = {},
      swaps = {},
    } --[[@as ModState]], ModState)
end

---@param action Action
---@return nil
function ModState:log_action(action)
  if #self.actions == 0
      or self.actions[#self.actions][1] ~= action[1]
      or self.actions[#self.actions][2] ~= action[2]
  then
    self.actions[#self.actions + 1] = action
  end
end

---@param swap Swap
---@return nil
function ModState:log_swap(swap)
  self.swaps[#self.swaps + 1] = swap.id
  self.prev_swap = swap
end

return ModState
