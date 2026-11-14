---@meta

---@class Modifier
---@field enabled boolean
Modifier = {}

---Called when the modifier name has already been parsed.
---Should parse the modifier's arguments.
---@param parser Parser
---@return Modifier?, string? error
function Modifier.parse(parser) end

---Modifier display name.
---@return string?, string? error
function Modifier:name() end

---Short description of what the moveset does and detailing the different
---modifier arguments if relevant.
---@return string?
function Modifier:description() end

---Enable the mod and initialize whatever needs it.
---@return nil
function Modifier:enable() end

---Disable the modifier and cleanup/reset whatever needs it.
---@return nil
function Modifier:disable() end

---Format-valid string representation of the modifier.
---e.g. AfterSwap { id: 5 } should be rendered as "AfterSwap(5)"
---@return string
function Modifier:__tostring() end

---Any modifier that is involved in the selection of a swap.
---@class Check : Modifier
Check = {}

---Performs the modifier's checking logic.
---@param state ModState
---@return boolean
function Check:check(state) end

---Any modifier that applies once the swap has been selected.
---@class Effect : Modifier
---@field is_effect true
Effect = {}

---@param state ModState
---@return nil
function Effect:on_swap(state) end

---@param state ModState
---@return nil
function Effect:on_frame(state) end

---@param state ModState
---@return nil
function Effect:on_hit(state) end

---Reserved for modifiers that need special treatment and can't just be
---run in the check/effect positions.
---@class Special : Modifier
---@field is_special true
Special = {}
