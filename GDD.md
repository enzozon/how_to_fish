# GDD — Jogo de pesca e sobrevivência (inspirado em How to Fish)

> Nome provisório: **Maré Brava** (troque à vontade).
> Este documento é a fonte da verdade do design. Os agentes (Claude e Grok) devem ler antes de implementar qualquer sistema.

---

## 0. Referência e limites

- **Referência:** *How to Fish* (Dazed Games, Steam, ago/2026). Jogo de 1–4 jogadores, pesca com física, sobrevivência e chefes, progressão ilha por ilha.
- **O que copiamos:** o gênero e as mecânicas (fome, pesca, peixe que briga em terra, loja, isca por tier, chefe que libera a próxima ilha, variantes raras, co-op).
- **O que NÃO copiamos:** nome, logo, arte, modelos, textos, nomes inventados de peixes/chefes/itens deles (ex.: "Drip", "Voxelfish", "Sengarat", "Boat Keys" como item de marca), nem a cadeia exata de iscas absurdas dos chefes. Espécies reais (atum, baiacu, tubarão) são livres.
- **Motivo:** jogos que só trocam o nome de outro podem ser derrubados por denúncia de propriedade intelectual e não se destacam. Uma identidade própria (ex.: tema brasileiro/litorâneo) é vantagem.

---

## 1. Visão geral

**Premissa:** o barco da tripulação encalha num arquipélago misterioso. Para voltar para casa, é preciso aprender a pescar, sobreviver, consertar o barco e derrotar os "guardiões" de cada ilha.

**Pilares:**
1. **Pescar é uma briga** — o peixe resiste na linha e continua brigando depois de fisgado.
2. **Sobreviver** — fome constante; peixe é comida *ou* dinheiro, você decide.
3. **Progredir por ilhas** — cada ilha tem bioma, peixes, isca, loja, missões e um chefe-portão.
4. **Caos em grupo** — co-op de até 4 jogadores por servidor.

**Loop principal (minuto a minuto):**
```
Comer → Pescar (lançar → esperar → fisgar → puxar) → Peixe cai em terra e briga
→ Subjugar (soco/faca/arma) → Decidir: comer, cozinhar ou vender
→ Comprar isca/arma/upgrade → Missão → Chefe → Próxima ilha
```

---

## 2. Mecânicas centrais

### 2.1 Fome
- Barra de fome de 0 a 100, drena com o tempo (mais rápido correndo/nadando).
- Em 0, perde vida por segundo.
- Comida inicial: **mariscos** na areia da praia (`E` para pegar, clique segurado para comer). Vendem por $1.
- Peixe cru mata pouca fome; peixe **cozido** na grelha mata mais e cura vida.

### 2.2 Pesca (adaptada ao Roblox)
O original usa física de mouse com vara que enverga e linha que arrebenta. No Roblox, fazemos uma versão confiável:

1. **Lançar:** segurar clique enche uma barra de força; soltar lança a boia. A boia é um objeto físico preso por `RopeConstraint` na ponta da vara.
2. **Esperar:** tempo aleatório (servidor decide). A boia afunda quando morde.
3. **Fisgar:** janela curta para clicar (reação). Perdeu a janela = peixe foge.
4. **Puxar (minijogo de tensão):**
   - Barra de **tensão**: segurar clique recolhe a linha e sobe a tensão; soltar alivia.
   - O peixe dá **puxões** aleatórios que sobem a tensão (peixes maiores puxam mais forte).
   - Tensão no máximo por tempo demais = **linha arrebenta** (perde a isca).
   - Barra de **distância** chega a zero = peixe sai da água.
   - Stats da vara: *força* (reduz ganho de tensão) e *resistência* (tensão máxima).
5. **Pouso:** o peixe vira um modelo físico no chão, perto do jogador.

> Regra de ouro: o **servidor** sorteia a espécie, o peso e se é variante rara. O cliente só roda o minijogo e manda o resultado; o servidor valida tempo mínimo e plausibilidade.

### 2.3 Peixe em terra (combate)
- Peixes comuns ficam pulando (inofensivos) e podem ser pegos.
- Peixes **agressivos** têm vida e atacam o jogador próximo (mordida, investida).
- Precisa subjugar antes de coletar: soco (mão livre), soco-inglês, faca, depois armas.
- Ao morrer, vira item coletável (carne/peixe inteiro).

### 2.4 Economia
- Moeda: **$** (dinheiro).
- **Tecla F:** inspecionar valor de qualquer item antes de vender.
- Vendedor NPC em cada ilha. Preço base × multiplicador de peso × multiplicador de raridade.
- **Carteira do grupo:** no original o dinheiro é compartilhado pela tripulação. No Roblox, recomendamos **carteira individual salva** + bônus de venda quando o grupo está junto (evita briga e abuso).

### 2.5 Iscas = progressão
A espécie que você pesca depende da **isca equipada**, não do lugar onde está. Cada ilha libera o próximo tier.

