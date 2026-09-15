# MELLY: ETAPA 0, KIT DE MEDIÇÃO E DIAGNÓSTICO

**Data:** 12 de setembro de 2026
**Base:** `omnimind-ai/OpenOmniBot`, commit `54aeae8`, leitura apenas
**Alterações no código:** nenhuma. Nenhum arquivo do projeto foi modificado, nada foi removido, o Agent Loop, o catálogo de ferramentas, a memória, o OpenClaw, o MCP e o ACP seguem exatamente como estão.

---

# 1. O QUE EU NÃO CONSIGO FAZER, E POR QUE

Os quatro testes exigem **rodar o app no seu celular** e ler a tela "Eu > Sobre > logs de requisição de IA". Eu não tenho acesso ao seu aparelho: esta sessão roda em um contêiner na nuvem, sem o app instalado, sem chave da DeepSeek e sem vínculo com o seu Android.

Então não vou inventar os números. **Nenhuma célula da tabela que você pediu pode ser preenchida por mim.** Os quatro testes precisam ser executados por você, e levam cerca de dez minutos.

O que eu fiz no lugar, e que considero o trabalho útil desta etapa:

1. **Verifiquei, no código, se cada um dos doze dados que você listou realmente existe** e onde. Quatro deles não estão disponíveis do jeito que você imaginou, e é melhor saber disso antes de procurar na tela.
2. **Montei o protocolo exato** de como rodar os testes, com os cuidados metodológicos que evitam medir a coisa errada.
3. **Medi, por simulação determinística, a parte que não depende do aparelho**: a inflação de resultado de ferramenta. E o resultado **contradiz duas afirmações que eu fiz com confiança excessiva nos documentos anteriores.** Está corrigido abaixo.
4. **Preparei a ordem das próximas alterações como árvore de decisão** amarrada aos números que você vai trazer, em vez de uma lista fixa.

---

# 2. DISPONIBILIDADE REAL DE CADA DADO

**FATO VERIFICADO** para cada linha, com o arquivo conferido.

| Dado que você pediu | Onde nasce | Dá para ler no celular hoje? |
|---|---|---|
| `promptTokens` | `usage.prompt_tokens` da resposta | **Sim**, dentro do `responseJson` na tela de logs |
| `completionTokens` | `usage.completion_tokens` | **Sim**, mesmo lugar |
| `reasoningTokens` | `usage.completion_tokens_details.reasoning_tokens` | **Sim, se o modelo devolver.** `deepseek-chat` normalmente não devolve; modelo de raciocínio devolve |
| `cachedTokens` | `usage.prompt_tokens_details.cached_tokens` | **Sim, se o provedor devolver** |
| `cacheCreationTokens` | `usage.prompt_tokens_details.cache_creation_tokens` | **Sim no `responseJson`.** Mas o modelo Dart `TokenUsageRecord` **não lê esse campo** (`ui/lib/services/token_usage_service.dart`), então nenhuma tela do app mostra ele, apesar de o Kotlin enviar |
| tamanho do `requestJson` | o próprio campo | **Não diretamente.** A tela mostra o JSON, não o tamanho. Só medindo fora do app |
| tamanho do `responseJson` | idem | **Não diretamente** |
| quantidade de ferramentas no request | array `tools` do `requestJson` | **Sim, contando na mão**, ou medindo fora do app |
| tamanho do array `tools` | idem | **Não diretamente** |
| quantidade de chamadas ao modelo | uma entrada de log por chamada HTTP | **Sim, contando as entradas** do mesmo intervalo |
| quantidade de tool calls | `tool_calls` na resposta, e mensagens `role: "tool"` no request seguinte | **Sim, contando na mão** |
| iterações do Agent Loop | igual ao número de chamadas ao modelo no turno | **Derivado** do item acima |

## 2.1 Quatro dados que NÃO estão onde parecia

