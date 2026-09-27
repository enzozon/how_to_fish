--!strict

-- Venda e inspeção de valor. Preços só no servidor (Lib/Pricing).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local CreatureService = require(script.Parent.CreatureService)
local FoodService = require(script.Parent.FoodService)
local Pricing = require(script.Parent.Parent.Lib.Pricing)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Food = require(ReplicatedStorage.Shared.Config.Food)
local PlayerConfig = require(ReplicatedStorage.Shared.Config.Player)

type SellEntry = { uid: string, name: string, weight: number?, price: number }

local EconomyService = {}

local lastRequestAt: { [Player]: number } = {}
local shopParts: { BasePart } = {}

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if now - (lastRequestAt[player] or 0) < Economy.REQUEST_MIN_INTERVAL then
		return false
	end
	lastRequestAt[player] = now
	return true
end

local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

function EconomyService.IsNearShop(player: Player, shopType: string): boolean
	local root = getLivingRoot(player)
	if root == nil then
		return false
	end
	for _, part in shopParts do
		if part:GetAttribute("ShopType") == shopType and (part.Position - root.Position).Magnitude <= Economy.SHOP_MAX_DISTANCE then
			return true
		end
	end
	return false
end

local function itemName(id: string): string
	local fish = Fish[id]
	if fish then
		return fish.name
	end
	local food = Food[id]
	return if food then food.name else id
end

local function onGetSellList(player: Player): { SellEntry }
	local data = DataService.GetData(player)
	if not allowRequest(player) or data == nil or not EconomyService.IsNearShop(player, "Sell") then
		return {}
	end
	local list: { SellEntry } = {}
	for uid, item in data.inventory do
		local price = Pricing.sellPrice(item)
		if price then
			table.insert(list, { uid = uid, name = itemName(item.id), weight = item.weight, price = price })
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

local function onSellItems(player: Player, uids: unknown)
	local data = DataService.GetData(player)
	if not allowRequest(player) or data == nil or not EconomyService.IsNearShop(player, "Sell") then
		return nil
	end
	if typeof(uids) ~= "table" or #uids > PlayerConfig.MAX_INVENTORY_ITEMS then
		return nil
	end

	local total, sold = 0, 0
	local seen: { [string]: boolean } = {}
	for _, uid in uids :: { unknown } do
		if typeof(uid) == "string" and not seen[uid] then
			seen[uid] = true
			local item = data.inventory[uid]
			local price = item and Pricing.sellPrice(item)
			if price and DataService.RemoveItem(player, uid) then
				total += price
				sold += 1
			end
		end
	end
	if total > 0 then
		DataService.AddMoney(player, total)
		FoodService.RefreshFoodTools(player)
	end
	return { sold = sold, earned = total, money = data.money }
end

local function onInspectValue(player: Player, target: unknown)
	if not allowRequest(player) then
		return nil
	end
	if typeof(target) == "Instance" then
		local landed = CreatureService.GetLandedFish(target)
		if landed then
			return { name = Fish[landed.fishId].name, price = Pricing.sellPrice({ id = landed.fishId, weight = landed.weight }) }
		end
	end

	local data = DataService.GetData(player)
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local foodId = tool and tool:GetAttribute("FoodId")
	if data == nil or typeof(foodId) ~= "string" or Food[foodId] == nil then
		return nil
	end
	for _, item in data.inventory do
		if item.id == foodId then
			return { name = Food[foodId].name, price = Pricing.sellPrice(item) }
		end
	end
	return nil
end

function EconomyService:Start()
	for _, child in Workspace:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("ShopType") ~= nil then
			table.insert(shopParts, child)
		end
	end

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local getSellList = remotes:WaitForChild("GetSellList") :: RemoteFunction
	local sellItems = remotes:WaitForChild("SellItems") :: RemoteFunction
	local inspectValue = remotes:WaitForChild("InspectValue") :: RemoteFunction
	getSellList.OnServerInvoke = onGetSellList
	sellItems.OnServerInvoke = onSellItems
	inspectValue.OnServerInvoke = onInspectValue

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
	end)
end

return EconomyService
