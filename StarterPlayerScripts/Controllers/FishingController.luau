--!strict

-- Carregar a força do lançamento (segurar o clique) e pedir o lançamento ao servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Fishing = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Fishing"))

local FishingController = {}

local player = Players.LocalPlayer
local RESULT_SECONDS = 2 -- tempo da mensagem de resultado na tela

local castLine: RemoteEvent
local hookFish: RemoteEvent
local reelInput: RemoteEvent
local biteLabel: TextLabel
local fightFrame: Frame
local tensionFill: Frame
local distanceFill: Frame
local resultLabel: TextLabel
local reeling = false
local resultShownAt = 0
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

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function updateFightBars(bobber: BasePart)
	local maxTension = numberAttribute(bobber, "MaxTension")
	local startDistance = numberAttribute(bobber, "StartDistance")
	if maxTension > 0 then
		tensionFill.Size = UDim2.fromScale(numberAttribute(bobber, "Tension") / maxTension, 1)
	end
	if startDistance > 0 then
		-- Enche conforme o peixe chega perto.
		distanceFill.Size = UDim2.fromScale(1 - numberAttribute(bobber, "Distance") / startDistance, 1)
	end
end

local function stopReeling()
	if reeling then
		reeling = false
		reelInput:FireServer(false)
	end
end

local function watchBobber(bobber: BasePart)
	local function update()
		local state = bobber:GetAttribute("State")
		biteLabel.Visible = state == "Bite"
		fightFrame.Visible = state == "Hooked"
		updateFightBars(bobber)
	end
	bobber:GetAttributeChangedSignal("State"):Connect(update)
	bobber:GetAttributeChangedSignal("Tension"):Connect(function()
		updateFightBars(bobber)
	end)
	bobber:GetAttributeChangedSignal("Distance"):Connect(function()
		updateFightBars(bobber)
	end)
	bobber.Destroying:Connect(function()
		biteLabel.Visible = false
		fightFrame.Visible = false
		reeling = false
	end)
	update()
end

local function showResult(result: string, fishName: string?)
	local text = if result == "Caught"
		then `Pegou: {fishName or "peixe"}!`
		elseif result == "Broke" then "A linha arrebentou!"
		else "O peixe escapou."
	resultLabel.Text = text
	resultLabel.Visible = true
	resultShownAt = os.clock()
	local shownAt = resultShownAt
	task.delay(RESULT_SECONDS, function()
		if resultShownAt == shownAt then
			resultLabel.Visible = false
		end
	end)
end

local function watchRod(tool: Tool)
	tool.Activated:Connect(function()
		-- Com a boia na água, o clique é para fisgar, recolher ou puxar o peixe, não para lançar.
		local bobber = findOwnBobberInWater()
		if bobber and bobber:GetAttribute("State") == "Hooked" then
			reeling = true
			reelInput:FireServer(true)
			return
		elseif bobber then
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
		stopReeling()
		if chargeStart == nil then
			return
		end
		local power = currentPower()
		stopCharging()
		castLine:FireServer(power)
	end)
	tool.Unequipped:Connect(function()
		stopReeling()
		stopCharging()
	end)
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
	reelInput = remotes:WaitForChild("ReelInput") :: RemoteEvent
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("FishingGui")
	powerBar = gui:WaitForChild("PowerBar") :: Frame
	powerFill = powerBar:WaitForChild("Fill") :: Frame
	biteLabel = gui:WaitForChild("BiteLabel") :: TextLabel
	fightFrame = gui:WaitForChild("FightFrame") :: Frame
	tensionFill = fightFrame:WaitForChild("TensionBar"):WaitForChild("Fill") :: Frame
	distanceFill = fightFrame:WaitForChild("DistanceBar"):WaitForChild("Fill") :: Frame
	resultLabel = gui:WaitForChild("ResultLabel") :: TextLabel

	local fishingResult = remotes:WaitForChild("FishingResult") :: RemoteEvent
	fishingResult.OnClientEvent:Connect(showResult)
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
