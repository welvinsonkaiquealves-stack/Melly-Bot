# MELLY: MASTER ARCHITECTURE v1.0
## Diagnóstico, decisão por componente e desenho do cérebro

**Versão:** 1.0
**Data:** 12 de setembro de 2026
**Base analisada:** `omnimind-ai/OpenOmniBot`, commit `54aeae8`, clonado e lido nesta sessão
**Status:** análise. Nenhuma linha de código foi escrita.
**Premissa aceita:** o OpenOmniBot é matéria-prima, não arquitetura a ser preservada.

---

# 0. O QUE MUDOU DESDE A ANÁLISE ANTERIOR

Cinco descobertas novas mudam o plano. Duas delas eliminam trabalho que estava previsto.

## 0.1 Você já pode medir o desperdício hoje, sem escrever uma linha de código

**FATO VERIFICADO.** `baselib/src/main/java/cn/com/omnimind/baselib/llm/AiRequestLogStore.kt` guarda, para cada chamada de LLM, o corpo completo da requisição em `requestJson` e da resposta em `responseJson`, com modelo, URL, status e erro. Quem grava é `assists/.../http/HttpController.kt:440`. Quem lê é `AssistsCoreManager.listRecentAiRequestLogs`. E existe tela pronta: `ui/lib/features/my/pages/about/ai_request_logs_page.dart`.

Ou seja: abra o app, mande "oi" em modo agente, abra essa tela e o JSON exato que foi enviado para a DeepSeek está lá, com o array `tools` inteiro. Isso responde "por que essa mensagem custou 36k tokens" em minutos, hoje, e valida ou derruba todo o meu diagnóstico antes de qualquer implementação.

Limitação: `MAX_LOG_COUNT = 10`. A janela de evidência é de dez chamadas.

## 0.2 O uso de token já é persistido, inclusive o que foi cache

**FATO VERIFICADO.** `baselib/.../database/TokenUsageRecord.kt` é uma tabela Room com `conversationId`, `model`, `promptTokens`, `completionTokens`, `reasoningTokens`, `textTokens`, `cachedTokens`, `cacheCreationTokens`, `createdAt`. `AssistsCoreManager.getTokenUsageRecords` expõe isso ao Dart.

Consequência: a pergunta "o catálogo de ferramentas está sendo absorvido pelo cache da DeepSeek?" já tem resposta gravada no banco do seu aparelho. Se `cachedTokens` for alto, a prioridade muda: o vilão passa a ser resultado de ferramenta duplicado, não o catálogo.

## 0.3 O roteador já tem para onde mandar a decisão

**FATO VERIFICADO.** `ui/lib/services/agent_runtime_service.dart:1415` declara `promptSession(...)` com o parâmetro **opcional `conversationMode`**, enviado por prompt no `session/prompt`. Também aceita `approvalPolicy`, `sandboxPolicy`, `model` e `effort`.

Isso significa que rotear por mensagem não exige inventar protocolo novo nem alterar o modo durável da conversa. O canal já carrega a decisão.

**INVESTIGAÇÃO NECESSÁRIA:** confirmar que o lado Kotlin honra um `conversationMode` por prompt **sem** persistir isso como modo durável da conversa. Se ele persistir, rotear mensagem a mensagem corromperia o registro da conversa, e aí é preciso um campo novo em vez de reusar esse.

## 0.4 O padrão de escopo de ferramentas por perfil já existe no código

**FATO VERIFICADO.** `AgentToolCatalog` é uma interface com `toolsForModel`, `runtimeDescriptor`, `validateArguments` e `searchTools`. E `runtime/SubagentToolCatalogView.kt` é um decorador que filtra o catálogo por perfil e **recusa a chamada na validação de argumentos**, antes de executar, com mensagem do tipo "Tool 'x' is outside the explorer role permissions". Ele chega a restringir quais ações do `browser_use` um perfil pode usar.

Consequência direta: o item 11 do seu documento (escopo de ferramentas por tarefa) e a parte de permissões do item 3 (Agents) não são arquitetura nova. São **uma classe decoradora de umas 60 linhas** seguindo um padrão que já está lá, sem tocar no orquestrador, no registro nem nas definições.

## 0.5 O `AssistsCoreManager` não é o que o documento central descreve

**FATO VERIFICADO.** No upstream de hoje, `app/src/main/java/cn/com/omnimind/bot/manager/AssistsCoreManager.kt` tem **3.554 linhas, 137 funções e 112 imports**. E ele não é um núcleo de acessibilidade. É o manipulador do canal `AssistsCore`, um objeto faz-tudo que responde ao Flutter sobre: CRUD de conversas, mensagens paginadas, títulos, resumos, compactação, instalar e habilitar skills, memória longa e curta, quick logs, configuração de embeddings, rollup, tarefas agendadas, alarmes exatos, perfis de provedor, catálogo de cenas, voz, área de transferência, apps instalados, notificações, logs de runtime e registros de uso de token.

O documento central da Melly fala de 6.786 linhas, 206 métodos e acessibilidade. Ou o seu fork divergiu, ou aquele número veio de outra medição. De qualquer forma: **o risco arquitetural desse arquivo não é ser um monólito de acessibilidade, é ser o gargalo por onde toda a interface fala com o sistema.**

E a acessibilidade de verdade é pequena e limpa, o que é a melhor notícia estrutural do repositório:

- `accessibility/.../service/AssistsService.kt`: **102 linhas**, mais o listener e o XML de configuração do serviço;
- `androidgui/`: **990 linhas em quatro arquivos**, sendo `AndroidGuiPlatform.kt` (542), `AndroidGuiEnvironment.kt` (316), `AndroidGuiXml.kt` (96) e `AndroidGuiOverlayHost.kt` (36).

Ou seja, toda a camada que enxerga e toca a tela do Android cabe em pouco mais de mil linhas, em dois módulos separados do resto. A "grande refatoração do AssistsCoreManager" que o documento central temia nunca foi necessária, e o que ela imaginava proteger já está isolado.

O módulo `assists/` é outra coisa ainda: transporte HTTP (`controller/http/HttpController.kt`, 4.653 linhas), gravação de trajetória humana (`HumanTrajectoryLearningSession.kt`, `ManualTraceRecorder.kt`, `ManualRecordingEngine.kt`) e identidade OpenClaw.

---

# A. DIAGNÓSTICO ARQUITETURAL: COMO O SISTEMA REALMENTE FUNCIONA

## A.1 Não existe um sistema. Existem três, empilhados

