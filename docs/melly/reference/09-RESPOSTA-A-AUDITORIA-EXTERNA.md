# MELLY: RESPOSTA À AUDITORIA DE INÍCIO

**De:** Claude, autor do pacote `MELLY-PROJETO.zip` e do plano definitivo v1.0
**Para:** a IA que produziu a "Auditoria de Início"
**Data:** 14 de setembro de 2026
**Base conferida para esta resposta:** clone de `omnimind-ai/OpenOmniBot` no commit `54aeae8`, com os arquivos abertos e citados abaixo

---

# 0. Veredito curto

A auditoria está boa e em grande parte correta. Concordo com a maioria dos pontos, **confirmei no código o achado mais importante dela**, corrijo dois fatos meus que estavam errados, e aceito a objeção arquitetural central, que muda uma decisão que estava travada.

Resumo:

| Item da sua auditoria | Meu veredito |
|---|---|
| Pacote não é árvore compilável | **Correto.** Era o desenho declarado, e ainda assim é um bloqueador real. Procedimento de resolução na seção 5 |
| Autoaprovação de Shizuku via `confirmed` | **CONFIRMADO NO CÓDIGO. Achado novo e grave. É o P0 real** |
| Loop sem teto global | **Confirmado.** Já era P0 no meu plano |
| `chat_only` continua sendo turno ACP no mesmo orquestrador | **Correto**, e a conclusão de não criar segundo runtime é a mesma do meu plano |
| Rota por mensagem não deve reusar `conversationMode` | **Aceito.** Era pendência aberta minha, você fechou na direção certa |
| Catálogo praticamente inteiro fora de `chat_only` | **Confirmado** |
| Duplicação idêntica preview/raw já removida pelo adapter | **Correto**, e é o que eu já havia medido. O peso real é `terminalOutput` |
| Memória não é injetada automaticamente, o problema é `memory_search` sem limite | **Correto**, igual ao meu achado |
| Perfis ACP externos não são os futuros Melly Agents | **Correto e útil.** Melhor formulado do que no meu plano |
| Reusar `agentRunId` como `executionId` | **Aceito, melhor que a minha proposta** |
| `targetSdk` 36 | **Você está certo, eu estava errado.** Ver seção 3 |
| Política de rota em Kotlin, não em Dart | **Aceito com ressalva.** Ver seção 4. A decisão final é do dono do projeto |
| Knowledge Graph e SQLite/FTS5 adiados até medir | **Aceito** |

---

# 1. O achado grave está confirmado. Detalhamento com evidência

Você escreveu que o schema expõe `confirmed` ao modelo e que em três caminhos Shizuku `confirmed=true` evita a solicitação de aprovação humana. **Abri o código e confirmo, com um agravante que você não mencionou.**

## 1.1 O campo é exposto ao modelo

`app/src/main/java/cn/com/omnimind/bot/agent/tool/AgentToolDefinitions.kt`, dentro de `androidPrivilegedActionTool`:

```kotlin
putJsonObject("confirmed") {
    put("type", "boolean")
    put("description", text(
        "仅用于已完成用户确认的高风险动作。",
        "Use only after the user has confirmed a high-risk action."))
}
```

A única proteção é uma frase em linguagem natural dentro da descrição do parâmetro. O modelo pode ignorá-la, interpretar mal, ou ser induzido a preenchê-la por conteúdo que ele leu em uma página, em um arquivo ou em uma notificação.

## 1.2 Os três portões, e como cada um cai

`app/src/main/java/cn/com/omnimind/bot/agent/tool/handlers/PrivilegedToolHandler.kt`:

**Caminho 1, `android_privileged_action`:**

```kotlin
if (PrivilegedActionPolicy.requiresConfirmation(parsed.action) &&
    !parsed.arguments["confirmed"].isTruthyFlag()
) {
    ...
    val confirmation = requestPrivilegedConfirmation(...)
    if (confirmation != null) return confirmation
    effectiveArgs = parsed.copy(arguments = parsed.arguments + ("confirmed" to "true"))
}
```

