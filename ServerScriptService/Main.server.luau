--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Util.Loader)

local services = script.Parent:FindFirstChild("Services")
if services == nil then
	warn("[Main] Pasta Services não encontrada; pulando carregamento.")
else
	Loader.loadFolder(services)
end

print("Servidor iniciado")
