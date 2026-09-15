> DOCUMENTO HISTORICO. Este arquivo e a origem do projeto, anterior a analise do codigo.
> Varias premissas dele foram corrigidas. A fonte de verdade atual e docs/00-PLANO-DEFINITIVO.md.

# MELLY — DOCUMENTO CENTRAL DO PROJETO
## Visão consolidada, arquitetura, capacidades, decisões, hipóteses e pendências

**Versão:** 0.1 — Consolidação de contexto  
**Objetivo deste documento:** servir como *handoff* completo do projeto para que outra IA possa continuar o desenvolvimento sem depender desta conversa.

> **Regra importante:** este documento não trata toda ideia discutida como decisão. Cada item possui um estado. Isso evita que uma sugestão, hipótese ou experimento vire requisito por engano.

---

# 0. COMO LER ESTE DOCUMENTO

Estados utilizados:

- **DECIDIDO** — direção que já foi escolhida.
- **BASE ATUAL** — algo que existe no projeto e precisa ser considerado.
- **PROPOSTA** — arquitetura/solução sugerida, ainda não definitivamente aprovada.
- **INVESTIGAR** — falta pesquisa ou análise antes de decidir.
- **TESTAR** — precisa de protótipo/benchmark para validar.
- **FUTURO** — capacidade desejada, mas não prioritária agora.
- **DESCARTADO/PÓSPOSTERGADO** — não entra na próxima etapa.
- **RISCO** — ponto que precisa de atenção especial.

A IA que continuar este projeto deve preservar essas distinções.

---

# 1. IDENTIDADE DO PROJETO

## 1.1 O que é Melly

**DECIDIDO**

Melly não deve ser apenas:

- um chatbot Android;
- um fork visual de OpenOmniBot;
- um simples assistente de voz;
- um wrapper de uma API de LLM;
- uma cópia de PalmClaw/OpenClaw/ZeroClaw.

A intenção é construir uma **plataforma de agente pessoal para Android**, capaz de utilizar o próprio dispositivo como ambiente computacional e operacional.

A ideia central é:

> **Melly recebe uma intenção, entende o objetivo, decide como executá-lo, utiliza ferramentas apropriadas, consulta memória quando necessário, executa ações e retorna o resultado.**

A interface de voz é importante, mas não deve definir toda a arquitetura.

---

# 2. OBJETIVO DE LONGO PRAZO

**DECIDIDO / VISÃO**

Melly deverá evoluir para um assistente que possa:

1. conversar por texto e voz;
2. interpretar pedidos simples localmente quando possível;
3. utilizar LLMs para tarefas complexas;
4. escolher entre diferentes provedores/modelos;
5. utilizar ferramentas;
6. executar tarefas em múltiplas etapas;
7. possuir memória persistente;
8. utilizar skills/módulos especializados;
9. automatizar tarefas no Android;
10. executar tarefas agendadas;
11. permanecer operacional em segundo plano quando permitido pelo Android;
12. controlar custos de APIs;
13. pedir confirmação para operações sensíveis;
14. trabalhar com arquivos e dados;
15. futuramente integrar Web, automação, MCP e outros ambientes;
16. permitir expansão sem transformar um único componente em um monólito impossível de manter.

---

# 3. PRINCÍPIO ARQUITETURAL PRINCIPAL

**DECIDIDO**

A arquitetura não deve depender de um único projeto externo.

Projetos como OpenOmniBot, PalmClaw, ZeroClaw, ZeroAI, OpenFang e outros devem ser tratados como:

- fontes de ideias;
- referências arquiteturais;
- componentes candidatos;
- provas de que determinada capacidade é possível;
- eventualmente dependências isoladas.

Não devem automaticamente definir a arquitetura de Melly.

## Regra

> **Melly deve possuir contratos próprios e adaptar componentes externos a esses contratos.**

Isso é especialmente importante para LLMs.

---

# 4. PONTO DE PARTIDA: OPENOMNIBOT

## 4.1 Estado

**BASE ATUAL**

OpenOmniBot é o ponto de partida do projeto.

A intenção original foi utilizar sua base funcional e transformá-la em algo substancialmente diferente.

Isso significa:

- preservar funcionalidades úteis;
- remover dependências arquiteturais inadequadas;
- criar novas abstrações;
- adicionar capacidades;
- substituir partes quando necessário;
- evitar que o projeto permaneça conceitualmente preso ao OpenOmniBot.

## 4.2 AssistsCoreManager

**BASE ATUAL / RISCO**

Foi analisado que `AssistsCoreManager.kt` possui aproximadamente:

- 6.786 linhas;
- 206 métodos;
- dependências/importações envolvendo mais de 40 classes.

Apesar do tamanho, foi observado que somente cerca de quatro arquivos da aplicação fazem chamadas diretas a ele.

### Consequência

O problema não é simplesmente "é grande, então deve ser reescrito".

A abordagem recomendada é:

1. mapear suas responsabilidades;
2. identificar dependências;
3. descobrir pontos de entrada;
4. separar interfaces;
5. criar adaptadores;
6. extrair responsabilidades gradualmente.

