# MELLY: ADENDO 01 AO PLANO DEFINITIVO

**Data:** 14 de setembro de 2026
**Emenda a:** `docs/00-PLANO-DEFINITIVO.md` v1.0
**Origem:** auditoria independente feita por outra IA sobre o pacote `MELLY-PROJETO.zip`, mais verificação minha no código
**Como usar:** salve este arquivo como `docs/08-ADENDO-01.md` dentro do pacote. O plano v1.0 continua válido, com as emendas abaixo. Onde o adendo discordar do plano, **o adendo vence**.

---

# 1. Emenda A: duas etapas novas antes de tudo

O plano começava em E0, medição. A auditoria externa mostrou que faltam duas etapas antes dela.

## E0-A. Estabelecer a árvore de trabalho e o baseline

**Objetivo:** ter um repositório Git real, compilável, com commit conhecido, e um baseline de build e testes registrado.

**Por que entrou:** o pacote distribuído é cópia para leitura, com 195 binários removidos, incluindo `gradle/wrapper/gradle-wrapper.jar` e os artefatos do módulo Flutter. Nele `./gradlew` falha com `ClassNotFoundException: org.gradle.wrapper.GradleWrapperMain`. Sem `.git` também não é possível confirmar que a árvore corresponde ao commit `54aeae8` que o plano cita. Qualquer implementação feita nesse estado é inverificável.

**Passos:**

```bash
git clone https://github.com/omnimind-ai/OpenOmniBot.git melly
cd melly
git rev-parse HEAD
git log -1 --format="%H %ad %s"
git status --porcelain            # tem de sair vazio
git switch -c melly/main

cd ui
flutter pub get --enforce-lockfile
flutter test
flutter analyze --no-fatal-warnings --no-fatal-infos
cd ..
./gradlew --no-daemon :app:testDevelopStandardDebugUnitTest
./gradlew --no-daemon :app:assembleDevelopStandardDebug -Ptarget=lib/main_standard.dart
```

**Teste de aceitação:** os cinco comandos passam, e o commit inicial, a contagem de testes que passaram e o tempo de build estão registrados no estado atual. Esse é o baseline: toda regressão futura é medida contra ele.

**Registro adicional:** se existir um fork anterior da Melly com trabalho já feito, ele é a árvore de trabalho e o upstream vira apenas referência. Isso precisa ser decidido antes de E0-A terminar.

## E0-B, P0-A. Eliminar a autoaprovação de operações privilegiadas

**Objetivo:** tornar impossível o modelo aprovar sozinho uma ação privilegiada.

**Por que entrou, e por que é o primeiro código a mudar:** verificado no código, em três caminhos.

`AgentToolDefinitions.kt`, em `androidPrivilegedActionTool`, expõe ao modelo um parâmetro booleano `confirmed`, protegido apenas pela frase "Use only after the user has confirmed a high-risk action" na descrição.

Em `PrivilegedToolHandler.kt`:

- `android_privileged_action`: a guarda é `if (requiresConfirmation(action) && !arguments["confirmed"].isTruthyFlag())`. Com `confirmed: true` vindo do modelo, o bloco é pulado e `requestPrivilegedConfirmation` nunca é chamado.
- `android_privileged_session_start`: `if (!parsed.confirmed)`, e o valor vem de `args["confirmed"]`.
- `android_privileged_session_exec`: idêntico, e com o agravante de que a checagem de comando bloqueado, `PrivilegedActionPolicy.blockedCommandReason`, está **dentro** do bloco pulado. A flag desativa ao mesmo tempo a aprovação humana e a lista de comandos proibidos.

Não existe segundo portão: `ShizukuCapabilityManager.executeRawShell` apenas repassa a flag em `confirmationArguments(confirmed)`, e o `PrivilegedCommandExecutor` não pede confirmação a ninguém.

Alcance, por `PrivilegedActionPolicy.requiresConfirmation`: `shell.exec`, `session.start`, `session.exec`, `package.force_stop`, `package.grant_permission`, `package.revoke_permission`, `package.set_appops`, `settings.put`, `device.set_mobile_data_enabled`.

Com Shizuku concedido, isso significa shell arbitrário com privilégio elevado sem nenhuma pessoa confirmar, acionável por injeção de prompt, que é o vetor natural de um agente que lê tela, arquivos, notificações e web.

