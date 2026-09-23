---@param module_path string
---@return string
local function module_to_path(module_path)
  local path = module_path:gsub("%.", "/")
  return path .. ".lua"
end

---@class File
---@field content string
---@field deps? {module_path: string, file_path: string, bind_name: string}[] module path, path, bind name

---@class Graph
---@field files table<string, File>
---@field file_count integer
---@field _added table<string, string> Files added to the result so far, with the module name in the script.
local Graph = {}
Graph.__index = Graph

---@return Graph
function Graph.new()
  return setmetatable({
    files = {},
    file_count = 0,
    _added = {},
  } --[[@as Graph]], Graph)
end

---@param path string
function Graph:add_file(path)
  local file = io.open(path, "rb")
  if not file then return "File not found" end
  ---@type string
  local code = file:read("*a")
  file:close()
  local deps = {}
  for bind_name, module_path in code:gmatch("([%w_]+) = require%(\"([^)]+)\"%)") do
    deps[#deps + 1] = { module_path = module_path, file_path = module_to_path(module_path), bind_name = bind_name }
  end
  self.files[path] = { content = code, deps = deps }
  self.file_count = self.file_count + 1
end

---@return string? output, string? error
function Graph:dot()
  if #self._added == 0 then
    local _, err = self:compile()
    if err then
      return nil, err
    end
  end

  local attributes = "    rankdir=BT\n"

  local aliases = ""
  for path, module in pairs(self._added) do
    aliases = aliases .. string.format("    %s [label=\"%s\"];\n", module, path)
  end

  local dependencies = ""
  for path, file in pairs(self.files) do
    for _, dep in ipairs(file.deps) do
      dependencies = dependencies .. string.format(
        "    %s -> %s;\n", self._added[path], self._added[dep.file_path])
    end
  end

  return ([[
digraph output {
%s%s%s}
]]):format(attributes, aliases, dependencies)
end

---@return string? output, string? error
function Graph:compile()
  local result = ""

  local added_count = 0
  repeat
    local cycle_or_missing = true
    for path, file in pairs(self.files) do
      if self._added[path] then
        goto continue
      end

      if file.deps then
        -- Unresolved dependencies
        for _, dep in pairs(file.deps) do
          if not self._added[dep.file_path] then
            goto continue
          end
        end

        for _, dep in ipairs(file.deps) do
          -- Replace require with module func call
          file.content = file.content:gsub(string.format("require%%(\"%s\"%%)", dep.module_path),
            self._added[dep.file_path])
        end
      end

      cycle_or_missing = false
      self._added[path] = string.format("module_%d", added_count + 1)
      added_count = added_count + 1
      result = result ..
          string.format("-- %s\nlocal %s = (function()\n%s\nend)()", path, self._added[path], file.content)
      ::continue::
    end

    -- Files remain without their dependencies or are cyclically required.
    if cycle_or_missing then
      local files = ""
      local found = false
      for path, _ in pairs(self.files) do
        if self._added[path] then goto continue end
        found = true
        if #files > 0 then
          files = files .. string.format(", '%s'", path)
        else
          files = "[ " .. string.format("'%s'", path)
        end
        ::continue::
      end
      files = files .. " ]"
      -- I don't understand why this is needed but lol whatever
      if not found then break end
      return nil, string.format("These files have a cycle or missing dependencies: %s", files)
    end

    -- Compiling finished
    if added_count == self.file_count then break end
  until false

  return result
end

local files = {
  "state.lua",
  "data.lua",
  "utils/parsing.lua",
  "utils/pprint.lua",
  "lexer.lua",
  "parser.lua",
  "moveset.lua",
  "moveset_manager.lua",
  "main.lua",
}

---@param command string
---@return string? output
local function run_command(command)
  local handle = io.popen(command, "r")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Automatically add all new modifier files
local paths = run_command("find modifiers -name '*.lua'  | grep -v '.*\\.d\\.lua'")
if paths then
  for path in paths:gmatch("(.-)\n") do
    files[#files + 1] = path
  end
end

local g = Graph.new()
for _, file in ipairs(files) do
  g:add_file(file)
end
local result, err = g:compile()
if result then
  local added = 0
  for _, _ in pairs(g._added) do added = added + 1 end
  if added ~= #files then
    print("Didn't process all the files")
    goto err
  end
  local file = io.open("output.lua", "w")
  if not file then
    print("Failed to save compiled file")
    goto err
  end
  file:write(result)
  file:close()
  result, err = g:dot()
  if result then print(result) else print(err) end
  ::err::
else
  print(err)
end