| Tier | Isca (nome provisório) | Libera em | Preço sugerido |
|---|---|---|---|
| 0 | Isca de Graça | Ilha 1 | $0 |
| 0.5 | Salsicha | Ilha 1 | $5 |
| 1 | Isca Iniciante | Ilha 2 | $8 |
| 2 | Isca Padrão | Ilha 3 | $15 |
| 3 | Isca Profissional | Ilha 4 | $50 |
| 4 | Isca Científica | Ilha 5 | $500 |

Chefes **não** usam isca da loja: cada um pede um **item de missão** estranho (piada central do gênero). Crie os seus.

### 2.6 Variantes raras (substitui o "Drip" original)
- Chance baixa (ex.: 1/150) de qualquer peixe vir como variante brilhante: **"Reluzente"**.
- Reluzentes valem pouco na loja, mas alimentam uma **máquina de prêmios** que dá skins de arma/barco/vara.
- Monetização saudável: skins são cosméticas; nada de vender poder.

### 2.7 Cozinha
- **Grelha** (liberada na Ilha 3; fogueira simples já na Ilha 1).
- Cozinhar: peixe cru → peixe assado (mais fome, cura vida).
- Receitas especiais para invocar chefes (opcional, dá conteúdo).

### 2.8 Barco e ilhas
- Barco encalhado no início. Ao vencer o primeiro chefe, troca o troféu dele com o NPC pela **chave do barco**.
- Cada missão concluída dá as **coordenadas** da próxima ilha.
- Upgrades de motor (velocidade) comprados na loja.

### 2.9 Morte
- Ao morrer: renasce no último ponto seguro da ilha e perde parte dos peixes não vendidos (não perde dinheiro nem equipamento). Simples e justo.

---

## 3. Mundo — as 5 ilhas

Espécies reais são livres. Chefes e itens de invocação abaixo são **originais**, sugestões para você trocar.

### Ilha 1 — Praia do Farol (tutorial)
- **Bioma:** praia, farol, poças de maré.
- **Vara:** Vara de Siri ($3). **Iscas:** de Graça, Salsicha.
- **Peixes:** caranguejo, camarão, siri, lagosta.
- **Chefe:** *Caranguejo-Ermitão Gigante* (usa um pneu velho como concha). Invocação: **Pneu Velho** achado na praia.
- **Recompensa:** concha → troca pela chave do barco.
- **Compras-chave:** Soco-inglês ($24), **Faca ($45)** — a compra mais importante do início.

### Ilha 2 — Lagoa da Floresta
- **Vara:** Vara de Pesca comum. **Isca:** Iniciante.
- **Peixes:** piranha (agressiva), cavala, peixe-agulha, traíra, tilápia, perca, peixe-porco.
- **Chefes:** *Pirarucu Ancião* (isca: **Chinelo Havaiano**) e *Cardume de Piranhas* com uma Rainha.
- **Arma liberada:** Escopeta.

### Ilha 3 — Ilha do Deserto
- **Isca:** Padrão. **Estação:** Grelha.
- **Peixes:** peixe-anjo, peixe-palhaço, bagre, ouriço, cavalo-marinho, salmão, peixe-cofre.
- **Chefes:** *Tubarão-Azul* (isca de chefe padrão) e *Baiacu Gigante* (isca: **Cenoura** → troque por algo seu, ex.: **Coxinha**). Solta veneno ao rolar.
- **Arma liberada:** Submetralhadora.

### Ilha 4 — Rochedo das Nuvens
- **Isca:** Profissional.
- **Peixes:** robalo, enguia, linguado, peixe-papagaio, peixe-voador, pargo, peixe-tigre.
- **Chefes:** *Atum-Rei* (isca de chefe profissional) e um chefe **aéreo** (ex.: *Fragata Gigante*), que usa o Atum-Rei como isca. Luta à distância.
- **Arma liberada:** Rifle de precisão.

### Ilha 5 — Ilha do Vulcão (final)
- **Isca:** Científica.
- **Peixes:** peixe-diabo, peixe-bolha, regaleco, peixe-pedra, peixe-anão (raro, vale muito).
- **Chefes:** *Tubarão-Duende*, *Baleia*, e o **final**: *Baleia Mutante de Magma* (isca: a Baleia).
- **Arma liberada:** Fuzil com acessórios.
- **Fim:** barco consertado → cutscene de volta para casa → modo pós-jogo (caça às Reluzentes, conquistas).

---

## 4. Conquistas (ideias originais)
- Primeira fisgada · Linha arrebentada 10 vezes · Vender um peixe de $10.000+ · Derrotar um chefe em 10 s · Terminar o jogo em 1 h · Derrotar o chefe final sem armas · Comer um chefe em vez de vender · Pegar 10 Reluzentes.

---

## 5. Arquitetura técnica (Roblox)