```text
┌─ FLUTTER ─────────────────────────────────────────────────────────┐
│ ui/lib                                                            │
│  agent_runtime_service.dart   1.948  API em estilo ACP            │
│  agent_event_reducer.dart     7.013  ÚNICO reducer de eventos     │
│  agent_tool_call_parser.dart         parser de resultado (UI)     │
│  chat/services/*             11 arquivos de runtime de conversa    │
│  ConversationMode: normal | chat_only | openclaw | subagent | agent│
└───────────┬───────────────────────────────────────┬───────────────┘
            │ AgentRuntime / AgentRuntimeEvents     │ AssistsCore
            ▼                                       ▼
┌─ KOTLIN: runtime de agente ──────────┐  ┌─ KOTLIN: faz-tudo ──────┐
│ AgentRuntimeChannel       103         │  │ AssistsCoreManager 3.554│
│ AgentRuntimeManager     4.974         │  │ 137 funções:            │
│ LocalAcpRuntime         4.964         │  │ conversas, skills,      │
│ OmniAgentExecutor         554         │  │ memória, provedores,    │
│ AgentOrchestrator         929  ← loop │  │ alarmes, logs, tokens   │
│ AgentLlmClient          1.014         │  └─────────┬───────────────┘
│ AgentToolRegistry         357         │            │
│ AgentToolDefinitions  116.565 chars   │            │
│ AgentEventAdapter         201  ← dup  │            │
│ AgentContextBudget + Compactor        │            │
│ WorkspaceMemoryService 65.899 chars   │            │
│ 116 arquivos, 50.476 linhas no total  │            │
└───────────┬──────────────────────────┘            │
            │                                        │
            ▼                                        ▼
┌─ TRANSPORTE E CAPACIDADES ────────────────────────────────────────┐
│ assists/controller/http/HttpController.kt  4.653                  │
│   roteamento de cena, resolução de provedor, streaming,            │
│   e gravação do AiRequestLogStore                                  │
│ baselib/llm: OpenAiWireApi, DeepSeekProvider, ModelProviderConfig  │
│ baselib/database: Room (conversas, mensagens, token_usage_records) │
│ ReTerminal: Alpine embarcado via proot                             │
│ assists/: gravação de trajetória humana, OpenClaw identity          │
└───────────┬───────────────────────────────────────────────────────┘
            ▼
   https://api.deepseek.com   e/ou   processos Node ACP no Alpine
```

## A.2 Dois cérebros concorrentes, e você herdou os dois

**Cérebro 1, local, em Kotlin.** `OmniAgentExecutor` monta o turno, `AgentOrchestrator` roda o loop, `AgentToolRouter` executa ferramenta, `AgentLlmClient` fala com a API. É o agente chamado 小万 (Xiaowan).

**Cérebro 2, externo, em Node.** `app/src/main/assets/acp/agents.json` declara Claude Code, Codex, Kimi Code, OpenCode e o harness oficial da DeepSeek (`@deepseek-ai/dsh@0.1.5-rc.1`), instalados por `npm install -g` dentro do rootfs Alpine, com binário nativo `node-pty` para `linux-arm64`. `assets/acp/install/deepseek-harness.sh` chega a aplicar patch em arquivo de biblioteca de terceiro durante a instalação, para consertar o fluxo de login por navegador.

Os dois compartilham a mesma superfície ACP e o mesmo reducer. Isso é engenharia competente e é também o dobro de superfície para manter. Para a Melly, com DeepSeek e uso pessoal, o cérebro 2 é peso morto.

## A.3 O caminho de uma mensagem, com os números reais

```text
usuário digita "oi"
  │
  ├─ Dart decide nada. Envia session/prompt com o modo DURÁVEL da conversa
  │
  ├─ Kotlin resolve harness (AgentConversationModePolicy.resolveHarness)
  │
  ├─ OmniAgentExecutor.buildInitialMessages:
  │    system 1: AgentSystemPrompt.build   cerca de 4,5 KB
  │               inclui workspace, regras de artifact, regras de tool,
  │               raízes de skills, índice de skills instaladas, SOUL
  │    system 2: [time_context] cacheado por snapshot
  │    histórico completo
  │    mensagem do usuário
  │
  ├─ AgentToolRegistry monta o catálogo:
  │    44 ferramentas embutidas
  │    + ferramentas de plugin e MCP (sessão aberta em TODO turno não chat_only)
  │    ESTIMATIVA: 30 a 45 KB de JSON, 8 a 12 mil tokens
  │
  ├─ AgentOrchestrator.roundLoop@ while (true)     SEM TETO DE RODADAS
  │    calcula toolBudget (linha 132) e NÃO o expõe a ninguém
  │
  ├─ HttpAgentLlmClient.streamTurn -> HttpController -> DeepSeek
  │    HttpController grava requestJson completo no AiRequestLogStore
  │
  └─ resposta
```

No modo `chat_only` o mesmo caminho carrega: um `system` com o prompt de chat do usuário, histórico sem tool calls, zero ferramentas, zero sessão de plugin. A diferença de custo entre os dois caminhos é de mais de uma ordem de grandeza, e a escolha entre eles é um botão na interface.

## A.4 O que já está bem resolvido e não deve ser tocado

Registro honesto, porque reescrever isso seria desperdício:

- **divulgação progressiva de skills.** `OmniAgentExecutor.kt:226-229` força `resolvedSkills` a lista vazia de propósito, com comentário explicando que o corpo da skill deve chegar por `skills_read` para não invalidar o prefixo cacheado.
- **memória não injetada.** `promptIdentityContext` carrega só o SOUL, com `longTermMemory = ""` e `todayShortMemory = ""`.
- **orçamento e compactação.** `AgentContextBudget` estima tokens com heurística documentada, conta imagem como 1.200 tokens e soma `toolTokens`. `AgentConversationContextCompactor` reserva espaço de saída, corta em ponto seguro sem separar tool call do resultado, e faz offload de saída grande para arquivo.
- **cache de prompt.** `PromptCacheKeyStore.forConversation` e conteúdo de sistema marcado para cache.
- **abstração de LLM.** `AgentLlmClient` é uma interface com `streamTurn`. O contrato `LlmProvider` que a Melly queria criar existe em substância.
- **escopo e permissão por perfil.** `AgentToolCatalog` + `SubagentToolCatalogView`.
- **observabilidade bruta.** `AiRequestLogStore`, `TokenUsageRecord`, `RuntimeLogStore`, mais telas em Dart.

---

# B. FALHAS

Quatorze. As cinco primeiras são as que custam dinheiro.

