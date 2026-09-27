--!strict

-- Venda e inspeção de valor. Preços só no servidor (Lib/Pricing).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local CreatureService = require(script.Parent.CreatureService)
local FoodService = require(script.Parent.FoodService)
local FishingService = require(script.Parent.FishingService)
local Pricing = require(script.Parent.Parent.Lib.Pricing)
local Types = require(ReplicatedStorage.Shared.Types)
local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Food = require(ReplicatedStorage.Shared.Config.Food)
local Lures = require(ReplicatedStorage.Shared.Config.Lures)
local Rods = require(ReplicatedStorage.Shared.Config.Rods)
local Weapons = require(ReplicatedStorage.Shared.Config.Weapons)
local PlayerConfig = require(ReplicatedStorage.Shared.Config.Player)

type SellEntry = { uid: string, name: string, weight: number?, price: number }

local EconomyService = {}

-- Intervalo mínimo por jogador e por Remote (vender e recarregar a lista em seguida é normal).
local lastRequestAt: { [Player]: { [string]: number } } = {}
local shopParts: { BasePart } = {}

local function allowRequest(player: Player, remoteName: string): boolean
	local perPlayer = lastRequestAt[player]
	if perPlayer == nil then
		perPlayer = {}
		lastRequestAt[player] = perPlayer
	end
	local now = os.clock()
	if now - (perPlayer[remoteName] or 0) < Economy.REQUEST_MIN_INTERVAL then
		return false
	end
	perPlayer[remoteName] = now
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
	if not allowRequest(player, "GetSellList") or data == nil or not EconomyService.IsNearShop(player, "Sell") then
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
	if not allowRequest(player, "SellItems") or data == nil or not EconomyService.IsNearShop(player, "Sell") then
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
	if not allowRequest(player, "InspectValue") then
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

-- Loja: tudo de Rods, Lures e Weapons com preço > 0.
type CatalogItem = { id: string, kind: "Rod" | "Lure" | "Weapon", name: string, price: number }
type BuyResult = { ok: boolean, reason: string?, money: number? }

local catalog: { [string]: CatalogItem } = {}
local catalogOrder: { CatalogItem } = {}

local function addToCatalog(kind: "Rod" | "Lure" | "Weapon", defs: { [string]: { id: string, name: string, price: number } })
	for id, def in defs do
		if def.price > 0 then
			local item: CatalogItem = { id = id, kind = kind, name = def.name, price = def.price }
			catalog[id] = item
			table.insert(catalogOrder, item)
		end
	end
end

local function isOwned(data: Types.PlayerData, item: CatalogItem): boolean
	if item.kind == "Rod" then
		return data.equippedRod == item.id
	elseif item.kind == "Weapon" then
		return data.ownedWeapons[item.id] == true
	end
	return false -- iscas se compram quantas quiser
end

local function onGetShopList(player: Player)
	local data = DataService.GetData(player)
	if not allowRequest(player, "GetShopList") or data == nil or not EconomyService.IsNearShop(player, "Buy") then
		return {}
	end
	local list = {}
	for _, item in catalogOrder do
		table.insert(list, { id = item.id, name = item.name, price = item.price, owned = isOwned(data, item) })
	end
	return list
end

local function onBuyItem(player: Player, id: unknown): BuyResult
	local data = DataService.GetData(player)
	if not allowRequest(player, "BuyItem") or data == nil or not EconomyService.IsNearShop(player, "Buy") then
		return { ok = false, reason = "Longe da loja" }
	end
	local item = if typeof(id) == "string" then catalog[id] else nil
	if item == nil then
		return { ok = false, reason = "Item inválido" }
	end
	if isOwned(data, item) then
		return { ok = false, reason = "Já tem" }
	end
	if data.money < item.price then
		return { ok = false, reason = "Sem dinheiro" }
	end

	-- A isca entra primeiro: se o inventário estiver cheio, nada é cobrado.
	if item.kind == "Lure" and DataService.AddItem(player, { id = item.id }) == nil then
		return { ok = false, reason = "Inventário cheio" }
	end
	DataService.SpendMoney(player, item.price) -- saldo já conferido, sem yield no meio
	if item.kind == "Lure" then
		DataService.SetEquippedLure(player, item.id)
	elseif item.kind == "Rod" then
		DataService.SetEquippedRod(player, item.id)
		FishingService.RefreshRodTool(player)
	else
		DataService.GiveWeapon(player, item.id)
	end
	return { ok = true, money = data.money }
end

function EconomyService:Start()
	addToCatalog("Rod", Rods)
	addToCatalog("Lure", Lures)
	addToCatalog("Weapon", Weapons)
	table.sort(catalogOrder, function(a, b)
		return a.price < b.price
	end)

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
	local getShopList = remotes:WaitForChild("GetShopList") :: RemoteFunction
	local buyItem = remotes:WaitForChild("BuyItem") :: RemoteFunction
	getShopList.OnServerInvoke = onGetShopList
	buyItem.OnServerInvoke = onBuyItem

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
	end)
end

return EconomyService