**Arquivos:**

- `app/src/main/java/cn/com/omnimind/bot/agent/tool/AgentToolDefinitions.kt`
- `app/src/main/java/cn/com/omnimind/bot/agent/tool/handlers/PrivilegedToolHandler.kt`
- `app/src/test/java/cn/com/omnimind/bot/agent/AgentToolDefinitionsPrivilegedTest.kt` (já existe)
- `baselib/src/test/java/cn/com/omnimind/baselib/shizuku/PrivilegedActionPolicyTest.kt` (já existe)

**Passos:**

1. **Remover `confirmed` do schema**, não apenas ignorar. Campo que existe no schema é campo que o modelo tenta preencher. O objeto de argumentos já tem `additionalProperties: false`, então remover é limpo.
2. **Descartar a flag na entrada**: em `parseAndroidPrivilegedArgs`, `parsePrivilegedSessionStartArgs` e `parsePrivilegedSessionExecArgs`, ignorar qualquer `confirmed` vindo de `args`. O valor nasce `false` sempre.
3. **Dar portador próprio à aprovação.** Um `Boolean` é fácil de forjar por acidente em refatoração futura. Use um tipo que só o caminho de UI consiga produzir: classe com construtor privado, ou token opaco emitido pelo `permissionRequester` e validado no handler. O compilador passa a ajudar.
4. **Tirar `blockedCommandReason` de dentro do bloco condicional.** A lista de comandos proibidos é avaliada sempre.
5. **Testes obrigatórios:** tentativa explícita de autoaprovação com `confirmed: true` nos argumentos, asserção de que o `permissionRequester` foi chamado, e de que sem decisão positiva o backend não foi chamado.

**Teste de aceitação:**

```bash
./gradlew --no-daemon :app:testDevelopStandardDebugUnitTest
./gradlew --no-daemon :baselib:test
```

Os testes novos passam, e o schema publicado ao modelo não contém mais `confirmed`.

**Limite honesto da correção:** quem concedeu Shizuku ao app aceitou dar esse poder ao app. A correção garante que o poder fica com a pessoa, não com o modelo.

---

# 2. Emenda B: nova ordem canônica

```text
E0-A  arvore de trabalho e baseline        novo, bloqueia tudo
E0-B  P0-A: autoaprovacao privilegiada     novo, primeiro codigo a mudar
E1    P0-B: teto do loop
E0    medicao                              pode rodar em paralelo com E0-B e E1
E2    instrumentacao, reusando agentRunId
E3    normalizador de resultado            ordem entre E3 e E4 definida por E0
E4    escopo de ferramentas
E5    RoutePlan e roteamento               BLOQUEADA ate D005 ser decidida
E6    memoria: limites primeiro, grafo depois de medir
E7    agents
E8    metacognicao
E9    acabamento
E10   fechamento
```

Mudanças em relação ao plano v1.0: E0-A e E0-B entram na frente; E0 deixa de ser bloqueante e passa a correr em paralelo, porque as duas correções de segurança e de custo não dependem de medição; E5 fica bloqueada por decisão pendente.

---

# 3. Emenda C: correções de fato

| O que o plano dizia | Correto |
|---|---|
| `targetSdk` 34 | **36.** `app/build.gradle.kts`: `compileSdk = 37`, `minSdk = 29`, `targetSdk = 36`. O valor errado veio do `AGENTS.md` do repositório, que está desatualizado |
| Flutter 3.9.2 e JDK 11, no `AGENTS.md` | Flutter **3.47.2** e JDK **21**, conforme `ci.yml` e `ui/pubspec.yaml` |
| Sem contagem de testes | **192** arquivos de teste Kotlin e **136** arquivos `_test.dart` |

O item do `targetSdk` importa além da precisão: com `targetSdk 36` as restrições de início de foreground service a partir do background são mais rígidas, o que reforça a conclusão de que automação totalmente autônoma em segundo plano não é viável de forma geral, só dentro das exceções do Android.

---

# 4. Emenda D: D005 é reaberta

A decisão D005 dizia "cérebro em Dart, Kotlin como camada de capacidades", e estava TRAVADA. **Ela volta a ABERTA**, como A005, por dois motivos técnicos:

