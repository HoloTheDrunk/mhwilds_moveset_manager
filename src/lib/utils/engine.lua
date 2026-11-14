---@return Vector2f? size in pixels
local function get_screen_size()
  local scene_manager = sdk.get_native_singleton("via.SceneManager")
  if not scene_manager then
    return
  end

  local scene_view = sdk.call_native_func(
    scene_manager,
    sdk.find_type_definition("via.SceneManager") --[[@as RETypeDefinition]],
    "get_MainView"
  )
  if not scene_view then
    return
  end

  local size = scene_view:call("get_Size")
  if not size then
    return
  end

  return Vector2f.new(size:get_field("w"), size:get_field("h"))
end

return {
  get_screen_size = get_screen_size
}
