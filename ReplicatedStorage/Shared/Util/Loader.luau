--!strict

-- No cliente, Types pode ainda não ter replicado; o require estático mantém a inferência de tipos.
script.Parent.Parent:WaitForChild("Types")
local Types = require(script.Parent.Parent.Types)

local Loader = {}

local function collectModuleScripts(folder: Instance): { ModuleScript }
	local moduleScripts: { ModuleScript } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(moduleScripts, child)
		end
	end
	table.sort(moduleScripts, function(a: ModuleScript, b: ModuleScript): boolean
		return a.Name < b.Name
	end)
	return moduleScripts
end

function Loader.loadFolder(folder: Instance): { [string]: Types.Module }
	local moduleScripts = collectModuleScripts(folder)
	local loaded: { [string]: Types.Module } = {}

	for _, moduleScript in moduleScripts do
		local ok, result = pcall(require, moduleScript)
		if not ok then
			error(`[Loader] Falha ao carregar {moduleScript.Name}: {result}`)
		end
		loaded[moduleScript.Name] = result :: Types.Module
	end

	for _, moduleScript in moduleScripts do
		local module = loaded[moduleScript.Name]
		if module.Init ~= nil then
			local ok, err = pcall(function()
				module:Init()
			end)
			if not ok then
				error(`[Loader] Falha no Init de {moduleScript.Name}: {err}`)
			end
		end
	end

	for _, moduleScript in moduleScripts do
		local module = loaded[moduleScript.Name]
		if module.Start ~= nil then
			task.spawn(function()
				module:Start()
			end)
		end
	end

	return loaded
end

return Loader
