# AGENTS.md — Regras para agentes de IA neste projeto

Leia este arquivo e o `GDD.md` antes de qualquer tarefa.

## Projeto
Jogo Roblox de pesca + sobrevivência + chefes, co-op até 4 jogadores. Design completo em `GDD.md`.

## Como o projeto sincroniza
- Código em arquivos `.luau` sincronizados com o Studio via **Script Sync**.
- Pastas sincronizadas: `ServerScriptService/`, `ReplicatedStorage/`, `StarterPlayerScripts/`.
- UI (StarterGui), ferramentas (StarterPack), Parts, Terrain e RemoteEvents são criados pelo **MCP do Roblox Studio**, não por arquivo.
- Sufixos: `.server.luau` = Script, `.local.luau` = LocalScript, `.luau` = ModuleScript.
- **Não use `.client.luau`**: o Script Sync gera um Script com RunContext Client, que roda duas vezes dentro de StarterPlayerScripts.
- Pastas vazias não sincronizam com o Studio; elas aparecem quando o primeiro arquivo entra nelas.
- `ServerScriptService/Packages/` guarda código de terceiros: não editar; as regras de estilo (ex.: `--!strict`) não se aplicam.
- `tools/` fica fora do Script Sync: scripts para rodar pelo MCP (`execute_luau` no Edit), como o greybox da ilha em `tools/greybox/`. São idempotentes e versionam o que o MCP monta no place.

## Linguagem e estilo
- Luau com `--!strict` no topo de todo arquivo.
- Tipos explícitos em funções públicas; tipos compartilhados em `ReplicatedStorage/Shared/Types.luau`.
- Serviços com `game:GetService(...)`, nunca `game.Workspace` direto.
- Nomes: `PascalCase` para módulos/serviços, `camelCase` para variáveis e funções.
- Nada de `wait()`, use `task.wait()`, `task.spawn()`, `task.delay()`.
- Sem números mágicos: valores de balanceamento ficam em `ReplicatedStorage/Shared/Config/`.

## Arquitetura
- Servidor: um módulo por serviço em `ServerScriptService/Services/`, iniciados por `Main.server.luau`.
- Cliente: um módulo por controller em `StarterPlayerScripts/Controllers/`, iniciados por `Main.local.luau`.
- Serviço não chama controller e vice-versa: comunicação só por Remotes em `ReplicatedStorage/Remotes`.

## Segurança (obrigatório)
- **O servidor é a autoridade.** Espécie, peso, raridade, dano, preço, dinheiro e recompensas são decididos no servidor.
- Todo `OnServerEvent`/`OnServerInvoke` valida: tipos dos argumentos, distância do jogador, cooldown e estado atual.
- Nunca aceitar valores numéricos de dinheiro, dano ou item vindos do cliente.
- Dados salvos com ProfileStore; nunca `DataStore:SetAsync` solto.
- Não usar `loadstring`. Não inserir modelos da Creator Store sem checar scripts internos.

## Como trabalhar
- Uma tarefa por vez, pequena e testável. Se a tarefa for grande, proponha a divisão antes de codar.
- Antes de editar, leia os arquivos relacionados. Não reescreva arquivos inteiros para mudar uma função.
- Depois de implementar, use o MCP para rodar play mode e ler o Output. Corrija erros antes de encerrar.
- Ao terminar, resuma: o que mudou, arquivos tocados, como testar.
- Não invente APIs do Roblox. Em dúvida, diga que não sabe.

## Fora do escopo
- Não copiar nomes, arte ou textos do jogo *How to Fish* (Dazed Games). Usar só o que está no `GDD.md`.
