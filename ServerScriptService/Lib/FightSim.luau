--!strict

-- Um passo da luta com o peixe. Pura: devolve um estado novo e não altera o recebido.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)

export type FightState = {
	tension: number,
	distance: number,
	overload: number, -- segundos seguidos no máximo de tensão
	pullLeft: number, -- segundos restantes do puxão atual (0 = sem puxão)
	elapsed: number,
}

export type FightResult = "Fighting" | "Caught" | "Broke" | "Escaped"

local FightSim = {}

function FightSim.newState(): FightState
	return { tension = 0, distance = Fishing.START_DISTANCE, overload = 0, pullLeft = 0, elapsed = 0 }
end

function FightSim.maxTension(rod: Types.RodDef): number
	return rod.resistance * Fishing.TENSION_PER_RESISTANCE
end

function FightSim.step(
	state: FightState,
	reeling: boolean,
	dt: number,
	fish: Types.FishDef,
	rod: Types.RodDef,
	rng: Random
): (FightState, FightResult)
	local pullLeft = math.max(state.pullLeft - dt, 0)
	if pullLeft == 0 and rng:NextNumber() < Fishing.PULL_CHANCE_PER_SECOND * dt then
		pullLeft = Fishing.PULL_DURATION_SECONDS
	end
	local pulling = pullLeft > 0

	local maxTension = FightSim.maxTension(rod)
	local tension = state.tension
	if reeling then
		tension += Fishing.REEL_TENSION_PER_SECOND * (1 - rod.strength * Fishing.STRENGTH_TENSION_REDUCTION) * dt
	else
		tension -= Fishing.RELAX_PER_SECOND * dt
	end
	if pulling then
		tension += fish.pullStrength * Fishing.PULL_TENSION_PER_STRENGTH * dt
	end
	tension = math.clamp(tension, 0, maxTension)

	local distance = state.distance
	if reeling then
		distance -= Fishing.REEL_SPEED * dt
	end
	if pulling then
		distance += fish.pullStrength * Fishing.PULL_DISTANCE_PER_STRENGTH * dt
	end
	distance = math.clamp(distance, 0, Fishing.START_DISTANCE)

	local overload = if tension >= maxTension then state.overload + dt else 0
	local elapsed = state.elapsed + dt
	local newState: FightState = {
		tension = tension,
		distance = distance,
		overload = overload,
		pullLeft = pullLeft,
		elapsed = elapsed,
	}

	if overload >= Fishing.BREAK_OVERLOAD_SECONDS then
		return newState, "Broke"
	elseif distance <= 0 then
		return newState, "Caught"
	elseif elapsed >= Fishing.MAX_FIGHT_SECONDS then
		return newState, "Escaped"
	end
	return newState, "Fighting"
end

return FightSim