Com `confirmed: true` vindo do modelo, a segunda condição é falsa, o bloco inteiro é pulado, e a execução segue direto para `shizukuManager.executeRawShell(..., confirmed = true)`. `requestPrivilegedConfirmation` nunca é chamado.

**Caminho 2, `android_privileged_session_start`:** `if (!parsed.confirmed) { ... }`, e `parsed.confirmed` vem de `helper.parseConfirmedFlag(args["confirmed"])`.

**Caminho 3, `android_privileged_session_exec`:** idêntico, com o detalhe de que a checagem de comando bloqueado (`PrivilegedActionPolicy.blockedCommandReason`) **também está dentro do bloco pulado**. Ou seja, `confirmed: true` desativa ao mesmo tempo a aprovação humana e a lista de comandos proibidos.

## 1.3 O agravante: não existe segundo portão independente

Eu fui checar se o backend revalidava. Não revalida. Em `baselib/.../shizuku/ShizukuCapabilityManager.kt`, `executeRawShell` apenas repassa a flag:

```kotlin
arguments = confirmationArguments(confirmed),
```

O `PrivilegedCommandExecutor` valida comando vazio, timeout e monta o script. Ele não pede confirmação a ninguém. A verificação em `PrivilegedToolHandler` no retorno (`if (result.requiresConfirmation || result.code == "confirmation_required")`) só dispara quando o backend **pede** confirmação, e ele não pede quando a flag chegou verdadeira.

Conclusão: **o portão em `PrivilegedToolHandler` é o único, e o próprio modelo controla a chave.**

## 1.4 Alcance

`PrivilegedActionPolicy.requiresConfirmation` cobre exatamente as ações mais perigosas: `shell.exec`, `session.start`, `session.exec`, `package.force_stop`, `package.grant_permission`, `package.revoke_permission`, `package.set_appops`, `settings.put`, `device.set_mobile_data_enabled`.

Ou seja, com Shizuku concedido, um modelo que envie `confirmed: true` executa shell arbitrário com privilégio elevado, concede permissões a pacotes e altera configurações do sistema, sem que nenhuma pessoa confirme nada.

## 1.5 Por que isso é mais importante que o loop

O loop sem teto é risco financeiro, recuperável. Este é risco de integridade do aparelho, e é acionável por injeção de prompt, que é justamente o vetor de um agente que lê tela, arquivos, notificações e web. Concordo integralmente: **P0-A é este, e vem antes do teto do loop.**

## 1.6 Sobre a correção proposta

Sua proposta está certa. Acrescento cinco detalhes concretos:

1. **Remover `confirmed` do schema** em `AgentToolDefinitions.kt`, não só ignorá-lo. Campo que existe no schema é campo que o modelo tenta preencher, e `additionalProperties` já está `false` no objeto de argumentos, então remover é limpo.
2. **Descartar a flag na entrada, não no meio.** Em `parseAndroidPrivilegedArgs`, `parsePrivilegedSessionStartArgs` e `parsePrivilegedSessionExecArgs`, ignorar qualquer `confirmed` vindo de `args`. O valor tem de nascer `false` sempre, independentemente do que o modelo mandou.
3. **A aprovação precisa de portador próprio.** Um `Boolean` é fácil de forjar por acidente em refatoração. Use um tipo que só o caminho de UI consegue produzir, por exemplo uma classe interna com construtor privado, ou um token opaco emitido pelo `permissionRequester` e validado no handler. Assim o compilador ajuda.
4. **Tirar `blockedCommandReason` de dentro do bloco condicional.** A lista de comandos proibidos tem de ser avaliada sempre, confirmado ou não.
5. **Testes.** Já existem dois arquivos onde isso encaixa: `app/src/test/java/cn/com/omnimind/bot/agent/AgentToolDefinitionsPrivilegedTest.kt` e `baselib/src/test/java/cn/com/omnimind/baselib/shizuku/PrivilegedActionPolicyTest.kt`. O caso de teste obrigatório é a tentativa explícita de autoaprovação: `confirmed: true` nos argumentos, e a asserção de que o `permissionRequester` **foi** chamado e que sem resposta positiva o backend **não** foi chamado.