**a) A linha de log com todos os tokens existe, mas você não consegue ler.** `HttpController.kt:530-536` grava `[TokenUsage] recording: model=..., prompt=..., completion=..., reasoning=..., text=..., cached=..., cacheCreation=..., stream=..., url=...`. Seria a medição perfeita, em uma linha. Só que ela usa `OmniLog.i`, e em `baselib/.../util/OmniLog.kt` apenas `e()` e `wtf()` chamam `storeRuntimeLog`. Ou seja: **INFO vai só para o logcat**, que exige `adb` e um PC. A tela "logs de runtime" do app só mostra ERROR e ASSERT.

**b) O número de ferramentas do turno também está em log INFO inacessível.** `AgentOrchestrator.kt:128` loga `round=$round request_tools=${toolRegistry.toolsForModel.size}` e `AgentToolRegistry.kt:173` loga `registered_tools count=... names=[...]`. Mesmo problema: logcat apenas.

**c) A tela de estatísticas de uso não serve para isolar uma mensagem.** `TokenUsageRecord` é gravado **uma vez por chamada HTTP** (`HttpController.kt:541`), o que é ótimo. Mas a interface (`usage_statistics_page.dart` e `activity_dashboard_card.dart`) agrega por dia, semana e modelo. Não existe tela que mostre registro por registro.

**d) A janela de evidência é de dez chamadas.** `AiRequestLogStore.MAX_LOG_COUNT = 10`. Um turno de agente com mais de dez rodadas **apaga as primeiras**. Isso afeta diretamente o teste 4.

## 2.2 Um cuidado metodológico que muda a leitura

O log guarda o request já formatado: `AiRequestLogStore.prettyJsonOrRaw(seed.requestJson)`. Então **o tamanho em bytes do que você vê na tela não é o tamanho exato do que foi enviado no fio.** Está inflado pela indentação do próprio log.

Consequência prática: use `usage.prompt_tokens` como verdade absoluta de custo, e use o JSON apenas para descobrir **proporção**, ou seja, quanto do request é `tools` e quanto é `messages`. Comparar bytes de log com tokens cobrados dá erro.

---

# 3. PROTOCOLO DOS QUATRO TESTES

## 3.1 Antes de começar

1. Encerre conversas abertas e **crie uma conversa nova para cada teste**. Histórico de conversa é a maior fonte de contaminação entre medições.
2. Anote o modelo configurado. Se for `deepseek-chat` ou `deepseek-reasoner` muda o que aparece em `reasoningTokens`.
3. Faça os testes 1 e 2 em sequência, sem nada no meio, para o cache de prompt não confundir a comparação.
4. Depois de **cada** teste, vá direto em Eu > Sobre > logs de requisição de IA. Não mande outra mensagem antes de olhar, por causa do limite de dez entradas.

## 3.2 Os testes

**Teste 1: "oi" em Agent Mode.** Conversa nova, modo agente. Espere a resposta. Abra os logs. Deve haver **uma** entrada nova.

**Teste 2: "oi" em Chat Mode.** Conversa nova, modo chat. Mesma coisa.

**Teste 3: "abra o navegador" em Agent Mode.** Conversa nova. Deixe rodar até terminar ou até você interromper. Abra os logs e conte **quantas entradas novas** apareceram: esse número é a quantidade de chamadas ao modelo e, portanto, de iterações do loop.

**Teste 4: o caso grande.** Se você não consegue reproduzir o de 200 mil tokens, use o mais próximo que tiver, por exemplo pedir para ler ou analisar um arquivo grande do workspace. Aqui vale um aviso: se o turno passar de dez chamadas, as primeiras somem do log. Se isso acontecer, registre isso na tabela em vez de tentar adivinhar. E não tente copiar o `requestJson` gigante no celular: para este teste, **basta o bloco `usage` da resposta**, que fica no fim do `responseJson` e é pequeno.

## 3.3 O que copiar, e para onde

A tela tem botão de copiar JSON (`_copyJson` em `ai_request_logs_page.dart:64`) e o texto é selecionável.

Para os testes 1, 2 e 3, cole aqui na conversa, para cada entrada:

- o `requestJson` completo, se couber;
- o `responseJson` completo, ou pelo menos o bloco `usage`.

