# M1 — Roteiro de tarefas (Ilha 1, sem arte)

Objetivo do M1: fome + mariscos + pescar + vender + comprar vara/faca + salvar. Tudo com cubos.
Critério de pronto: pescar por 10 minutos com cubos já é divertido.

---

## Como dividir o trabalho

| Ferramenta | Papel | Modelo |
|---|---|---|
| **Claude Code** (sua assinatura) | Planeja cada tarefa, escreve o plano em arquivo, revisa o código depois | Opus para planejar/revisar, Sonnet para o resto (`/model`) |
| **Chat do Cursor** (grátis) | Implementa seguindo o plano | Agent mode |
| **Você** | Testa no Studio, faz commit | — |

### O ciclo de cada tarefa (sempre o mesmo)

**1. Claude Code — planejar**
```
Leia AGENTS.md e GDD.md. Planeje a tarefa TXX deste arquivo (M1_TAREFAS.md).
Escreva o plano em docs/planos/TXX.md com: arquivos a criar/editar, o que cada
um faz, remotes e objetos que precisam existir no Studio, validações de segurança
no servidor e como testar. Não escreva o código ainda.
```

**2. Chat do Cursor — implementar**
```
Leia AGENTS.md e docs/planos/TXX.md. Implemente exatamente o plano.
Use o MCP do Roblox Studio para criar os objetos que o plano pede.
Ao final, rode o play mode pelo MCP, leia o Output e corrija erros.
```

**3. Você — testar** no Studio (botão Play). Se funcionar: `git add . && git commit -m "TXX: ..."`

**4. Claude Code — revisar**
```
Revise o último commit (git show HEAD). Foque em: validação no servidor,
exploits possíveis, bugs e desvios do plano em docs/planos/TXX.md.
Liste problemas por gravidade. Corrija só os críticos.
```

> Se o chat do Cursor bater no limite grátis, faça o passo 2 no Claude Code com Sonnet.

---

## Tarefas

### T00 — Esqueleto do projeto
Main.server.luau, Main.local.luau, pasta Services/, Controllers/, Types.luau, pastas Config/ vazias.
Main de cada lado carrega todos os módulos da pasta e chama `:Init()` e depois `:Start()`.
Pasta `Remotes` em ReplicatedStorage criada via MCP.
**Teste:** play mode sem erros; Output mostra "Servidor iniciado" e "Cliente iniciado".

### T01 — Configs do M1
`Fish.luau` (só espécies da Ilha 1: caranguejo, camarão, siri, lagosta), `Lures.luau` (Isca de Graça, Salsicha), `Rods.luau` (Vara de Siri), `Weapons.luau` (Mão, Soco-inglês, Faca). Campos conforme GDD seção 5.2.
**Teste:** um script de teste imprime a tabela sem erro de tipo.

### T02 — DataService (save)
ProfileStore (baixar o módulo oficial do GitHub para `ServerScriptService/Packages/`).
Dados: dinheiro, inventário, vara equipada, isca equipada, fome.
Expõe `GetData(player)`, `AddMoney`, `AddItem`, `RemoveItem`.
Mostra dinheiro num `leaderstats` (placar simples, provisório).
**Teste:** ganhe dinheiro via comando de teste, saia e volte: o valor persiste. (Ative "Enable Studio Access to API Services" em Game Settings → Security.)

### T03 — Fome
HungerService no servidor drena a fome (config em `Config/Survival.luau`). Em 0, perde vida.
HungerController desenha uma barra simples na tela (UI criada via MCP em StarterGui).
**Teste:** a barra desce; em 0 a vida cai.

### T04 — Mariscos
Mariscos (cubos pequenos) espalhados na areia com ProximityPrompt "Pegar" (E).
Servidor adiciona ao inventário e reaparece depois de X segundos.
Comer: item no inventário, clique segurado → servidor recupera fome.
**Teste:** pegar, comer, fome sobe; o marisco reaparece.

### T05 — Vara: lançar
Tool "Vara de Siri" via MCP. Segurar clique enche barra de força; soltar lança a boia (Part física + RopeConstraint na ponta da vara).
Servidor valida se o jogador está perto da água e com a vara equipada.
**Teste:** a boia voa conforme a força e cai na água presa pela linha.

### T06 — Mordida e fisgada
Servidor sorteia tempo de espera e espécie (pela isca equipada). Boia afunda na mordida.
Janela curta para clicar. Errou = peixe foge.
**Teste:** mordida acontece, fisgar funciona, errar faz o peixe fugir.

### T07 — Minijogo de tensão
UI de tensão + distância (GDD 2.2 item 4). Puxões aleatórios pela `pullStrength` da espécie.
Linha arrebenta = perde a isca. Distância em 0 = sucesso.
Servidor valida duração mínima da luta (anti-exploit).
**Teste:** pescar com sucesso, e também arrebentar a linha de propósito.

### T08 — Peixe em terra
Ao ganhar, o servidor cria um modelo (cubo colorido por espécie) perto do jogador, que "pula" com impulsos aleatórios.
ProximityPrompt "Pegar" → vai para o inventário.
**Teste:** o peixe cai, pula e pode ser pego.

### T09 — Venda + inspeção (F)
NPC vendedor (cubo com ProximityPrompt). Menu de venda do inventário.
Tecla F mostra o valor do item olhado ou segurado. Preço calculado só no servidor.
**Teste:** vender aumenta o dinheiro; o valor do F bate com o preço pago.

### T10 — Loja
Mesmo NPC ou outro: comprar Vara de Siri ($3), Salsicha ($5), Soco-inglês ($24), Faca ($45).
Servidor checa saldo antes de dar o item.
**Teste:** comprar com e sem dinheiro suficiente.

### T11 — Greybox da Ilha 1
Via MCP: ilha de terrain, praia, pier, farol (cilindro), cabana do vendedor, água ao redor, spawn.
**Teste:** dá para andar, pescar do pier e chegar no vendedor.

### T12 — Playtest do M1
Jogue 10–15 min. Anote no arquivo `docs/playtest-m1.md`: o que é chato, o que é fácil demais, bugs.
Mande ao Claude Code: "Leia docs/playtest-m1.md e proponha ajustes de balanceamento nas Configs."

---

## Depois do M1
Peça ao Claude Code (Opus): "Com base no GDD e no que existe no código, quebre o M2 em tarefas no mesmo formato deste arquivo."
