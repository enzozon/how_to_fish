--!strict

-- Pesca. Valores provisórios; balanceamento na T12.
return table.freeze({
	CHARGE_SECONDS = 1.2, -- tempo segurando para chegar à força máxima (cliente)
	MIN_CAST_POWER = 0.2, -- força mínima aceita (evita lançar no pé)
	CAST_MAX_SPEED = 80, -- studs/s na força 1 (~30 studs de alcance a 35°)
	CAST_ANGLE_DEGREES = 35, -- ângulo do lançamento acima da horizontal
	ROPE_LENGTH = 60, -- comprimento máximo da linha (do píer, o lançamento máximo chega a ~44)
	CAST_COOLDOWN_SECONDS = 1, -- intervalo mínimo entre lançamentos (servidor)
	SETTLE_TIMEOUT_SECONDS = 5, -- sem cair na água nesse tempo, a boia é recolhida
	SETTLE_SPEED = 2, -- studs/s: abaixo disso fora da água, a boia "parou no chão"
	MAX_TIP_DISTANCE = 8, -- distância máxima entre a ponta da vara e o HumanoidRootPart
	BITE_WAIT_MIN_SECONDS = 3, -- espera mínima até a mordida
	BITE_WAIT_MAX_SECONDS = 8, -- espera máxima
	HOOK_WINDOW_SECONDS = 1, -- janela para clicar depois da mordida
	HOOK_LATENCY_GRACE_SECONDS = 0.3, -- folga no servidor pela latência
	BITE_SINK_DEPTH = 1, -- studs que a boia afunda na mordida
	RARITY_WEIGHTS = table.freeze({ Comum = 60, Incomum = 30, Raro = 9, ["Épico"] = 1 }),
	FIGHT_TICK_SECONDS = 0.1, -- passo da simulação no servidor
	START_DISTANCE = 20, -- "metros" até o peixe sair da água
	REEL_SPEED = 4, -- distância recolhida por segundo segurando (luta mínima = 5 s)
	REEL_TENSION_PER_SECOND = 30, -- tensão ganha por segundo segurando
	STRENGTH_TENSION_REDUCTION = 0.05, -- cada ponto de rod.strength reduz 5% do ganho de tensão
	RELAX_PER_SECOND = 40, -- tensão perdida por segundo sem segurar
	TENSION_PER_RESISTANCE = 33, -- tensão máxima = rod.resistance × isto (Vara de Siri: 99)
	PULL_CHANCE_PER_SECOND = 0.5, -- chance de o peixe começar um puxão, por segundo
	PULL_DURATION_SECONDS = 0.8,
	PULL_TENSION_PER_STRENGTH = 12, -- tensão/s por ponto de pullStrength durante o puxão
	PULL_DISTANCE_PER_STRENGTH = 0.8, -- distância/s que o peixe ganha por ponto de pullStrength
	BREAK_OVERLOAD_SECONDS = 0.75, -- tempo no máximo de tensão até arrebentar
	MAX_FIGHT_SECONDS = 60, -- depois disso o peixe escapa
	LANDED_FISH_BASE_SIZE = 0.8, -- studs; lado do cubo de 0 kg
	LANDED_FISH_SIZE_PER_KG = 0.5, -- quanto o lado cresce por kg
	LANDED_FISH_MAX_SIZE = 3,
	LANDED_FISH_SPAWN_DISTANCE = 4, -- studs atrás do jogador
	LANDED_FISH_JUMP_MIN_SECONDS = 0.8, -- intervalo entre pulos
	LANDED_FISH_JUMP_MAX_SECONDS = 1.6,
	LANDED_FISH_JUMP_UP_SPEED = 28, -- studs/s para cima em cada pulo (~2 studs de altura)
	LANDED_FISH_JUMP_SIDE_SPEED = 6, -- studs/s de lado (direção aleatória)
	LANDED_FISH_LIFETIME_SECONDS = 120,
})
