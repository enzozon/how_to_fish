--!strict

local Types = require(script.Parent.Parent.Types)

-- "mao" é a arma padrão do combate (M2); não é vendida.
local Weapons: { [string]: Types.WeaponDef } = {
	mao = { id = "mao", name = "Mão", price = 0, damage = 5 },
	soco_ingles = { id = "soco_ingles", name = "Soco-inglês", price = 24, damage = 10 },
	faca = { id = "faca", name = "Faca", price = 45, damage = 20 },
}

for _, def in Weapons do
	table.freeze(def)
end

return table.freeze(Weapons)
