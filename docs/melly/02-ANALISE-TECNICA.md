# MELLY: ANÁLISE TÉCNICA DO OPENOMNIBOT E ARQUITETURA DO CÉREBRO
## Entregas A a G. Nenhuma linha de código foi escrita.

**Versão:** 0.2
**Data:** 12 de setembro de 2026
**Base analisada:** `omnimind-ai/OpenOmniBot`, clone raso do branch principal, feito hoje
**Decisões incorporadas:** uso pessoal, APK por GitHub Actions, automação híbrida, cérebro em Dart, Kotlin como camada de capacidade, três casos de uso, DeepSeek único, limites configuráveis, Rust fora

---

# 0. COMO LER, E O QUE MUDOU DEPOIS DE ABRIR O CÓDIGO

## 0.1 Classificação

- **FATO VERIFICADO**: eu abri o arquivo e li a linha. Cito caminho e número de linha.
- **ESTIMATIVA**: cálculo meu a partir de dados reais do repositório, com margem declarada.
- **HIPÓTESE**: plausível, não verificado.
- **CONFLITO**: o documento da Melly assume uma coisa e o código mostra outra.
- **RECOMENDAÇÃO**, **RISCO**, **INVESTIGAÇÃO NECESSÁRIA**, **TESTE NECESSÁRIO**: como na auditoria anterior.

## 0.2 Aviso sobre o que eu analisei

Clonei `omnimind-ai/OpenOmniBot` hoje, com `--depth 1`. Analisei o upstream, não o seu fork. Se o seu fork já divergiu, alguns números mudam, mas a estrutura e os mecanismos de desperdício que descrevo estão no código base que você herdou.

O repositório tem 2.428 arquivos versionados. O pacote do agente em Kotlin (`app/src/main/java/cn/com/omnimind/bot/agent`) tem 116 arquivos e 50.476 linhas. Não li as 50 mil linhas. Li os pontos de entrada, o montador de prompt, o orquestrador, o adaptador de resultado de ferramenta, o registro de ferramentas, a política de modo, o serviço de memória e a fronteira Dart/Kotlin, que é onde estão as respostas às suas dez perguntas.

## 0.3 Três coisas que mudam o plano antes de qualquer outra

**CONFLITO 1: o "cérebro" hoje não é nem Dart nem um wrapper fino de Kotlin. São dois cérebros paralelos.**

Existe um agente completo escrito em Kotlin dentro do app, com loop, ferramentas, memória, compactação de contexto e orçamento de tokens. E existe, em paralelo, um runtime de agentes externos que roda processos Node dentro do ambiente Alpine embarcado, falando ACP (Agent Client Protocol) por JSON-RPC. `app/src/main/assets/acp/agents.json` lista Claude Code, Codex, Kimi Code, OpenCode e o harness oficial da DeepSeek (`@deepseek-ai/dsh`), todos instalados por npm no rootfs. O agente embutido chama-se 小万 (Xiaowan) e é o caminho Kotlin.

Consequência direta: "cérebro em Dart" não é reorganizar, é decidir o que fazer com 50 mil linhas de agente Kotlin que já funcionam. Trato isso na entrega C com duas alternativas honestas.

**CONFLITO 2: já existe um modo de chat sem ferramentas, mas ele é um botão, não um roteador.**

`AgentConversationModePolicy.CHAT_ONLY_MODE` existe e, quando ativo, `filterToolDefinitionsForConversationMode` devolve lista vazia de ferramentas (`AgentConversationModePolicy.kt:83-85`). O caminho de chat barato que você quer para "oi" já está implementado. O que não existe é alguém decidindo automaticamente que "oi" deveria usá-lo. A escolha é manual, feita pelo usuário na interface.

Isso é excelente notícia: o caso de uso 1 da Melly (CHAT barato) é em grande parte uma decisão de roteamento, não uma reescrita.

**CONFLITO 3: o projeto tem regras arquiteturais escritas que proíbem exatamente o padrão mais tentador.**

`AGENTS.md`, linhas 152 a 238, estabelece como regra permanente que existe um único reducer, um único protocolo e um único ciclo de vida `Conversation -> ACP Session -> Turn -> Item`, e proíbe explicitamente criar um segundo protocolo de stream, um segundo reducer, uma segunda máquina de estados ou um caminho paralelo de retry para consertar um sintoma. O reducer Dart tem 7.013 linhas (`ui/lib/services/agent_event_reducer.dart`).

Essas regras existem porque alguém já apanhou desse problema. Se a Melly adicionar um segundo caminho de execução sem respeitar esse ciclo, o resultado previsível é mensagem duplicada, cartão de ferramenta fantasma e histórico corrompido. A arquitetura que eu recomendo na entrega C respeita essa regra em vez de brigar com ela.

---

# A. DIAGNÓSTICO DO OPENOMNIBOT ATUAL

## A.1 O fluxo real, de ponta a ponta

**FATO VERIFICADO.** Caminho de uma mensagem no modo agente:

```text
Flutter (ui/lib)
  ui/lib/services/agent_runtime_service.dart        1.948 linhas, API em estilo ACP
        │  MethodChannel  "cn.com.omnimind.bot/AgentRuntime"
        │  EventChannel   "cn.com.omnimind.bot/AgentRuntimeEvents"
        ▼
Kotlin
  ui/channel/AgentRuntimeChannel.kt                 103 linhas, só transporte
        ▼
  agent/runtime/AgentRuntimeManager.kt              4.974 linhas, sessão, modo, binding
        ▼
  agent/runtime/LocalAcpRuntime.kt                  4.964 linhas, superfície ACP local
        ▼
  agent/runtime/OmniAgentExecutor.kt                554 linhas, monta o turno
        │   ├── AgentSystemPrompt.build(...)        193 linhas, prompt de sistema
        │   ├── AgentWorkspaceManager               workspace, artifacts, offload
        │   ├── WorkspaceMemoryService              65 KB, memória em markdown
        │   ├── SkillIndexService / SkillLoader     índice e corpo de skills
        │   ├── AgentToolRegistry                   catálogo de ferramentas do turno
        │   └── OmniPluginHost.openSession()        plugins e MCP
        ▼
  agent/runtime/AgentOrchestrator.kt                929 linhas, o loop
        │   roundLoop: modelo -> tool_calls -> executa -> resultado -> modelo
        ▼
  agent/tool/AgentToolRouter.kt  ->  handlers/      terminal, file, browser, vlm,
                                                    skills, memory, schedule, alarm,
                                                    calendar, music, privileged, subagent
        ▼
  agent/llm/AgentLlmClient.kt (HttpAgentLlmClient)  1.014 linhas
        ▼
  baselib/llm/OpenAiWireApi.kt, DeepSeekProvider.kt
        ▼
  https://api.deepseek.com   (protocolo OpenAI, /chat/completions)
```

Em paralelo, para agentes externos:

```text
AgentRuntimeManager
   └── XiaowanAcpConnection.kt (2.344)  /  AcpAgentCatalog  /  AcpAgentProfileStore
          └── processo Node dentro do Alpine embarcado (ReTerminal)
                 claude-agent-acp | codex-acp | kimi acp | opencode acp | @deepseek-ai/dsh
```

