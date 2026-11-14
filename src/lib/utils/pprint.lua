---@type integer
---Used to indent lines when dumping with newlines.
local depth = 0

local function indent(s)
  return (' '):rep(4 * depth) .. s
end

---@param value any
---@param pretty? boolean Adds line breaks.
local function dump(value, pretty)
  pretty = pretty or false

  if type(value) == 'table' then
    local s = '{'

    depth = depth + 1
    local first = true
    for k, v in pairs(value) do
      if first then
        first = false
        s = s .. (pretty and '\n' or ' ')
      else
        s = s .. (pretty and ',\n' or ', ')
      end
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      local l = '[' .. k .. '] = ' .. dump(v, pretty)
      s = s .. (pretty and indent(l) or l)
    end
    depth = depth - 1

    -- Show empty tables as '{ }'
    if not first then
      s = s .. (pretty and ('\n' .. indent('}')) or ' }')
    else
      s = s .. ' }'
    end
    return s
  else
    return tostring(value)
  end
end

return { dump = dump }