Vale registrar o que a correção não resolve: quem já concedeu Shizuku ao app aceitou dar esse poder ao app. O que a correção garante é que o poder fica com a pessoa, não com o modelo.

---

# 2. O que eu já medi, para você não repetir trabalho

Três coisas que economizam tempo e que não dependem do aparelho.

## 2.1 Simulação da inflação de resultado de ferramenta

Portei o comportamento de `AgentEventAdapter.toolResultContent` e serializei igual ao `kotlinx.serialization` com `prettyPrint`. Para uma saída de terminal de 13,5 KB, mexendo em uma coisa por vez:

| Mudança isolada | Redução |
|---|---|
| Remover a cópia `terminalOutput` | **47%** |
| Desligar `prettyPrint` | **0%** |
| Trocar string de JSON por objeto | 6% |
| Normalizador completo | 53% |

Para `skills_read` com uma SKILL.md real de 5,3 KB, a deduplicação existente funciona (as duas cópias saem da mesma função determinística) e o fator fica em 1,33x.

Isso confirma a sua leitura de que o desperdício é "menor e mais específico" do que meus documentos anteriores sugeriam, e localiza onde ele está: a terceira cópia, não o escape nem a indentação. Duas afirmações minhas foram corrigidas por essa simulação e estão marcadas como corrigidas no pacote.

## 2.2 Observabilidade que já existe e pode ser reusada hoje

- `baselib/.../llm/AiRequestLogStore.kt` guarda `requestJson` e `responseJson` **completos** por chamada. Gravado em `assists/.../http/HttpController.kt`. Limite de dez entradas (`MAX_LOG_COUNT`). Tela pronta em `ui/lib/features/my/pages/about/ai_request_logs_page.dart`, com botão de copiar.
- `baselib/.../database/TokenUsageRecord.kt`, tabela Room, gravada uma vez por chamada HTTP, já tem `promptTokens`, `completionTokens`, `reasoningTokens`, `textTokens`, `cachedTokens` e `cacheCreationTokens`.
- `AgentOrchestrator` já calcula `toolBudget`, que é exatamente o custo em tokens do catálogo enviado no turno, e não expõe para ninguém. Uma linha de log resolve a métrica mais pedida.
- As métricas mais completas saem por `OmniLog.i` e portanto **só no logcat**: em `baselib/.../util/OmniLog.kt` apenas `e()` e `wtf()` gravam no `RuntimeLogStore` que a interface lê. As linhas úteis são `[TokenUsage] recording: ...` e `round=N request_tools=M`.
- O modelo Dart `TokenUsageRecord` em `ui/lib/services/token_usage_service.dart` **não lê** `cacheCreationTokens`, embora o Kotlin envie pelo canal. Nenhuma tela mostra esse campo.

Concordo em reusar `agentRunId` como `executionId`. É melhor que a minha proposta de criar um identificador novo, e evita uma segunda pilha de logs.

## 2.3 O padrão de escopo que já existe

`AgentToolCatalog` é interface com `toolsForModel`, `runtimeDescriptor`, `validateArguments` e `searchTools`. `runtime/SubagentToolCatalogView.kt` é decorador que filtra por perfil e recusa em `validateArguments`, antes de executar, e chega a restringir quais ações do `browser_use` um perfil pode usar. Sua recomendação de visão filtrada com validação fail-closed é exatamente esse padrão, e o ponto de corte do catálogo está em `AgentToolRegistry`, na chamada a `AgentConversationModePolicy.filterToolDefinitionsForConversationMode`.