**FATO VERIFICADO.** `app/src/main/assets/acp/install/deepseek-harness.sh` instala `@deepseek-ai/dsh@0.1.5-rc.1` por npm dentro do container, incluindo `node-pty` com binário nativo para `linux-arm64`, e chega a aplicar patch em arquivo de biblioteca de terceiro em tempo de instalação. Isso é um subsistema inteiro que a Melly não precisa e que você pode desligar.

## A.2 Onde cada coisa que você pediu está

| O que você pediu para localizar | Onde está |
|---|---|
| Entrada do Chat | `AgentRuntimeChannel.kt` (canal) e `AgentRuntimeManager.kt:2403` (resolve o modo); modo `chat_only` em `AgentConversationModePolicy.kt` |
| Entrada do Executor | `OmniAgentExecutor.processUserMessage(...)` em `runtime/OmniAgentExecutor.kt:172` |
| Carregamento de Skills | `SkillIndexService.listInstalledSkills()` chamado em `OmniAgentExecutor.kt:216`; corpo via ferramenta `skills_read` em `tool/handlers/SkillsToolHandler.kt:108`; embutidas em `app/src/main/assets/builtin_skills/` (112 KB, 5 skills) |
| SOUL e contexto | `WorkspaceMemoryService.readSoul()` em `OmniAgentExecutor.kt:205-209`, injetado por `AgentSystemPrompt.kt:64-80` |
| Memória | `agent/workspace/memory/WorkspaceMemoryService.kt` (65.899 bytes), `MemoryIndex.kt` (índice de longo prazo por slug), `PlatformEmbeddingGateway.kt` (embeddings opcionais) |
| Construção do prompt | `OmniAgentExecutor.buildInitialMessages(...)` em `:381-439` |
| DeepSeek | `baselib/src/main/java/cn/com/omnimind/baselib/llm/DeepSeekProvider.kt` e `OpenAiWireApi.kt` |
| Tool calling | `AgentToolDefinitions.kt` (116.565 caracteres, 44 ferramentas), `AgentToolRegistry.kt`, `AgentToolRouter.kt` |
| Retorno de ferramentas | `runtime/AgentEventAdapter.kt:50-183`, função `toolResultContent` |
| Duplicação de resultados | mesma função, campos `summary`, `previewJson`, `rawResultJson`, `terminalOutput`, `artifacts` |
| Agent Loop existente | `runtime/AgentOrchestrator.kt`, `roundLoop@ while (true)` na linha 136 |
| Scheduler | `agent/workspace/schedule/WorkspaceScheduledTaskScheduler.kt` (618) + `tool/alarm/AgentAlarmReceiver.kt` + AlarmManager |
| AssistsCoreManager | módulo `assists/`, apenas 26 arquivos no total; confirmando a auditoria: raio de contato pequeno |
| Fronteira Dart/Kotlin | dois canais nomeados, `AgentRuntime` e `AgentRuntimeEvents`, mais 23 outros canais em `ui/channel/` |

## A.3 O que o turno carrega hoje, em ordem

**FATO VERIFICADO**, de `OmniAgentExecutor.buildInitialMessages`, linhas 396 a 439:

No modo `chat_only`:

1. um `system` com o prompt de chat que o usuário escreveu nas configurações, e nada mais;
2. histórico filtrado por `filterChatOnlyHistoryMessages`, que remove tool calls e resultados antigos;
3. a mensagem do usuário;
4. zero ferramentas, zero sessão de plugin (linha 234 evita abrir a sessão de plugin nesse modo).

Fora do `chat_only`:

1. um `system` com `AgentSystemPrompt.build`, que inclui caminhos do workspace, regras de arquivo e artifacts, regras de uso de ferramenta, raízes de skills, o índice de skills instaladas e o SOUL;
2. um segundo `system` com `[time_context]`, com data grossa, dia da semana e fuso, cacheado por snapshot;
3. histórico completo;
4. mensagem do usuário;
5. **o catálogo completo de ferramentas**, construído por `AgentToolRegistry` com as 44 embutidas mais as de plugin e MCP.

Duas decisões boas que já estão lá e que a Melly deve preservar:

- **corpo de skill não é injetado.** O comentário em `OmniAgentExecutor.kt:226-229` chama isso de "Pi-style progressive disclosure": `resolvedSkills` é forçado a lista vazia e o corpo só chega por `skills_read`, virando resultado de ferramenta replayável em vez de um bloco volátil que invalida o prefixo cacheado.
- **memória não é injetada automaticamente.** `promptIdentityContext` carrega só o SOUL, com `longTermMemory = ""` e `todayShortMemory = ""` (linhas 204 a 210). O prompt de sistema instrui o modelo a buscar memória por ferramenta antes de responder sobre o passado.

Ou seja: as duas otimizações que pareciam ser a grande sacada da Melly já existem no código. O desperdício está em outro lugar.

---

# B. DIAGNÓSTICO DO DESPERDÍCIO: POR QUE "oi" CUSTA CARO

Oito causas. As quatro primeiras explicam a maior parte da conta.

## B.1 O catálogo inteiro de ferramentas viaja em toda requisição

**FATO VERIFICADO.** `AgentConversationModePolicy.filterToolDefinitionsForConversationMode` (linhas 75 a 87) tem exatamente dois comportamentos: se o modo é `chat_only`, devolve `emptyList()`; em qualquer outro caso, devolve `definitions` sem filtrar nada. O comentário no próprio código explica a intenção: "um nome de modo não deve manter uma segunda política de ferramentas escrita à mão".

A intenção é defensável. O efeito colateral é que não existe nenhum nível intermediário entre "todas as 44 ferramentas mais plugins mais MCP" e "nenhuma ferramenta".

E o prompt de sistema confirma que isso é deliberado, na linha 164 da versão em inglês: "The current request already includes the complete schemas for installed capabilities. Call the matching schema directly; do not wait for discovery". Existe uma ferramenta `tools_search` declarada no arquivo (linha 453), sinal de que houve uma fase de descoberta progressiva, mas o prompt atual manda o modelo não esperar por ela.

**Tamanho.** `AgentToolDefinitions.kt` tem 116.565 caracteres. Desses, 34.423 são o mapa de tradução para inglês e 82.141 são os construtores de schema. Somando apenas os literais de string dentro dos construtores: 25.436 caracteres, em 1.792 strings, das quais 4.673 caracteres são ideogramas. O mapa inglês soma outros 25.004 caracteres.

**ESTIMATIVA.** O JSON serializado das 44 ferramentas, com chaves, aninhamento e schemas de parâmetro, fica entre 30 KB e 45 KB. Em tokens, entre 8 mil e 12 mil para o locale inglês, e provavelmente entre 5 mil e 9 mil em chinês, que é mais denso por caractere. Margem grande porque não rodei o app.

**E aqui está a melhor notícia desta análise.** O número exato já é calculado pelo próprio código, e ninguém o mostra. `AgentOrchestrator.kt:132-133`:

```kotlin
val toolBudget = AgentContextBudget.textTokens(json.encodeToString(toolRegistry.toolsForModel))
    .coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
```

Essa variável é exatamente o custo em tokens do catálogo enviado no turno, com o mesmo estimador usado no resto do sistema. E a linha 128 já loga `request_tools=${toolRegistry.toolsForModel.size}`, a quantidade de ferramentas. Ou seja, a primeira métrica da entrega F não precisa ser implementada, precisa ser **exposta**: uma linha de log e um campo no evento do canal.

