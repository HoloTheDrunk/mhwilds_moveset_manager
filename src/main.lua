local ModState = require("lib.state")
local state = ModState.new()
MovesetManagerState = state

local Logger = require("lib.utils.logger")
Logger:set_name("Moveset Manager")

local get_screen_size = require("lib.utils.engine").get_screen_size

local hunter_type = sdk.find_type_definition("app.HunterCharacter")
local change_action_req_method = hunter_type and
    hunter_type:get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)")

local action_id_type = sdk.find_type_definition("ace.ACTION_ID") --[[@as RETypeDefinition]]

-- Avoid recursive calling by only processing each call once.
local call_processed = false
local perform_on_swap_effects = false

if change_action_req_method then
  sdk.hook(change_action_req_method,
    function(args)
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

      -- Get requested move IDs
      local action_id = args[4]

      ---@type integer
      local category = sdk.get_native_field(action_id, action_id_type, "_Category")
      ---@type integer
      local index = sdk.get_native_field(action_id, action_id_type, "_Index")

      if call_processed then
        state:log_action({ category, index })
        return
      end

      local moveset = state.manager:get_active_moveset(state.game.weapon_type)
      if not moveset then
        state.prev_swap = nil
        state:log_action({ category, index })
        return
      end

      local swap = moveset:get_swap(category, index, state)
      if not swap then
        state.prev_swap = nil
        state:log_action({ category, index })
        return
      end

      state:log_swap(swap)

      Logger:log("info", string.format("Swap: %d %d => %d %d", swap.from[1], swap.from[2], swap.to[1], swap.to[2]),
        "main")

      state.control.final = swap.modifiers.final and swap.modifiers.final.enabled or false

      call_processed = true

      sdk.set_native_field(action_id, action_id_type, "_Category", swap.to[1])
      sdk.set_native_field(action_id, action_id_type, "_Index", swap.to[2])

      state.game.hunter_character:call(
        "changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)",
        args[3], action_id, args[5])

      state:log_action({ swap.to[1], swap.to[2] })

      perform_on_swap_effects = true

      return sdk.PreHookResult.SKIP_ORIGINAL
    end,
    function()
      call_processed = false
    end
  )
end

re.on_frame(function()
  if not state.game:init() then return end

  if state.prev_swap then
    for _, effect in ipairs(state.prev_swap.modifiers.effects) do
      if perform_on_swap_effects and effect.on_swap then
        effect:on_swap(state)
      end

      if effect.on_frame then
        effect:on_frame(state)
      end
    end
    perform_on_swap_effects = false
  else
    -- Reset important game state
    state.game.hunter_character:call("set_Gravity2", -9.81)
    state.game.player
        :call("get_Controller")
        :call("get_GameObject")
        :call("set_TimeScale", 1.)
  end

  if state.settings.debug then
    if #state.actions > 0 then
      local screen_size = get_screen_size()
      if not screen_size then return end

      local top = #state.actions
      local bottom = math.max(1, #state.actions - 10)
      local font_size = imgui.get_default_font_size()
      for i = top, bottom, -1 do
        local action = state.actions[i]
        local text = string.format("%d: %d", action[1], action[2])
        draw.text(text, screen_size.x / 2,
          screen_size.y - (font_size * 1.2 * 10) + font_size * 1.2 * (top - i),
          0xffffffff)
      end
    end
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
      if state.game.weapon_type and imgui.collapsing_header("Moveset") then
        local mv = state.manager:get_active_moveset(state.game.weapon_type)
        imgui.text(tostring(mv))
      end

      Logger:on_draw_ui()

      if state.game:init() and imgui.collapsing_header("Stats") then
        imgui.text(string.format("TimeScale: %s",
          state.game.player
          :call("get_Controller")
          :call("get_GameObject")
          :call("get_TimeScale")
        ))
        imgui.text(string.format("ActionMotionSpeed: %s", state.game.hunter_character:call("get_ActionMotionSpeed")))
        imgui.text(string.format("Gravity: %s", state.game.hunter_character:call("get_Gravity2")))

        if state.game.weapon_type then
          imgui.text("Weapon: " .. tostring(state.game.weapon_type))
        end
      end

      if imgui.collapsing_header("Action Log") and #state.actions > 0 then
        local top = #state.actions
        local bottom = math.max(1, #state.actions - 10)
        for i = top, bottom, -1 do
          local action = state.actions[i]
          local text = string.format("%d: %d", action[1], action[2])
          imgui.text(text)
        end
      end
    end

    imgui.end_disabled()
    imgui.tree_pop()
  end
end)
