--!strict

-- Peixes em terra: aparecem depois da captura, pulam e podem ser pegos pelo dono.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Survival = require(ReplicatedStorage.Shared.Config.Survival)

type LandedFish = { owner: Player, fishId: string, weight: number }

local CreatureService = {}

-- Espécie e peso ficam só aqui; a Part leva só o dono.
local landed: { [BasePart]: LandedFish } = {}
local rng = Random.new()

local function removeFish(part: BasePart)
	landed[part] = nil
	part:Destroy()
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

local function onPickup(part: BasePart, player: Player)
	local entry = landed[part]
	if entry == nil or entry.owner ~= player then
		return
	end
	local root = getLivingRoot(player)
	if root == nil or (root.Position - part.Position).Magnitude > Survival.PICKUP_MAX_DISTANCE then
		return
	end
	if DataService.AddItem(player, { id = entry.fishId, weight = entry.weight }) == nil then
		return -- inventário cheio: o peixe fica no chão
	end
	removeFish(part)
end

local function jumpLoop(part: BasePart)
	while landed[part] do
		task.wait(rng:NextNumber(Fishing.LANDED_FISH_JUMP_MIN_SECONDS, Fishing.LANDED_FISH_JUMP_MAX_SECONDS))
		if landed[part] == nil then
			return
		end
		local angle = rng:NextNumber(0, 2 * math.pi)
		part.AssemblyLinearVelocity = Vector3.new(
			math.cos(angle) * Fishing.LANDED_FISH_JUMP_SIDE_SPEED,
			Fishing.LANDED_FISH_JUMP_UP_SPEED,
			math.sin(angle) * Fishing.LANDED_FISH_JUMP_SIDE_SPEED
		)
	end
end

function CreatureService.SpawnLandedFish(player: Player, fishId: string, weight: number)
	local fish = Fish[fishId]
	local root = getLivingRoot(player)
	if fish == nil or root == nil then
		return
	end

	local side = math.min(Fishing.LANDED_FISH_BASE_SIZE + Fishing.LANDED_FISH_SIZE_PER_KG * weight, Fishing.LANDED_FISH_MAX_SIZE)
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z).Unit

	local part = Instance.new("Part")
	part.Name = "Peixe"
	part.Size = Vector3.new(side, side, side)
	part.Color = fish.color
	-- Atrás do jogador: pescando, ele está virado para a água (ex.: ponta do píer).
	part.Position = root.Position - forward * Fishing.LANDED_FISH_SPAWN_DISTANCE + Vector3.new(0, 2, 0)
	part:SetAttribute("OwnerUserId", player.UserId)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pegar"
	prompt.ObjectText = fish.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(triggeringPlayer)
		onPickup(part, triggeringPlayer)
	end)

	landed[part] = { owner = player, fishId = fishId, weight = weight }
	part.Parent = Workspace
	part:SetNetworkOwner(nil)

	task.spawn(jumpLoop, part)
	task.delay(Fishing.LANDED_FISH_LIFETIME_SECONDS, function()
		if landed[part] then
			removeFish(part)
		end
	end)
end

-- Só leitura (inspeção). nil se a Part não é um peixe em terra.
function CreatureService.GetLandedFish(part: Instance): { fishId: string, weight: number }?
	local entry = if part:IsA("BasePart") then landed[part] else nil
	if entry == nil then
		return nil
	end
	return { fishId = entry.fishId, weight = entry.weight }
end

function CreatureService:Start()
	Players.PlayerRemoving:Connect(function(player)
		for part, entry in landed do
			if entry.owner == player then
				removeFish(part)
			end
		end
	end)
end

return CreatureService