**Eu meço tudo o resto.** Tamanho em bytes, contagem de ferramentas, tamanho do array `tools`, proporção entre `tools` e `messages`, quantidade de `role: "tool"`, quantidade de `tool_calls`, e a tabela preenchida. Você não precisa contar nada na mão.

Se o `requestJson` do teste 1 for grande demais para colar, cole em duas partes, ou cole só o começo até o fim do array `tools` e me diga que cortou.

## 3.4 A tabela para preencher

Deixo no formato que você pediu, com duas colunas extras que você listou nos dados e que faltavam no cabeçalho:

| Teste | Prompt | Cached | Completion | Request JSON | Tools | LLM calls | Iterações |
|---|---|---|---|---|---|---|---|
| oi, Agent | | | | | | | |
| oi, Chat | | | | | | | |
| navegador | | | | | | | |
| caso ~200k | | | | | | | |

Complementares, se aparecerem: `reasoningTokens`, `cacheCreationTokens`, tamanho do `responseJson`, tamanho do array `tools`, quantidade de tool calls.

---

# 4. O QUE EU CONSEGUI MEDIR SEM O APARELHO

Uma coisa não depende do celular: **quanto um resultado de ferramenta infla entre sair do handler e chegar ao modelo.** Isso é determinado pelo código, então simulei exatamente o que `SkillsToolHandler` e `AgentEventAdapter.toolResultContent` fazem, com serialização equivalente à do `kotlinx.serialization` com `prettyPrint`.

**Classificação: SIMULAÇÃO.** Não é medição no aparelho. As premissas estão declaradas.

## 4.1 Caso `skills_read`, com uma SKILL.md real de 5,3 KB

| Cenário | Bytes entregues ao modelo | Fator |
|---|---|---|
| Hoje, com a deduplicação funcionando | 7.266 | 1,33x |
| Hoje, se o preview diferir em um caractere | 14.119 | 2,58x |
| `prettyPrint` desligado | 6.972 | 1,28x |
| Com normalizador (objeto, uma cópia, compacto) | 5.856 | 1,07x |

## 4.2 Caso `terminal_execute`, com 13,5 KB de saída cheia de aspas e quebras de linha

| Cenário | Bytes entregues ao modelo | Fator |
|---|---|---|
| Hoje, deduplicação funcionando, `terminalOutput` presente | 31.899 | 2,31x |
| Hoje, deduplicação falhando | 48.706 | 3,53x |
| `prettyPrint` desligado | 31.794 | 2,30x |
| Com normalizador | 14.953 | 1,08x |

## 4.3 Atribuição isolada, que é o número que importa

Partindo do caso de terminal com deduplicação funcionando, mexendo em **uma** coisa por vez:

| Mudança isolada | Redução |
|---|---|
| Remover a cópia `terminalOutput` | **47%** |
| Desligar `prettyPrint` | **0%** |
| Garantir cópia única de preview | 0% neste caso, porque a dedupe já funcionou |
| Trocar string-de-JSON por objeto | 6% |
| Normalizador completo | **53%** |

## 4.4 Duas correções ao que eu escrevi antes

**Correção 1. Eu disse que `prettyPrint = true` era "a correção de melhor relação entre esforço e retorno de toda a análise". Está errado.** Para resultado de ferramenta, desligar `prettyPrint` reduz zero por cento. A indentação é irrelevante quando o volume vem de conteúdo duplicado. Ele pode continuar valendo para outros JSON no caminho, como argumentos de chamada de ferramenta, mas não para o que eu usei como justificativa.

**Correção 2. Eu disse que o escape duplo explicava "14 KB virando 56 a 60 KB". Exagerei.** O escape duplo sozinho responde por cerca de 6%. O que de fato multiplica é a **terceira cópia**: no `TerminalResult`, o mesmo texto vai em `rawResultJson` e outra vez em `terminalOutput`, e nenhuma deduplicação cobre esse par. Com a deduplicação falhando, aí sim chega a 3,53x, que é a faixa que você observou. Então o mecanismo é duplicação e triplicação de conteúdo, não escape.

Isso reordena a prioridade dentro do item B3/B4/B8: **B8, que eu havia classificado como gravidade média, é na verdade a maior causa isolada de inflação em resultado de ferramenta.**

