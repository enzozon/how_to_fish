--!strict

-- Economia. Valores provisórios; balanceamento na T12.
return table.freeze({
	RARITY_PRICE_MULTIPLIER = table.freeze({ Comum = 1, Incomum = 1.5, Raro = 2.5, ["Épico"] = 5 }),
	SHOP_MAX_DISTANCE = 12, -- studs entre o jogador e o NPC para vender/comprar
	REQUEST_MIN_INTERVAL = 0.2, -- s entre chamadas de um jogador às RemoteFunctions da economia
})
