--!strict

-- Fome e sobrevivência. Valores provisórios; balanceamento na T12.
return table.freeze({
	TICK_SECONDS = 1, -- intervalo do loop da fome
	HUNGER_DRAIN_PER_SECOND = 0.1, -- parado: 100 → 0 em ~16 min
	MOVING_MULTIPLIER = 1.5, -- andando: ~11 min
	SWIMMING_MULTIPLIER = 2, -- nadando: ~8 min
	MOVING_SPEED_THRESHOLD = 1, -- studs/s na horizontal para contar como "andando"
	STARVE_DAMAGE_PER_SECOND = 5, -- com vida 100: morre em ~20 s de fome zerada
	RESPAWN_MIN_HUNGER = 30, -- fome mínima ao (re)nascer
})