---

# 5. RESPOSTAS PROVISÓRIAS ÀS SUAS SEIS PERGUNTAS

Cada uma marcada pelo tipo de evidência que eu tenho hoje.

**1. O catálogo completo de ferramentas está causando grande parte do custo?**
**PRECISA DO APARELHO.** O que eu sei: são 44 ferramentas embutidas, mais plugin e MCP, enviadas sempre fora do `chat_only` (`AgentConversationModePolicy.kt:83-86`), e o `AgentToolDefinitions.kt` tem 25.436 caracteres de literais de string nos construtores, o que me faz estimar de 30 a 45 KB de JSON serializado. Mas se o cache da DeepSeek estiver absorvendo esse prefixo, o custo em dinheiro é uma fração da contagem de tokens. A comparação entre o teste 1 e o teste 2 responde isso de forma definitiva, e é a razão pela qual esses dois testes vêm primeiro.

**2. O cache está funcionando e quanto ele absorve?**
**PRECISA DO APARELHO.** O campo existe e é extraído (`HttpController.kt:515`). O número aparece em `cachedTokens`. A leitura é simples: `cachedTokens / promptTokens` no teste 1 repetido duas vezes seguidas na mesma conversa. Se a segunda chamada mostrar cache alto e a primeira não, o cache funciona e o problema é só a primeira mensagem de cada sessão.

**3. Existe duplicação de tool results?**
**SIM, CONFIRMADO POR CÓDIGO E QUANTIFICADO POR SIMULAÇÃO.** Esta é a única das seis que eu posso responder sem o aparelho. Em `TerminalResult` e `Interrupted`, o mesmo conteúdo aparece em `rawResultJson` e em `terminalOutput`, sem nenhuma deduplicação. Em todos os tipos, `previewJson` só é removido quando é byte a byte idêntico a `rawResultJson` (`AgentEventAdapter.kt:178-181`). Fator medido: 2,31x no caso bom, 3,53x no caso ruim, contra 1,08x com normalizador. Um detalhe que descobri e que ameniza: para `skills_read`, as duas cópias vêm da mesma função determinística, então a dedupe funciona e o fator cai para 1,33x.

**4. O Agent Loop faz chamadas ou iterações desnecessárias?**
**PARCIALMENTE RESPONDIDO POR CÓDIGO.** Confirmado: `AgentOrchestrator.kt:136` é `roundLoop@ while (true)` e não existe comparação contra máximo em nenhum ponto do arquivo. O loop termina quando o modelo para de pedir ferramenta, quando um erro marca `terminated = true` ou por cancelamento. Isso significa que **nada impede** iterações desnecessárias. Se elas acontecem na prática, só o teste 3 e o teste 4 mostram, contando as entradas de log.

**5. O `requestJson` carrega contexto excessivo?**
**PRECISA DO APARELHO.** Duas coisas a favor do código, que eu já verifiquei: corpo de skill não é injetado (`OmniAgentExecutor.kt:226-229`) e memória não é injetada (`:204-210`). Então, se houver excesso, ele vem de `tools`, de histórico acumulado, ou de resultados de ferramenta antigos que ainda estão no histórico. Colando o `requestJson` você descobre qual dos três, porque eu meço a proporção entre os blocos.

**6. Qual parece ser o maior gargalo real?**
**HIPÓTESE, e é o que os testes existem para confirmar ou derrubar.** Minha melhor hipótese hoje, já corrigida pela simulação: em conversa curta, o gargalo é o catálogo de ferramentas na primeira chamada de cada sessão, mitigado por cache nas seguintes. Em tarefa com ferramentas, o gargalo passa a ser **resultado de ferramenta duplicado dentro de um loop sem teto**, porque cada rodada reenvia o histórico inteiro, e o histórico contém resultados inflados em 2,3 a 3,5 vezes. Os dois efeitos se multiplicam: dez rodadas com resultados triplicados custa o que eu suspeito que gerou o seu caso de 200 mil.

---

# 6. ORDEM DAS PRÓXIMAS ALTERAÇÕES, COMO ÁRVORE DE DECISÃO