| # | Falha | Gravidade | Evidência |
|---|---|---|---|
| B1 | Loop de agente sem teto de iterações | **P0** | `AgentOrchestrator.kt:136`, `while (true)`, nenhuma comparação contra máximo no arquivo |
| B2 | Catálogo completo de ferramentas em toda requisição | Alta | `AgentConversationModePolicy.kt:83-86`, dois estados apenas |
| B3 | JSON dentro de JSON com escape duplo | Alta | `AgentEventAdapter.kt:90-152`, `previewJson` e `rawResultJson` são Strings |
| B4 | Deduplicação por igualdade exata de string | Alta | `AgentEventAdapter.kt:178-181` |
| B5 | `prettyPrint = true` no caminho do modelo | Média-alta | `OmniAgentExecutor.kt:168`, `AgentOrchestrator.kt:60`, `AgentToolRouter.kt:32` |
| B6 | Sessão de plugin e MCP aberta em todo turno | Média | `OmniAgentExecutor.kt:234-241`, flag é `const val = true` |
| B7 | Nenhum roteamento automático | Alta (é a falha de produto) | nenhum classificador em nenhum lugar |
| B8 | `terminalOutput` é uma terceira cópia, sem nenhuma dedupe | Média | `AgentEventAdapter.kt:124` |
| B9 | `searchMemory` com `limit = Int.MAX_VALUE` por padrão | Média | `WorkspaceMemoryService.kt:507` |
| B10 | Índice de memória relê e re-hasheia o arquivo inteiro por consulta | Média | `MemoryIndex.kt`, `get(slug)` chama `list()`, que faz `file.readText()` |
| B11 | Janela de evidência de dez chamadas | Média | `AiRequestLogStore.kt:62`, `MAX_LOG_COUNT = 10` |
| B12 | Modo é durável por conversa, não por mensagem | Média (armadilha de design) | `ConversationMode` persistido; `promptSession` aceita override, comportamento a confirmar |
| B13 | Objeto faz-tudo na fronteira | Média | `AssistsCoreManager.kt`, 137 funções sem relação entre si |
| B14 | Texto de ferramenta só em chinês e inglês | Baixa-média | `AgentToolDefinitions.kt`, `englishStringMap` de 34 KB; não existe pt-BR |

---

# C. CAUSA DE CADA FALHA

Não basta dizer que está ruim. A causa muda a correção.

**C-B1. Por que o loop não tem teto.** O projeto tratou a terminação como propriedade do protocolo, não do orçamento. `AGENTS.md` diz que "um `session/prompt` canônico termina no `PromptResponse` oficial do ACP" e proíbe sintetizar evento terminal por conveniência. Levado ao extremo, isso virou "o loop acaba quando o modelo decide parar". Está coerente com o protocolo e errado como política de custo. A correção não é violar o ACP: é terminar o turno **com um resultado de erro legítimo** ao bater no teto, que é exatamente o que o código já faz em `terminated = true` nas linhas 289, 439 e 446.

**C-B2. Por que o catálogo vai inteiro.** Decisão explícita e justificada no comentário de `filterToolDefinitionsForConversationMode`: "um nome de modo não deve manter uma segunda política de ferramentas escrita à mão". Eles fugiram de uma lista paralela mal mantida e caíram no extremo oposto. A correção respeita a intenção: o escopo não vem de um nome de modo escrito à mão, vem de um objeto calculado por requisição, o que é diferente.

**C-B3 e C-B4. Por que existem duas e três cópias.** A mesma estrutura serve dois consumidores com necessidades opostas: o modelo quer o mínimo suficiente, a interface quer o máximo para desenhar cartões ricos e restaurar conversa. Ninguém separou os dois públicos, então o caminho do modelo recebeu o formato da interface. `previewJson` e `rawResultJson` nasceram Strings porque vêm de handlers que já serializavam, e aí embutir em outro JSON escapa tudo de novo. A dedupe por igualdade exata é a marca de quem percebeu o sintoma sem atacar a causa.

**C-B5. Por que `prettyPrint`.** Uma única instância de `Json` foi criada para depurar e acabou usada também para o fio. Causa: uma configuração servindo dois propósitos.

**C-B6. Por que plugin abre sempre.** `ENABLE_PLUGIN_RUNTIME` é `const val Boolean = true`, constante de compilação. Nunca houve intenção de desligar em runtime.

**C-B7. Por que não existe roteador.** Porque o produto foi desenhado como "agente geral". Um agente geral não pergunta se deve ser agente. Essa é a diferença conceitual entre o OpenOmniBot e a Melly, e é a razão pela qual a Melly não é o OpenOmniBot com mais ferramentas.

**C-B9 e C-B10. Por que a memória é um arquivo.** `MemoryIndex.kt` documenta a escolha: manter o layout físico de `MEMORY.md` "para evitar uma migração de disco" e ainda assim dar endereço por slug ao agente. Foi uma decisão consciente de compatibilidade. Custa reler o arquivo por consulta.

**C-B12. Por que o modo é durável.** Porque ele é parte da identidade da conversa no ciclo `Conversation -> Session -> Turn -> Item`, e a conversa precisa ser restaurável. A causa é boa; a armadilha é usar esse campo para uma decisão por mensagem.

**C-B13. Por que o faz-tudo existe.** Canal de plataforma é caro de criar, então cada recurso novo virou mais uma função no manipulador que já estava lá. Entropia normal de app híbrido.

**C-B14. Por que não tem português.** O produto é chinês, com inglês como segundo idioma.

---

# D. SOLUÇÃO ARQUITETURAL

## D.1 Um cérebro, não cinco

Acatando a sua diretriz: **não** haverá `ReasoningEngine`, `MemoryBrain`, `MetacognitionBrain`, `PlanningBrain` e `DecisionBrain`. Havia esse risco na minha proposta anterior e ele estava errado. Cinco cérebros criam cinco estados, cinco pontos de falha e a tentação de cada um chamar um LLM.

O desenho é: **um cérebro com políticas**. O cérebro é um objeto com um método de entrada, e as políticas são funções puras que ele consulta.

```text
MellyBrain.decide(mensagem, conversa, perfilDeAgente) -> RoutePlan
```

`RoutePlan` é um valor imutável:

```text
RoutePlan
  route          CHAT | EXECUTOR | LOCAL
  toolScope      lista de nomes de ferramenta permitidos
  memoryPlan     nenhuma | descoberta | descoberta+recuperação
  budget         tokensPorChamada, tokensPorTarefa, maxIteracoes, gastoRestante
  needsApproval  bool, derivado do risco das ferramentas do escopo
  reason         string legível, para o log
```

Tudo que decide é função pura sobre esse plano. Nada de estado escondido, nada de segunda máquina de estados. O ciclo de vida continua sendo o do ACP, e a Melly só escolhe **com que forma** entrar nele.

## D.2 As três camadas, mapeadas em mecanismos reais

