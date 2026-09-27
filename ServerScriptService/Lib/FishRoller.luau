--!strict

-- Sorteio de espécie e peso. Sem estado: recebe o Random de quem chama.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Fish = require(Shared.Config.Fish)
local Lures = require(Shared.Config.Lures)
local Fishing = require(Shared.Config.Fishing)

local FREE_LURE_ID = "isca_gratis"

local FishRoller = {}

-- Isca que vale: a equipada, ou a de graça se a paga acabou.
function FishRoller.resolveLureId(data: Types.PlayerData): string
	local lure = Lures[data.equippedLure]
	if lure == nil then
		return FREE_LURE_ID
	end
	if lure.price == 0 then
		return lure.id
	end
	for _, item in data.inventory do
		if item.id == lure.id then
			return lure.id
		end
	end
	return FREE_LURE_ID
end

-- Sorteia a espécie (peso pela raridade) e o peso em kg. nil se nenhuma espécie tiver esse tier.
function FishRoller.roll(lureTier: number, rng: Random): (string?, number)
	local candidates: { Types.FishDef } = {}
	local totalWeight = 0
	for _, fish in Fish do
		if fish.lureTier == lureTier then
			table.insert(candidates, fish)
			totalWeight += Fishing.RARITY_WEIGHTS[fish.rarity]
		end
	end
	if #candidates == 0 then
		return nil, 0
	end
	-- Ordem fixa para a mesma semente dar o mesmo resultado.
	table.sort(candidates, function(a, b)
		return a.id < b.id
	end)

	local pick = rng:NextNumber() * totalWeight
	local chosen = candidates[#candidates]
	for _, fish in candidates do
		pick -= Fishing.RARITY_WEIGHTS[fish.rarity]
		if pick <= 0 then
			chosen = fish
			break
		end
	end

	-- r² deixa peixes pesados mais raros.
	local r = rng:NextNumber()
	local range = chosen.weightRange
	return chosen.id, range.min + (range.max - range.min) * r * r
end

return FishRoller
