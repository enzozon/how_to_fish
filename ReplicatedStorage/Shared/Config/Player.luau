--!strict

-- Valores iniciais do save e limites do jogador.
return table.freeze({
	STARTING_MONEY = 0,
	STARTING_LURE = "isca_gratis",
	MAX_HUNGER = 100, -- também é a fome inicial
	MAX_INVENTORY_ITEMS = 100, -- segura o tamanho do save
})
