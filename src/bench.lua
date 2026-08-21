local s = os.clock()

local tokens = {}

for _ = 1, 10000, 1 do
  tokens[#tokens + 1] = { tok = math.random(100), str = tostring(math.random()) }
end

for i, token in ipairs(tokens) do
  if token.tok % 10 == 0 then
    print(string.format("%3d: %s -> %d", i, token.str, token.tok))
  end
end

local e = os.clock()

print(string.format("elapsed time: %.2f", e - s))
