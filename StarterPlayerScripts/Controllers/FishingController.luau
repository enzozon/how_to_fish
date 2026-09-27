--!strict

-- Carregar a força do lançamento (segurar o clique) e pedir o lançamento ao servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Fishing = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))

local FishingController = {}

local player = Players.LocalPlayer
local castLine: RemoteEvent
local hookFish: RemoteEvent
local biteLabel: TextLabel
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

local function isOwnBobber(instance: Instance): boolean
	return instance:IsA("BasePart") and instance.Name == "Boia" and instance:GetAttribute("OwnerUserId") == player.UserId
end

-- Boia do jogador já na água (tem State). Em voo não conta.
local function findOwnBobberInWater(): BasePart?
	for _, child in Workspace:GetChildren() do
		if isOwnBobber(child) and child:GetAttribute("State") ~= nil then
			return child :: BasePart
		end
	end
	return nil
end

local function watchBobber(bobber: BasePart)
	local function update()
		biteLabel.Visible = bobber:GetAttribute("State") == "Bite"
	end
	bobber:GetAttributeChangedSignal("State"):Connect(update)
	bobber.Destroying:Connect(function()
		biteLabel.Visible = false
	end)
	update()
end

local function watchRod(tool: Tool)
	tool.Activated:Connect(function()
		-- Com a boia na água, o clique é para fisgar (ou recolher), não para lançar.
		if findOwnBobberInWater() then
			hookFish:FireServer()
			return
		end
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
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	castLine = remotes:WaitForChild("CastLine") :: RemoteEvent
	hookFish = remotes:WaitForChild("HookFish") :: RemoteEvent
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("FishingGui")
	powerBar = gui:WaitForChild("PowerBar") :: Frame
	powerFill = powerBar:WaitForChild("Fill") :: Frame
	biteLabel = gui:WaitForChild("BiteLabel") :: TextLabel
end

function FishingController:Start()
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	Workspace.ChildAdded:Connect(function(child)
		if isOwnBobber(child) then
			watchBobber(child :: BasePart)
		end
	end)
end

return FishingController