| Camada | O que é, concretamente |
|---|---|
| **CHAT** | `RoutePlan(route: CHAT, toolScope: [], memoryPlan: nenhuma)`, enviado como `conversationMode: 'chat_only'` no `session/prompt`. Zero ferramenta, zero plugin, histórico limpo, prompt de sistema curto. Reusa o que já existe. |
| **EXECUTOR** | `RoutePlan(route: EXECUTOR, toolScope: [...])`. O Kotlin recebe o escopo e embrulha o catálogo em `MellyScopedCatalogView`, decorador irmão do `SubagentToolCatalogView`. O loop ganha teto de rodadas e de tokens vindos do `budget`. |
| **AGENTS** | Um `AgentProfile` em Dart que **produz** um `RoutePlan` parcial: escopo, orçamento, autonomia, instruções. O agente não executa nada, não tem ferramenta própria e não tem loop próprio. Ele configura a chamada. |

## D.3 As sete invariantes que sustentam o desenho

1. **Uma decisão por mensagem, antes de qualquer chamada cara.** Nenhum caminho envia prompt sem um `RoutePlan`.
2. **Um único ciclo de vida.** A Melly não cria reducer, stream, retry ou state machine. Ela escolhe parâmetros do ciclo existente.
3. **Dois públicos, dois formatos.** O modelo recebe resultado compacto. A interface e o histórico recebem o completo. Isso é explícito no tipo, não implícito.
4. **Orçamento é pré-condição, não relatório.** Nada executa sem verificar. O estouro decide entre reduzir, pedir autorização e parar.
5. **Escopo é fechado por padrão.** Ferramenta ausente do escopo é recusada na validação, antes de executar, com erro legível.
6. **Memória entrega fragmento, nunca corpo inteiro, nunca sem origem.**
7. **Toda execução é explicável.** Um `executionId` amarra rota, motivo, tokens por bloco, ferramentas, iterações, custo e resultado.

## D.4 O que a Melly deixa de ser

Ela deixa de ser um agente geral que sempre se comporta do jeito mais caro. Passa a ser um sistema que escolhe o comportamento mais barato que resolve o pedido. Essa frase é a arquitetura inteira.

---

# E. DECISÃO SOBRE CADA COMPONENTE DO OPENOMNIBOT

Legenda: **KEEP** mantém como está; **MODIFY** a ideia serve, a implementação muda; **REPLACE** contradiz a arquitetura da Melly; **REMOVE** sai do caminho; **ABSORB** a função existe, mas integrada em outro componente da Melly; **DEFER** interessante, não agora.

## E.1 Runtime e orquestração

| Componente | Decisão | Justificativa |
|---|---|---|
| `AgentRuntimeChannel` (103) | **KEEP** | 103 linhas de transporte puro, sem lógica. É a fronteira e ela está correta. Ganha campos novos no payload, não reescrita. |
| `AgentRuntimeManager` (4.974) | **MODIFY** | Faz duas coisas: gerencia sessão, modo e binding do agente local, e faz plumbing de ACP remoto. A primeira a Melly precisa. A segunda vira caminho morto. Modificar significa passar o `RoutePlan` adiante e desligar a resolução de harness externo, não refatorar. |
| `LocalAcpRuntime` (4.964) | **DEFER** | É a superfície ACP local completa, com `session/*`. Para uso pessoal com um provedor, é infraestrutura para um problema que a Melly não tem. Não apagar: desligar do caminho principal e reavaliar se um dia você quiser plugar um agente externo. |
| `OmniAgentExecutor` (554) | **MODIFY** | É o lugar certo e o tamanho certo. Recebe o `RoutePlan`, aplica escopo e orçamento, mantém a divulgação progressiva que já acerta. Aqui entram 3 dos 5 patches. |
| `AgentOrchestrator` (929) | **MODIFY** | O loop é bom, o desenho de rodada com replay e recuperação de overflow é sério. Falta teto. Duas condições no `while` e a exposição do `toolBudget` que ele já calcula. |
| `AgentLlmClient` / `HttpAgentLlmClient` (1.014) | **KEEP** | Interface `streamTurn` com streaming incremental, snapshot de reasoning, timeout de stream idle e emissão em fila. É exatamente o contrato `LlmProvider` que o documento central queria criar. Criar outro seria reescrever pior. |
| `XiaowanAcpConnection` (2.344) | **REMOVE do caminho** | Conexão com agente ACP externo. Sem função na Melly inicial. Desligar por configuração. |
| `AcpAgentCatalog`, `AcpAgentProfileStore`, `AcpHarness*`, `KimiCodeRuntime`, `RemoteCodexBridgeConnection` | **REMOVE do caminho** | Catálogo e adaptadores de Claude Code, Codex, Kimi, OpenCode. Nada disso serve a uma Melly pessoal com DeepSeek, e cada um traz npm, Node e rede. |
| `assets/acp/*` e `install/deepseek-harness.sh` | **REMOVE do caminho** | Instalação de pacotes npm e patch em biblioteca de terceiro dentro do aparelho. Superfície de risco alta, benefício zero para a Melly. |
| `SubagentDispatcher` (414) + `SubagentProfile` + `SubagentToolCatalogView` | **KEEP e ESTENDER** | É a peça mais valiosa do repositório para a Melly. O decorador de catálogo com validação pré-execução é literalmente o sistema de permissão de Agents que você especificou. A Melly escreve um irmão dele. |

## E.2 Ferramentas

| Componente | Decisão | Justificativa |
|---|---|---|
| `AgentToolRegistry` (357) | **MODIFY** | Constrói o catálogo por turno e já tem o ponto de corte na linha 157, onde chama a política de modo. Ganha um parâmetro de escopo. Mudança pequena, no lugar certo. |
| `AgentToolDefinitions` (116.565 chars, 44 ferramentas) | **KEEP o conteúdo, MODIFY a entrega** | Os schemas são bons e caros de reescrever. O problema nunca foi o conteúdo, foi mandar todos sempre. Não tocar nos schemas; filtrar na entrega. |
| `AgentToolRouter` + 17 handlers | **KEEP** | Execução de terminal, arquivo, browser, vlm, skills, memória, agenda, alarme, calendário, música, privilegiado. É o corpo da Melly e funciona. |
| `AgentEventAdapter.toolResultContent` (linhas 50-183) | **REPLACE** | Este é o único componente que eu substituo de verdade, e não por gosto: ele contradiz a invariante 3 da Melly, porque produz um formato que serve a interface e entrega ele ao modelo. É uma função de 130 linhas em um arquivo de 201. Substituição pequena, efeito grande. |
| `tools_search` / `ToolSearchHandler` | **DEFER** | Descoberta progressiva de ferramenta é uma boa ideia que o prompt atual manda o modelo ignorar. Com escopo por requisição funcionando, ela perde urgência. Reavaliar se o escopo errar demais. |
| `OmniPluginHost` / plugins / MCP | **DEFER** | Sem uso na Melly inicial e custa tokens e inicialização em todo turno. `ENABLE_PLUGIN_RUNTIME` para `false`. Um caractere. |
| `AgentConversationModePolicy` | **MODIFY** | A função de filtro está certa em intenção e insuficiente em capacidade. Passa a receber escopo, mantendo o comportamento atual quando o escopo é nulo, o que preserva compatibilidade. |