Esse bloco é enviado quando você digita "oi" em modo agente. Ele não depende do que você escreveu.

## B.2 A sessão de plugin e MCP abre em toda conversa que não é chat_only

**FATO VERIFICADO.** `OmniAgentExecutor.kt:234-241`: se `ENABLE_PLUGIN_RUNTIME` está ligado e o modo não é `chat_only`, `OmniPluginHost.get(context).openSession()` é chamado, e `activePluginSession?.toolDefinitions` entra no registro de ferramentas (linha 247). Cada servidor MCP conectado soma seus próprios schemas ao bloco do item B.1.

Custo em tokens além do catálogo base, mais custo de inicialização por turno.

## B.3 `prettyPrint = true` no caminho que vai para o modelo

**FATO VERIFICADO.** A instância de `Json` com `prettyPrint = true` aparece em cinco lugares, e três deles estão no caminho do fio:

- `runtime/OmniAgentExecutor.kt:168`, e essa mesma instância é passada para `AgentEventAdapter(json)` na linha 270;
- `runtime/AgentOrchestrator.kt:60`;
- `tool/AgentToolRouter.kt:32`, que alimenta o `SharedHelper` usado por todos os handlers;
- além de `browser/BrowserUseEngine.kt:415` e `plugin/sandbox/SandboxPluginPool.kt:33`.

Resultado: todo JSON de resultado de ferramenta é serializado com indentação e quebra de linha, e essas quebras e espaços viajam como tokens. Em JSON aninhado com muitas chaves, a indentação chega a somar de 20% a 30% do texto.

Isso é uma linha de código por arquivo. É a correção de melhor relação entre esforço e retorno de toda esta análise.

## B.4 JSON dentro de JSON: o mecanismo do 14 KB que virou 56 KB

**FATO VERIFICADO**, e esta é a explicação exata do que você observou.

`AgentEventAdapter.toolResultContent` (linhas 50 a 183) monta um mapa e serializa em JSON. Para `ContextResult`, `McpResult`, `MemoryResult` e `TerminalResult`, esse mapa inclui:

```text
summary          texto
previewJson      String que CONTÉM JSON
rawResultJson    String que CONTÉM JSON
terminalOutput   texto bruto (apenas em TerminalResult)
artifacts        lista, com renderMarkdown
```

`previewJson` e `rawResultJson` não são objetos, são **strings** cujo conteúdo é JSON. Quando essas strings entram no JSON externo, todo caractere especial é escapado outra vez. Cada `"` interno vira `\"`, cada quebra de linha vira `\n`, e como o JSON interno já está com `prettyPrint`, cada `\n` interno vira `\\n` no externo.

A conta, para uma SKILL.md de 14 KB lida por `skills_read`:

```text
14 KB de markdown
  → payload interno com bodyMarkdown + references + frontmatter + metadata
  → serializado com prettyPrint e escapado:            cerca de 17 a 20 KB
  → embutido como STRING em rawResultJson e escapado
    de novo (escape duplo):                            cerca de 30 a 38 KB
  → mais previewJson, se ele não for byte a byte igual: cerca de 56 a 60 KB
```

Que é exatamente a faixa que você mediu. O mecanismo não é misterioso, é escape duplo de JSON somado a duas representações do mesmo conteúdo.

## B.5 A deduplicação existente é muito frágil

**FATO VERIFICADO.** `AgentEventAdapter.kt:176-181`:

```kotlin
// Xiaowan's model needs the complete raw result once. A distinct
// preview remains useful, but an identical copy adds no information.
val rawResult = enriched["rawResultJson"]
if (rawResult != null && enriched["previewJson"] == rawResult) {
    enriched.remove("previewJson")
}
```

Alguém já percebeu o problema e escreveu uma proteção. Mas ela compara **igualdade exata de string**. Qualquer diferença de formatação, ordem de chave, truncamento ou espaço faz as duas cópias passarem.

Pior: em `TerminalResult` existe uma terceira cópia do mesmo conteúdo, `terminalOutput`, e nenhuma comparação a cobre. Em `ContextResult` de browser, o texto da página pode aparecer em `summary`, em `previewJson` e em `rawResultJson`.

Sobre os cinco nomes que você listou: `previewJson`, `rawResultJson`, `result` e `artifacts` chegam ao modelo. `contentItems` **não**. Ele só aparece em `ui/lib/services/agent_tool_call_parser.dart:1140` e em `agent_event_reducer.dart`, ou seja, é caminho de interface, não de contexto. Corrigir o lado do modelo não exige tocar nele.

## B.6 `skills_read` devolve mais do que o corpo da skill

**FATO VERIFICADO.** `SkillsToolHandler.kt:122-141` monta um payload com `id`, `name`, `description`, `enabled`, `source`, `installed`, `rootPath`, `androidRootPath`, `skillFilePath`, `androidSkillFilePath`, `scriptsDir`, `assetsDir`, `references` (o conteúdo das referências carregadas), `metadata`, `frontmatter`, `bodyMarkdown` e `uri`. E então passa esse payload **duas vezes**, em `previewJson` e em `rawResultJson`, pelas linhas 138 e 139.

Como as duas chamadas usam a mesma função determinística, nesse caso específico a deduplicação do item B.5 deve funcionar. Mas o payload em si carrega dois pares de caminhos (shell e Android) e o conteúdo das referências, quando o modelo precisava do corpo e de um identificador.

## B.7 A memória de longo prazo é um arquivo único

**FATO VERIFICADO.** `MemoryIndex.kt` documenta a decisão: a memória de longo prazo é o arquivo `.omnibot/memory/MEMORY.md`, e "cada linha `- <texto>` é uma entrada". `LongTermMemoryIndex.list()` **lê o arquivo inteiro a cada chamada** e reconstrói os slugs; `get(slug)` chama `list()` e filtra. `WorkspaceMemoryService.readLongTermMemory()` devolve o arquivo todo como String, e `searchMemory(query, limit = Int.MAX_VALUE)` tem limite infinito por padrão (linha 507).

Há um ponto positivo: a arquitetura de slug permite `memory_load(slug)` buscar uma entrada só, o que já é descoberta seguida de recuperação seletiva. E existe `PlatformEmbeddingGateway`, ou seja, embeddings opcionais.

Então o caminho de 200 a 300 mil tokens que você viu provavelmente **não** vem do MEMORY.md em si, vem de:

1. `file_read` em arquivos grandes de projeto, cujo resultado passa pelo escape duplo do item B.4;
2. `searchMemory` sem limite;
3. histórico longo de conversa antes da compactação disparar.

**INVESTIGAÇÃO NECESSÁRIA:** reproduzir "carregar projeto X" com a instrumentação da entrega F ligada e ver qual ferramenta trouxe o volume. Sem essa medição, qualquer conserto é chute.

## B.8 Não existe roteamento. "oi" só é barato se o usuário lembrar de trocar o modo

**FATO VERIFICADO.** O modo vem da conversa, resolvido em `AgentRuntimeManager.kt:2403` e em `AgentConversationModePolicy.resolveHarness`. Nada no código classifica a mensagem. O usuário escolhe a superfície.

