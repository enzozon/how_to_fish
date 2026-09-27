--!strict

-- Carregar a força do lançamento (segurar o clique) e pedir o lançamento ao servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fishing = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))

local FishingController = {}

local player = Players.LocalPlayer
local castLine: RemoteEvent
local powerBar: Frame
local powerFill: Frame
local chargeStart: number? = nil
local renderConnection: RBXScriptConnection? = nil
local watched: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function currentPower(): number
	return if chargeStart then math.min((os.clock() - chargeStart) / Fishing.CHARGE_SECONDS, 1) else 0
end

local function stopCharging()
	chargeStart = nil
	powerBar.Visible = false
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

local function watchRod(tool: Tool)
	tool.Activated:Connect(function()
		chargeStart = os.clock()
		powerFill.Size = UDim2.fromScale(0, 1)
		powerBar.Visible = true
		if renderConnection == nil then
			renderConnection = RunService.RenderStepped:Connect(function()
				powerFill.Size = UDim2.fromScale(currentPower(), 1)
			end)
		end
	end)
	tool.Deactivated:Connect(function()
		if chargeStart == nil then
			return
		end
		local power = currentPower()
		stopCharging()
		castLine:FireServer(power)
	end)
	tool.Unequipped:Connect(stopCharging)
end

local function onCharacterAdded(character: Model)
	character.ChildAdded:Connect(function(child)
		-- A mesma Tool entra no personagem a cada equipada; conecta só uma vez.
		if child:IsA("Tool") and child:GetAttribute("RodId") ~= nil and not watched[child] then
			watched[child] = true
			watchRod(child)
		end
	end)
end

function FishingController:Init()
	castLine = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CastLine") :: RemoteEvent
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("FishingGui")
	powerBar = gui:WaitForChild("PowerBar") :: Frame
	powerFill = powerBar:WaitForChild("Fill") :: Frame
end

function FishingController:Start()
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

return FishingController