## E.3 Contexto e memória

| Componente | Decisão | Justificativa |
|---|---|---|
| `AgentContextBudget` | **KEEP e EXPOR** | Estimador de token honesto e documentado, já soma `toolTokens`. O Dart deve usar a mesma heurística para os números baterem. Falta expor a decomposição que ele já calcula. |
| `AgentConversationContextCompactor` (549) | **KEEP** | Reserva de saída, corte em ponto seguro, offload de saída grande. Reescrever isso em Dart seria repetir meses de aprendizado alheio. |
| `AgentConversationHistoryRepository` + `HistorySupport` (3.168 somados) | **KEEP** | Persistência e projeção de histórico com identidade de mensagem. Território minado, funciona, não mexer. |
| `AgentSystemPrompt` (193) | **MODIFY** | O conteúdo é bom e bem pensado. Mas ele descreve um agente geral com todas as capacidades. Na rota EXECUTOR com escopo restrito, metade das regras é irrelevante e paga token. Versão por escopo, com o núcleo compartilhado. |
| `WorkspaceMemoryService` (65.899 chars) | **ABSORB** | A funcionalidade tem de existir: SOUL, memória diária, memória longa, rollup, quick logs, embeddings opcionais. Mas a **estratégia de recuperação** passa a ser da Melly. O serviço continua sendo o armazenamento de markdown; o grafo da Melly passa a ser o índice que decide o que ler. |
| `MemoryIndex` / `LongTermMemoryIndex` | **REPLACE** | Relê e re-hasheia o arquivo inteiro por consulta, e o modelo de dados (uma linha por entrada) não sustenta nós, relações, fragmentos nem procedência. Substituído pelo esquema SQLite da entrega F. O `MEMORY.md` continua existindo como fonte importável. |
| `PlatformEmbeddingGateway` | **DEFER** | Embeddings existem e são opcionais. FTS5 primeiro. Ligar só quando a busca textual comprovadamente falhar. |
| `AgentPromptSettingsStore` (SOUL e prompt de chat) | **KEEP** | Dois textos editáveis pelo usuário nas configurações. Simples e correto. É onde a Melly define a personalidade e o idioma da resposta. |

## E.4 Skills, agenda e capacidades Android

| Componente | Decisão | Justificativa |
|---|---|---|
| `SkillIndexService`, `SkillLoader`, `skills_list`, `skills_read` | **KEEP** | Índice no prompt, corpo por ferramenta. É o padrão certo e já está implementado. |
| `SkillsToolHandler` payload | **MODIFY** | Devolve dois pares de caminho, referências carregadas, frontmatter e metadata, duas vezes. O modelo precisa do corpo e de um identificador. Enxugar o payload. |
| `assets/builtin_skills` (112 KB, 5 skills) | **MODIFY** | Três delas são sobre instalar agentes ACP e pets do Codex, que a Melly remove. `skill-creator` e `self-improving-agent` podem ficar. |
| `agentSkillSyncOfficialRepository` | **REMOVE do caminho** | Sincroniza repositório oficial de skills de terceiro. Rede, supply chain e nenhuma necessidade pessoal. |
| `WorkspaceScheduledTaskScheduler` (618) | **KEEP** | `AlarmManager.setExactAndAllowWhileIdle` com `RTC_WAKEUP`, reagendamento de todas as tarefas habilitadas, receiver de alarme. É a abordagem correta no Android e já lida com o caso difícil. |
| `AgentAlarmToolService`, `AgentCalendarToolService`, `AgentMusicPlaybackService` | **KEEP** | Capacidades reais, isoladas, sem custo quando fora do escopo. |
| `BrowserUseEngine` (3.813) | **KEEP com escopo** | Motor de navegador com controle de risco e download. Fora do escopo não custa nada. Dentro, é capacidade difícil de reconstruir. |
| `PrivilegedToolHandler` + Shizuku | **KEEP com confirmação obrigatória** | Casa com a sua decisão 3: ações sensíveis exigem confirmação explícita. O risco já é declarado por ferramenta. |
| `assists/` HumanTrajectoryLearning, ManualTraceRecorder, ManualRecordingEngine | **DEFER** | Gravação de trajetória humana é exatamente o modelo "humano define o script, executor determinístico repete" que a auditoria anterior recomendou para automação. Vale muito, e não é Fase 1. |
| `assists/openclaw/*` e `ConversationMode.openclaw` | **REMOVE do caminho** | Identidade de dispositivo e token para integração OpenClaw. Não serve a Melly. |
| `accessibility/AssistsService.kt` (102) | **KEEP** | O `AccessibilityService` inteiro tem 102 linhas. Não há nada a refatorar aqui, e ele é a base da automação híbrida que você decidiu. |
| `androidgui/` (990 em 4 arquivos) | **KEEP** | Toda a leitura e o toque de tela. Pequeno, isolado, difícil de reconstruir. É o corpo da automação. |
| `AssistsCoreManager` (3.554, 137 funções) | **MODIFY, sem refatorar** | Não reescrever. Ele é a porta por onde a interface fala com tudo. A Melly adiciona os handlers que precisa e ignora o resto. Se um dia incomodar, a saída é dividir o canal por assunto, não reorganizar o arquivo. |
| `ReTerminal` / Alpine via proot | **KEEP** | Terminal embarcado é diferencial real e caríssimo de construir. Mantém. O que sai é o uso dele para instalar agentes npm. |

## E.5 Lado Dart

| Componente | Decisão | Justificativa |
|---|---|---|
| `agent_event_reducer.dart` (7.013) | **KEEP** | Reducer único, exigido pelas regras do próprio projeto. Criar outro é o erro que o `AGENTS.md` proíbe em quatro parágrafos diferentes. |
| `agent_runtime_service.dart` (1.948) | **MODIFY** | Já aceita `conversationMode`, `approvalPolicy` e `model` por prompt. Ganha o `RoutePlan` no payload. |
| `agent_tool_call_parser.dart` | **KEEP** | Consome o formato completo para a interface. É justamente o segundo público da invariante 3, e por isso o formato completo precisa continuar existindo para ele. |
| `chat/services/*` (11 arquivos) | **MODIFY em um ponto** | O envio de mensagem passa a chamar o `MellyBrain` antes de `promptSession`. Um ponto de inserção, não onze. |
| `ConversationMode` (enum, 5 valores) | **MODIFY** | Remover `openclaw`. Manter `chat_only` e `agent` como as duas rotas reais da Melly, e não usar o campo durável para decisão por mensagem. |
| `ai_request_log_service.dart` + `ai_request_logs_page.dart` | **KEEP e ESTENDER** | Já mostra o JSON da requisição. A Melly acrescenta a decomposição por bloco e o motivo do roteamento. |
| `model_provider_config_service.dart` | **MODIFY** | Reduzir para DeepSeek mais um perfil manual. O catálogo de dezenas de provedores é manutenção sem uso. |
| Tela de agentes ACP, mercado de plugins | **REMOVE do caminho** | Interface para subsistemas removidos. |

