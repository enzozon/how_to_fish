--!strict

-- Pesca. Valores provisórios; balanceamento na T12.
return table.freeze({
	CHARGE_SECONDS = 1.2, -- tempo segurando para chegar à força máxima (cliente)
	MIN_CAST_POWER = 0.2, -- força mínima aceita (evita lançar no pé)
	CAST_MAX_SPEED = 80, -- studs/s na força 1 (~30 studs de alcance a 35°)
	CAST_ANGLE_DEGREES = 35, -- ângulo do lançamento acima da horizontal
	ROPE_LENGTH = 45, -- comprimento máximo da linha
	CAST_COOLDOWN_SECONDS = 1, -- intervalo mínimo entre lançamentos (servidor)
	SETTLE_TIMEOUT_SECONDS = 5, -- sem cair na água nesse tempo, a boia é recolhida
	SETTLE_SPEED = 2, -- studs/s: abaixo disso fora da água, a boia "parou no chão"
	MAX_TIP_DISTANCE = 8, -- distância máxima entre a ponta da vara e o HumanoidRootPart
})
