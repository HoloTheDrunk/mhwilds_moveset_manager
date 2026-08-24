local Manager = require("moveset_manager")

local settings = {
  enabled = true,
  debug = true,
}

local game = {
  ---@type REManagedObject
  player_mgr = sdk.get_managed_singleton("app.PlayerManager") --[[@as REManagedObject]],
  ---@type REManagedObject?
  player = nil,
  ---@type REManagedObject?
  hunter_character = nil,
}

local manager = Manager.new()
manager:load_movesets()
manager:load_config()

local hunter_type = sdk.find_type_definition("app.HunterCharacter")
local change_action_req_method = hunter_type and
    hunter_type:get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)")

local action_id_type = sdk.find_type_definition("ace.ACTION_ID") --[[@as RETypeDefinition]]

local hunter_character = nil
---@type integer?
local weapon_type = nil
local current_action = nil
local actions = {}

local modifiers = {
  final = false,
  ---@type number?
  ts = nil,
  ---@type number?
  g = nil,
}

local prev = {
  ---@type [integer, integer]
  ---We can safely assume people will do *something* before a replaced action.
  move = nil,
  ---@type integer?
  swap = nil,
}

if change_action_req_method then
  sdk.hook(change_action_req_method, function(args)
    local ret = sdk.PreHookResult.CALL_ORIGINAL

    if not settings.enabled then goto finish end

    if modifiers.final then
      modifiers.final = false
      goto finish
    end

    if not hunter_character then
      hunter_character = sdk.to_managed_object(args[2])
    end
    if not hunter_character then goto finish end

    ---@type boolean, integer?
    _, weapon_type = pcall(hunter_character.call, hunter_character, "get_WeaponType")
    if not weapon_type then return end

    do
      modifiers.g = nil
      modifiers.ts = nil

      local action_id = args[4]
      local category = sdk.get_native_field(action_id, action_id_type, "_Category")
      local index = sdk.get_native_field(action_id, action_id_type, "_Index")

      -- Ignore seikret actions
      if category == 0 and index > 400 then goto finish end

      current_action = { category = category, index = index }

      local tbl = manager.weapons[weapon_type]
      if not tbl or not tbl.active then goto finish end

      local moveset = tbl.movesets[tbl.active]
      local swap = moveset:get_swap(category, index, prev.move, prev.swap)
      if swap then
        prev.swap = swap.id
        modifiers.final = swap.modifiers.final and swap.modifiers.final.enabled
        if swap.modifiers.gravity and swap.modifiers.gravity.enabled then
          modifiers.g = swap.modifiers.gravity.g2
        end
        if swap.modifiers.time_scale and swap.modifiers.time_scale.enabled then
          modifiers.ts = swap.modifiers.time_scale.ts
        end

        sdk.set_native_field(action_id, action_id_type, "_Category", swap.to[1])
        sdk.set_native_field(action_id, action_id_type, "_Index", swap.to[2])
        hunter_character:call(
          "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
          args[3], action_id, args[5])

        ret = sdk.PreHookResult.SKIP_ORIGINAL
      end
    end

    ::finish::
    if current_action then
      prev.move = { current_action.category, current_action.index }
    end
    return ret
  end)
end

re.on_frame(function()
  if not game.player then
    game.player = game.player_mgr:call("getMasterPlayer")
  end

  if game.player and not game.hunter_character then
    game.hunter_character = game.player:call("get_Character")
  end

  if game.player then
    -- NaN check
    if modifiers.ts ~= modifiers.ts then modifiers.ts = 1 end
    game.player
        :call("get_Controller")
        :call("get_GameObject")
        :call("set_TimeScale", modifiers.ts and modifiers.ts + 0.0001 or 1.)
  end

  if game.hunter_character and modifiers.g then
    -- NaN check
    if modifiers.g ~= modifiers.g then modifiers.g = 1 end
    game.hunter_character:call("set_Gravity2", -9.81 * modifiers.g)
  end
end)

re.on_draw_ui(function()
  if imgui.tree_node("Moveset Manager") then
    _, settings.enabled = imgui.checkbox("Enable", settings.enabled)
    imgui.text(string.format("TimeScale: %s (%s)", tostring(type(modifiers.ts)), modifiers.ts))
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
        if not manager.weapons[weapon] then manager.weapons[weapon] = { movesets = {} } end
        for i, mv in ipairs(manager.weapons[weapon].movesets) do
          if mv.name == name then
            manager.weapons[weapon].active = i
            break
          end
        end
      end
    end

    imgui.same_line()

    if imgui.button("Save config") then
      manager:save_config()
    end

    imgui.same_line()

    if imgui.button("Load config") then
      manager:load_config()
    end

    local success, err = pcall(manager.draw_ui, manager)
    if not success then
      imgui.text("Failed to render manager: " .. err)
    end

    if weapon_type then
      local tbl = manager.weapons[weapon_type]
      if tbl and tbl.active then
        imgui.text(tbl.movesets[tbl.active].name)
        if tbl.movesets[tbl.active].description then
          imgui.text(tbl.movesets[tbl.active].description)
        end
      end
    end

    _, settings.debug = imgui.checkbox("Enable debug", settings.debug)
    if settings.debug then
      if weapon_type then
        imgui.text("Weapon: " .. tostring(weapon_type))
      end
      if current_action and (#actions == 0 or actions[#actions].category ~= current_action.category or actions[#actions].index ~= current_action.index) then
        actions[#actions + 1] = current_action
      end
      if #actions > 0 then
        imgui.separator()

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