## E.6 Observabilidade e transporte

| Componente | Decisão | Justificativa |
|---|---|---|
| `AiRequestLogStore` | **MODIFY** | Já guarda requestJson e responseJson completos. Subir `MAX_LOG_COUNT`, adicionar `executionId` e a decomposição por bloco. Base perfeita, janela pequena demais. |
| `TokenUsageRecord` (Room) | **MODIFY** | Já tem prompt, completion, reasoning, cached e cacheCreation por conversa. Falta `executionId`, rota e custo estimado. Migração de esquema simples. |
| `RuntimeLogStore` / `OmniLog` | **KEEP** | Log em arquivo com leitura no app. Exatamente o que a auditoria anterior pedia para um desenvolvedor sem PC. |
| `assists/.../HttpController` (4.653) | **KEEP** | Roteamento de cena, resolução de provedor, streaming e gravação de log. Grande, mas é transporte testado, e é onde o log de requisição nasce. |
| `baselib/llm/*` (OpenAiWireApi, DeepSeekProvider, ModelProviderConfigStore) | **KEEP** | Fala protocolo OpenAI, que é o que a DeepSeek usa. |
| `SceneVoicePlaybackManager`, cenas de voz | **DEFER** | Voz não é Fase 1, e já foi adiada. |
| Login WeChat, atualização forçada, `omnilink-control-plane`, telemetria de conta | **REMOVE** | Uso pessoal não tem conta, loja nem backend. |

## E.7 Resumo da auditoria

| Decisão | Quantos | Peso aproximado |
|---|---|---|
| KEEP | 24 componentes | a maior parte do corpo, do transporte e da persistência |
| MODIFY | 14 componentes | quase tudo pequeno e localizado |
| REPLACE | 2 componentes | `toolResultContent` e `MemoryIndex` |
| ABSORB | 1 componente | `WorkspaceMemoryService` como armazenamento, estratégia na Melly |
| REMOVE do caminho | 11 componentes | ACP externo, plugins, OpenClaw, conta, loja |
| DEFER | 8 componentes | embeddings, tools_search, trajetória humana, voz, MCP |

Duas substituições em 50 mil linhas. Isso não é preservar o OpenOmniBot por preguiça: é o resultado de olhar cada peça e descobrir que o problema quase nunca era a peça, era **o que era feito com ela**. As falhas B1 a B8 são todas de política, não de capacidade. A única falha de modelo de dados é a memória, e essa sim é substituída.

---

# F. O NOVO DESENHO DO CÉREBRO

## F.1 Fluxo completo, com marcação de onde o LLM é usado

```text
ENTRADA  mensagem do usuário
   │
   ▼
[1] NORMALIZAÇÃO                                        sem LLM
    trim, idioma, anexos, referência a mensagem anterior
   │
   ▼
[2] INTERPRETAÇÃO DETERMINÍSTICA                        sem LLM
    intent grosso: conversa | tarefa | comando local
    entidades candidatas, referências ("aquele projeto")
    ambiguidade, risco aparente, necessidade de memória
   │
   ├── comando local conhecido ("que horas são") ──────► [9] RESPOSTA
   │
   ▼
[3] MEMÓRIA: DESCOBERTA                    sem LLM, só se [2] pedir
    FTS5 em node.title + fragment
    devolve títulos e summaries de nós, teto 500 tokens
   │
   ▼
[4] MEMÓRIA: SELEÇÃO                                    sem LLM
    ranking por casamento textual, peso de aresta, recência
   │
   ▼
[5] DECISÃO: RoutePlan                                  sem LLM
    route, toolScope, memoryPlan, budget, needsApproval, reason
    verifica orçamento ANTES de gastar
   │
   ├── route CHAT ──────────────────────────────────────┐
   │                                                    │
   ▼ route EXECUTOR                                     │
[6] MEMÓRIA: RECUPERAÇÃO               sem LLM          │
    só os fragmentos escolhidos, com origem             │
   │                                                    │
   ▼                                                    │
[7] EXECUÇÃO                                            │
    ┌─────────────────────────────────────────┐         │
    │ rodada:                                 │         │
    │   chamada ao modelo        ◄── USA LLM  │         │
    │   tool_calls                            │         │
    │   validação de escopo      sem LLM      │         │
    │   confirmação se sensível  sem LLM      │         │
    │   execução da ferramenta   sem LLM      │         │
    │   normalização do resultado sem LLM     │         │
    │   invariantes:             sem LLM      │         │
    │     teto de rodadas                     │         │
    │     repetição de chamada                │         │
    │     tamanho do resultado                │         │
    │     orçamento consumido                 │         │
    │     mudança de estado                   │         │
    └──────────────┬──────────────────────────┘         │
                   │ gatilho duro de invariante         │
                   ▼                                    │
[8] METACOGNIÇÃO           ◄── USA LLM, e só aqui       │
    uma chamada, contexto reduzido de propósito:        │
    objetivo, ações tentadas, erros. Nada de saída bruta│
    devolve: mudar abordagem | perguntar | desistir     │
                   │                                    │
                   ▼                                    ▼
[9] RESPOSTA  ◄──────────── CHAT: uma chamada  ◄── USA LLM
   │
   ▼
[10] REGISTRO                                           sem LLM
     executionId, rota, motivo, tokens por bloco,
     ferramentas, iterações, custo, resultado
   │
   ▼
[11] ESCRITA DE MEMÓRIA                                 sem LLM
     entidades, casamento, arestas, procedência
```

## F.2 Onde o LLM entra, e só ali

Três lugares. Nenhum mais.

1. **CHAT**, uma chamada, prompt curto, sem ferramentas.
2. **Rodada do EXECUTOR**, uma chamada por rodada, com escopo restrito e teto de rodadas.
3. **Metacognição**, uma chamada por tarefa no máximo, e só por gatilho duro.

Tudo o mais é regra, índice, contador ou comparação. É isso que faz "oi" custar duzentos tokens.

## F.3 O que "oi" faz neste desenho

