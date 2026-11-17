local lu = require("test.luaunit")
local capture_output = require("test.utils").capture_output

local Parser = require("lib.parser")
local parsing_lib = require("lib.utils.parsing")

TestComparison = {}

for test_name, comparison in pairs({ eq = "=", lt = "<", lte = "<=", gt = ">", gte = ">=" }) do
  TestComparison["test_" .. test_name] = function()
    capture_output(true)

    local parser = Parser.new("IfSpiritGauge(" .. comparison .. " 1)")

    local modifiers = { checks = {}, effects = {} }
    local err = parser:parse_modifier(modifiers)
    if err then return lu.fail(err) end

    local check = modifiers.checks[1] --[[@as IfSpiritGauge]]
    if check and check.comparison and check.comparison.type ~= parsing_lib.ComparisonType[comparison] then
      capture_output(false)
      lu.fail(string.format(
        "Expected %s, got %s",
        comparison,
        parsing_lib.comparison_type_to_string[check.comparison.type]
      ))
    end

    capture_output(false, true)
  end
end
