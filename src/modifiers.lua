---@type table<Comparison, fun(a, b): boolean>
local comparisons = {
  ["="] = function(a, b) return a == b end,
  ["!="] = function(a, b) return a ~= b end,
  [">"] = function(a, b) return a > b end,
  [">="] = function(a, b) return a >= b end,
  ["<"] = function(a, b) return a < b end,
  ["<="] = function(a, b) return a <= b end,
}

---@type (fun(modifier: M_CheckAttrib, hunter_character: REManagedObject): boolean)[]
local attrib_fns = {
  ---@param attr SpiritGauge
  ---@param hunter REManagedObject
  spirit_gauge = function(attr, hunter)
    -- app.cHunterWp03Handling
    local handling = hunter:call("get_WeaponHandling")
    if not handling then return false end

    local aura_level = handling:call("get_AuraLevel")

    return comparisons[attr.comparison](aura_level - 1, attr.level)
  end,
}

---@param modifier M_CheckAttrib
---@param hunter_character REManagedObject app.HunterCharacter
local function check_attribute(modifier, hunter_character)
  local attr = modifier.attribute
  ---@cast attr SpiritGauge
  if attr._spirit_gauge then
    attrib_fns.spirit_gauge(attr, hunter_character)
  end
end

return { check_attribute = check_attribute }