```text
[1] normaliza
[2] mensagem curta, sem verbo de ação, sem caminho, sem app,
    sem referência temporal, sem demonstrativo  →  conversa
[3] memoryPlan = nenhuma, não consulta nada
[5] RoutePlan(CHAT, toolScope: [], budget: chat)
[9] uma chamada: prompt de chat + histórico curto + "oi"
[10] registra
```

Nenhuma sessão de plugin, nenhum catálogo, nenhuma skill, nenhuma leitura de arquivo.

## F.4 O que "carrega aquele projeto" faz

```text
[2] demonstrativo "aquele" + substantivo "projeto"  →  referência,
    entidade candidata desconhecida
[3] descoberta: FTS5 por "projeto" em node.title
    encontra nós candidatos, devolve títulos e summaries (teto 500)
[4] seleção: se houver mais de um candidato plausível, [5] decide
    perguntar ao usuário qual, o que custa quase nada
[5] escolhido o nó, RoutePlan(EXECUTOR, escopo de leitura,
    memoryPlan: descoberta+recuperação)
[6] recupera os fragmentos do nó relevantes à tarefa (teto 2 a 4 mil)
[7] executa com escopo de leitura apenas
```

O que ele **não** faz: ler o projeto inteiro, chamar `file_read` em tudo, despejar 300 mil tokens.

---

# G. ESTRUTURA DE ARQUIVOS E MÓDULOS

## G.1 Dart, o cérebro

```text
ui/lib/melly/
├── brain/
│   ├── melly_brain.dart              o único cérebro; decide(...) -> RoutePlan
│   ├── route_plan.dart               valor imutável, sem comportamento
│   └── policies/                     funções puras, sem estado
│       ├── intent_policy.dart        conversa | tarefa | local
│       ├── entity_policy.dart        entidades e referências
│       ├── scope_policy.dart         verbo/entidade -> escopo de ferramentas
│       ├── memory_policy.dart        precisa de memória? qual estágio?
│       ├── risk_policy.dart          risco -> precisa de confirmação?
│       └── budget_policy.dart        cabe no orçamento? reduzir, pedir, parar
├── budget/
│   ├── budget_config.dart            tetos configuráveis, persistidos
│   ├── budget_ledger.dart            consumo corrente por tarefa e por dia
│   └── token_estimator.dart          MESMA heurística do AgentContextBudget
├── memory/
│   ├── graph_schema.dart             DDL e migrações
│   ├── graph_store.dart              node, edge, fragment, source
│   ├── graph_discovery.dart          estágio 1, com teto
│   ├── graph_selection.dart          estágio 2, ranking
│   ├── graph_retrieval.dart          estágio 3, fragmentos
│   └── memory_writer.dart            escrita conectada, com procedência
├── agents/
│   ├── agent_profile.dart            identidade, objetivo, escopo, orçamento
│   ├── agent_registry.dart           perfis persistidos
│   └── agent_state.dart              IDLE..ERROR, só dados
├── meta/
│   └── invariants.dart               os cinco gatilhos determinísticos
├── log/
│   ├── execution_log.dart            executionId e os campos da seção 17
│   └── execution_log_store.dart      SQLite local
└── executor/
    └── melly_executor.dart           contrato sobre o canal existente
```

Regras da pasta: nada em `melly/` importa widget. Tudo é testável com `flutter test`. `melly_brain.dart` é o único arquivo com orquestração; o resto são funções e dados.

## G.2 Kotlin, o corpo

Nenhum módulo novo. Arquivos novos e mudanças pontuais:

```text
app/src/main/java/cn/com/omnimind/bot/
├── agent/
│   ├── melly/                                        (novo)
│   │   ├── MellyRoutePlan.kt            espelho do valor Dart
│   │   ├── MellyScopedCatalogView.kt    irmão do SubagentToolCatalogView
│   │   ├── ToolResultNormalizer.kt      substitui toolResultContent
│   │   └── ExecutionTelemetry.kt        decomposição por bloco
│   ├── runtime/OmniAgentExecutor.kt     MODIFY: recebe o plano
│   ├── runtime/AgentOrchestrator.kt     MODIFY: teto de rodadas, telemetria
│   ├── runtime/AgentEventAdapter.kt     MODIFY: duas saídas
│   ├── tool/AgentToolRegistry.kt        MODIFY: aceita escopo
│   ├── AgentConversationModePolicy.kt   MODIFY: aceita escopo
│   └── runtime/AgentRuntimeContracts.kt MODIFY: flag de plugin para false
└── ui/channel/AgentRuntimeChannel.kt    MODIFY: plano entra, telemetria sai
```

---

# H. PLANO DE IMPLEMENTAÇÃO

Nove etapas. Cada uma tem um critério verificável e nenhuma depende da seguinte para ser útil.

## Etapa 0. Medir, sem escrever código

Mandar, no app atual: "oi" em modo agente, "oi" em modo chat, "abra o navegador", e o caso que gerou 200 mil tokens. Depois abrir a tela de logs de requisição e anotar, para cada um: tamanho do `requestJson`, tamanho do array `tools`, `promptTokens` e `cachedTokens` do registro de uso.

**Critério:** uma tabela com quatro linhas e cinco colunas. Com ela, a ordem das etapas 2 e 3 pode mudar, e a mudança será baseada em evidência.

## Etapa 1. P0: loop seguro

Teto de rodadas, teto de tokens por tarefa, detecção de chamada repetida, timeout e kill switch, tudo lido de configuração. Ao bater no teto, termina o turno pelo caminho de erro que já existe.

**Critério:** teste unitário em Kotlin com um cliente de LLM falso que sempre pede a mesma ferramenta, provando que o loop para na rodada N e que o usuário recebe mensagem clara.

## Etapa 2. Instrumentação completa

`executionId` por turno. Decomposição de tokens por bloco, usando o `toolBudget` que o orquestrador já calcula. `MAX_LOG_COUNT` maior. Campos novos em `TokenUsageRecord`. Tela que mostra o formato da seção 17.

**Critério:** para um turno qualquer, a soma dos blocos bate com o total reportado pelo provedor com diferença abaixo de 5%.

## Etapa 3. Correções comprovadas

Nesta ordem, e só o que a Etapa 0 confirmar: `prettyPrint` desligado no caminho do fio; `ENABLE_PLUGIN_RUNTIME` para `false`; `ToolResultNormalizer` com duas saídas; payload de `skills_read` enxuto; `searchMemory` com limite padrão.

**Critério:** o mesmo pedido da Etapa 0 repetido, com redução medida e registrada. Se a redução não aparecer, a causa estava em outro lugar e o diagnóstico se corrige com dado.

## Etapa 4. Escopo de ferramentas

`MellyScopedCatalogView`, escopo no `RoutePlan`, parâmetro em `AgentToolRegistry` e na política de modo, com comportamento atual preservado quando o escopo é nulo.

