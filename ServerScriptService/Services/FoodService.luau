--!strict

-- Coleta de mariscos, comer e a Tool que espelha a comida do inventário.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local Food = require(ReplicatedStorage.Shared.Config.Food)
local PlayerConfig = require(ReplicatedStorage.Shared.Config.Player)
local Survival = require(ReplicatedStorage.Shared.Config.Survival)

local MARISCO_ID = "marisco"

local FoodService = {}

local available: { [BasePart]: boolean } = {}
local lastEatAt: { [Player]: number } = {}

local function getLivingRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function findFoodTool(container: Instance?, foodId: string): Tool?
	if container == nil then
		return nil
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("FoodId") == foodId then
			return child
		end
	end
	return nil
end

local function findItemUid(player: Player, itemId: string): (string?, number)
	local data = DataService.GetData(player)
	local foundUid: string? = nil
	local count = 0
	if data ~= nil then
		for uid, item in data.inventory do
			if item.id == itemId then
				foundUid = foundUid or uid
				count += 1
			end
		end
	end
	return foundUid, count
end

local function createFoodTool(foodId: string, name: string, backpack: Backpack)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.RequiresHandle = false
	tool.CanBeDropped = false -- soltar tiraria a Tool de sincronia com o save
	tool:SetAttribute("FoodId", foodId)
	tool.Parent = backpack
end

local function refreshFoodTools(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	for foodId, food in Food do
		local _, count = findItemUid(player, foodId)
		local tool = findFoodTool(player.Character, foodId) or findFoodTool(backpack, foodId)
		if count == 0 then
			if tool then
				tool:Destroy()
			end
		elseif tool then
			tool.Name = `{food.name} ({count})`
		elseif backpack then
			createFoodTool(foodId, `{food.name} ({count})`, backpack)
		end
	end
end

local function onMariscoTriggered(part: BasePart, prompt: ProximityPrompt, player: Player)
	if not available[part] then
		return
	end
	local root = getLivingRoot(player)
	if root == nil or (root.Position - part.Position).Magnitude > Survival.PICKUP_MAX_DISTANCE then
		return
	end
	if DataService.AddItem(player, { id = MARISCO_ID }) == nil then
		return
	end

	available[part] = false
	local originalTransparency = part.Transparency
	part.Transparency = 1
	prompt.Enabled = false
	refreshFoodTools(player)

	task.delay(Survival.MARISCO_RESPAWN_SECONDS, function()
		part.Transparency = originalTransparency
		prompt.Enabled = true
		available[part] = true
	end)
end

local function onEatFood(player: Player, foodId: unknown)
	if typeof(foodId) ~= "string" then
		return
	end
	local food = Food[foodId]
	if food == nil then
		return
	end
	local now = os.clock()
	if now - (lastEatAt[player] or 0) < Survival.EAT_MIN_INTERVAL_SECONDS then
		return
	end
	if getLivingRoot(player) == nil or findFoodTool(player.Character, foodId) == nil then
		return
	end
	local data = DataService.GetData(player)
	if data == nil or data.hunger >= PlayerConfig.MAX_HUNGER then
		return
	end
	local uid = findItemUid(player, foodId)
	if uid == nil then
		return
	end

	lastEatAt[player] = now
	DataService.RemoveItem(player, uid)
	DataService.SetHunger(player, data.hunger + food.hungerRestore)
	refreshFoodTools(player)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		-- A mochila é esvaziada a cada morte; recria a Tool depois do save carregar.
		if DataService.WaitForData(player) ~= nil then
			refreshFoodTools(player)
		end
	end)
end

-- Para quem muda comida do inventário fora daqui (ex.: venda).
FoodService.RefreshFoodTools = refreshFoodTools

function FoodService:Start()
	local mariscos = Workspace:FindFirstChild("Mariscos")
	if mariscos == nil then
		warn("[FoodService] Workspace.Mariscos não encontrado; sem mariscos.")
	else
		for _, part in mariscos:GetChildren() do
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if part:IsA("BasePart") and prompt ~= nil then
				available[part] = true
				prompt.Triggered:Connect(function(player)
					onMariscoTriggered(part, prompt, player)
				end)
			end
		end
	end

	local eatFood = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EatFood") :: RemoteEvent
	eatFood.OnServerEvent:Connect(onEatFood)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
		task.spawn(function()
			if DataService.WaitForData(player) ~= nil then
				refreshFoodTools(player)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastEatAt[player] = nil
	end)
end

return FoodService