### 5.1 Estrutura de pastas (Script Sync)
```
MeuJogo/
├─ AGENTS.md
├─ GDD.md
├─ ServerScriptService/
│  ├─ Main.server.luau            -- inicia todos os serviços
│  └─ Services/
│     ├─ DataService.luau         -- save/load (ProfileStore)
│     ├─ HungerService.luau
│     ├─ FishingService.luau      -- sorteio, validação de captura
│     ├─ CreatureService.luau     -- peixe em terra, IA, vida
│     ├─ CombatService.luau       -- dano de armas (validado)
│     ├─ EconomyService.luau      -- venda, compra
│     ├─ QuestService.luau
│     └─ BossService.luau
├─ ReplicatedStorage/
│  ├─ Shared/
│  │  ├─ Config/
│  │  │  ├─ Fish.luau             -- tabela de espécies
│  │  │  ├─ Lures.luau
│  │  │  ├─ Rods.luau
│  │  │  ├─ Weapons.luau
│  │  │  ├─ Islands.luau
│  │  │  └─ Bosses.luau
│  │  ├─ Types.luau
│  │  └─ Util/
│  └─ Remotes/                    -- RemoteEvents/Functions (criados via MCP)
└─ StarterPlayerScripts/
   ├─ Main.local.luau
   └─ Controllers/
      ├─ FishingController.luau   -- minijogo, UI de tensão
      ├─ HungerController.luau    -- HUD
      ├─ CombatController.luau
      └─ ShopController.luau
```
UI (StarterGui) e ferramentas (StarterPack) ficam fora do Script Sync: crie via MCP ou à mão no Studio.

### 5.2 Formato de dados (exemplo)
```luau
-- ReplicatedStorage/Shared/Config/Fish.luau
export type FishDef = {
	id: string,
	name: string,
	island: number,
	lureTier: number,
	rarity: "Comum" | "Incomum" | "Raro" | "Épico",
	baseValue: number,
	weightRange: { number },  -- {min, max} em kg
	aggressive: boolean,
	health: number?,
	pullStrength: number,     -- 1..10, afeta o minijogo
}
```

### 5.3 Regras de segurança (anti-exploit)
- Servidor decide: espécie, peso, variante, dano, preço, recompensa.
- Todo RemoteEvent valida: tipo dos argumentos, distância do jogador, cooldown e estado ("estava pescando?").
- Nunca confie em valor vindo do cliente (dinheiro, dano, espécie).
- Salvar dados com **ProfileStore** (sessão travada, evita duplicação).

### 5.4 Multiplayer
- Servidores de até 4 jogadores (dá para testar 8 depois).
- Chefes escalam vida com o número de jogadores próximos.
- Progresso por jogador (ilhas liberadas, dinheiro, inventário).

---

## 6. Modelos 3D e arte — como fazer

Claude e Grok não geram modelos 3D bons. O fluxo recomendado:

1. **Greybox primeiro (via MCP):** os agentes montam as ilhas com Parts e Terrain só para testar gameplay. Arte só depois do jogo ser divertido.
2. **Props simples** (caixas, barris, boias, vara, grelha): Assistant do Studio com `/generate_mesh` (Cube 3D). Ative as APIs de EditableMesh/EditableImage em Game Settings → Security e **publique** os meshes como assets, senão somem ao reabrir.
3. **Peixes e chefes:** estilo **low-poly** (combina com o gênero e é leve). Opções: Meshy (plano grátis, exporta FBX/GLB), Blender, ou Creator Store.
4. **Creator Store:** modelos grátis ajudam, mas **inspecione scripts** dentro deles (procure `require(` com número e `loadstring`), pois é comum virem com backdoor.
5. **Animação de peixe:** use física (impulsos aleatórios para "pular") e tweens simples em vez de animações rigadas. Muito mais barato.
6. **Limites de importação:** texturas até 1024×1024; mantenha contagem de triângulos baixa.

---

## 7. Roadmap (milestones)

**M1 — Protótipo do loop (Ilha 1, sem arte)**
- Fome + mariscos · lançar/esperar/fisgar/puxar · peixe cai em terra · vender · loja com vara e faca · save básico.
- ✅ Critério: é divertido pescar 10 minutos com cubos?

**M2 — Combate e primeiro chefe**
- Peixe agressivo · soco/faca · chefe da Ilha 1 · troca por chave · barco navegável.

**M3 — Ilhas 2 e 3**
- Iscas por tier · armas de fogo · grelha · missões com coordenadas.

**M4 — Ilhas 4 e 5 + final**
- Chefe aéreo · cadeia de chefes · cutscene final.

**M5 — Polimento e lançamento**
- Arte final · Reluzentes + máquina de prêmios · conquistas (Badges) · UI mobile · game passes cosméticos.

---

## 8. Divisão de trabalho com IA

| Etapa | Quem | Como |
|---|---|---|
| Quebrar milestone em tarefas | Claude | Gera lista de tarefas pequenas (1 sistema por vez) |
| Implementar | Grok (Cursor) | Uma tarefa por chat; lê AGENTS.md + GDD.md |
| Montar objetos no Studio | Grok/Claude via MCP | Remotes, UI, ferramentas, greybox |
| Revisar | Claude | Revisa o diff focando segurança do servidor e bugs |
| Testar | Você + MCP | Playtest; peça ao agente para ler o Output |
| Commit | Você | `git commit` a cada tarefa que funcionar |