Este é o item que a Melly realmente adiciona, e ele é pequeno comparado com o resto.

## B.9 O que já está mitigado, e não deve ser reescrito

Para ser justo com a base, e para você não gastar crédito reinventando o que existe:

- **cache de prompt.** `PromptCacheKeyStore.forConversation` é usado em `OmniAgentExecutor.kt:192`, e há `buildCachedSystemPromptContent` e `buildCachedTimeContextMessage`. Em provedores com cache de prefixo, incluindo a DeepSeek, o catálogo de ferramentas repetido é candidato a acerto de cache, o que reduz o preço marginal, mas não reduz a contagem de tokens de entrada nem ajuda na primeira chamada.
- **orçamento de contexto.** `conversation/AgentContextBudget.kt` estima tokens com a heurística do Gemini CLI (ASCII dividido por 4, não ASCII vezes 1,5), conta imagem como 1.200 tokens e soma `toolTokens` explicitamente. Ou seja, o custo do catálogo já é reconhecido pelo estimador.
- **compactação com offload.** `AgentConversationContextCompactor.kt` reserva espaço de saída, corta em ponto seguro sem separar tool call de resultado, e manda saída grande de ferramenta para arquivo via `workspaceManager.writeOffload` (`OmniAgentExecutor.kt:283-285`).
- **divulgação progressiva de skills e memória**, como descrito em A.3.

Conclusão da entrega B: a base não é ingênua. Ela é **monomodal**. Tudo que ela sabe fazer, ela faz no tamanho máximo, e o único jeito de pagar menos é desligar as ferramentas por completo.

---

# C. ARQUITETURA PROPOSTA

## C.1 A decisão que precisa ser tomada antes do desenho

Você decidiu que o cérebro fica em Dart e Kotlin fica como camada estreita de capacidades. Depois de ler o código, existem dois caminhos para chegar lá e eles têm ordens de grandeza diferentes.

| | C-A. Cérebro Dart acima do executor Kotlin | C-B. Loop de agente reescrito em Dart |
|---|---|---|
| O que a Melly escreve | roteador, entendimento semântico, orçamento, perfis de agente, observabilidade, normalizador | tudo isso mais o loop, o registro de ferramentas, o cliente de LLM, a compactação, o replay |
| O que reaproveita | as 44 ferramentas, memória, scheduler, terminal, automação, compactação | apenas as capacidades individuais, chamadas uma por uma pelo canal |
| Linhas de Kotlin que precisam mudar | da ordem de centenas | 50 mil linhas ficam órfãs ou precisam de fachada por ferramenta |
| Travessias de canal por turno | uma por turno | uma por chamada de ferramenta, dentro do loop |
| Testável em `flutter test` | roteador, orçamento, perfis, normalizador Dart | quase tudo, mas depois de meses |
| Respeita as regras do `AGENTS.md` | sim, se o roteador escolher a superfície antes do `session/prompt` | difícil, tende a criar um segundo ciclo de vida |
| Prazo realista no seu ambiente | semanas | meses, com risco alto de não terminar |

**RECOMENDAÇÃO: C-A agora, e C-B nunca, a menos que apareça um motivo concreto.**

O ponto que importa: o que diferencia a Melly é **decidir**, não **executar**. Executar terminal, acessibilidade, alarme e arquivo é trabalho chato e já está feito. Se a Melly escrever o cérebro em Dart e continuar usando o corpo Kotlin atrás de uma interface própria, ela já é uma coisa diferente do OpenOmniBot, porque o que muda é exatamente a parte que o usuário sente: o custo, a latência e a previsibilidade.

Isso também não fecha a porta. Se um dia o loop precisar ir para Dart, o roteador e o orçamento já estarão lá, e o executor Kotlin vira apenas um dos backends possíveis.

## C.2 A arquitetura

```text
┌──────────────────────────────────────────────────────────────┐
│ FLUTTER / DART: o cérebro da Melly                           │
│                                                              │
│  UI: chat, agentes, grafo de memória, logs de execução        │
│                                                              │
│  MellyRouter          decide a rota antes de qualquer chamada │
│     ├── nível 0: resposta local, sem LLM                     │
│     ├── nível 1: entendimento semântico determinístico        │
│     ├── CHAT:     provider direto, sem tools, sem memória     │
│     └── EXECUTOR:  delega ao corpo, com escopo declarado      │
│                                                              │
│  SemanticUnderstanding   intenção, entidades, referências     │
│  ContextBudgetManager    tokens, iterações, gasto, por camada │
│  MemoryBrain             grafo, índices, fragmentos           │
│  AgentProfiles           identidade, escopo de tools, limites  │
│  Metacognition           invariantes, não uma segunda LLM      │
│  ExecutionLog            id de execução, rota, tokens, custo   │
│                                                              │
│  Tudo isto é Dart puro e roda em flutter test no CI           │
└────────────────────────────┬─────────────────────────────────┘
                             │  a MESMA fronteira que já existe:
                             │  cn.com.omnimind.bot/AgentRuntime
                             │  cn.com.omnimind.bot/AgentRuntimeEvents
                             ▼
┌──────────────────────────────────────────────────────────────┐
│ KOTLIN: o corpo, herdado, atrás de contratos da Melly         │
│                                                              │
│  MellyExecutor (interface nova, fina)                         │
│     └── AgentRuntimeManager -> OmniAgentExecutor ->           │
│         AgentOrchestrator -> AgentToolRouter -> handlers       │
│                                                              │
│  Patches cirúrgicos, não refatoração:                         │
│   P1. prettyPrint = false no caminho do fio                   │
│   P2. ToolResultNormalizer no toolResultContent               │
│   P3. escopo de ferramentas por requisição, não só por modo    │
│   P4. telemetria de tokens por etapa no evento de execução     │
└──────────────────────────────────────────────────────────────┘
```

## C.3 As três camadas que você pediu, mapeadas no que existe

**CHAT.** Reaproveita `chat_only`. O roteador Dart escolhe essa rota e o Kotlin já garante zero ferramentas, zero sessão de plugin, histórico limpo de tool calls e prompt de sistema curto. A única coisa que falta é o roteador.

**HIPÓTESE a testar:** para o chat puro, talvez valha a pena a Melly chamar a DeepSeek diretamente do Dart, sem passar pelo canal. O lado Dart já tem configuração de provedor (`ui/lib/services/model_provider_config_service.dart`) e `HttpChannel`. Ganho: streaming e cancelamento sem atravessar fronteira, e nenhuma inicialização de runtime de agente para responder "oi". Custo: um segundo caminho de conversa, o que colide com a regra de reducer único do `AGENTS.md`. **RECOMENDAÇÃO: começar reusando `chat_only` pelo canal**, medir, e só considerar o caminho Dart direto se a latência de inicialização se mostrar ruim na medição.

**EXECUTOR.** É o `OmniAgentExecutor` mais o `AgentOrchestrator`, com um parâmetro novo: o escopo de ferramentas. Hoje o escopo é derivado do modo. Passa a ser derivado de um objeto que o cérebro Dart envia junto com o pedido: lista de ferramentas permitidas, teto de iterações, teto de tokens, nível de autonomia, se exige confirmação.