**NÃO DECIDIDO:** reescrever completamente o `AssistsCoreManager`.

---

# 5. ABSTRAÇÃO DE LLM

## 5.1 Problema descoberto

**DECIDIDO — BLOQUEADOR ARQUITETURAL**

A base analisada não possui uma abstração comum suficientemente clara para os provedores de LLM.

Foi observado que existem provedores implementados de maneira independente, incluindo referências a:

- DeepSeek;
- MiniMax;
- MiMo;
- Moonshot;
- Bailian;
- outros componentes relacionados.

`DeepSeekProvider` foi identificado como `object`, e não como implementação de um contrato comum.

Isso dificulta:

- troca de modelos;
- fallback;
- roteamento;
- testes;
- controle de custo;
- streaming uniforme;
- integração com outro runtime.

---

# 6. CONTRATO PRÓPRIO DE MELLY

**DECIDIDO COMO DIREÇÃO**

Melly deve criar seu próprio contrato de LLM.

Exemplo conceitual:

```text
Melly
  ↓
LlmRouter
  ↓
LlmProvider
  ├── DeepSeekAdapter
  ├── OutroProviderAdapter
  ├── ZeroClawAdapter
  └── FakeProvider
```

O ponto mais importante:

> **ZeroClaw NÃO deve definir o contrato central de Melly.**

O contrato pertence a Melly.

ZeroClaw, DeepSeek ou qualquer outro sistema será adaptado ao contrato.

---

# 7. FAKE PROVIDER

**PROPOSTA FORTE / RECOMENDADO**

Antes de integrar Rust/ZeroClaw, criar um `FakeProvider`.

Objetivo:

- testar UI;
- testar fluxo de mensagens;
- testar streaming;
- testar erros;
- testar cancelamento;
- testar histórico;
- testar roteamento;
- testar custos simulados.

Sem depender de API externa ou compilação Rust.

Isso reduz drasticamente o número de variáveis durante a integração.

---

# 8. ROTEAMENTO DE MODELOS

## 8.1 Estado

**PROPOSTA / TESTAR**

Melly deverá futuramente escolher qual LLM utilizar.

Critérios possíveis:

- complexidade da tarefa;
- custo;
- latência;
- capacidade do modelo;
- contexto necessário;
- necessidade de ferramentas;
- disponibilidade;
- falhas;
- preferência do usuário.

## 8.2 Estratégia inicial

**RECOMENDADO**

Começar com roteamento determinístico por regras.

Exemplo:

```text
pedido simples
    ↓
modelo barato/local

pedido complexo
    ↓
modelo mais capaz

falha
    ↓
fallback

custo acima do limite
    ↓
pedir confirmação
```

Não adicionar inicialmente um "roteador inteligente" baseado em outro LLM.

Primeiro coletar dados.

Depois, se necessário, adicionar inteligência ao roteamento.

---

# 9. CONTROLE DE CUSTO

**DECIDIDO COMO REQUISITO DE PRODUTO**

Custo de API é uma preocupação central.

Melly deverá conseguir:

- estimar custo antes de tarefas caras;
- acompanhar tokens quando possível;
- registrar custo por tarefa;
- aplicar limites;
- utilizar modelos baratos quando adequados;
- fazer fallback;
- evitar chamadas desnecessárias;
- informar o usuário quando uma operação exigir gasto relevante.

Foi discutida como ideia de produto uma pequena taxa de ativação/análise, por exemplo alguns centavos, e tarefas que podem custar alguns reais dependendo das APIs utilizadas.

**NÃO DECIDIDO:** valores comerciais definitivos.

---

# 10. MEMÓRIA

A memória deve ser tratada como subsistema independente.

## Tecnologias discutidas

- Obsidian;
- SQLite;
- Neo4j;
- memória própria;
- memória fornecida por runtimes externos.

## Estado

**INVESTIGAR / DEFINIR**

Ainda não existe uma decisão final sobre a arquitetura de memória.

### Possível divisão

```text
Memória imediata
→ contexto da conversa

Memória persistente simples
→ SQLite / arquivos

Memória documental
→ Obsidian

Memória relacional/grafo
→ Neo4j, somente se houver necessidade real
```

Não assumir Neo4j como obrigatório.

---

# 11. AGENTE

Melly deve evoluir de "chat + comandos" para um loop de agente.

Arquitetura conceitual:

```text
Entrada
 ↓
Interpretação
 ↓
Planejamento
 ↓
Seleção de ferramentas
 ↓
Execução
 ↓
Observação do resultado
 ↓
Correção/replanejamento
 ↓
Resposta
```

Esse loop precisa ser projetado e testado.

**AINDA FALTA:** especificação formal do Agent Loop.

---

# 12. TOOLS

Ferramentas são uma parte central da visão.

Categorias discutidas:

- arquivos;
- shell;
- Web;
- navegador;
- automação Android;
- MCP;
- mídia;
- APIs externas;
- notificações;
- memória;
- tarefas agendadas;
- aplicativos;
- Accessibility;
- captura de tela;
- Termux.

