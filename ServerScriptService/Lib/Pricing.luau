--!strict

-- Preço de venda. Só no servidor: o cliente sempre pergunta o valor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Fish = require(Shared.Config.Fish)
local Food = require(Shared.Config.Food)
local Economy = require(Shared.Config.Economy)

local Pricing = {}

local function roundPrice(value: number): number
	return math.max(1, math.floor(value + 0.5))
end

-- Preço de venda de um item do inventário, ou nil se o item não é vendável.
function Pricing.sellPrice(item: Types.ItemData): number?
	local fish = Fish[item.id]
	if fish then
		if item.weight == nil then
			return nil
		end
		local averageWeight = (fish.weightRange.min + fish.weightRange.max) / 2
		local weightMultiplier = item.weight / averageWeight
		return roundPrice(fish.baseValue * weightMultiplier * Economy.RARITY_PRICE_MULTIPLIER[fish.rarity])
	end
	local food = Food[item.id]
	if food then
		return roundPrice(food.baseValue)
	end
	return nil -- iscas e ids desconhecidos não são vendáveis
end

return Pricing