**AGENTES.** São perfis em Dart, exatamente como você desenhou. Um agente não tem cópia de ferramenta: ele é um conjunto de valores que parametriza a chamada ao executor, mais um espaço de memória próprio no grafo. O estado visual 2D lê o `AgentState` que o `ExecutionLog` e os eventos do canal já produzem.

Existe precedente no código para isso: `runtime/SubagentProfile.kt` e `runtime/SubagentToolCatalogView.kt` já implementam "um agente com catálogo reduzido de ferramentas". `SubagentToolCatalogView.kt:15` mapeia nomes de ferramenta para categorias. Vale ler esses dois arquivos antes de escrever o sistema de agentes da Melly, porque metade do problema já foi resolvida ali.

## C.4 Por que isso não é "OpenOmniBot com mais ferramentas"

Porque a Melly não adiciona ferramenta nenhuma. Ela adiciona três coisas que o OpenOmniBot não tem:

1. uma decisão automática de quanto gastar antes de gastar;
2. um contrato de resultado de ferramenta que impede o modelo de receber o mesmo conteúdo três vezes;
3. uma memória que é um mapa navegável, com origem e com interface visual, em vez de um arquivo markdown que cresce.

E remove uma: o subsistema de agentes externos por npm e Node dentro do Alpine, que para uso pessoal com DeepSeek é peso morto.

---

# D. ARQUITETURA DA MEMÓRIA

## D.1 O princípio

Quatro estágios separados, com orçamento próprio em cada um:

```text
1. DESCOBERTA     o que existe sobre isso?        grafo + índice, sem LLM
2. SELEÇÃO        o que é relevante para a tarefa? ranking determinístico
3. RECUPERAÇÃO    trazer só os fragmentos escolhidos
4. CONTEÚDO BRUTO só sob pedido explícito, com teto
```

A regra que resolve o problema dos 200 mil tokens: **nenhum estágio pode entregar ao modelo mais tokens do que o orçamento daquele estágio**, e o estágio 4 nunca é automático.

## D.2 Esquema, em SQLite, sem Neo4j

Você pediu para avaliar. Avaliação: **SQLite com FTS5 é suficiente e Neo4j continua fora.** Um grafo de conhecimento pessoal de um usuário tem, com folga, milhares de nós, não milhões. O que você quer do grafo é vizinhança a um ou dois saltos e ranking, e isso é uma junção e uma consulta recursiva.

```sql
-- nós
CREATE TABLE node (
  id          TEXT PRIMARY KEY,
  kind        TEXT NOT NULL,     -- projeto, pessoa, conceito, decisao, tarefa,
                                 -- arquivo, evento, conversa, agente, topico
  title       TEXT NOT NULL,
  summary     TEXT,              -- curto, é isto que vai ao modelo na descoberta
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

-- relações, direcionadas e tipadas
CREATE TABLE edge (
  src       TEXT NOT NULL REFERENCES node(id),
  dst       TEXT NOT NULL REFERENCES node(id),
  rel       TEXT NOT NULL,       -- pertence_a, depende_de, relacionado_a,
                                 -- criado_por, modifica, usa, deriva_de,
                                 -- contradiz, continua, referencia
  weight    REAL NOT NULL DEFAULT 1.0,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (src, dst, rel)
);

-- fragmentos: a unidade que realmente vai para o prompt
CREATE TABLE fragment (
  id        TEXT PRIMARY KEY,
  node_id   TEXT NOT NULL REFERENCES node(id),
  body      TEXT NOT NULL,
  tokens    INTEGER NOT NULL,    -- calculado na escrita, não na leitura
  created_at INTEGER NOT NULL
);

-- procedência: de onde veio, para poder corrigir e para nunca fundir às cegas
CREATE TABLE source (
  fragment_id TEXT NOT NULL REFERENCES fragment(id),
  origin_kind TEXT NOT NULL,     -- conversa, arquivo, ferramenta, usuario
  origin_ref  TEXT NOT NULL,     -- conversationId, caminho, toolCallId
  quoted_at   INTEGER NOT NULL
);

-- busca textual
CREATE VIRTUAL TABLE fragment_fts USING fts5(
  body, content='fragment', content_rowid='rowid'
);
```

Pontos do desenho que importam:

- `tokens` é gravado na escrita. O orçamento precisa saber o custo antes de ler o corpo.
- `summary` no nó é o que viaja no estágio de descoberta. Um nó pode ter 200 fragmentos e custar 30 tokens para ser mencionado.
- `source` é tabela separada e obrigatória. É o que garante o que você pediu na seção 8 do seu prompt: toda memória mantém origem e pode ser corrigida.
- nada de fusão irreversível. Quando duas entidades parecem a mesma, cria-se uma aresta `relacionado_a` com peso alto e a fusão é uma ação do usuário na interface do grafo, nunca uma decisão automática do sistema.

## D.3 A busca híbrida, com números

```text
"carregar o projeto Melly"
   │
   ├─ 1. entendimento semântico, em Dart, sem LLM
   │     entidade candidata: "Melly"  (casa com node.title por FTS5)
   │
   ├─ 2. descoberta: nó Melly + vizinhos a 1 salto
   │     devolve títulos e summaries. Teto: 500 tokens
   │     [Melly] → arquitetura, LLM, Executor, Agentes, memória, Android, decisões
   │
   ├─ 3. seleção: ranking por (casamento textual, peso da aresta, recência)
   │     se a tarefa menciona LLM, os nós de Android e de UI caem no ranking
   │     Teto: os N fragmentos que couberem no orçamento da etapa
   │
   ├─ 4. recuperação: fragmentos escolhidos. Teto: 2.000 a 4.000 tokens
   │
   └─ 5. conteúdo bruto: só se o usuário ou o agente pedir explicitamente,
         e mesmo assim por arquivo, com teto por arquivo
```

Os tetos são configuráveis, como você pediu, e ficam no `ContextBudgetManager`, não espalhados pelo código.

## D.4 Escrita que se conecta sozinha

Fluxo, tudo determinístico e sem LLM extra:

1. extrair candidatos a entidade do texto salvo (nomes próprios, termos entre aspas, títulos de arquivo, termos que já existem como `node.title`);
2. casar contra `node` por FTS5;
3. se casou com confiança alta, criar o fragmento sob aquele nó;
4. se casou com confiança média, criar o fragmento sob um nó novo **e** uma aresta `relacionado_a` para o candidato, deixando a decisão de fusão para o usuário;
5. se não casou, criar nó novo;
6. sempre gravar `source`.

Um detalhe que evita um bug clássico: nunca deduzir relação a partir de proximidade no texto. Duas coisas mencionadas na mesma frase não estão necessariamente relacionadas, e um grafo que aprende isso sozinho fica cheio de ruído em uma semana.

## D.5 Cérebro visual

O grafo da interface lê exatamente as tabelas acima. Sem estrutura paralela, sem cache de layout que possa divergir dos dados. O toque em um nó abre os fragmentos, cada fragmento mostra a origem, e a origem é clicável. Crescimento da memória é uma consulta por `created_at`.

Sobre a estética: bolhas e conexões em Flutter com `CustomPainter` e uma simulação simples de forças resolve. Isso é trabalho de UI e não bloqueia nada, então entra depois que o grafo real existir e tiver dados.