## Regra

Uma ferramenta não deve ser habilitada apenas porque um projeto externo possui essa ferramenta.

Cada tool deverá possuir:

- contrato;
- entrada;
- saída;
- permissões;
- risco;
- timeout;
- limites;
- tratamento de erro;
- confirmação quando necessário.

---

# 13. SKILLS

**VISÃO / PROPOSTA**

Skills devem permitir adicionar capacidades sem transformar o núcleo em um monólito.

Uma skill pode representar:

- conhecimento especializado;
- conjunto de ferramentas;
- workflow;
- integração;
- instruções;
- lógica especializada.

Ainda falta definir formalmente:

- formato;
- descoberta;
- instalação;
- versionamento;
- permissões;
- sandbox;
- confiança;
- atualização;
- remoção;
- compatibilidade.

---

# 14. MCP

**FUTURO / INVESTIGAR**

MCP foi discutido como possível mecanismo de integração com ferramentas externas.

Não deve ser tratado como obrigatório para a primeira versão.

Antes de adotá-lo:

- definir quais problemas reais ele resolve;
- avaliar overhead;
- segurança;
- permissões;
- compatibilidade Android;
- necessidade de servidores MCP;
- impacto de manutenção.

---

# 15. ANDROID COMO AMBIENTE DE EXECUÇÃO

Uma das maiores diferenças pretendidas para Melly é utilizar capacidades reais do Android.

Possíveis capacidades:

- Accessibility;
- captura de tela;
- interação com aplicativos;
- notificações;
- intents;
- arquivos;
- processos em segundo plano;
- serviço persistente;
- Termux;
- automação de UI.

A ideia é aproximar Melly de:

> **um agente que opera dentro do Android**, não apenas um aplicativo que conversa.

---

# 16. AUTOMATION / MOBILE USE

**FUTURO / INVESTIGAR / TESTAR**

Foi discutida automação semelhante ao conceito de MobileUse:

```text
LLM
 ↓
observa estado da tela
 ↓
decide ação
 ↓
toca/clica/digita/volta
 ↓
observa novo estado
 ↓
continua
```

Isso pode usar:

- Accessibility;
- screenshots;
- reconhecimento de UI;
- ações Android;
- ferramentas específicas.

Ainda falta decidir a implementação.

---

# 17. TERMUX

**FUTURO / INVESTIGAR**

Termux foi considerado como uma ponte para capacidades de sistema.

Pode permitir:

- comandos;
- scripts;
- ferramentas Unix;
- automação;
- execução de processos.

Mas deve haver:

- timeout;
- limite de saída;
- controle de permissões;
- confirmação para operações relevantes;
- sandbox quando possível.

Não conceder acesso irrestrito apenas para "facilitar".

---

# 18. PUPPETEER / WEB

**FUTURO / POSTERGADO**

Puppeteer foi tratado como o possível "braço esquerdo" do conceito original:

- navegador;
- Web;
- automação de páginas;
- coleta de dados;
- workflows Web.

Pode ser útil para tarefas específicas.

Porém, não deve dominar a primeira fase do projeto.

---

# 19. N8N

**FUTURO / INVESTIGAR**

n8n foi discutido como possível componente para workflows.

Pode ser útil quando Melly precisar:

- integrar APIs;
- criar automações;
- executar pipelines;
- conectar serviços.

Ainda falta decidir se:

1. Melly executará workflows diretamente;
2. n8n será backend externo;
3. n8n será opcional;
4. Melly substituirá parte das funções do n8n.

---

# 20. SCHEDULER

**DECIDIDO COMO DIREÇÃO**

Melly precisa executar tarefas programadas.

Exemplos:

```text
07:00 → verificar tarefa
12:00 → executar workflow
20:00 → gerar relatório
```

## OpenFang

Foi analisado que OpenFang é um sistema muito maior, descrito como "Agent Operating System", e não apenas um scheduler.

Conclusão:

> Para scheduling básico de Melly, importar OpenFang inteiro provavelmente é desnecessário.

## Alternativa inicial

Um scheduler próprio e pequeno pode utilizar:

- SQLite;
- mecanismos nativos do Android;
- WorkManager;
- AlarmManager quando apropriado.

**AINDA FALTA:** escolher implementação final e validar comportamento em diferentes versões do Android.

---

# 21. HEARTBEAT / AUTONOMIA

**VISÃO / FUTURO**

Foi discutido que Melly poderá possuir:

- cron;
- heartbeat;
- tarefas recorrentes;
- despertar em horários definidos;
- execução sem interação imediata do usuário.

Isso é importante para transformar o sistema em agente.

Porém, autonomia deve ser limitada por:

- permissões;
- orçamento;
- riscos;
- confirmação;
- regras do usuário;
- limitações do Android.

---

# 22. ZEROCLAW

## Papel

**CANDIDATO / REFERÊNCIA**

ZeroClaw foi analisado como runtime de agente Rust.

Possui conceitos relevantes de:

- providers;
- tools;
- memory;
- channels;
- runtime;
- traits;
- modularidade.