1. Escopo, confirmação, orçamento e execução já estão em Kotlin. Produzir o plano em Dart e aplicar em Kotlin cria duas verdades, e a que executa é a de Kotlin. A vulnerabilidade da emenda A é exatamente o que acontece quando um portão confia em valor vindo de fora.
2. Os dois pilares do raciocínio original caíram. O primeiro era "só Dart é testável no CI", e é falso: o CI já roda `:app:testDevelopStandardDebugUnitTest` e existem 192 arquivos de teste Kotlin. O segundo era "desenvolvimento só pelo celular, sem PC", e não vale mais.

**Recomendação:** aceitar a formulação abaixo.

- `RoutePlan` é **produzido e aplicado em Kotlin**, como política pura e testável, em pacote próprio da Melly, com contratos próprios.
- Kotlin é **fail-closed**: escopo, orçamento, confirmação e teto do loop validados no ponto de execução, sem confiar em nada externo.
- Flutter **configura, apresenta e observa**. Escolha explícita do usuário é entrada para a política, nunca a política.
- **Nenhum classificador duplicado.** Uma implementação, um lugar.

Isso não enfraquece a Melly. O diferencial é decidir o mínimo necessário, e isso é indiferente à linguagem. O cérebro continua sendo código próprio da Melly.

**Enquanto A005 não for decidida pelo dono do projeto, ninguém implementa `RoutePlan` em nenhum dos dois lados.** E0-A, E0-B, E1, E0, E2, E3 e E4 não dependem dessa decisão.

---

# 5. Emenda E: ajustes dentro de etapas existentes

**E2, instrumentação.** Reusar o `agentRunId` que já existe como `executionId`, em vez de criar identificador novo, e não criar uma segunda pilha de logs em Dart. Já existem `TokenUsageRecord`, `AiRequestLogStore`, `RuntimeLogStore` e `InternalRunLogStore`; o que falta é correlação, não armazenamento.

**E3, normalizador.** Ordem interna definida por simulação: remover a cópia `terminalOutput` primeiro, porque vale 47% sozinha; depois garantir cópia única; depois trocar string de JSON por objeto, que vale 6%. `prettyPrint` sai da lista de prioridades, porque reduz zero por cento nesse caminho.

**E6, memória.** Invertida a ordem interna. Primeiro limitar `memory_search`, cujo padrão hoje é `Int.MAX_VALUE`, e separar descoberta de carregamento. SQLite com FTS5 e o Knowledge Graph só depois de medir volume e latência reais. O esquema do plano v1.0 continua válido como desenho pronto, não como próxima tarefa.

**E7, agents.** Os perfis ACP atuais descrevem comandos e runtimes externos, e o `SubagentDispatcher` cria outros `AgentOrchestrator`. Isso **não** é o conceito de Melly Agent. Não reaproveitar esses perfis semanticamente: o legado fica fora do caminho principal e o perfil leve de políticas é criado depois.

**Loop, E1.** Ao bater no teto, terminar o turno pelo caminho de erro que já existe (`terminated = true`), sem sintetizar evento terminal novo. Vale a proibição de segundo ciclo de vida do `AGENTS.md`.

---

# 6. Emenda F: o handoff passa a ser o repositório

Distribuir o projeto como zip criou um problema que nenhuma IA consegue resolver do lado dela: não há como confirmar que a árvore recebida corresponde ao que o plano descreve, e a árvore não compila.

**Nova regra de processo:** `docs/` e `medicao/` são commitados dentro do fork da Melly. O handoff entre IAs é o `git clone` mais o hash do commit. Zip só para quem não tem acesso ao repositório, e sempre declarado como cópia de leitura.

Consequência prática: toda IA que assumir uma etapa passa a poder responder "esta árvore é a que o plano descreve?" com `git rev-parse HEAD`.

---

# 7. O que continua valendo sem mudança

As sete invariantes da arquitetura, a definição de aplicativo funcional em C1 a C5, as regras de execução (uma etapa por vez, no máximo três arquivos Kotlin por etapa, nunca aplicar mudança por número de linha, nenhum teste tocando a API real), a lista do que não construir, e todas as outras decisões travadas do registro.

Duas delas ganham reforço com este adendo:

- **D003**, ação sensível exige confirmação explícita que o modelo não pode preencher. A emenda A é a implementação dessa decisão em um lugar onde o código a violava.
- **D008**, ciclo de vida único. Tanto o teto do loop quanto o roteamento têm de respeitar isso.
