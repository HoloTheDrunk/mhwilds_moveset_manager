local ModState = require("state")
local state = ModState.new()

local hunter_type = sdk.find_type_definition("app.HunterCharacter")
local change_action_req_method = hunter_type and
    hunter_type:get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)")

local action_id_type = sdk.find_type_definition("ace.ACTION_ID") --[[@as RETypeDefinition]]

if change_action_req_method then
  sdk.hook(change_action_req_method, function(args)
    if not state.settings.enabled then return end
    if not state.game:init() then return end

    if state.control.final then
      state.control.final = false
      return
    end

    if not state.game.hunter_character or state.game.hunter_character ~= sdk.to_managed_object(args[2]) then
      return
    end

    if not state.game:update_weapon() then return end

    state.prev_swap = nil

    -- Get requested move IDs
    local action_id = args[4]
    ---@type integer
    local category = sdk.get_native_field(action_id, action_id_type, "_Category")
    ---@type integer
    local index = sdk.get_native_field(action_id, action_id_type, "_Index")

    state:log_action({ category, index })

    local moveset = state.manager:get_active_moveset(state.game.weapon_type)
    if not moveset then return end

    local swap = moveset:get_swap(category, index, state)
    if not swap then return end

    state:log_swap(swap)

    state.control.final = swap.modifiers.final and swap.modifiers.final.enabled or false

    sdk.set_native_field(action_id, action_id_type, "_Category", swap.to[1])
    sdk.set_native_field(action_id, action_id_type, "_Index", swap.to[2])
    state.game.hunter_character:call(
      "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
      args[3], action_id, args[5])

    for _, effect in ipairs(state.prev_swap.modifiers.effects) do
      if effect.on_swap then
        effect:on_swap(state)
      end
    end

    return sdk.PreHookResult.SKIP_ORIGINAL
  end)
end

re.on_frame(function()
  if not state.game:init() then return end

  if state.prev_swap then
    for _, effect in ipairs(state.prev_swap.modifiers.effects) do
      log.info("[on_frame] effect " .. effect:name())
      if effect.on_frame then
        effect:on_frame(state)
      end
    end
  else
    -- Reset important game state
    state.game.hunter_character:call("set_Gravity2", -9.81)
    state.game.player
        :call("get_Controller")
        :call("get_GameObject")
        :call("set_TimeScale", 1.)
  end
end)

re.on_draw_ui(function()
  if imgui.tree_node("Moveset Manager") then
    _, state.settings.enabled = imgui.checkbox("Enable", state.settings.enabled)
    imgui.begin_disabled(not state.settings.enabled)

    if imgui.button("Reload") then state.manager:reload() end
    imgui.same_line()
    if imgui.button("Save config") then state.manager:save_config() end
    imgui.same_line()
    if imgui.button("Load config") then state.manager:load_config() end

    local success, err = pcall(state.manager.draw_ui, state.manager)
    if not success then
      imgui.text("Failed to render state.manager: " .. err)
    end

    if state.game.weapon_type then
      local tbl = state.manager.weapons[state.game.weapon_type]
      if tbl and tbl.active then
        imgui.text(tbl.movesets[tbl.active].name)
        if tbl.movesets[tbl.active].description then
          imgui.text(tbl.movesets[tbl.active].description)
        end
      end
    end

    _, state.settings.debug = imgui.checkbox("Enable debug", state.settings.debug)
    if state.settings.debug then
      if state.game:init() then
        imgui.text(string.format("TimeScale: %s",
          state.game.player
          :call("get_Controller")
          :call("get_GameObject")
          :call("get_TimeScale")
        ))
        imgui.text(string.format("Gravity: %s", state.game.hunter_character:call("get_Gravity2")))

        if state.game.weapon_type then
          imgui.text("Weapon: " .. tostring(state.game.weapon_type))
        end
      end
      imgui.get_cursor_pos()
      if #state.actions > 0 then
        imgui.separator()

        for i = #state.actions, math.max(1, #state.actions - 10), -1 do
          local action = state.actions[i]
          imgui.text(string.format("%d: %d", action[1], action[2]))
        end
      end
    end

    imgui.end_disabled()
    imgui.tree_pop()
  end
end)
