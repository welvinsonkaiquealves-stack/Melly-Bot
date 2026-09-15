# MELLY: REGISTRO DE DECISÕES

Cada decisão tem identificador, estado e justificativa. **Decisão TRAVADA não se reabre** sem o dono do projeto pedir. Se você discorda, registre na seção de objeções do `05-ESTADO-ATUAL.md` e siga o plano.

Estados: **TRAVADA**, **ABERTA** (falta decidir), **REVOGADA** (com o motivo).

---

## Produto e distribuição

### D001. A Melly é para uso pessoal
**TRAVADA.** Sem loja, sem conta de usuário, sem backend, sem cobrança. Isso elimina de uma vez processamento de pagamento, obrigação fiscal, risco de abuso de chave e a maior parte do problema de privacidade.

### D002. APK gerado por GitHub Actions e instalado direto no Android
**TRAVADA.** Sem Play Store. Consequência: a política do Play que proíbe ação autônoma via AccessibilityService deixa de ser um bloqueio, porque não há submissão. Se um dia houver intenção de publicar, essa decisão volta à mesa junto com D003.

### D003. Automação híbrida
**TRAVADA.** Ação simples e de baixo risco pode ser autônoma. Ação sensível exige confirmação explícita do usuário, e essa confirmação não pode ser gerada nem preenchida pelo modelo.

### D004. Licença aceita como AGPL-3.0 para uso pessoal
**TRAVADA para o cenário atual.** A base é AGPL-3.0 com licença comercial separada. Uso pessoal sem distribuição não gera obrigação. Distribuir o APK para terceiro ou cobrar aciona as obrigações, e nesse momento a decisão precisa ser revista. O arquivo de licença e os avisos de copyright não podem ser removidos.

---

## Arquitetura

### D005. Cérebro em Dart, corpo em Kotlin
**TRAVADA.** Toda decisão, política, roteamento, orçamento e seleção de contexto em Dart. Kotlin permanece como camada de capacidades e dono do loop de execução herdado.

### D006. Não reescrever o loop de agente em Dart
**TRAVADA.** Existem cerca de 50 mil linhas de agente Kotlin funcionando, com loop, replay, recuperação de overflow e compactação. Reescrever isso em Dart levaria meses, com risco alto de não terminar, e não muda o que o usuário sente. O que diferencia a Melly é decidir, não executar.

### D007. Um cérebro com políticas, não vários cérebros
**TRAVADA.** Nada de `ReasoningEngine`, `MemoryBrain`, `MetacognitionBrain`, `PlanningBrain`, `DecisionBrain`. Um objeto `MellyBrain`, um `RoutePlan` imutável de saída, e políticas que são funções puras.

### D008. Um único ciclo de vida
**TRAVADA.** A Melly não cria reducer, stream, retry, lifecycle nem máquina de estados nova. O ciclo `Conversation -> ACP Session -> Turn -> Item` que já existe é o único, e a Melly escolhe parâmetros dele. O `AGENTS.md` do repositório proíbe o contrário em quatro parágrafos, e a razão é boa: violar isso produz histórico duplicado e cartão de ferramenta fantasma.

### D009. Três camadas: CHAT, EXECUTOR, AGENTS
**TRAVADA.** Agents não têm ferramentas próprias nem loop próprio. Um agente produz um `RoutePlan` parcial.

### D010. Dois públicos, dois formatos de resultado de ferramenta
**TRAVADA.** O modelo recebe compacto, a interface e o histórico recebem completo. Explícito no tipo, nunca implícito.

### D011. Escopo de ferramentas fechado por padrão
**TRAVADA.** Ferramenta fora do escopo é recusada na validação, antes de executar. Implementação segue o padrão que já existe em `SubagentToolCatalogView`.

### D012. Orçamento é pré-condição
**TRAVADA.** Tokens por chamada, tokens por tarefa, iterações, gasto diário. Verificados antes de gastar. Ao estourar: reduzir, pedir autorização, ou parar.

### D013. Teto duro no loop de agente é P0
**TRAVADA.** Um loop sem limite máximo, com chave de API própria, é risco financeiro aberto. Entra antes de qualquer otimização.

---

## Provedor e modelo

### D014. DeepSeek é o único provedor inicial
**TRAVADA.** Chave do próprio usuário. `AgentLlmClient` já é uma interface com `streamTurn` e cumpre o papel do contrato `LlmProvider`; não criar outro.

### D015. Nenhum teste automatizado toca a API real
**TRAVADA.** Provedor falso em toda a suíte de CI.

### D016. Texto voltado ao modelo em inglês, interface em português
**TRAVADA.** Os schemas de ferramenta já têm versão em inglês. Traduzir 34 KB de schema para português não compra nada. O SOUL, o prompt de chat e toda a interface ficam em português, e é o SOUL que define o idioma da resposta.

---

## Memória

### D017. Knowledge Graph local em SQLite com FTS5
**TRAVADA.** Neo4j está fora: é servidor JVM, inviável no aparelho, e um grafo pessoal tem milhares de nós, não milhões.

