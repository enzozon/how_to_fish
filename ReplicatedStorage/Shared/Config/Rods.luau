--!strict

local Types = require(script.Parent.Parent.Types)

local Rods: { [string]: Types.RodDef } = {
	vara_siri = { id = "vara_siri", name = "Vara de Siri", price = 3, strength = 1, resistance = 3 },
}

for _, def in Rods do
	table.freeze(def)
end

return table.freeze(Rods)
