--!strict

-- Segurar o clique com uma comida equipada pede ao servidor para comer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Survival = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Survival"))

local FoodController = {}

local player = Players.LocalPlayer
local eatFood: RemoteEvent
local holdId = 0
local watched: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function watchTool(tool: Tool)
	local foodId = tool:GetAttribute("FoodId")
	if typeof(foodId) ~= "string" then
		return
	end
	local function cancel()
		holdId += 1
	end
	tool.Activated:Connect(function()
		holdId += 1
		local myHold = holdId
		task.delay(Survival.EAT_HOLD_SECONDS, function()
			if holdId == myHold and tool.Parent == player.Character then
				eatFood:FireServer(foodId)
			end
		end)
	end)
	tool.Deactivated:Connect(cancel)
	tool.Unequipped:Connect(cancel)
end

local function onCharacterAdded(character: Model)
	character.ChildAdded:Connect(function(child)
		-- A mesma Tool entra no personagem a cada equipada; conecta só uma vez.
		if child:IsA("Tool") and child:GetAttribute("FoodId") ~= nil and not watched[child] then
			watched[child] = true
			watchTool(child)
		end
	end)
end

function FoodController:Init()
	eatFood = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EatFood") :: RemoteEvent
end

function FoodController:Start()
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

return FoodController
