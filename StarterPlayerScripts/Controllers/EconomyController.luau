--!strict

-- Menus de venda (Vendedor) e de compra (Lojista), e inspeção de valor (tecla F).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local INSPECT_SECONDS = 2 -- tempo do rótulo da inspeção na tela

type SellEntry = { uid: string, name: string, weight: number?, price: number }
type ShopEntry = { id: string, name: string, price: number, owned: boolean }

local EconomyController = {}

local player = Players.LocalPlayer
local remotes: { [string]: RemoteFunction } = {}
local sellWindow: Frame
local buyWindow: Frame
local inspectLabel: TextLabel
local statusLabel: TextLabel
local sellEntries: { SellEntry } = {}
local inspectShownAt = 0

local function invoke(name: string, ...: any): any
	-- Erro no servidor não pode travar a UI.
	local remote = remotes[name]
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	return if ok then result else nil
end

-- Recria as linhas de uma janela a partir do Template; fill preenche cada linha.
local function buildRows<T>(window: Frame, entries: { T }, fill: (row: Frame, entry: T) -> ())
	local list = window:FindFirstChild("List") :: ScrollingFrame
	local template = list:FindFirstChild("Template") :: Frame
	for _, child in list:GetChildren() do
		if child:IsA("Frame") and child ~= template then
			child:Destroy()
		end
	end
	for index, entry in entries do
		local row = template:Clone()
		row.Name = `Row{index}`
		row.LayoutOrder = index
		row.Visible = true
		fill(row, entry)
		row.Parent = list
	end
end

local function setRowText(row: Frame, name: string, price: number)
	local nameLabel = row:FindFirstChild("NameLabel") :: TextLabel
	local priceLabel = row:FindFirstChild("PriceLabel") :: TextLabel
	nameLabel.Text = name
	priceLabel.Text = `${price}`
end

local refreshSell: () -> ()
local refreshBuy: () -> ()

local function sell(uids: { string })
	if #uids > 0 then
		invoke("SellItems", uids)
		refreshSell()
	end
end

refreshSell = function()
	local entries = invoke("GetSellList")
	sellEntries = if type(entries) == "table" then entries else {}
	buildRows(sellWindow, sellEntries, function(row, entry: SellEntry)
		local name = if entry.weight then string.format("%s (%.2f kg)", entry.name, entry.weight) else entry.name
		setRowText(row, name, entry.price)
		local sellButton = row:FindFirstChild("SellButton") :: TextButton
		sellButton.Activated:Connect(function()
			sell({ entry.uid })
		end)
	end)
end

local function buy(entry: ShopEntry)
	local result = invoke("BuyItem", entry.id)
	if type(result) == "table" and result.ok then
		statusLabel.Text = `Comprou {entry.name}!`
	else
		statusLabel.Text = if type(result) == "table" and type(result.reason) == "string" then result.reason else "Erro"
	end
	refreshBuy()
end

refreshBuy = function()
	local entries = invoke("GetShopList")
	buildRows(buyWindow, if type(entries) == "table" then entries else {}, function(row, entry: ShopEntry)
		setRowText(row, entry.name, entry.price)
		local button = row:FindFirstChild("BuyButton") :: TextButton
		button.Text = if entry.owned then "Comprado" else "Comprar"
		button.AutoButtonColor = not entry.owned
		button.Active = not entry.owned
		button.Activated:Connect(function()
			if not entry.owned then
				buy(entry)
			end
		end)
	end)
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
	local result = invoke("InspectValue", player:GetMouse().Target)
	if type(result) == "table" and type(result.name) == "string" and type(result.price) == "number" then
		showInspect(`{result.name}: ${result.price}`)
	else
		showInspect("Nada para inspecionar")
	end
end

local function closeAll()
	sellWindow.Visible = false
	buyWindow.Visible = false
end

function EconomyController:Init()
	local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in { "GetSellList", "SellItems", "InspectValue", "GetShopList", "BuyItem" } do
		remotes[name] = remoteFolder:WaitForChild(name) :: RemoteFunction
	end

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("EconomyGui")
	sellWindow = gui:WaitForChild("Window") :: Frame
	buyWindow = gui:WaitForChild("BuyWindow") :: Frame
	inspectLabel = gui:WaitForChild("InspectLabel") :: TextLabel
	statusLabel = buyWindow:WaitForChild("StatusLabel") :: TextLabel

	local sellAllButton = sellWindow:WaitForChild("SellAllButton") :: TextButton
	sellAllButton.Activated:Connect(function()
		local uids = {}
		for _, entry in sellEntries do
			table.insert(uids, entry.uid)
		end
		sell(uids)
	end)
	for _, window in { sellWindow, buyWindow } do
		local closeButton = window:WaitForChild("CloseButton") :: TextButton
		closeButton.Activated:Connect(function()
			window.Visible = false
		end)
	end
end

function EconomyController:Start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local shopType = prompt.Parent and prompt.Parent:GetAttribute("ShopType")
		if shopType == "Sell" then
			closeAll()
			sellWindow.Visible = true
			refreshSell()
		elseif shopType == "Buy" then
			closeAll()
			statusLabel.Text = ""
			buyWindow.Visible = true
			refreshBuy()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
			inspect()
		end
	end)
	player.CharacterAdded:Connect(closeAll)
end

return EconomyController
