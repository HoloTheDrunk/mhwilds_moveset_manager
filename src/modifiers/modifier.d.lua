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
