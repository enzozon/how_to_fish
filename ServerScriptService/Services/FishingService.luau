--!strict

-- Vara na mochila e lançamento da boia (simulada no servidor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)

type Cast = { bobber: BasePart, inWater: boolean }

local FishingService = {}

local casts: { [Player]: Cast } = {}
local lastCastAt: { [Player]: number } = {}
local rodTemplates: { [string]: Tool } = {}

local function findRodTool(container: Instance?): Tool?
	if container == nil then
		return nil
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("RodId") ~= nil then
			return child
		end
	end
	return nil
end

local function removeCast(player: Player)
	local cast = casts[player]
	if cast then
		cast.bobber:Destroy()
		casts[player] = nil
	end
end

local function isInWater(bobber: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { bobber }
	params.IgnoreWater = false
	local result = Workspace:Raycast(bobber.Position + Vector3.new(0, 2, 0), Vector3.new(0, -4, 0), params)
	return result ~= nil and result.Material == Enum.Material.Water
end

local function followBobber(player: Player, cast: Cast)
	local deadline = os.clock() + Fishing.SETTLE_TIMEOUT_SECONDS
	while os.clock() < deadline do
		task.wait(0.1)
		if casts[player] ~= cast then
			return
		end
		if isInWater(cast.bobber) then
			cast.inWater = true
			cast.bobber:SetAttribute("InWater", true)
			return
		end
		if cast.bobber.AssemblyLinearVelocity.Magnitude < Fishing.SETTLE_SPEED then
			break -- parou no chão
		end
	end
	if casts[player] == cast then
		removeCast(player)
	end
end

local function createBobber(player: Player, tip: Attachment, velocity: Vector3): BasePart
	local bobber = Instance.new("Part")
	bobber.Name = "Boia"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.6, 0.6, 0.6)
	bobber.Color = Color3.fromRGB(220, 40, 40)
	bobber.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.3, 0.5)
	bobber.Position = tip.WorldPosition
	bobber:SetAttribute("OwnerUserId", player.UserId)

	local attachment = Instance.new("Attachment")
	attachment.Parent = bobber
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = tip
	rope.Attachment1 = attachment
	rope.Length = Fishing.ROPE_LENGTH
	rope.Visible = true
	rope.Parent = bobber

	bobber.Parent = Workspace
	bobber:SetNetworkOwner(nil)
	bobber.AssemblyLinearVelocity = velocity
	return bobber
end

local function onCastLine(player: Player, power: unknown)
	if typeof(power) ~= "number" or power ~= power then
		return
	end
	local now = os.clock()
	if now - (lastCastAt[player] or 0) < Fishing.CAST_COOLDOWN_SECONDS then
		return
	end
	local data = DataService.GetData(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local tool = findRodTool(character)
	if data == nil or humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return
	end
	if tool == nil or tool:GetAttribute("RodId") ~= data.equippedRod then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	local tip = handle and handle:FindFirstChild("Tip")
	if tip == nil or not tip:IsA("Attachment") or (tip.WorldPosition - root.Position).Magnitude > Fishing.MAX_TIP_DISTANCE then
		return
	end

	local clampedPower = math.clamp(power, Fishing.MIN_CAST_POWER, 1)
	lastCastAt[player] = now
	removeCast(player)

	local look = root.CFrame.LookVector
	local horizontal = Vector3.new(look.X, 0, look.Z).Unit
	local angle = math.rad(Fishing.CAST_ANGLE_DEGREES)
	local direction = horizontal * math.cos(angle) + Vector3.yAxis * math.sin(angle)

	local cast = { bobber = createBobber(player, tip, direction * Fishing.CAST_MAX_SPEED * clampedPower), inWater = false }
	casts[player] = cast
	task.spawn(followBobber, player, cast)
end

-- Garante que a mochila tenha a vara do save (ou nenhuma).
function FishingService.RefreshRodTool(player: Player)
	local data = DataService.GetData(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if data == nil or backpack == nil then
		return
	end
	local tool = findRodTool(player.Character) or findRodTool(backpack)
	if tool and tool:GetAttribute("RodId") ~= data.equippedRod then
		tool:Destroy()
		tool = nil
	end
	local template = data.equippedRod and rodTemplates[data.equippedRod]
	if tool == nil and template then
		local newTool = template:Clone()
		newTool.Unequipped:Connect(function()
			removeCast(player)
		end)
		newTool.Parent = backpack
	end
end

function FishingService:Init()
	local tools = ServerStorage:WaitForChild("Tools")
	for _, tool in tools:GetChildren() do
		local rodId = tool:GetAttribute("RodId")
		if tool:IsA("Tool") and typeof(rodId) == "string" then
			rodTemplates[rodId] = tool
		end
	end
end

function FishingService:Start()
	local castLine = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CastLine") :: RemoteEvent
	castLine.OnServerEvent:Connect(onCastLine)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			removeCast(player)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				removeCast(player)
			end)
			if DataService.WaitForData(player) ~= nil then
				FishingService.RefreshRodTool(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		removeCast(player)
		lastCastAt[player] = nil
	end)
end

return FishingService