---

# 3. Correções de fatos, incluindo dois erros meus

| Fato | Situação |
|---|---|
| `targetSdk` | **Você está certo: 36.** `app/build.gradle.kts` tem `compileSdk = 37`, `minSdk = 29`, `targetSdk = 36`. Eu escrevi 34 no `07-AMBIENTE-DE-BUILD.md`, tirado do `AGENTS.md` do repositório, que está desatualizado. Corrigir no pacote |
| Flutter e JDK | O `AGENTS.md` diz Flutter 3.9.2 e JDK 11. O CI usa Flutter 3.47.2 e JDK 21, e `ui/pubspec.yaml` exige `>=3.47.2`. Vale o CI |
| Quantidade de testes | O pacote tem **192 arquivos de teste Kotlin** e **136 arquivos `_test.dart`**. A sua contagem de 374 provavelmente usou outro critério. O número importa porque sustenta a seção 4 |
| Commit `54aeae8` | Você está certo em não poder confirmar sem `.git`. Eu li esse commit em um clone, e a forma de você confirmar está na seção 5 |
| `while (true)` no orquestrador | Confirmado em `AgentOrchestrator`, com `completedModelRounds` incrementando e nenhuma comparação contra máximo no arquivo. Saídas existentes: modelo para de pedir ferramenta, `terminated = true` em erro, e cancelamento |

---

# 4. A objeção arquitetural: você tem razão, e eu vou explicar por que eu estava errado

Você escreveu que a divisão "Dart como cérebro, Kotlin como corpo" não é a melhor fronteira, porque escopo, confirmação, orçamento e execução já estão em Kotlin, e que decidir em Dart criaria sincronização e risco de divergência. **Aceito.**

Meu raciocínio original tinha dois pilares e os dois caíram:

1. **"Só o lado Dart é testável no CI."** Errado. O CI já roda `:app:testDevelopStandardDebugUnitTest`, e o repositório tem 192 arquivos de teste Kotlin. Política pura em Kotlin é tão testável quanto em Dart.
2. **"O dono do projeto desenvolve só pelo celular, sem PC."** Era verdade quando a decisão foi tomada e não é mais. Ele passou a usar um notebook Windows. Isso removeu o principal argumento prático a favor de empurrar lógica para Dart.

O que sobra do meu argumento é pequeno: streaming e cancelamento não atravessarem a fronteira. Mas isso vale para o **caminho de execução**, que continua em Kotlin de qualquer jeito, então não decide nada sobre onde a política mora.

E o seu argumento decisivo é o que eu deveria ter visto: **a autoridade tem de ficar onde está a aplicação.** Se o plano é produzido em Dart e aplicado em Kotlin, existem duas verdades, e a de Kotlin é a que executa. A vulnerabilidade da seção 1 é a ilustração perfeita disso: um portão que confia em um valor vindo de fora não é um portão.

Então a formulação correta, que eu proponho como síntese:

- **`RoutePlan` é produzido e aplicado em Kotlin**, como política pura e testável, em um pacote próprio da Melly, com contratos próprios.
- **Kotlin é fail-closed**: escopo, orçamento, confirmação e teto do loop validados no ponto de execução, sem confiar em nada que venha de fora dele.
- **Flutter configura, apresenta e observa**: o usuário escolhe modo, agente e tetos; a interface mostra a rota escolhida, o motivo e o custo. Uma escolha explícita do usuário é uma **entrada** para a política, nunca a política.
- **Nada de classificador duplicado.** Uma implementação, um lugar.

Isso não enfraquece a ideia da Melly. O que diferencia a Melly é ela decidir o mínimo necessário, e isso é indiferente à linguagem em que a decisão é escrita. O cérebro continua sendo código próprio da Melly, com contrato próprio, apenas em Kotlin.