## Decisão importante

Não importar ZeroClaw inteiro automaticamente.

Primeiro identificar:

- quais partes Melly realmente precisa;
- quais partes são incompatíveis;
- quais partes aumentam o tamanho;
- quais partes criam risco;
- quais partes podem ser adaptadas.

---

# 23. ZEROCLAW E ANDROID

Foi encontrada evidência de builds Android/AArch64 do ZeroClaw e de projetos que usam Rust + Kotlin + UniFFI.

Isso demonstra que a abordagem é tecnicamente plausível.

Mas existem riscos.

Foi observado também um projeto Android baseado em ZeroClaw que acabou arquivado, com o próprio autor alertando sobre crescimento de escopo e segurança de uma base fortemente gerada por IA.

### Conclusão

Isso não significa que "Rust/FFI não funciona".

Significa:

> **Integração FFI + permissões + código gerado/alterado por IA exige revisão humana e testes.**

---

# 24. ZEROAI

ZeroAI foi estudado como exemplo concreto de:

- Kotlin;
- Rust;
- UniFFI;
- core Rust;
- serviço Android de longa duração;
- memória;
- tools;
- routing;
- scheduling;
- plugins.

Isso torna o projeto uma referência útil para arquitetura.

Mas ZeroAI também não deve ser copiado inteiro.

Seu valor principal é demonstrar padrões de integração.

---

# 25. RUST + KOTLIN + UNIFFI

**PROPOSTA / TESTAR**

Arquitetura possível:

```text
Flutter / Android UI
        ↓
Kotlin
        ↓
UniFFI
        ↓
Rust core
        ↓
runtime / ferramentas
```

Benefícios possíveis:

- núcleo performático;
- isolamento de componentes;
- aproveitamento de bibliotecas Rust;
- integração com runtimes como ZeroClaw.

Riscos:

- complexidade de build;
- ABI;
- debugging;
- lifecycle Android;
- concorrência;
- integração FFI;
- manutenção.

## Primeiro teste obrigatório

Antes de integrar o agente inteiro:

```text
Android
 ↓
Kotlin
 ↓
Rust
 ↓
função simples
 ↓
resultado em Kotlin
```

Depois:

```text
streaming
erro
cancelamento
concorrência
lifecycle
```

Somente depois integrar o runtime.

---

# 26. CHAQUOPY

**CANDIDATO / ALTERNATIVA**

Chaquopy foi considerado para Python dentro do Android.

É viável, mas possui custos/limitações Android.

Foi pesquisada a versão atual 17.0 durante a análise anterior, além de questões como:

- minSdk;
- ABIs;
- tamanho;
- limitações de `multiprocessing`;
- overhead.

Conclusão:

> Não escolher Python/Chaquopy apenas porque Python parece mais simples. A escolha deve depender do componente que precisa ser executado.

---

# 27. PALMCLAW

PalmClaw foi estudado especificamente porque se aproxima da visão de Melly.

Características relevantes observadas:

- Android-first;
- local-first;
- memória;
- skills;
- tools;
- channels;
- cron;
- heartbeat;
- agent loop;
- configuração de providers;
- automação Android planejada;
- Accessibility/screen capture no roadmap;
- Termux Bridge opcional;
- confirmações para operações de risco;
- limites de timeout/output.

## Conclusão

PalmClaw é uma **referência arquitetural e de produto extremamente relevante** para Melly.

Mas:

> **Melly não deve virar "PalmClaw 2".**

A função de PalmClaw no projeto é servir como benchmark:

```text
"O que um agente Android moderno já provou que pode fazer?"
```

Melly então deve responder:

```text
"O que podemos combinar, simplificar ou melhorar para criar uma arquitetura própria?"
```

---

# 28. OPENFANG

**REFERÊNCIA / NÃO PRIORITÁRIO**

OpenFang foi analisado como sistema muito mais amplo do que um simples scheduler.

Conclusão:

- não é necessário para a primeira implementação;
- pode ser estudado como referência;
- somente incorporar componentes se houver necessidade concreta.

---

# 29. AIOS

**FUTURO / INVESTIGAR**

AIOS foi considerado como outra referência possível para arquitetura de agentes.

Não há decisão de integração.

Não adicionar apenas para aumentar a lista de tecnologias.

---

# 30. OPENCLAW

**REFERÊNCIA / INVESTIGAR**

OpenClaw inspirou conceitos de agente, skills, ferramentas e automação.

Porém, qualquer integração deve considerar:

- segurança;
- superfície de ataque;
- permissões;
- supply chain;
- manutenção;
- compatibilidade Android.

Melly não deve importar funcionalidades indiscriminadamente.

---

# 31. ARQUITETURA CONCEITUAL CONSOLIDADA

Uma arquitetura candidata:

