--!strict

local Types = require(script.Parent.Parent.Types)

-- Valores provisórios; balanceamento na T12.
local Food: { [string]: Types.FoodDef } = {
	marisco = { id = "marisco", name = "Marisco", hungerRestore = 15, baseValue = 1 },
}

for _, def in Food do
	table.freeze(def)
end

return table.freeze(Food)
