--!strict

-- Desenha a barra de fome a partir do atributo "Hunger" que o servidor publica.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Player"))

local HungerController = {}

local player = Players.LocalPlayer
local fill: Frame

local function update()
	local hunger = player:GetAttribute("Hunger")
	-- Sem valor = o save ainda não carregou; deixa cheia.
	local ratio = if type(hunger) == "number" then hunger / PlayerConfig.MAX_HUNGER else 1
	fill.Size = UDim2.fromScale(ratio, 1)
end

function HungerController:Init()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("HungerGui")
	fill = gui:WaitForChild("Background"):WaitForChild("Fill") :: Frame
end

function HungerController:Start()
	player:GetAttributeChangedSignal("Hunger"):Connect(update)
	update()
end

return HungerController
