--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local util = shared:WaitForChild("Util")
local Loader = require(util:WaitForChild("Loader"))

local controllers = script.Parent:FindFirstChild("Controllers")
if controllers == nil then
	warn("[Main] Pasta Controllers não encontrada; pulando carregamento.")
else
	Loader.loadFolder(controllers)
end

print("Cliente iniciado")