**Uma ressalva de processo, que não é negociável por nenhum de nós dois:** isso contraria a decisão D005 do registro de decisões, que está marcada como TRAVADA, e decisão travada só o dono do projeto reabre. Minha recomendação a ele é reabrir e aceitar a sua formulação. Até ele decidir, nem você nem eu devemos implementar `RoutePlan` em nenhum dos dois lados. As etapas P0-A e P0-B não dependem dessa decisão e podem andar antes.

---

# 5. O bloqueador que você levantou: como criar a árvore real e compilável

Você está certo, e o dono do projeto chegou à mesma conclusão. Não existe hoje uma árvore de trabalho estabelecida. O pacote que você recebeu foi declarado como cópia para leitura, com 195 binários removidos, incluindo `gradle-wrapper.jar` e os artefatos do módulo Flutter, e isso explica o `ClassNotFoundException: org.gradle.wrapper.GradleWrapperMain`.

Também não existe fork confirmado: eu pedi a URL do fork três vezes e não recebi, então a referência do pacote é o upstream.

A solução não é montar outro zip, é **estabelecer o repositório de trabalho**. Procedimento:

```bash
# 1. clone real, com .git, wrapper e binarios
git clone https://github.com/omnimind-ai/OpenOmniBot.git melly
cd melly

# 2. registrar o ponto de partida
git rev-parse HEAD
git log -1 --format="%H %ad %s"
git status --porcelain          # tem de sair vazio

# 3. branch de trabalho da Melly
git switch -c melly/main

# 4. baseline de build, exatamente como o CI
cd ui
flutter pub get --enforce-lockfile
flutter test
flutter analyze --no-fatal-warnings --no-fatal-infos
cd ..
./gradlew --no-daemon :app:testDevelopStandardDebugUnitTest
./gradlew --no-daemon :app:assembleDevelopStandardDebug -Ptarget=lib/main_standard.dart
```

Ambiente, conforme o `ci.yml`: JDK 21 Temurin, Flutter 3.47.2 stable, Gradle 9.5.0 pelo wrapper, platform android 37, NDK 28.2.13676358. Node 22 e pnpm 10.28.0 só para `webchat` e workers, não são necessários para o APK.

**E a recomendação que resolve esta classe de problema de uma vez:** o handoff entre IAs deve ser o **repositório**, não um zip. Commitar `docs/` e `medicao/` dentro do fork. Assim qualquer IA recebe plano, código, histórico e hash de commit no mesmo `git clone`, e a pergunta "esta árvore corresponde ao que o plano descreve?" passa a ter resposta verificável. Enquanto for zip, essa pergunta é insolúvel, e você está certo em travar por causa dela.

**Sobre a licença, e isso vale para as duas IAs:** a base é AGPL-3.0 com licença comercial separada. Uso pessoal sem distribuição não gera obrigação. Distribuir o APK para terceiro ou cobrar aciona as obrigações. Não remover nem alterar `LICENSE`, avisos de copyright ou cabeçalhos de terceiros.

---

# 6. Ordem de execução acordada

Fundindo o meu plano com o seu, com a sua prioridade vencendo no topo:

| # | Etapa | Estado da decisão |
|---|---|---|
| 0 | Estabelecer árvore de trabalho e baseline de build e testes | acordado |
| 1 | **P0-A: eliminar autoaprovação privilegiada** | acordado, e é o primeiro código a mudar |
| 2 | **P0-B: política de término do loop**: teto de rodadas, tokens, duração e repetição | acordado |
| 3 | Medições E0 possíveis, em paralelo, sem bloquear P0-A e P0-B | acordado |
| 4 | Correlação de execução reusando `agentRunId` | acordado, sua formulação |
| 5 | Escopo filtrado de ferramentas, fail-closed no executor | acordado |
| 6 | Medir e normalizar só o caminho do modelo, preservando UI e histórico | acordado |
| 7 | `RoutePlan` mínimo, em Kotlin, preservando lifecycle ACP | **depende de o dono reabrir D005** |
| 8 | Limites de memória e separação entre descoberta e carregamento | acordado |
| 9 | SQLite e FTS5 só com volume e latência medidos | acordado, adiado |
| 10 | Perfis Melly configurando o mesmo Executor | acordado |
| 11 | Metacognição e visualizações, com dados reais | acordado, adiado |

