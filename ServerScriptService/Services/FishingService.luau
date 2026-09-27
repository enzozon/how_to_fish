--!strict

-- Vara na mochila e lançamento da boia (simulada no servidor).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local CreatureService = require(script.Parent.CreatureService)
local FishRoller = require(script.Parent.Parent.Lib.FishRoller)
local FightSim = require(script.Parent.Parent.Lib.FightSim)
local Fishing = require(ReplicatedStorage.Shared.Config.Fishing)
local Fish = require(ReplicatedStorage.Shared.Config.Fish)
local Lures = require(ReplicatedStorage.Shared.Config.Lures)
local Rods = require(ReplicatedStorage.Shared.Config.Rods)

-- O estado vai para o cliente pelo atributo "State" da boia; espécie e peso ficam só aqui.
type CastState = "Flying" | "Waiting" | "Bite" | "Hooked"
type Cast = {
	bobber: BasePart,
	state: CastState,
	biteEndsAt: number, -- os.clock() em que a janela de fisgada fecha
	fishId: string?,
	weight: number?,
	fight: FightSim.FightState?,
	reeling: boolean,
	startPos: Vector3?, -- onde a boia estava ao fisgar
}

local FishingService = {}

local casts: { [Player]: Cast } = {}
local lastCastAt: { [Player]: number } = {}
local rodTemplates: { [string]: Tool } = {}
local rng = Random.new()
local fishingResult: RemoteEvent

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