```text
┌──────────────────────────────────────────┐
│                MELLY APP                 │
│                                          │
│ UI / Voz / Conversa / Estado             │
└────────────────────┬─────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────┐
│             MELLY ORCHESTRATOR           │
│                                          │
│ Intent → Planner → Executor → Observer   │
└────────────────────┬─────────────────────┘
                     │
          ┌──────────┼───────────┐
          ▼          ▼           ▼
       Memory      Tools       Skills
          │          │           │
          └──────────┼───────────┘
                     ▼
                LLM Router
                     │
              ┌──────┼───────┐
              ▼      ▼       ▼
          Provider Provider Provider
             │
             ▼
      API / Local / Runtime
```

Camada de infraestrutura:

```text
Android
 ├── Kotlin
 ├── Services
 ├── WorkManager
 ├── Accessibility
 ├── Notifications
 └── Intent APIs

Opcional:
 └── Rust core via UniFFI
```

---

# 32. MODELO DE CAMADAS

Uma divisão possível:

## Camada 1 — Interface

- texto;
- voz;
- notificações;
- UI.

## Camada 2 — Orquestração

- interpretação;
- planejamento;
- execução;
- estado;
- agente.

## Camada 3 — Inteligência

- LLM Router;
- providers;
- fallback;
- custos.

## Camada 4 — Memória

- conversa;
- fatos;
- documentos;
- conhecimento;
- histórico de tarefas.

## Camada 5 — Capacidades

- tools;
- skills;
- automação;
- navegador;
- arquivos;
- APIs.

## Camada 6 — Sistema

- Android;
- Kotlin;
- Rust;
- Termux;
- serviços;
- scheduler.

---

# 33. SEGURANÇA

**DECIDIDO COMO PRINCÍPIO**

Quanto maior o poder da ferramenta, maior deve ser o controle.

Categorias de risco:

### Baixo

- responder perguntas;
- calcular;
- organizar texto.

### Médio

- modificar arquivos;
- executar workflows;
- acessar dados locais.

### Alto

- comandos de sistema;
- ações externas irreversíveis;
- operações financeiras;
- publicação;
- alterações importantes;
- acesso amplo a aplicativos.

## Mecanismos desejados

- confirmação;
- senha/biometria quando aplicável;
- permissões explícitas;
- limites;
- sandbox;
- logs;
- auditoria;
- timeout;
- kill switch;
- orçamento.

---

# 34. PERMISSÕES POR TOOL

Cada ferramenta deveria declarar algo semelhante a:

```text
Tool: executar_comando

Risk: HIGH

Permissions:
- shell.execute

Confirmation:
- required

Timeout:
- 10s

Output limit:
- 50KB
```

Isso deve ser parte do design, não um recurso adicionado no final.

---

# 35. MEMÓRIA + PRIVACIDADE

Ainda falta definir:

- o que pode ser salvo;
- por quanto tempo;
- onde;
- criptografia;
- exclusão;
- quais tools podem acessar;
- quais dados podem entrar no prompt;
- como evitar vazamento para APIs externas.

**INVESTIGAR**

---

# 36. VOZ

**VISÃO**

Melly deverá aceitar comandos de voz.

Fluxo:

```text
Voz
 ↓
Speech-to-Text
 ↓
Intent
 ↓
Agente
 ↓
Execução
 ↓
Text-to-Speech
```

Ainda falta decidir:

- STT local vs API;
- TTS local vs API;
- ativação por palavra;
- execução contínua;
- consumo de bateria;
- privacidade.

---

# 37. BACKGROUND / 24 HORAS

**VISÃO / TESTAR**

Objetivo de longo prazo:

> Melly continuar funcionando em segundo plano e executar tarefas programadas.

Isso não significa que Android permitirá qualquer processo arbitrariamente por 24h.

É necessário estudar:

- Foreground Service;
- WorkManager;
- AlarmManager;
- restrições de bateria;
- Doze;
- versões do Android;
- permissões.

---

# 38. HARDWARE / SERVIDOR

Foi discutida uma futura máquina pequena para deixar componentes funcionando continuamente.

Um N100 foi considerado desejável no futuro, mas inicialmente pode ser inviável pelo orçamento.

A arquitetura deve portanto permitir:

```text
Melly no Android
        ↓
opcional
        ↓
servidor doméstico / VPS
```

O servidor não deve ser requisito para funcionalidades básicas.

---

# 39. ARQUITETURA LOCAL-FIRST

**VISÃO**

Sempre que possível:

```text
Tarefa simples
→ local

Tarefa que exige LLM
→ modelo barato

Tarefa complexa
→ modelo mais capaz

Tarefa pesada
→ servidor/API
```

Isso reduz:

- custo;
- latência;
- dependência externa;
- consumo de dados.

---

# 40. FLUXO IDEAL DE UMA TAREFA

Exemplo:

> "Melly, amanhã às 8h faça X."

Fluxo:

```text
Voz
 ↓
STT
 ↓
Intent parser
 ↓
Scheduler
 ↓
Persistência
 ↓
Android agenda execução
 ↓
8h
 ↓
Melly acorda
 ↓
LLM interpreta tarefa
 ↓
Router escolhe modelo
 ↓
Planner monta execução
 ↓
Tools executam
 ↓
Resultado salvo
 ↓
Usuário recebe notificação
```

