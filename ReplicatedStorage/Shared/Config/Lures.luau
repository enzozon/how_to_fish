--!strict

local Types = require(script.Parent.Parent.Types)

local Lures: { [string]: Types.LureDef } = {
	isca_gratis = { id = "isca_gratis", name = "Isca de Graça", tier = 0, island = 1, price = 0 },
	salsicha = { id = "salsicha", name = "Salsicha", tier = 0.5, island = 1, price = 5 },
}

for _, def in Lures do
	table.freeze(def)
end

return table.freeze(Lures)