local function isTooFar(player: Player, bobber: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root == nil or not root:IsA("BasePart") or (root.Position - bobber.Position).Magnitude > Fishing.ROPE_LENGTH
end

local function setState(cast: Cast, state: CastState)
	cast.state = state
	cast.bobber:SetAttribute("State", state)
end

local function sinkBobber(bobber: BasePart)
	-- Ancorada, o empuxo não briga com o afundar.
	bobber.Anchored = true
	bobber.CFrame -= Vector3.new(0, Fishing.BITE_SINK_DEPTH, 0)
end

local function floatBobber(bobber: BasePart)
	bobber.Anchored = false
	-- Ao desancorar, o Roblox pode passar a posse para um jogador; o servidor continua dono.
	bobber:SetNetworkOwner(nil)
end

local function biteCycle(player: Player, cast: Cast)
	while casts[player] == cast and cast.state == "Waiting" do
		task.wait(rng:NextNumber(Fishing.BITE_WAIT_MIN_SECONDS, Fishing.BITE_WAIT_MAX_SECONDS))
		local data = DataService.GetData(player)
		if casts[player] ~= cast or cast.state ~= "Waiting" or data == nil then
			return
		end
		local lure = Lures[FishRoller.resolveLureId(data)]
		local fishId, weight = FishRoller.roll(lure.tier, rng)
		if fishId == nil then
			warn(`[FishingService] Nenhuma espécie para o tier {lure.tier}`)
			return
		end

		cast.fishId, cast.weight = fishId, weight
		cast.biteEndsAt = os.clock() + Fishing.HOOK_WINDOW_SECONDS
		sinkBobber(cast.bobber)
		setState(cast, "Bite")

		task.wait(Fishing.HOOK_WINDOW_SECONDS + Fishing.HOOK_LATENCY_GRACE_SECONDS)
		if casts[player] == cast and cast.state == "Bite" then
			-- Ninguém fisgou: o peixe foge e a espera recomeça.
			cast.fishId, cast.weight = nil, nil
			floatBobber(cast.bobber)
			setState(cast, "Waiting")
		end
	end
end

-- Linha arrebentada: a isca paga em uso se perde (a de graça não).
local function consumeLure(player: Player)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end
	local lureId = FishRoller.resolveLureId(data)
	if Lures[lureId].price == 0 then
		return
	end
	for uid, item in data.inventory do
		if item.id == lureId then
			DataService.RemoveItem(player, uid)
			return
		end
	end
end

local function onFishCaught(player: Player, fishId: string, weight: number)
	CreatureService.SpawnLandedFish(player, fishId, weight)
end

local function finishFight(player: Player, cast: Cast, result: FightSim.FightResult)
	if casts[player] ~= cast then
		return
	end
	local fishName: string? = nil
	if result == "Broke" then
		consumeLure(player)
	elseif result == "Caught" and cast.fishId and cast.weight then
		fishName = Fish[cast.fishId].name
		onFishCaught(player, cast.fishId, cast.weight)
	end
	-- O peso não vai para o cliente; o valor aparece na inspeção (T09).
	fishingResult:FireClient(player, result, fishName)
	removeCast(player)
end

local function fightLoop(player: Player, cast: Cast)
	local fish = cast.fishId and Fish[cast.fishId]
	local data = DataService.GetData(player)
	local rod = data and data.equippedRod and Rods[data.equippedRod]
	local startPos = cast.startPos
	if fish == nil or rod == nil or startPos == nil then
		finishFight(player, cast, "Escaped")
		return
	end

	while casts[player] == cast and cast.state == "Hooked" do
		local dt = task.wait(Fishing.FIGHT_TICK_SECONDS)
		if casts[player] ~= cast or cast.fight == nil then
			return
		end
		local newFight, result = FightSim.step(cast.fight, cast.reeling, dt, fish, rod, rng)
		cast.fight = newFight
		cast.bobber:SetAttribute("Tension", newFight.tension)
		cast.bobber:SetAttribute("Distance", newFight.distance)

		-- A boia vem na direção do jogador conforme a distância cai (ancorada desde a mordida).
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local shore = Vector3.new(root.Position.X, startPos.Y, root.Position.Z)
			cast.bobber.CFrame = CFrame.new(startPos:Lerp(shore, 1 - newFight.distance / Fishing.START_DISTANCE))
		end

		if result ~= "Fighting" then
			finishFight(player, cast, result)
			return
		end
	end
end

local function startFight(player: Player, cast: Cast)
	local data = DataService.GetData(player)
	local rod = data and data.equippedRod and Rods[data.equippedRod]
	if rod == nil then
		removeCast(player)
		return
	end
	cast.fight = FightSim.newState()
	cast.reeling = false
	cast.startPos = cast.bobber.Position
	cast.bobber:SetAttribute("MaxTension", FightSim.maxTension(rod))
	cast.bobber:SetAttribute("StartDistance", Fishing.START_DISTANCE)
	cast.bobber:SetAttribute("Tension", 0)
	cast.bobber:SetAttribute("Distance", Fishing.START_DISTANCE)
	setState(cast, "Hooked") -- a boia continua afundada
	task.spawn(fightLoop, player, cast)
end

local function followBobber(player: Player, cast: Cast)
	local deadline = os.clock() + Fishing.SETTLE_TIMEOUT_SECONDS
	while os.clock() < deadline and cast.state == "Flying" do
		task.wait(0.1)
		if casts[player] ~= cast then
			return
		end
		if isInWater(cast.bobber) then
			setState(cast, "Waiting")
			task.spawn(biteCycle, player, cast)
		elseif cast.bobber.AssemblyLinearVelocity.Magnitude < Fishing.SETTLE_SPEED then
			break -- parou no chão
		end
	end

	-- Na água: a linha "arrebenta" se o jogador se afastar mais que o comprimento dela.
	while cast.state ~= "Flying" and casts[player] == cast and not isTooFar(player, cast.bobber) do
		task.wait(0.25)
	end
	if casts[player] == cast then
		if cast.state == "Hooked" then
			finishFight(player, cast, "Escaped")
		else
			removeCast(player)
		end
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

	-- Beam e não RopeConstraint: a corda liga o personagem à boia do servidor e o
	-- servidor passa a ser dono do personagem (o jogador fica preso). O limite de
	-- comprimento é checado em followBobber.
	local attachment = Instance.new("Attachment")
	attachment.Parent = bobber
	local line = Instance.new("Beam")
	line.Attachment0 = tip
	line.Attachment1 = attachment
	line.Width0 = 0.05
	line.Width1 = 0.05
	line.FaceCamera = true
	line.Color = ColorSequence.new(Color3.new(1, 1, 1))
	line.Parent = bobber

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

	local cast: Cast = {
		bobber = createBobber(player, tip, direction * Fishing.CAST_MAX_SPEED * clampedPower),
		state = "Flying",
		biteEndsAt = 0,
		reeling = false,
	}
	casts[player] = cast
	task.spawn(followBobber, player, cast)
end

local function onHookFish(player: Player)
	local cast = casts[player]
	if cast == nil or cast.state == "Flying" or cast.state == "Hooked" then
		return
	end
	if cast.state == "Bite" and os.clock() <= cast.biteEndsAt + Fishing.HOOK_LATENCY_GRACE_SECONDS then
		startFight(player, cast)
		return
	end
	-- Clicou antes da mordida: recolhe a linha.
	removeCast(player)
end

local function onReelInput(player: Player, isReeling: unknown)
	local cast = casts[player]
	if typeof(isReeling) ~= "boolean" or cast == nil or cast.state ~= "Hooked" then
		return
	end
	cast.reeling = isReeling
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
	local hookFish = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HookFish") :: RemoteEvent
	hookFish.OnServerEvent:Connect(onHookFish)
	local reelInput = ReplicatedStorage.Remotes:WaitForChild("ReelInput") :: RemoteEvent
	reelInput.OnServerEvent:Connect(onReelInput)
	fishingResult = ReplicatedStorage.Remotes:WaitForChild("FishingResult") :: RemoteEvent

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
