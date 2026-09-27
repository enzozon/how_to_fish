--!strict

-- Menu de venda (prompt do vendedor) e inspeção de valor (tecla F).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local INSPECT_SECONDS = 2 -- tempo do rótulo da inspeção na tela

type SellEntry = { uid: string, name: string, weight: number?, price: number }

local EconomyController = {}

local player = Players.LocalPlayer
local getSellList: RemoteFunction
local sellItems: RemoteFunction
local inspectValue: RemoteFunction
local window: Frame
local list: ScrollingFrame
local template: Frame
local inspectLabel: TextLabel
local currentEntries: { SellEntry } = {}
local inspectShownAt = 0

local function invoke(remote: RemoteFunction, ...: any): any
	-- Erro no servidor não pode travar a UI.
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	return if ok then result else nil
end

local function clearRows()
	for _, child in list:GetChildren() do
		if child:IsA("Frame") and child ~= template then
			child:Destroy()
		end
	end
end

local refreshList: () -> ()

local function sell(uids: { string })
	if #uids > 0 then
		invoke(sellItems, uids)
		refreshList()
	end
end

refreshList = function()
	local entries = invoke(getSellList)
	currentEntries = if type(entries) == "table" then entries else {}
	clearRows()
	for index, entry in currentEntries do
		local row = template:Clone()
		row.Name = "Row"
		row.LayoutOrder = index
		row.Visible = true
		local nameLabel = row:FindFirstChild("NameLabel") :: TextLabel
		local priceLabel = row:FindFirstChild("PriceLabel") :: TextLabel
		local sellButton = row:FindFirstChild("SellButton") :: TextButton
		nameLabel.Text = if entry.weight then string.format("%s (%.2f kg)", entry.name, entry.weight) else entry.name
		priceLabel.Text = `${entry.price}`
		sellButton.Activated:Connect(function()
			sell({ entry.uid })
		end)
		row.Parent = list
	end
end

local function openWindow()
	window.Visible = true
	refreshList()
end

local function showInspect(text: string)
	inspectLabel.Text = text
	inspectLabel.Visible = true
	inspectShownAt = os.clock()
	local shownAt = inspectShownAt
	task.delay(INSPECT_SECONDS, function()
		if inspectShownAt == shownAt then
			inspectLabel.Visible = false
		end
	end)
end

local function inspect()
	local result = invoke(inspectValue, player:GetMouse().Target)
	if type(result) == "table" and type(result.name) == "string" and type(result.price) == "number" then
		showInspect(`{result.name}: ${result.price}`)
	else
		showInspect("Nada para inspecionar")
	end
end

function EconomyController:Init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	getSellList = remotes:WaitForChild("GetSellList") :: RemoteFunction
	sellItems = remotes:WaitForChild("SellItems") :: RemoteFunction
	inspectValue = remotes:WaitForChild("InspectValue") :: RemoteFunction

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("EconomyGui")
	window = gui:WaitForChild("Window") :: Frame
	list = window:WaitForChild("List") :: ScrollingFrame
	template = list:WaitForChild("Template") :: Frame
	inspectLabel = gui:WaitForChild("InspectLabel") :: TextLabel
	local sellAllButton = window:WaitForChild("SellAllButton") :: TextButton
	local closeButton = window:WaitForChild("CloseButton") :: TextButton

	sellAllButton.Activated:Connect(function()
		local uids = {}
		for _, entry in currentEntries do
			table.insert(uids, entry.uid)
		end
		sell(uids)
	end)
	closeButton.Activated:Connect(function()
		window.Visible = false
	end)
end

function EconomyController:Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local parent = prompt.Parent
		if parent and parent:GetAttribute("ShopType") == "Sell" then
			openWindow()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
			inspect()
		end
	end)
	player.CharacterAdded:Connect(function()
		window.Visible = false
	end)
end

return EconomyController
