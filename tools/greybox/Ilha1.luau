-- Greybox da Ilha 1 (Praia do Farol). Rodar pelo MCP: execute_luau no datamodel Edit.
-- Sem --!strict: roda no plugin do MCP, não no jogo. Idempotente: limpa e monta de novo.
-- Mantém (só reposiciona) SpawnLocation, Vendedor, Lojista e Mariscos, que os serviços
-- procuram como filhos diretos do Workspace.

local Workspace = game:GetService("Workspace")
local terrain = Workspace.Terrain

local SEA_LEVEL = 0
local SAND_TOP = 2
local GRASS_TOP = 3
local BEACH_RADIUS = 90
local GRASS_RADIUS = 70
local OCEAN_SIZE = 1000
local OCEAN_DEPTH = 20

-- Limpeza ----------------------------------------------------------------------
terrain:Clear()
local old = Workspace:FindFirstChild("Ilha1")
if old then
	old:Destroy()
end
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local island = Instance.new("Folder")
island.Name = "Ilha1"
island.Parent = Workspace

local partCount = 0
local function makePart(parent: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	partCount += 1
	return part
end

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = island
	return f
end

-- Terrain -----------------------------------------------------------------------
terrain:FillBlock(CFrame.new(0, SEA_LEVEL - OCEAN_DEPTH - 2, 0), Vector3.new(OCEAN_SIZE, 4, OCEAN_SIZE), Enum.Material.Sand)
terrain:FillBlock(CFrame.new(0, SEA_LEVEL - OCEAN_DEPTH / 2, 0), Vector3.new(OCEAN_SIZE, OCEAN_DEPTH, OCEAN_SIZE), Enum.Material.Water)
local beachHeight = SAND_TOP + OCEAN_DEPTH
terrain:FillCylinder(CFrame.new(0, SAND_TOP - beachHeight / 2, 0), beachHeight, BEACH_RADIUS, Enum.Material.Sand)
local grassHeight = GRASS_TOP + OCEAN_DEPTH
terrain:FillCylinder(CFrame.new(0, GRASS_TOP - grassHeight / 2, 0), grassHeight, GRASS_RADIUS, Enum.Material.Grass)
-- Poças de maré na areia
terrain:FillBlock(CFrame.new(80, 1, 30), Vector3.new(8, 2, 6), Enum.Material.Water)
terrain:FillBlock(CFrame.new(-75, 1, -35), Vector3.new(8, 2, 6), Enum.Material.Water)

-- Altura do chão (os voxels do terrain arredondam a superfície; melhor medir do que supor).
-- O raycast só enxerga o terrain novo depois de um frame.
task.wait(1)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { terrain }
groundParams.IgnoreWater = true
local function groundY(x: number, z: number): number
	local hit = Workspace:Raycast(Vector3.new(x, 50, z), Vector3.new(0, -100, 0), groundParams)
	return if hit then hit.Position.Y else GRASS_TOP
end

-- Píer --------------------------------------------------------------------------
local pier = folder("Pier")
local wood = Color3.fromRGB(125, 90, 60)
makePart(pier, {
	Name = "Deck",
	Size = Vector3.new(40, 1, 8),
	Position = Vector3.new(105, SAND_TOP + 0.5, 0),
	Color = wood,
	Material = Enum.Material.WoodPlanks,
})
for _, x in { 90, 100, 110, 120 } do
	for _, z in { -3.5, 3.5 } do
		makePart(pier, {
			Name = "Estaca",
			Size = Vector3.new(1, 24, 1),
			Position = Vector3.new(x, SAND_TOP - 12, z),
			Color = wood,
			Material = Enum.Material.Wood,
		})
	end
end

-- Farol -------------------------------------------------------------------------
local lighthouse = folder("Farol")
local lx, lz = -55, -45
local baseY = groundY(lx, lz)
local upright = CFrame.Angles(0, 0, math.rad(90)) -- o eixo do cilindro é X; gira para ficar em pé
makePart(lighthouse, {
	Name = "Base",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(15, 8, 8),
	CFrame = CFrame.new(lx, baseY + 7.5, lz) * upright,
	Color = Color3.fromRGB(240, 240, 240),
	Material = Enum.Material.Concrete,
})
makePart(lighthouse, {
	Name = "Topo",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(15, 8, 8),
	CFrame = CFrame.new(lx, baseY + 22.5, lz) * upright,
	Color = Color3.fromRGB(200, 40, 40),
	Material = Enum.Material.Concrete,
})
local lamp = makePart(lighthouse, {
	Name = "Lampada",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(6, 6, 6),
	Position = Vector3.new(lx, baseY + 33, lz),
	Color = Color3.fromRGB(255, 220, 90),
	Material = Enum.Material.Neon,
})
local light = Instance.new("PointLight")
light.Range = 40
light.Brightness = 3
light.Color = lamp.Color
light.Parent = lamp

-- Cabana (frente aberta para o spawn, em -Z) -------------------------------------
local hut = folder("Cabana")
local hx, hz = 30, 40
local floorY = groundY(hx, hz) + 0.5
local plank = Color3.fromRGB(150, 110, 70)
makePart(hut, { Name = "Piso", Size = Vector3.new(20, 1, 12), Position = Vector3.new(hx, floorY, hz), Color = plank, Material = Enum.Material.WoodPlanks })
local wallY = floorY + 0.5 + 4
makePart(hut, { Name = "Fundo", Size = Vector3.new(20, 8, 1), Position = Vector3.new(hx, wallY, hz + 5.5), Color = plank, Material = Enum.Material.Wood })
makePart(hut, { Name = "LadoEsquerdo", Size = Vector3.new(1, 8, 12), Position = Vector3.new(hx - 9.5, wallY, hz), Color = plank, Material = Enum.Material.Wood })
makePart(hut, { Name = "LadoDireito", Size = Vector3.new(1, 8, 12), Position = Vector3.new(hx + 9.5, wallY, hz), Color = plank, Material = Enum.Material.Wood })
makePart(hut, { Name = "Telhado", Size = Vector3.new(22, 1, 14), Position = Vector3.new(hx, wallY + 4.5, hz), Color = Color3.fromRGB(110, 60, 40), Material = Enum.Material.Wood })

-- Reposicionamentos ---------------------------------------------------------------
local floorTop = floorY + 0.5
-- Dentro da cabana a câmera fica atrás das paredes: sem exigir linha de visão no prompt.
local function placeNpc(name: string, x: number): BasePart?
	local npc = Workspace:FindFirstChild(name)
	if npc == nil then
		return nil
	end
	npc.Position = Vector3.new(x, floorTop + npc.Size.Y / 2, hz + 2)
	local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.RequiresLineOfSight = false
	end
	return npc
end
local vendor = placeNpc("Vendedor", hx - 5)
local shopkeeper = placeNpc("Lojista", hx + 5)

local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
if spawnLocation then
	spawnLocation.Position = Vector3.new(0, groundY(0, 0) + spawnLocation.Size.Y / 2, 0)
end

local mariscos = Workspace:FindFirstChild("Mariscos")
local mariscoRadius = 80
local mariscoAngles = { 45, 100, 150, 240, 290, 330 } -- longe do píer (0°) e das poças
if mariscos then
	for index, marisco in mariscos:GetChildren() do
		local angle = math.rad(mariscoAngles[(index - 1) % #mariscoAngles + 1])
		local x, z = math.cos(angle) * mariscoRadius, math.sin(angle) * mariscoRadius
		marisco.Position = Vector3.new(x, groundY(x, z) + marisco.Size.Y / 2, z)
	end
end

return string.format(
	"Ilha1: %d Parts | spawn=%s | Vendedor=%s | Lojista=%s | mariscos=%d",
	partCount,
	tostring(spawnLocation and spawnLocation.Position),
	tostring(vendor and vendor.Position),
	tostring(shopkeeper and shopkeeper.Position),
	mariscos and #mariscos:GetChildren() or 0
)