## D.6 Coexistência com a memória que já existe

**RECOMENDAÇÃO:** não migrar nada na Fase 1. O `MEMORY.md` e o `WorkspaceMemoryService` continuam funcionando como estão. O grafo da Melly nasce ao lado, alimentado pelo que for salvo a partir de agora, e uma importação do `MEMORY.md` linha por linha pode ser feita depois, quando o esquema tiver provado que funciona. Migração de dados na primeira versão é a receita para perder memória de verdade.

---

# E. ARQUITETURA SEMÂNTICA E METACOGNITIVA

## E.1 O erro que quase todo mundo comete aqui

Você já identificou o risco no seu prompt: metacognição que chama LLM para pensar sobre o pensamento destrói o objetivo de controle de custo. Vou além: **quase tudo que você listou como pergunta metacognitiva não precisa de LLM nenhum.**

Releia a sua própria lista:

| Pergunta metacognitiva | Como responder sem LLM |
|---|---|
| Estou repetindo uma ação? | hash de (nome da ferramenta + argumentos) visto nesta execução |
| A ferramenta retornou informação demais? | contagem de tokens do resultado contra o teto da etapa |
| Estou perto do limite de custo? | soma corrente contra o orçamento |
| Estou prestes a executar ação desnecessária? | a ferramenta está no escopo declarado deste agente? |
| Existe risco de ação inesperada? | nível de risco declarado na ferramenta |
| Minha estratégia está funcionando? | rodadas consecutivas sem resultado novo, ou sem mudança de estado |
| Tenho informação suficiente? | esta é a única que às vezes precisa de um modelo |
| O resultado atende ao objetivo? | esta também |

Seis das oito são invariantes de execução, verificáveis em Dart, com teste unitário, custo zero e latência zero. Só as duas últimas às vezes justificam uma chamada.

## E.2 Os níveis, com gatilhos concretos

```text
NÍVEL 0  resposta local, zero LLM
  saudação, agradecimento, "que horas são", comando de app conhecido,
  repetição exata de pergunta já respondida nesta conversa

NÍVEL 1  entendimento semântico determinístico, zero LLM
  classifica: conversa ou tarefa; extrai entidades candidatas;
  decide se precisa de memória; decide se precisa de ferramenta;
  escolhe a rota CHAT ou EXECUTOR e o escopo de ferramentas

NÍVEL 2  uma chamada de LLM, escopo mínimo
  CHAT: prompt curto, sem ferramentas, sem memória pesada
  EXECUTOR simples: catálogo restrito ao escopo, até 3 iterações

NÍVEL 3  metacognição, e somente por gatilho duro
  gatilhos, todos verificáveis sem LLM:
    a) 3 rodadas sem mudança de estado observável
    b) mesma ferramenta com os mesmos argumentos 2 vezes
    c) 70% do orçamento da tarefa consumido sem resultado
    d) erro de ferramenta repetido 2 vezes
  quando dispara: UMA chamada, com contexto reduzido de propósito
  (objetivo, ações tentadas, erros, nada de saída bruta),
  pedindo uma decisão entre: mudar de abordagem, pedir dado ao
  usuário, ou desistir com explicação

NÍVEL 4  execução complexa
  múltiplas ferramentas, replanejamento, subagentes.
  Só entra com confirmação do usuário quando o orçamento estimado
  passar do teto configurado
```

A propriedade que faz isso funcionar: o nível 3 é **raro por construção**. Se ele estiver disparando com frequência, o problema não é falta de metacognição, é o nível 1 classificando errado, e a correção é no classificador.

## E.3 Como o classificador do nível 1 funciona sem LLM

Não é aprendizado de máquina, é uma tabela de regras com prioridade, escrita e testada em Dart:

1. **negativas fortes primeiro.** Mensagem com até N caracteres, sem verbo de ação conhecido, sem caminho de arquivo, sem nome de app, sem referência temporal, e sem pronome demonstrativo apontando para contexto: rota CHAT.
2. **positivas fortes.** Contém verbo de ação de uma lista curta (abrir, executar, criar, apagar, enviar, agendar, buscar, instalar, ler, converter) ou um caminho, ou um nome de app instalado, ou expressão temporal: rota EXECUTOR, e o verbo já sugere a categoria de ferramenta.
3. **referência a contexto.** "aquele projeto", "esse arquivo", "o que falamos": aciona descoberta de memória antes de decidir a rota.
4. **ambiguidade.** Se as regras empatam, a rota padrão é CHAT com uma pergunta de esclarecimento, que custa menos que executar errado.

Esse classificador é um arquivo de umas 200 linhas com uns 40 testes. É a peça mais barata e mais valiosa de toda a Melly, porque é ela que decide se "oi" custa 200 tokens ou 15 mil.

**RECOMENDAÇÃO:** registrar, em cada execução, a decisão do classificador e o que a execução acabou precisando. Depois de algumas centenas de mensagens reais, você tem os dados para decidir se algum caso merece regra nova. Sem esses dados, qualquer heurística mais sofisticada é adivinhação.

---

# F. PLANO DA FASE 1

Ordem deliberada: **medir, depois consertar o vazamento, depois adicionar o cérebro.** Otimizar antes de medir é como o documento central alerta na seção 46, tecnologia sem problema concreto.

## F1. Instrumentação (primeiro, e sem isto nada mais faz sentido)

| Arquivo | Mudança |
|---|---|
| `app/.../agent/runtime/AgentOrchestrator.kt` | emitir por rodada: bytes e tokens estimados do system prompt, do catálogo de ferramentas, do histórico, de cada resultado de ferramenta; um `executionId` por turno |
| `app/.../agent/conversation/AgentContextBudget.kt` | expor a decomposição que ele já calcula, em vez de só o total |
| `app/.../agent/runtime/AgentEventAdapter.kt` | medir, por resultado, bytes recebidos do handler e bytes entregues ao modelo, e o fator de redução |
| `app/.../bot/ui/channel/AgentRuntimeChannel.kt` | encaminhar esses eventos pelo `AgentRuntimeEvents` |
| `ui/lib/services/execution_log_service.dart` (novo) | persistir em SQLite local, sem rede |
| `ui/lib/features/.../execution_log_page.dart` (novo) | tela de leitura e exportação |

Saída esperada, por turno, é exatamente o formato que você desenhou:

```text
EXECUÇÃO #183
Input: "oi"          Rota: CHAT
Tools: 0             Skills: 0        Memória: 0
Catálogo: 0 tokens   Sistema: 180     Histórico: 240
Contexto total: 431 tokens   Custo: R$ 0,0002   Tempo: 820 ms
```

E, para comparação, o mesmo turno com a rota atual do OpenOmniBot. Esse par de números é o que prova que a Melly existe.

## F2. Os quatro patches cirúrgicos no corpo Kotlin

**P1. Desligar `prettyPrint` no caminho do fio.**
`OmniAgentExecutor.kt:168`, `AgentOrchestrator.kt:60`, `AgentToolRouter.kt:32`. Se algum log depende de JSON legível, criar uma segunda instância só para log. Uma linha por arquivo.

**P2. `ToolResultNormalizer`, exatamente onde você desenhou.**
Ponto de inserção: `AgentEventAdapter.toolResultContent`, `runtime/AgentEventAdapter.kt:50-183`. Regras:

1. o modelo recebe **um** corpo, nunca dois. `rawResultJson` sobrevive, `previewJson` sai do payload do modelo sempre, não só quando é idêntico;
2. `terminalOutput` e `rawResultJson` nunca coexistem; vale o que tiver mais informação;
3. `summary` fica, porque é curto e é o que o modelo lê primeiro;
4. o corpo entra como **objeto JSON**, não como string contendo JSON, o que elimina o escape duplo;
5. teto configurável por resultado. Acima do teto, truncar no meio, preservar começo e fim, e anexar o caminho do arquivo de offload, que o `AgentWorkspaceManager.writeOffload` já sabe criar;
6. registrar bytes antes, bytes depois e fator de redução.

**RISCO e INVESTIGAÇÃO NECESSÁRIA antes de mexer:** `ui/lib/services/agent_tool_call_parser.dart` lê `rawResultJson`, `previewJson`, `terminalOutput` e `contentItems`, e o comentário na linha 72 avisa que "live ACP and restored tool events share this parser". A mensagem de resultado também é persistida no histórico por `callback.onToolReplayReady` (`AgentOrchestrator.kt:697-701`). Antes de trocar o formato, é preciso confirmar se a restauração de cartões da interface lê o payload do modelo ou os eventos separados. Se ler o payload do modelo, o normalizador precisa gerar **duas** saídas: a magra para o modelo e a completa para a interface e o histórico. Isso é uma checagem de meia hora e evita quebrar a restauração de conversa.

**P3. Escopo de ferramentas por requisição.**
`AgentConversationModePolicy.filterToolDefinitionsForConversationMode` passa a aceitar, além do modo, uma lista de nomes permitidos vinda do cérebro Dart. Sem lista, comportamento atual, o que mantém compatibilidade. `AgentToolRegistry.kt` já constrói o catálogo por turno, então o ponto de corte existe.
Referência útil: `runtime/SubagentToolCatalogView.kt` já faz visão reduzida de catálogo por categoria. Reusar a mesma ideia em vez de inventar outra.

**P5, e na verdade este deveria ser o P0: teto duro de rodadas no loop.**
**FATO VERIFICADO.** `AgentOrchestrator.kt:136` abre `roundLoop@ while (true)` e incrementa `completedModelRounds` a cada rodada. Não existe nenhuma comparação contra um máximo em nenhum ponto do arquivo. O loop só termina quando o modelo para de pedir ferramenta (linha 277), quando um erro marca `terminated = true` (linhas 289, 439, 446) ou por cancelamento do usuário.

Um loop de agente sem teto de iteração é o cenário clássico de conta inesperada: basta o modelo entrar em um ciclo de chamar a mesma ferramenta, receber o mesmo erro e tentar de novo. Cada rodada reenvia o catálogo inteiro de ferramentas mais o histórico crescente.

Correção: um teto configurável de rodadas por tarefa, vindo do `ContextBudgetManager` da Melly, com mensagem clara ao usuário quando bater no limite. É uma condição a mais no `while` e um valor de configuração. Provavelmente é a correção mais importante deste documento em termos de risco financeiro, e é a mais barata.

**P4. Desligar o que a Melly não usa.**
Sessão de plugin e MCP passa a ser opcional por configuração, não implícita em todo turno não `chat_only` (`OmniAgentExecutor.kt:234-241`). O catálogo de agentes ACP externos (`assets/acp/agents.json`, `XiaowanAcpConnection.kt`, `AcpAgentCatalog.kt`) fica desligado por configuração. Não apagar código nesta fase, apenas não executar.

## F3. O cérebro em Dart

| Arquivo novo em `ui/lib/melly/` | Responsabilidade |
|---|---|
| `router/melly_router.dart` | decide rota e escopo, único ponto de decisão |
| `router/intent_classifier.dart` | as regras do nível 1, função pura |
| `router/route_decision.dart` | rota, escopo de ferramentas, tetos, motivo da decisão |
| `budget/context_budget.dart` | tetos por etapa, por tarefa e diário, e o bloqueio |
| `budget/token_estimator.dart` | mesma heurística do `AgentContextBudget` para os números baterem |
| `memory/graph_store.dart` | o esquema da entrega D, em sqflite |
| `memory/graph_query.dart` | descoberta, seleção, recuperação, com tetos |
| `memory/memory_writer.dart` | extração de entidade, casamento, procedência |
| `agents/agent_profile.dart` | identidade, objetivo, instruções, escopo, orçamento, autonomia |
| `agents/agent_state.dart` | IDLE, THINKING, PLANNING, USING_TOOL, WAITING, SUCCESS, ERROR |
| `meta/invariants.dart` | os seis gatilhos determinísticos do nível 3 |
| `log/execution_log.dart` | o registro da F1, do lado Dart |
| `executor/melly_executor.dart` | contrato da Melly sobre o canal existente |

Nenhum desses arquivos toca a interface de usuário. Todos são testáveis com `flutter test` no GitHub Actions, que é o único nível de teste que escala no seu ambiente.

## F4. Os oito testes que você definiu, com critério objetivo

| Teste | Critério de aprovação, medido pelo log da F1 |
|---|---|
| 1. "oi" | rota CHAT, tools 0, skills 0, memória 0, contexto abaixo de 800 tokens |
| 2. "quanto é 2+2" | rota CHAT, uma chamada de LLM, nenhuma ferramenta |
| 3. "abra o navegador" | rota EXECUTOR, escopo contendo apenas ferramentas de app e Android, catálogo enviado abaixo de 2.000 tokens |
| 4. pergunta que exige memória | estágios de descoberta e seleção aparecem no log, contexto de memória abaixo do teto configurado, e a resposta cita a origem |
| 5. "carregar projeto X" | nenhum resultado de ferramenta acima do teto por resultado; total do turno abaixo do teto da tarefa; offload usado em vez de corpo inteiro |
| 6. tarefa que exige correção | pelo menos um gatilho de invariante registrado no log, e no máximo uma chamada de metacognição |
| 7. selecionar um agente | escopo efetivo igual ao declarado no perfil; tentativa de usar ferramenta fora do escopo é recusada, com teste unitário |
| 8. custo por etapa | soma das etapas igual ao total reportado, com diferença abaixo de 5% em relação ao uso reportado pelo provedor |

## F5. O que NÃO entra na Fase 1

Grafo visual, agentes visuais 2D, metacognição de nível 3 completa, migração do `MEMORY.md`, embeddings, automação nova. Tudo isso depende de o cérebro existir e de os números da F1 mostrarem que a rota certa está sendo escolhida.

---

# G. RISCOS E O QUE FALTA INVESTIGAR

## G.1 Riscos

**R1. Mudar o formato de resultado de ferramenta pode quebrar a restauração de conversa.** Probabilidade média, impacto alto. O parser Dart é compartilhado entre evento vivo e evento restaurado, e tem 7.013 linhas de reducer atrás dele. Mitigação: a checagem descrita em P2, e normalizador com duas saídas se for o caso.