---

# 41. EXEMPLO DE TAREFA COMPLEXA

> "Pegue os arquivos X, processe-os e faça Y."

Fluxo:

```text
Pedido
 ↓
Planejamento
 ↓
Verificação de permissões
 ↓
Estimativa de custo
 ↓
Confirmação, se necessária
 ↓
Execução
 ↓
Observação
 ↓
Correção
 ↓
Resultado
 ↓
Log
```

---

# 42. O QUE AINDA NÃO FOI DECIDIDO

Esta seção é importante.

Ainda faltam decisões formais sobre:

1. arquitetura final Flutter/Kotlin/Rust;
2. quais componentes realmente serão Rust;
3. se ZeroClaw será incorporado;
4. quanto de ZeroClaw será incorporado;
5. contrato definitivo de `LlmProvider`;
6. formato de `LlmRequest`;
7. formato de `LlmResponse`;
8. streaming;
9. cancelamento;
10. tratamento de erros;
11. router;
12. política de custos;
13. memória principal;
14. papel exato do Obsidian;
15. necessidade real do Neo4j;
16. sistema de skills;
17. sistema de tools;
18. MCP;
19. Accessibility;
20. MobileUse;
21. Termux;
22. Puppeteer;
23. n8n;
24. scheduler;
25. heartbeat;
26. background service;
27. voz;
28. STT;
29. TTS;
30. autenticação;
31. confirmação;
32. sandbox;
33. criptografia;
34. sincronização;
35. servidor;
36. distribuição;
37. atualização;
38. telemetria;
39. testes;
40. arquitetura final de módulos.

---

# 43. O QUE PRECISA SER PESQUISADO

Antes de implementar grandes partes:

## Android

- limitações de background;
- Accessibility;
- serviços;
- WorkManager;
- bateria;
- permissões.

## Rust

- Android targets;
- UniFFI;
- lifecycle;
- threads;
- streaming;
- tamanho do binário.

## LLM

- APIs;
- preços;
- streaming;
- tool calling;
- contexto;
- limites;
- modelos gratuitos;
- fallback.

## Memória

- SQLite;
- Obsidian;
- embeddings;
- busca semântica;
- grafos;
- retenção.

## Segurança

- sandbox;
- secrets;
- tool permissions;
- supply chain;
- skills externas;
- execução de código.

---

# 44. O QUE PRECISA SER TESTADO

Não substituir testes por "parece funcionar".

## Teste 1

Kotlin → Rust → Kotlin.

## Teste 2

FakeProvider.

## Teste 3

Provider real.

## Teste 4

Streaming.

## Teste 5

Erro/fallback.

## Teste 6

Router.

## Teste 7

Tool simples.

## Teste 8

Memória.

## Teste 9

Scheduler.

## Teste 10

Background.

## Teste 11

Accessibility.

## Teste 12

Agent loop.

Somente depois juntar tudo.

---

# 45. ORDEM DE IMPLEMENTAÇÃO RECOMENDADA

## FASE 0 — MAPEAR A BASE

- analisar OpenOmniBot;
- mapear `AssistsCoreManager`;
- mapear providers;
- mapear UI;
- mapear chamadas;
- documentar dependências.

**Resultado:** mapa técnico.

---

## FASE 1 — CONTRATOS

Criar:

```text
LlmProvider
LlmRequest
LlmResponse
Tool
ToolResult
Memory
Skill
AgentTask
```

**Resultado:** Melly começa a ter arquitetura própria.

---

## FASE 2 — FAKE PROVIDER

Implementar provider falso.

Testar:

- UI;
- streaming;
- erros;
- cancelamento;
- histórico.

---

## FASE 3 — PROVIDER REAL

Criar:

```text
DeepSeekAdapter
```

ou outro provider escolhido.

Não acoplar a UI diretamente ao provider.

---

## FASE 4 — ROUTER

Implementar regras:

```text
cheap
normal
complex
fallback
```

Registrar custo.

---

## FASE 5 — AGENT LOOP

Implementar:

```text
intent
→ plan
→ tool
→ observe
→ continue
```

Começar com poucas tools.

---

## FASE 6 — MEMÓRIA

Começar simples.

Provável ordem:

```text
SQLite
 ↓
arquivos/documentos
 ↓
Obsidian
 ↓
grafo/Neo4j se necessário
```

Não começar pelo sistema mais complexo.

---

## FASE 7 — TOOLS + SKILLS

Criar arquitetura de plugins/capacidades.

Implementar apenas tools necessárias.

---

## FASE 8 — SCHEDULER

Implementar tarefas programadas.

Preferir mecanismo Android adequado antes de importar um sistema externo enorme.

---

## FASE 9 — RUST

Somente quando existir uma necessidade concreta.

Primeiro:

```text
hello world FFI
```

Depois:

```text
core mínimo
```

Depois avaliar ZeroClaw.

---

## FASE 10 — ANDROID AUTOMATION

- Accessibility;
- screenshots;
- UI actions;
- confirmação;
- limites.

---

## FASE 11 — AUTONOMIA

