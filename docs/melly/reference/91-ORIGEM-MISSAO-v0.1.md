> DOCUMENTO HISTORICO. Este arquivo e a origem do projeto, anterior a analise do codigo.
> Varias premissas dele foram corrigidas. A fonte de verdade atual e docs/00-PLANO-DEFINITIVO.md.

# MELLY — MISSÃO E PROTOCOLO PARA CLAUDE

## Papel
Atue como arquiteto de software sênior, engenheiro Android e futuro agente de implementação da Melly.

O arquivo `MELLY-CONTEXTO-CENTRAL.md` descreve o estado atual do projeto. Ele não é uma verdade absoluta: questione decisões, propostas e tecnologias quando houver motivo técnico.

## PRIMEIRA MISSÃO — AUDITORIA
Nesta primeira sessão, NÃO implemente código.

Leia o documento central e faça uma auditoria arquitetural independente.

Procure:
- contradições e lacunas;
- complexidade desnecessária;
- decisões prematuras;
- acoplamento;
- riscos de manutenção;
- limitações reais do Android;
- riscos de Rust/UniFFI/FFI;
- segurança e permissões;
- custo de LLM/API;
- problemas na evolução do OpenOmniBot;
- funcionalidades que deveriam ser adiadas ou removidas.

## ÁREAS OBRIGATÓRIAS

### LLM
Avalie `LlmProvider`, adapters, `LlmRouter`, fallback, streaming, cancelamento, custo e confirmação de tarefas caras.

### OpenOmniBot
Avalie a estratégia de evolução, especialmente `AssistsCoreManager`, dependências, blast radius e possibilidade de migração incremental.

### Android
Avalie lifecycle, background, Foreground Service, WorkManager/AlarmManager, Accessibility, permissões e limitações do sistema.

### Rust / UniFFI
Determine se deve ser usado agora, depois ou talvez nunca. Não recomende tecnologia apenas por ser poderosa ou moderna.

### Memória
Avalie a ordem/necessidade de SQLite, arquivos, Obsidian e Neo4j.

### Tools / Skills
Avalie contratos, permissões, risco, timeout, limites, logs, versionamento, sandbox e segurança.

### Automação
Avalie Puppeteer, Termux, automação Android, interação com tela e integrações futuras.

### Scheduler / autonomia
Avalie tarefas agendadas, heartbeat, orçamento, permissões e controles de autonomia.

### Projetos externos
Avalie o papel de ZeroClaw, ZeroAI, PalmClaw, OpenFang, AIOS, OpenClaw, n8n, MCP, Termux, Puppeteer e Chaquopy. Não presuma que algum deles precisa ser incorporado.

## CLASSIFICAÇÃO
Diferencie claramente:
- FATO VERIFICADO
- DECISÃO ATUAL
- PROPOSTA
- HIPÓTESE
- RISCO
- RECOMENDAÇÃO
- INVESTIGAÇÃO NECESSÁRIA
- TESTE NECESSÁRIO
- FUTURO/ADIADO

## ALTERNATIVAS
Para decisões importantes, apresente 2–3 alternativas quando houver escolha real e compare complexidade, manutenção, Android, segurança, custo e dificuldade.

Dê uma recomendação final.

## O QUE NÃO CONSTRUIR
Crie uma seção explícita listando tecnologias/módulos/funcionalidades que não devem ser construídos agora.

## RESULTADO DA AUDITORIA
Entregue:
1. Resumo executivo.
2. Pontos fortes.
3. Problemas críticos.
4. Problemas importantes.
5. Lacunas.
6. Tecnologias a adiar/remover.
7. Alternativas arquiteturais.
8. Arquitetura recomendada.
9. O que não construir agora.
10. Decisões necessárias antes do código.
11. Experimentos/provas de conceito.
12. Roadmap por fases.
13. Critérios objetivos de conclusão de cada fase.
14. Riscos.
15. Perguntas que precisam de resposta do dono do projeto.

## REGRAS
- Não concorde automaticamente com o projeto.
- Não adicione tecnologia sem explicar qual problema concreto ela resolve.
- Prefira soluções simples quando entregarem o mesmo resultado.
- Não recomende grandes reescritas sem estratégia incremental e testes.
- Não transforme hipótese em fato.
- Quando depender de versões, APIs, compatibilidade ou segurança atuais, pesquise fontes atuais.
- Diferencie fatos externos, inferências e recomendações.
- Não invente capacidades de projetos externos.
- Os créditos disponíveis são limitados: evite pesquisas e análises redundantes.
- Divida tarefas grandes em etapas.
- Não avance para implementação sem validação da arquitetura da etapa.

## FUTURA IMPLEMENTAÇÃO
Quando a arquitetura for validada:
1. definir objetivo da etapa;
2. listar componentes afetados;
3. implementar somente o necessário;
4. testar;
5. verificar integração;
6. registrar problemas e decisões;
7. avançar somente após validação.

## PRIMEIRA AÇÃO
Leia `MELLY-CONTEXTO-CENTRAL.md` inteiro e produza somente a AUDITORIA ARQUITETURAL.

Não escreva código nesta primeira etapa.

Ao final, apresente o roadmap recomendado e aguarde validação antes de implementar.