**R2. Criar um segundo caminho de conversa viola as regras do próprio projeto.** Probabilidade alta se o chat puro for para o Dart direto, impacto alto. O `AGENTS.md` proíbe segundo reducer e segundo ciclo de vida, e o sintoma de violar isso é histórico duplicado. Mitigação: o roteador decide **antes** e usa a superfície existente; qualquer caminho novo só depois de medição que justifique.

**R3. Divergência entre o seu fork e o upstream.** Probabilidade alta, impacto médio. Analisei o upstream de hoje. Os números de linha que citei podem estar deslocados no seu fork. Mitigação: conferir cada ponto de inserção antes de editar, e nunca aplicar patch por número de linha, sempre por conteúdo.

**R4. 50 mil linhas de Kotlin que ninguém leu inteiras.** Probabilidade certa, impacto médio. Mitigação: os quatro patches são cirúrgicos e localizados; a interface `MellyExecutor` isola o resto; nada de refatoração.

**R5. Licença AGPL-3.0.** Uso pessoal, sem distribuir, está resolvido. Mas gerar APK por GitHub Actions em repositório público significa publicar o derivado, e distribuir o APK para qualquer outra pessoa aciona as obrigações da AGPL. Mitigação: repositório privado se você não quiser abrir o código, ou aceitar conscientemente que o fork é AGPL e público. Decisão sua, e não é urgente enquanto o app roda só no seu aparelho.

**R6. A medição pode contradizer o diagnóstico.** Probabilidade baixa a média, impacto baixo, e é por isso que a F1 vem primeiro. Se o catálogo de ferramentas estiver batendo no cache de prompt da DeepSeek na maioria dos turnos, o custo real por mensagem pode ser bem menor do que a contagem de tokens sugere, e a prioridade muda do item B.1 para o item B.4. O plano já está ordenado para descobrir isso antes de gastar trabalho.

**R7. O classificador vai errar.** Probabilidade certa, impacto baixo se o padrão em caso de dúvida for CHAT mais pergunta, e alto se o padrão for EXECUTOR. Mitigação: em ambiguidade, nunca executar.

**R8. Desligar o runtime ACP externo pode ter efeito colateral.** Probabilidade média, impacto médio. `AgentRuntimeManager` e `LocalAcpRuntime` têm quase 10 mil linhas combinadas e o modo normal resolve o harness para o xiaowan por padrão (`AgentConversationModePolicy.kt:36-43`). Desligar por configuração, não apagar, e testar que o caminho local continua funcionando.

## G.2 Investigações necessárias antes de escrever código

1. **Medir de verdade** o tamanho serializado do catálogo de ferramentas e a proporção de acerto de cache da DeepSeek. Sem isso, a estimativa de 8 a 12 mil tokens do item B.1 continua sendo estimativa.
2. **Confirmar o consumidor do payload do modelo** na restauração de cartões de ferramenta, conforme P2.
3. **Reproduzir o caso de 200 a 300 mil tokens** com o log ligado e identificar qual ferramenta trouxe o volume. Minha hipótese é `file_read` somado ao escape duplo, não o `MEMORY.md`.
4. **Conferir o comportamento do scheduler** em relação aos limites do Android que a auditoria anterior verificou, principalmente as cotas novas do Android 16 para jobs iniciados a partir de foreground service.
5. **Checar a licença do framework de acessibilidade** que o módulo `assists/` usa, já que ele parece derivar de um projeto de terceiro, e a auditoria anterior já mostrou que ninguém tinha olhado licença até agora.

## G.3 Onde eu discordo do seu prompt, e por quê

Você pediu para priorizar a análise técnica quando ela conflitar com as ideias do prompt. Três pontos:

**Sobre "criar uma camada Tool Result Normalizer".** Concordo inteiramente, e a análise mostra que ela é menor do que você imaginava: é uma função de 130 linhas em um único arquivo, `AgentEventAdapter.kt`. Você desenhou uma camada; o código pede uma função. Fazer menor é melhor aqui.

**Sobre "raciocínio semântico" e "metacognição" como camadas de inteligência.** A análise me convenceu de que 75% do valor que você quer delas sai de regras determinísticas e invariantes de execução, sem nenhuma chamada extra de modelo. Tratar as duas como "camadas que pensam" convida a gastar LLM onde uma comparação de hash resolve. Proponho tratá-las como **política**, não como inteligência.

**Sobre o Knowledge Graph ser o mapa da memória.** Concordo, e acrescento uma restrição que você não pediu: o grafo só entrega `summary` e fragmentos, nunca corpo bruto, e nunca sem procedência. Sem essa restrição, um grafo bem construído se torna um jeito mais elegante de mandar 200 mil tokens para o modelo.

---

# CONCLUSÃO E PEDIDO DE APROVAÇÃO

Três frases, se for para levar só isso:

1. O desperdício é real, tem quatro causas identificadas com arquivo e linha, e a maior parte se conserta com uma função e três linhas de configuração, não com uma reescrita.
2. O caminho barato de chat já existe no código como `chat_only`; o que a Melly adiciona é a decisão automática de usá-lo, e essa decisão é um classificador em Dart de umas 200 linhas.
3. O cérebro em Dart acima do corpo Kotlin entrega a diferença que você quer em semanas; reescrever o loop em Dart entrega a mesma coisa em meses e pode não terminar.

Não escrevi código e não vou avançar sem sua aprovação. O que eu preciso de você agora:

1. Aprovação do caminho C-A (cérebro Dart acima do executor Kotlin herdado) ou pedido explícito de C-B, sabendo o custo.
2. Confirmação de que a Fase 1 começa pela instrumentação (F1) e não pelo roteador, porque medir primeiro muda a prioridade dos consertos.
3. A URL do seu fork, se ele já divergiu do upstream, para eu conferir os pontos de inserção no código que você vai realmente compilar.
4. Os valores iniciais dos tetos: tokens por chamada, tokens por tarefa, iterações por tarefa e gasto diário. Se preferir, eu proponho valores na próxima etapa.

---

# FONTES

Arquivos lidos neste repositório, clonado hoje de `github.com/omnimind-ai/OpenOmniBot`:

`AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`, `app/src/main/assets/acp/agents.json`, `app/src/main/assets/acp/install/deepseek-harness.sh`, `app/src/main/assets/builtin_skills/`, `app/src/main/java/cn/com/omnimind/bot/agent/AgentConversationModePolicy.kt`, `.../agent/runtime/AgentSystemPrompt.kt`, `.../agent/runtime/OmniAgentExecutor.kt`, `.../agent/runtime/AgentOrchestrator.kt`, `.../agent/runtime/AgentEventAdapter.kt`, `.../agent/runtime/AgentModels.kt`, `.../agent/tool/AgentToolDefinitions.kt`, `.../agent/tool/handlers/SkillsToolHandler.kt`, `.../agent/tool/handlers/SharedHelper.kt`, `.../agent/conversation/AgentContextBudget.kt`, `.../agent/conversation/AgentConversationContextCompactor.kt`, `.../agent/workspace/memory/MemoryIndex.kt`, `.../agent/workspace/memory/WorkspaceMemoryService.kt`, `.../bot/ui/channel/AgentRuntimeChannel.kt`, `ui/lib/services/agent_runtime_service.dart`, `ui/lib/services/agent_tool_call_parser.dart`.

**FIM: ANÁLISE TÉCNICA v0.2**
