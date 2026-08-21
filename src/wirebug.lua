local settings = {
  enabled = true,
}
local function get_player_transform()
  local playerMgr = sdk.get_managed_singleton("app.PlayerManager")
  if not playerMgr then return nil end

  local player
  pcall(function() player = playerMgr:call("getMasterPlayer") end)
  if not player then return nil end

  local playerObj
  pcall(function() playerObj = player:call("get_Object") or player:call("get_GameObject") end)
  if not playerObj then return nil end

  local transform
  pcall(function()
    transform = playerObj:call("getComponent(System.Type)", sdk.typeof("via.Transform")) or
        playerObj:call("get_Transform")
  end)

  local rb = playerObj:call("getComponent(System.Type)", sdk.typeof("via.dynamics.RigidBody"))

  return transform, rb
end

local function get_camera_transform()
  local camera = sdk.get_primary_camera()
  if not camera then return nil end

  local cameraObj = camera:call("get_GameObject")
  if not cameraObj then return nil end

  local cameraTransform = cameraObj:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
  if not cameraTransform then return nil end

  return cameraTransform
end

local key_pressed = false
local axis_vec = nil
local player_transform = nil
local player_rb = nil
local camera_transform = nil

---@type {start: Vector3f, target: Vector3f, start_time: number, duration: number}?
local slide = nil

re.on_frame(function()
  local key_down = reframework:is_key_down(0x47) -- G

  if not camera_transform then
    camera_transform = get_camera_transform()
  else
    axis_vec = camera_transform:call("get_AxisZ")
  end

  if not player_transform then return end

  if not slide and key_down and not key_pressed and axis_vec then
    local pos = player_transform:call("get_Position")
    local target = pos + axis_vec * -5. + Vector3f.new(0., 1., 0.)
    slide = { start = pos, target = target, start_time = os.clock(), duration = 1 }
  end

  if slide then
    local progress = (os.clock() - slide.start_time) / slide.duration
    if progress < 1 then
      if player_rb then
        player_rb:call("set_LinearVelocity", slide.target - slide.start)
      else
        player_transform:call("set_Position", slide.start * (1 - progress) + slide.target * progress)
      end
    else
      slide = nil
    end
  end

  if key_pressed and key_down then return end
  key_pressed = key_down
end)

re.on_draw_ui(function()
  if imgui.tree_node("Wirebug") then
    imgui.text("G pressed: " .. tostring(key_pressed))
    if axis_vec then
      imgui.text(string.format("Axis: (%.3f, %.3f, %.3f)", axis_vec.x, axis_vec.y, axis_vec.z))
      if not player_transform then
        player_transform, player_rb = get_player_transform()
        imgui.text("Player transform missing")
      else
        local pos = player_transform:call("get_Position") + axis_vec
        imgui.text(string.format("Pos: (%.3f, %.3f, %.3f)", pos.x, pos.y, pos.z))
        local screen_pos = draw.world_to_screen(pos)
        if screen_pos then
          imgui.text(string.format("Screen pos: (%.3f, %.3f)", screen_pos.x, screen_pos.y))
          draw.filled_circle(screen_pos.x, screen_pos.y, 50, 0xffffffff, 8)
        else
          imgui.text("Pos not on screen!")
        end
      end
    end

    _, settings.enabled = imgui.checkbox("Enable", settings.enabled)
    imgui.begin_disabled(not settings.enabled)
    imgui.end_disabled()

    imgui.tree_pop()
  end
end)
