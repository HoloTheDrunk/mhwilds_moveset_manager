local function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    local first = true
    for k, v in pairs(o) do
      if first then
        first = false
      else
        s = s .. ', '
      end
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. dump(v)
    end
    return s .. ' }'
  else
    return tostring(o)
  end
end

return { dump = dump }
