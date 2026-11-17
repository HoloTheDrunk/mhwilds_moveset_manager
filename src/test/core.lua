---@diagnostic disable: lowercase-global

local lu = require("test.luaunit")

require("test.parser._mod")

os.exit(lu.LuaUnit.run("-v", table.unpack(arg)))
