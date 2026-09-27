--!strict

-- Save/load dos jogadores com ProfileStore. Só servidor: nunca chamar
-- direto com argumentos vindos de Remote sem validar antes.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local Shared = ReplicatedStorage.Shared
local Types = require(Shared.Types)
local Fish = require(Shared.Config.Fish)
local Lures = require(Shared.Config.Lures)
local Food = require(Shared.Config.Food)
local Rods = require(Shared.Config.Rods)
local Weapons = require(Shared.Config.Weapons)
local PlayerConfig = require(Shared.Config.Player)

type Profile = ProfileStore.Profile<Types.PlayerData>

local STORE_NAME = "PlayerData_v1"

local DataService = {}

local store: ProfileStore.ProfileStore<Types.PlayerData>
local profiles: { [Player]: Profile } = {}
local validItemIds: { [string]: boolean } = {}

local function createLeaderstats(player: Player, data: Types.PlayerData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Dinheiro"
	money.Value = data.money
	money.Parent = leaderstats
	leaderstats.Parent = player
end

local function onPlayerAdded(player: Player)
	-- O tipo de params no ProfileStore só declara Steal, mas Cancel é suportado (tutorial oficial).
	local params: any = {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}
	local profile = store:StartSessionAsync(`Player_{player.UserId}`, params)
	if profile == nil then
		player:Kick("Não foi possível carregar seus dados. Entre de novo.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Sessão encerrada. Entre de novo.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	createLeaderstats(player, profile.Data)
	player:SetAttribute("Hunger", profile.Data.hunger)
end

local function countItems(inventory: { [string]: Types.ItemData }): number
	local count = 0
	for _ in inventory do
		count += 1
	end
	return count
end

function DataService:Init()
	for id in Fish do
		validItemIds[id] = true
	end
	for id in Lures do
		validItemIds[id] = true
	end
	for id in Food do
		validItemIds[id] = true
	end

	local template: Types.PlayerData = {
		money = PlayerConfig.STARTING_MONEY,
		inventory = {},
		equippedLure = PlayerConfig.STARTING_LURE,
		hunger = PlayerConfig.MAX_HUNGER,
		ownedWeapons = {},
	}
	-- Cast: o tipo JSONAcceptable do ProfileStore não reconhece tabelas com tipo próprio.
	store = ProfileStore.New(STORE_NAME, template :: any)
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile ~= nil then
			profile:EndSession()
		end
	end)
end

-- Tabela viva: só leitura por convenção. Mudanças passam pelas funções abaixo.
function DataService.GetData(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Espera o save carregar. nil se o jogador sair antes.
function DataService.WaitForData(player: Player): Types.PlayerData?
	while profiles[player] == nil and player.Parent == Players do
		task.wait(0.5)
	end
	return DataService.GetData(player)
end

local function isValidAmount(amount: number): boolean
	-- NaN falha em amount == math.floor(amount).
	return amount > 0 and amount < math.huge and amount == math.floor(amount)
end

local function syncMoney(player: Player, data: Types.PlayerData)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Dinheiro")
	if money and money:IsA("IntValue") then
		money.Value = data.money
	end
end

function DataService.AddMoney(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile == nil or not isValidAmount(amount) then
		return false
	end
	profile.Data.money += amount
	syncMoney(player, profile.Data)
	return true
end

-- Recusa se o saldo não for suficiente.
function DataService.SpendMoney(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile == nil or not isValidAmount(amount) or profile.Data.money < amount then
		return false
	end
	profile.Data.money -= amount
	syncMoney(player, profile.Data)
	return true
end

function DataService.GiveWeapon(player: Player, weaponId: string): boolean
	local profile = profiles[player]
	if profile == nil or Weapons[weaponId] == nil then
		return false
	end
	profile.Data.ownedWeapons[weaponId] = true
	return true
end

-- Limita a 0..MAX_HUNGER e espelha no atributo "Hunger" do Player (lido pelo HUD).
function DataService.SetHunger(player: Player, value: number): boolean
	local profile = profiles[player]
	if profile == nil or value ~= value then
		return false
	end

	profile.Data.hunger = math.clamp(value, 0, PlayerConfig.MAX_HUNGER)
	player:SetAttribute("Hunger", profile.Data.hunger)
	return true
end

-- No M1, equippedRod também é a posse: nil = sem vara.
function DataService.SetEquippedRod(player: Player, rodId: string?): boolean
	local profile = profiles[player]
	if profile == nil or (rodId ~= nil and Rods[rodId] == nil) then
		return false
	end
	profile.Data.equippedRod = rodId
	return true
end

function DataService.SetEquippedLure(player: Player, lureId: string): boolean
	local profile = profiles[player]
	if profile == nil or Lures[lureId] == nil then
		return false
	end
	profile.Data.equippedLure = lureId
	return true
end

function DataService.AddItem(player: Player, item: Types.ItemData): string?
	local profile = profiles[player]
	if profile == nil or not validItemIds[item.id] then
		return nil
	end
	local inventory = profile.Data.inventory
	if countItems(inventory) >= PlayerConfig.MAX_INVENTORY_ITEMS then
		return nil
	end

	local uid = HttpService:GenerateGUID(false)
	inventory[uid] = { id = item.id, weight = item.weight }
	return uid
end

function DataService.RemoveItem(player: Player, uid: string): Types.ItemData?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end
	local inventory = profile.Data.inventory
	local item = inventory[uid]
	inventory[uid] = nil
	return item
end

return DataService
