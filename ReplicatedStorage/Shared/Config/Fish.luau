--!strict

local Types = require(script.Parent.Parent.Types)

-- Valores provisórios; balanceamento na T12.
local Fish: { [string]: Types.FishDef } = {
	camarao = {
		id = "camarao",
		name = "Camarão",
		island = 1,
		lureTier = 0,
		rarity = "Comum",
		baseValue = 2,
		weightRange = { min = 0.02, max = 0.1 },
		aggressive = false,
		pullStrength = 1,
	},
	caranguejo = {
		id = "caranguejo",
		name = "Caranguejo",
		island = 1,
		lureTier = 0,
		rarity = "Comum",
		baseValue = 3,
		weightRange = { min = 0.2, max = 1.0 },
		aggressive = false,
		pullStrength = 2,
	},
	siri = {
		id = "siri",
		name = "Siri",
		island = 1,
		lureTier = 0.5,
		rarity = "Incomum",
		baseValue = 6,
		weightRange = { min = 0.3, max = 1.2 },
		aggressive = false,
		pullStrength = 3,
	},
	lagosta = {
		id = "lagosta",
		name = "Lagosta",
		island = 1,
		lureTier = 0.5,
		rarity = "Raro",
		baseValue = 15,
		weightRange = { min = 0.5, max = 3.0 },
		aggressive = false,
		pullStrength = 5,
	},
}

for _, def in Fish do
	table.freeze(def.weightRange)
	table.freeze(def)
end

return table.freeze(Fish)
