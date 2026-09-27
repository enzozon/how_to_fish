--!strict

-- Drena a fome dos jogadores e tira vida quando ela chega a 0.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Survival = require(ReplicatedStorage.Shared.Config.Survival)

local HungerService = {}

local function getDrainMultiplier(humanoid: Humanoid, rootPart: BasePart): number
	-- TODO(T11): confirmar se o servidor enxerga o estado Swimming quando houver água.
	if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
		return Survival.SWIMMING_MULTIPLIER
	end
	local velocity = rootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	if horizontalSpeed > Survival.MOVING_SPEED_THRESHOLD then
		return Survival.MOVING_MULTIPLIER
	end
	return 1
end

local function tick(player: Player, dt: number)
	local data = DataService.GetData(player)
	local character = player.Character
	if data == nil or character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end

	local multiplier = getDrainMultiplier(humanoid, rootPart)
	DataService.SetHunger(player, data.hunger - Survival.HUNGER_DRAIN_PER_SECOND * multiplier * dt)
	if data.hunger <= 0 then
		humanoid:TakeDamage(Survival.STARVE_DAMAGE_PER_SECOND * dt)
	end
end

local function onCharacterAdded(player: Player)
	-- ponytail: resetar o personagem devolve a fome ao mínimo; a morte ganha custo com a perda de peixes (GDD 2.9).
	local data = DataService.GetData(player)
	if data ~= nil and data.hunger < Survival.RESPAWN_MIN_HUNGER then
		DataService.SetHunger(player, Survival.RESPAWN_MIN_HUNGER)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		onCharacterAdded(player)
	end)
end

function HungerService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	task.spawn(function()
		while true do
			local dt = task.wait(Survival.TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				tick(player, dt)
			end
		end
	end)
end

return HungerService
