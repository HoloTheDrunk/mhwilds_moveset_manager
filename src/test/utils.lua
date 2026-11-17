local Utils = {}

local output = {}

local regular_print = print
local function captured_print(...)
  output[#output + 1] = { ... }
end

local function dump_output()
  if #output > 0 then
    regular_print("\n")
  end
  for _, entry in ipairs(output) do
    regular_print(table.unpack(entry))
  end
  output = {}
end

---@param enable boolean
---@param clear_output? boolean True means that the captured output should be voided.
function Utils.capture_output(enable, clear_output)
  print = enable and captured_print or regular_print
  if clear_output then
    output = {}
  end
  if not enable then
    dump_output()
  end
end

return Utils