- heartbeat;
- cron;
- background;
- workflows.

---

## FASE 12 — EXPANSÃO

Somente depois:

- MCP;
- Termux;
- Puppeteer;
- n8n;
- servidor;
- automações complexas;
- integrações externas.

---

# 46. REGRA CONTRA COMPLEXIDADE PREMATURA

Uma das maiores ameaças ao projeto é transformar Melly em um agregador de frameworks.

Não fazer:

```text
OpenOmniBot
+ ZeroClaw
+ PalmClaw
+ OpenFang
+ AIOS
+ n8n
+ OpenClaw
+ MCP
+ Neo4j
+ Termux
+ Puppeteer
+ Rust
+ Python
```

apenas porque cada tecnologia é interessante.

A pergunta obrigatória deve ser:

> **"Qual problema concreto esta tecnologia resolve que Melly não consegue resolver de forma menor?"**

Se não houver resposta, adiar.

---

# 47. BENCHMARKS / PROJETOS DE REFERÊNCIA

## OpenOmniBot

Função:
- base inicial.

## PalmClaw

Função:
- benchmark de agente Android.

## ZeroClaw

Função:
- referência de runtime Rust/agente modular.

## ZeroAI

Função:
- referência de integração Android + Rust + UniFFI.

## OpenFang

Função:
- referência de sistemas de agentes mais amplos.

## AIOS

Função:
- referência de arquitetura de agentes.

## OpenClaw

Função:
- referência de ecossistema de skills/tools/agentes.

Nenhum desses projetos deve ser considerado automaticamente uma dependência.

---

# 48. DIFERENCIAL PRETENDIDO DE MELLY

O diferencial não deve ser simplesmente:

> "tem mais ferramentas."

A proposta mais forte é combinar:

```text
Android-native
+
agente
+
memória
+
LLM routing
+
controle de custo
+
tools
+
skills
+
automação Android
+
scheduler
+
autonomia controlada
+
arquitetura modular
```

em uma arquitetura coerente.

---

# 49. CONCEITO DE PRODUTO

Melly pode ser entendido como:

> **um agente pessoal que transforma o Android de um simples dispositivo de aplicativos em um ambiente que pode ser operado por uma inteligência orientada a tarefas.**

Isso é mais abrangente do que um assistente de voz tradicional.

---

# 50. METÁFORA ORIGINAL

A metáfora usada durante o desenvolvimento:

- **LLM = cérebro**
- **Andromate = braço direito**
- **Puppeteer = braço esquerdo**
- futuras integrações = "pernas"

Essa metáfora é útil para explicar o conceito, mas não deve obrigatoriamente determinar a arquitetura de código.

---

# 51. CRITÉRIO PARA ACEITAR COMPONENTES EXTERNOS

Antes de adicionar um projeto externo:

1. Qual problema resolve?
2. Podemos implementar menor?
3. Qual o tamanho?
4. Qual a licença?
5. Qual o estado de manutenção?
6. Quais dependências traz?
7. Quais permissões exige?
8. Qual superfície de ataque cria?
9. Podemos removê-lo depois?
10. Existe uma interface que isole a dependência?

Se as respostas forem ruins, não adicionar.

---

# 52. REGRA PARA IA CONTINUAR O PROJETO

Qualquer IA que receba este documento deve:

1. não assumir que "PROPOSTA" significa decisão;
2. não implementar tecnologias marcadas como INVESTIGAR sem verificar;
3. não remover decisões já marcadas como DECIDIDO sem justificar;
4. separar pesquisa de implementação;
5. pesquisar fontes atuais quando a questão depender de versões atuais;
6. testar antes de afirmar que uma integração funciona;
7. evitar reescrever grandes módulos sem mapear dependências;
8. evitar adicionar frameworks apenas por conveniência;
9. preservar os contratos próprios de Melly;
10. registrar novas decisões neste documento.

---

# 53. LOG DE DECISÕES

## D001 — Melly não será apenas um fork visual

**Status:** DECIDIDO

Melly deve evoluir para uma plataforma própria.

## D002 — OpenOmniBot é ponto de partida

**Status:** DECIDIDO

## D003 — Criar abstração própria de LLM

**Status:** DECIDIDO

## D004 — Não deixar ZeroClaw definir o contrato de Melly

**Status:** DECIDIDO

## D005 — FakeProvider antes de integração complexa

**Status:** RECOMENDADO

## D006 — Router inicialmente baseado em regras

**Status:** RECOMENDADO

## D007 — OpenFang não será usado apenas como scheduler

**Status:** DECIDIDO/POSTERGADO

## D008 — PalmClaw é benchmark, não base para copiar

**Status:** DECIDIDO

## D009 — Ferramentas devem possuir permissões

**Status:** DECIDIDO

## D010 — FFI/Rust precisa de protótipo mínimo antes de integração completa

**Status:** DECIDIDO COMO PROCESSO

---

# 54. PRINCIPAIS RISCOS

## Risco 1 — Escopo

Melly pode tentar fazer tudo ao mesmo tempo.

**Mitigação:** roadmap incremental.