Você pediu a ordem com base nos números. Como os números ainda não existem, entrego a regra de decisão em vez de uma lista fixa. Cada ramo abaixo é decidido por um valor que os quatro testes produzem.

**Fixo, independente de qualquer número: P0 é o teto do Agent Loop.**
Não é otimização, é proteção. Um loop sem limite máximo, em um app pessoal com chave de API própria, é risco financeiro aberto. Mesmo que os testes mostrem que hoje ele nunca passa de três rodadas, o teto entra primeiro, porque o custo de implementar é uma condição no `while` e o custo de não ter é ilimitado.

**Ramo A. Se no teste 3 ou 4 a contagem de iterações for alta, ou passar de dez entradas de log.**
Então a ordem é: teto do loop, depois detecção de repetição de chamada, depois o normalizador. O loop é o multiplicador e tem de ser contido antes de qualquer coisa que reduza o tamanho de cada rodada.

**Ramo B. Se `cachedTokens / promptTokens` no teste 1 repetido for acima de uns 70%.**
Então o catálogo de ferramentas **não** é o vilão em conversa, e a prioridade do escopo de ferramentas cai. A ordem passa a ser: teto do loop, normalizador de resultado (começando por remover `terminalOutput` duplicado, que é 47% sozinho), e só depois escopo de ferramentas.

**Ramo C. Se `cachedTokens` for zero ou perto disso.**
Então o cache não está funcionando, o catálogo é pago inteiro em toda chamada, e o escopo de ferramentas sobe para logo depois do teto do loop. Vale também investigar por que o cache não pega, porque `PromptCacheKeyStore` existe e está sendo usado, e isso pode ser um bug de ordem de mensagens em vez de um problema de arquitetura.

**Ramo D. Se a diferença entre o teste 1 (Agent) e o teste 2 (Chat) for pequena.**
Então minha hipótese central está errada, o catálogo não domina, e o roteador automático deixa de ser a primeira entrega de produto. Nesse caso a prioridade vira tamanho de histórico e resultado de ferramenta, e eu reescrevo a seção de prioridades do Master Architecture antes de qualquer código.

**Ramo E. Se o teste 4 mostrar um único resultado de ferramenta gigante.**
Então a correção é teto por resultado com offload, e não normalização. O `AgentWorkspaceManager.writeOffload` já existe e já é usado pelo compactador; o que falta é aplicar antes, no momento em que o resultado é criado.

Em todos os ramos, a instrumentação (`executionId`, decomposição por bloco, aumento do `MAX_LOG_COUNT`, exposição do `toolBudget` que o orquestrador já calcula) entra logo depois do P0, porque sem ela cada correção seguinte volta a ser discussão em vez de medição.

---

# 7. O QUE FALTOU, EXPLICITAMENTE

Você pediu para eu dizer o que faltou em vez de inventar. Lista completa:

1. **Todos os doze dados dos quatro testes.** Nenhum foi medido. Preciso do seu aparelho.
2. **A linha de log `[TokenUsage] recording:`**, que traria tudo de uma vez. Indisponível sem PC, porque é `OmniLog.i` e só ERROR e ASSERT vão para o armazenamento de log lido pelo app.
3. **A contagem exata de ferramentas por turno** (`request_tools=N`). Mesma razão.
4. **O tamanho real, no fio, do array `tools` serializado.** Minha estimativa de 30 a 45 KB vem de contar literais de string no fonte Kotlin, não de serializar. Só a medição fecha.
5. **`cacheCreationTokens` em qualquer tela do app.** O Kotlin manda, o modelo Dart não lê. Está no `responseJson` bruto, e é de lá que você tira.
6. **Se o seu fork divergiu do commit `54aeae8`.** Todos os números de linha e comportamentos que eu citei são do upstream de hoje.
7. **O modelo configurado no seu app.** Muda o que aparece em `reasoningTokens` e a política de cache.

---

Nenhuma linha do projeto foi alterada. Quando você trouxer os logs, eu preencho a tabela, respondo as seis perguntas com dado em vez de hipótese, e fecho a ordem das alterações no ramo que os números indicarem.