### D018. Quatro estágios separados, com teto por estágio
**TRAVADA.** Descoberta, seleção, recuperação, conteúdo bruto. Conteúdo bruto nunca é automático.

### D019. Procedência obrigatória, fusão nunca automática
**TRAVADA.** Todo fragmento guarda origem. Similaridade cria aresta `relacionado_a`, nunca fusão irreversível. Fusão é ação do usuário.

### D020. Não migrar o `MEMORY.md` na primeira versão
**TRAVADA.** O grafo nasce ao lado. O arquivo antigo continua intacto. Importação é etapa separada e opcional. Migração de dados na primeira versão é como se perde memória de verdade.

### D021. Substituir apenas o índice de memória longa
**TRAVADA.** `WorkspaceMemoryService` continua sendo o armazenamento. `MemoryIndex` e `LongTermMemoryIndex` são substituídos porque releem e re-hasheiam o arquivo inteiro a cada consulta e o modelo de uma linha por entrada não sustenta nós, relações, fragmentos e procedência.

### D022. Embeddings adiados
**TRAVADA por ora.** `PlatformEmbeddingGateway` existe e é opcional. FTS5 primeiro. Ligar só quando a busca textual comprovadamente falhar em caso que importe.

---

## Metacognição

### D023. Metacognição é política, não inteligência
**TRAVADA.** Seis das oito verificações são invariantes determinísticas: hash de chamada repetida, tokens do resultado, orçamento consumido, escopo, risco declarado, rodadas sem mudança de estado. Só "tenho informação suficiente" e "o resultado atende ao objetivo" podem exigir modelo.

### D024. No máximo uma chamada de metacognição por tarefa, e só por gatilho duro
**TRAVADA.** Se estiver disparando com frequência, o problema é o classificador, não a metacognição.

---

## Componentes externos

### D025. OpenClaw, MCP e ACP externo não são removidos
**TRAVADA.** Ficam desligados por configuração, fora do caminho principal da Melly. Nada de remoção física. Isso preserva a opção de plugar um agente externo depois.

### D026. Runtime de plugin desligado por configuração
**TRAVADA.** Hoje `ENABLE_PLUGIN_RUNTIME` é constante de compilação `true`, e a sessão de plugin abre em todo turno que não é `chat_only`. Passa a ser configuração, com padrão desligado para a Melly.

### D027. Rust fora do roadmap
**TRAVADA.** Nenhum requisito conhecido exige desempenho nativo. UniFFI não gera binding oficial para Dart, e a pilha Flutter sobre Kotlin sobre Rust teria três linguagens e duas travessias de fronteira em série.

### D028. Não refatorar `AssistsCoreManager` nem o módulo de acessibilidade
**TRAVADA.** `AssistsCoreManager` tem 3.554 linhas e 137 funções, e é o faz-tudo do canal, não um núcleo de acessibilidade. A acessibilidade de verdade são 102 linhas em `accessibility/AssistsService.kt` mais 990 linhas em `androidgui/`, já isoladas. A "grande refatoração" que o documento original temia nunca foi necessária.

### D029. Não reescrever o que já está correto
**TRAVADA.** Ficam como estão: `AgentContextBudget`, `AgentConversationContextCompactor`, `AgentConversationHistoryRepository`, `AgentLlmClient`, `AgentToolRouter` e os handlers, `WorkspaceScheduledTaskScheduler`, `ReTerminal`, `agent_event_reducer.dart`, `HttpController`, `baselib/llm`. A auditoria fechou em 24 KEEP, 14 MODIFY, 2 REPLACE, 1 ABSORB, 11 REMOVE do caminho, 8 DEFER.

---

## Processo

### D030. Medir antes de otimizar
**TRAVADA.** E0 existe porque a hipótese de que o catálogo de ferramentas domina o custo ainda não foi verificada, e a ordem de E3 e E4 depende do resultado. Já houve duas afirmações minhas corrigidas por simulação; uma terceira correção por medição é esperada e bem-vinda.

### D031. Uma etapa por vez, no máximo três arquivos Kotlin por etapa
**TRAVADA.** Cada etapa tem teste de aceitação. Sem ele passar, não avança.

### D032. Nunca aplicar mudança por número de linha
**TRAVADA.** Localizar por nome de função ou trecho de código.

---

## Decisões ainda ABERTAS

### A001. Valores iniciais dos tetos
**ABERTA.** Máximo de rodadas, tokens por chamada, tokens por tarefa, gasto diário. Sugestão inicial: 12 rodadas. Os demais só fazem sentido depois de E0.

### A002. Repositório de trabalho público ou privado
**ABERTA.** Afeta a obrigação da AGPL. Uso pessoal sem distribuição não obriga nada, mas um repositório público já é publicação do derivado, o que é compatível com a licença e talvez não seja o que o dono quer.

### A003. Perfis iniciais de agente e escopo de cada um
**ABERTA.** Proposta: Pesquisador, Programador, Escritor, Automação. Escopos a definir em E7.

### A004. Destino do `MEMORY.md` no longo prazo
**ABERTA.** Importar para o grafo, manter em paralelo, ou aposentar. Decidir depois de E6 rodando.