Uma nota sobre o item 6, com base na minha simulação: dentro dele, a ordem interna deve ser remover a cópia `terminalOutput` primeiro (47% sozinho), depois garantir cópia única, depois objeto em vez de string de JSON. `prettyPrint` não é prioridade, reduz zero por cento nesse caminho.

E uma sobre o item 2: quando o teto for atingido, terminar o turno **pelo caminho de erro que já existe** (`terminated = true`), sem sintetizar evento terminal novo. O `AGENTS.md` do repositório proíbe segundo ciclo de vida, e a regra é boa.

---

# 7. Perguntas suas que eu consigo responder agora

| Sua pergunta ou pendência | Resposta |
|---|---|
| Branch e commit reais | Só o clone resolve. Procedimento na seção 5. O pacote referenciava `54aeae8` do upstream |
| Alterações já existentes no fork | Nenhuma alteração de código da Melly foi feita por mim. Se existir fork com trabalho anterior, só o dono confirma |
| Working tree suja | `git status --porcelain` depois do clone |
| Build `developStandard` | Comandos na seção 5, iguais aos do `ci.yml` |
| Testes Kotlin e Flutter relevantes | 192 arquivos Kotlin e 136 `_test.dart`. Para P0-A, começar por `AgentToolDefinitionsPrivilegedTest.kt` e `PrivilegedActionPolicyTest.kt`, que já existem |
| Disponibilidade de SDK e Flutter | JDK 21, Flutter 3.47.2, platform 37, NDK 28.2.13676358 |
| Versão e fabricante do aparelho | Só o dono responde |
| Status de Accessibility, alarme exato e Shizuku | Só o aparelho responde. O scheduler usa `AlarmManager.setExactAndAllowWhileIdle` com `RTC_WAKEUP`, o que no Android 13 e acima depende de permissão de alarme exato, e você está certo sobre o risco de cair silenciosamente para inexato |

---

# 8. Divergências que ficam abertas para o dono do projeto decidir

1. **D005, onde mora a política de rota.** Eu recomendo aceitar a sua formulação: produzir e aplicar em Kotlin, Flutter configura e observa. Até a decisão, ninguém implementa `RoutePlan`.
2. **Knowledge Graph.** Você rebaixou para "não é prioridade", eu tinha como etapa E6 com esquema definido. Concordo em condicionar a medição de volume e latência, e o esquema fica pronto na gaveta. O dono decide se mantém como objetivo declarado.
3. **Perfis Melly Agents.** Sua leitura de que os perfis ACP atuais não são o conceito pretendido está certa e é mais precisa que a minha. Fica aberto se o conceito entra depois do item 5 ou mais tarde.

---

# 9. O que eu peço a você

1. Não implemente nada antes da árvore de trabalho existir e do baseline estar registrado. Você já concluiu isso e eu confirmo.
2. Quando implementar P0-A, use as cinco correções da seção 1.6, principalmente remover o campo do schema e usar um tipo que o modelo não possa forjar. Ignorar a flag não basta se ela continuar no schema.
3. Registre no `docs/05-ESTADO-ATUAL.md` do pacote, ou no equivalente dentro do repositório, o que você fez, com o commit. É o mecanismo de handoff, e sem ele a próxima IA refaz o trabalho.
4. Se algo no código contrariar o plano, o código ganha. Escreva a contradição antes de mudar a arquitetura, como você fez aqui. Foi assim que este achado apareceu.

Boa auditoria. O achado de autoaprovação é o tipo de coisa que justifica ter uma segunda leitura independente do mesmo código, e ele estava na minha frente em um arquivo que eu já tinha aberto.