**Critério:** um teste prova que, com escopo `[file_read, file_list]`, o catálogo enviado tem duas ferramentas e uma chamada a `terminal_execute` é recusada na validação, sem executar.

## Etapa 5. O cérebro, versão mínima

`MellyBrain`, `RoutePlan`, `intent_policy`, `scope_policy`, `budget_policy`. O envio de mensagem em Dart passa a chamar o cérebro e a mandar o plano.

**Critério:** os testes 1, 2 e 3 da sua seção 22 passam, com números no log de execução. E uma suíte de umas 40 mensagens de exemplo classificadas corretamente, rodando no CI.

## Etapa 6. Memória seletiva

Esquema do grafo, descoberta, seleção, recuperação com teto, escrita conectada com procedência. Importação do `MEMORY.md` opcional e separada.

**Critério:** testes 4 e 5 passam. Um fragmento é recuperado por busca em menos de 100 ms com mil fragmentos. Nenhum estágio entrega mais tokens que o teto.

## Etapa 7. Agents

`AgentProfile` produzindo `RoutePlan` parcial, registro de perfis, estado.

**Critério:** teste 7 passa. Um agente com escopo de leitura não consegue escrever arquivo, e a recusa aparece no log com o motivo.

## Etapa 8. Metacognição por gatilho

As cinco invariantes, e uma única chamada de LLM quando um gatilho duro dispara.

**Critério:** teste 6 passa. Em uma tarefa que falha de propósito, o log mostra o gatilho, uma chamada de metacognição e uma mudança de abordagem ou uma desistência explicada.

## Etapa 9. Visual

Grafo de memória e agentes 2D, lendo estado real.

**Critério:** o grafo mostra os mesmos nós que uma consulta direta ao banco.

---

# I. RISCOS

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|---|
| I1 | Trocar o formato do resultado quebra a restauração de conversa | Média | Alto | Normalizador com duas saídas; a completa continua indo para interface e histórico. Confirmar o consumidor antes de mexer: `agent_tool_call_parser.dart:72` avisa que evento vivo e restaurado compartilham o parser |
| I2 | Criar um segundo caminho de conversa viola as regras do projeto | Alta se o chat for direto do Dart | Alto | O cérebro decide **antes** e usa a superfície existente. Nenhum reducer, stream, retry ou state machine novo |
| I3 | `conversationMode` por prompt pode ser persistido como modo durável | Média | Alto | Verificar em `AgentRuntimeManager` antes da Etapa 5. Se persistir, usar campo novo no payload |
| I4 | Teto de rodadas interrompe tarefa legítima | Média | Médio | Teto generoso no começo, medido, ajustado com dado. Mensagem clara e opção de continuar |
| I5 | Classificador erra e manda tarefa para o CHAT | Certa | Baixo se o padrão em dúvida for perguntar | Em ambiguidade, nunca executar. Registrar cada decisão e o que a execução precisou |
| I6 | Desligar o runtime ACP externo quebra o caminho local | Média | Médio | O modo normal já resolve para o agente local por padrão. Desligar por configuração, não apagar, e testar |
| I7 | Divergência entre o seu fork e o upstream | Alta | Médio | Nenhum patch por número de linha. Sempre por conteúdo. Conferir cada ponto antes de editar |
| I8 | Migração de memória perde dados | Média | Alto | Grafo nasce ao lado. `MEMORY.md` continua intacto. Importação é etapa separada e opcional |
| I9 | Complexidade do próprio cérebro | Média | Médio | Um cérebro, políticas puras, nenhum estado escondido. Se `melly_brain.dart` passar de umas 300 linhas, algo virou motor escondido |
| I10 | Custo de API durante o desenvolvimento | Média | Médio | Cliente de LLM falso para toda a suíte de testes. Nenhum teste do CI toca a API |
| I11 | Segurança: injeção de prompt | Média | Alto | Conteúdo de ferramenta e de arquivo entra marcado como dado, nunca com status de instrução. Confirmação de ação sensível nunca é preenchida pelo modelo |
| I12 | Licença AGPL-3.0 com build público | Baixa enquanto for pessoal | Médio | Repositório privado, ou aceitar que o fork é AGPL e público. Distribuir APK para terceiro aciona as obrigações |
| I13 | Idioma: textos de ferramenta só em zh e en | Certa | Baixo | Manter o texto voltado ao modelo em inglês, que já existe, e usar português no SOUL, no prompt de chat e na interface. Não traduzir 34 KB de schema |
| I14 | Regressão silenciosa em 50 mil linhas não lidas | Alta | Médio | Cada etapa com teste próprio; `flutter analyze` e `gradlew test` no CI; nenhuma etapa mexe em mais de três arquivos Kotlin |

---

# CONCLUSÃO

O que a análise do código mudou em relação ao que você supunha:

**As falhas são de política, não de capacidade.** Sete das oito principais se resolvem com configuração, uma condição no loop e uma função reescrita. O OpenOmniBot não está mal construído; ele foi construído para ser um agente geral, e um agente geral não pergunta se deveria ser agente. A Melly pergunta. É essa a diferença, e ela custa duas substituições em 50 mil linhas.

**Duas peças que você ia construir já existem.** O padrão de escopo e permissão por perfil (`AgentToolCatalog` mais `SubagentToolCatalogView`) e a observabilidade bruta (`AiRequestLogStore` com o requestJson completo, `TokenUsageRecord` com tokens de cache). Isso economiza a parte mais chata do trabalho.

**E um medo do documento central não existia.** A camada de acessibilidade não é um monólito de 6.786 linhas a ser decomposto com cuidado: são 102 linhas de `AccessibilityService` mais 990 linhas de leitura e toque de tela, em dois módulos já isolados do resto. Toda a fase que o roadmap original reservava para domar esse arquivo pode ser apagada.

**Você pode validar meu diagnóstico inteiro hoje, de graça.** A Etapa 0 não escreve código: são quatro mensagens no app e uma tela que já está lá.

**A memória é a única coisa que substituo de verdade.** Um arquivo markdown com uma linha por entrada, relido e re-hasheado a cada consulta, não sustenta nós, relações, fragmentos e procedência. O resto do que a Melly precisa de memória já existe como armazenamento, e o grafo entra como o índice que decide o que ler.

Nada foi implementado. O que eu preciso de você para começar a Etapa 1:

1. Aprovação desta tabela de decisões, ou correção dos pontos em que você discorda.
2. Os resultados da Etapa 0, ou autorização para eu seguir com base nas estimativas.
3. A URL do seu fork, se ele divergiu do upstream `54aeae8`.
4. Valores iniciais dos tetos, ou permissão para eu propor um conjunto e você ajustar depois de ver o log.

---

**FIM: MASTER ARCHITECTURE v1.0**