## Risco 2 — Monólito

`AssistsCoreManager` pode continuar concentrando responsabilidades.

**Mitigação:** interfaces e extração progressiva.

## Risco 3 — Dependência externa excessiva

Melly pode virar uma colagem de projetos.

**Mitigação:** contratos próprios.

## Risco 4 — Segurança

Tools poderosas podem receber acesso excessivo.

**Mitigação:** permissões, confirmação, sandbox e logs.

## Risco 5 — Custo

Agentes podem gerar muitas chamadas de LLM.

**Mitigação:** router, limites, cache, modelos baratos e confirmação.

## Risco 6 — Android

Background e automação podem ser limitados pelo sistema.

**Mitigação:** testes reais em Android.

## Risco 7 — IA gerando código sem validação

Projetos grandes podem compilar e ainda estar arquiteturalmente errados.

**Mitigação:** testes, revisão e mudanças incrementais.

---

# 55. CHECKLIST ATUAL

## Arquitetura

- [ ] mapear OpenOmniBot
- [ ] mapear AssistsCoreManager
- [ ] definir módulos
- [ ] definir interfaces

## LLM

- [ ] `LlmProvider`
- [ ] request
- [ ] response
- [ ] streaming
- [ ] erros
- [ ] FakeProvider
- [ ] adapter real
- [ ] router
- [ ] custo

## Agent

- [ ] intent
- [ ] planner
- [ ] executor
- [ ] observer
- [ ] loop
- [ ] estado

## Memory

- [ ] SQLite
- [ ] histórico
- [ ] memória persistente
- [ ] Obsidian
- [ ] avaliar Neo4j

## Tools

- [ ] contrato
- [ ] permissões
- [ ] risco
- [ ] timeout
- [ ] limites
- [ ] logs

## Skills

- [ ] formato
- [ ] carregamento
- [ ] permissões
- [ ] versionamento

## Android

- [ ] service
- [ ] background
- [ ] scheduler
- [ ] notifications
- [ ] Accessibility
- [ ] intents

## Rust

- [ ] hello world
- [ ] UniFFI
- [ ] streaming
- [ ] lifecycle
- [ ] avaliar ZeroClaw

## Autonomia

- [ ] cron
- [ ] heartbeat
- [ ] tarefas recorrentes
- [ ] limites

## Segurança

- [ ] confirmation
- [ ] secrets
- [ ] sandbox
- [ ] audit log
- [ ] kill switch

---

# 56. PRÓXIMA AÇÃO RECOMENDADA

A próxima etapa **não deveria ser adicionar mais uma tecnologia**.

A sequência recomendada é:

```text
1. Mapear OpenOmniBot
        ↓
2. Mapear AssistsCoreManager
        ↓
3. Definir LlmProvider
        ↓
4. Criar FakeProvider
        ↓
5. Criar adapter de um provider real
        ↓
6. Criar router simples
        ↓
7. Criar Agent Loop mínimo
        ↓
8. Adicionar uma Tool
        ↓
9. Adicionar memória simples
        ↓
10. Criar scheduler mínimo
        ↓
11. Testar Rust/UniFFI
        ↓
12. Só então avaliar integração ZeroClaw
```

---

# 57. O QUE ESTE DOCUMENTO AINDA NÃO É

Este arquivo **não é ainda**:

- especificação definitiva de código;
- API final;
- desenho final de banco;
- arquitetura final de Rust;
- arquitetura final de Android;
- threat model completo;
- benchmark completo;
- plano financeiro;
- implementação.

Ele é o **documento central de contexto e direção**.

A finalidade é garantir continuidade entre IAs e evitar perda de decisões, hipóteses e pendências.

---

# 58. DOCUMENTOS QUE DEVEM SER CRIADOS DEPOIS

Quando o projeto avançar, separar este documento em documentos especializados:

```text
MELLY/
│
├── 00-CONTEXTO-CENTRAL.md
├── 01-VISAO.md
├── 02-ARQUITETURA.md
├── 03-LLM-E-ROUTING.md
├── 04-AGENT-LOOP.md
├── 05-MEMORIA.md
├── 06-TOOLS-E-SKILLS.md
├── 07-AUTOMACAO-ANDROID.md
├── 08-SCHEDULER-E-AUTONOMIA.md
├── 09-SEGURANCA.md
├── 10-INTEGRACOES.md
├── 11-RUST-UNIFFI.md
├── 12-ROADMAP.md
├── 13-BENCHMARKS.md
├── 14-DECISOES.md
└── 15-TESTES.md
```

Este arquivo continua como o **contexto central**.

---

# 59. PRINCÍPIO FINAL

Melly não precisa vencer projetos externos fazendo absolutamente tudo que eles fazem.

O objetivo é construir uma arquitetura na qual:

> **cada capacidade importante pode ser adicionada, substituída, testada ou removida sem destruir o restante do sistema.**

Essa modularidade é o que permite que Melly deixe de ser uma adaptação de OpenOmniBot e se torne um projeto próprio.

---

## FIM — VERSÃO 0.1
