# Melly — Assistente de IA On-Device para Android

<p align="center">
  <b>Melly</b> é um assistente pessoal inteligente autônomo projetado para execução direta no dispositivo Android (<i>on-device AI agent</i>), integrando raciocínio com modelos de linguagem, automação de sistema, emulação de terminal e segurança avançada.
</p>

---

## 🌟 Visão Geral do Projeto

Diferente de chatbots convencionais, a Melly opera em um ciclo contínuo de agente: **compreender → decidir → executar → refletir**. O projeto combina uma interface fluida em Flutter com um núcleo de execução nativo de alto desempenho em Android Kotlin.

### Principais Capacidades
- **Ambiente de Ferramentas Extensível:** Acesso a terminal embutido (baseado em Termux), integração com navegador, execução de scripts e ferramentas locais.
- **Automação Privilegiada Segura:** Integração com **Shizuku** e **AccessibilityService** para execução de ações de sistema sem necessidade de root tradicional, com controle estrito de aprovação humana.
- **Protocolo de Agente (ACP):** Separação desacoplada entre a orquestração do agente em Kotlin e a renderização de componentes visuais em Flutter.
- **Persistência e Métricas Locais:** Banco de dados Room integrado para acompanhamento detalhado de consumo de tokens, latência e histórico de execuções.
- **Privacidade e Identidade Independente:** Identidade de aplicação isolada (`com.melly.assistant`) e interface em Português Brasileiro (pt-BR).

---

## 🚦 Status Atual do Desenvolvimento

O desenvolvimento da Melly é regido por etapas atômicas, com auditorias prévias e cobertura de testes contínua:

| Etapa | Descrição | Status | Detalhes |
|---|---|:---:|---|
| **E0-A** | Estabelecimento da baseline de execução | ✅ Concluído | Importação e preservação de integridade do repositório base (PR #1). |
| **P0-A** | Blindagem de segurança do Shizuku | ✅ Concluído | Eliminação da autoaprovação do modelo; confirmação obrigatória de sistema (PR #2). |
| **E0-A2** | Identidade de instalação independente | ✅ Concluído | Configuração de `applicationId = "com.melly.assistant"` para instalação isolada (PR #4). |
| **E0-A3** | Identidade visual e localização pt-BR | ✅ Concluído | Tradução para português brasileiro, fallback de idioma e correção de saudação (PR #5 e #6). |
| **E1** | Contenção do loop do agente | ✅ Concluído | Tetos rígidos de segurança (*hard ceilings*) para rounds, chamadas de ferramentas e tempo limite (PR #7). |
| **E2** | Instrumentação de execuções | ✅ Concluído | Tabela Room `agent_run_summaries` correlacionando métricas completas por `agentRunId` (PR #8). |
| **E3** | Normalizador de resultado de ferramentas | 🔄 Em andamento | Eliminação de duplicações de saída de terminal (`previewJson`/`terminalOutput`) para corte de tokens em ~53%. |

A documentação detalhada das decisões arquiteturais e histórico operacional está preservada em [`docs/MELLY-EXECUTION-HANDOFF.md`](docs/MELLY-EXECUTION-HANDOFF.md) e na pasta [`docs/melly/`](docs/melly/).

---

## 📦 Como Baixar e Gerar o APK

### 1. Download Direto (Releases)
Os executáveis pré-compilados estão disponíveis na aba de [**Releases**](https://github.com/welvinsonkaiquealves-stack/Melly-Bot/releases):
- Baixe a versão mais recente (ex.: [**v0.1.0-melly**](https://github.com/welvinsonkaiquealves-stack/Melly-Bot/releases/tag/v0.1.0-melly)) com o APK de depuração oficial anexado (`app-develop-standard-debug.apk`).

### 2. Download via GitHub Actions (CI)
A cada Pull Request ou commit na branch principal, o pipeline de integração contínua gera um novo binário:
1. Acesse a aba [**Actions**](https://github.com/welvinsonkaiquealves-stack/Melly-Bot/actions/workflows/ci.yml).
2. Selecione a última execução bem-sucedida do workflow **Pull Request CI**.
3. No rodapé da página (seção *Artifacts*), baixe o pacote `melly-develop-standard-debug-<commit>`.

### 3. Compilação Local
Requisitos do ambiente de desenvolvimento:
- **JDK:** 21 (Temurin recomendado)
- **Flutter:** 3.47.2 (canal stable)
- **Android SDK:** Platform API 37.0, NDK 28.2
- **CMake:** 3.22.1

Comandos de compilação:
```bash
# Obter dependências Flutter
cd ui && flutter pub get && cd ..

# Compilar o APK standard de desenvolvimento
./gradlew :app:assembleDevelopStandardDebug -Ptarget=ui/lib/main_standard.dart
```

---

## 🙏 Reconhecimento e Créditos

O projeto **Melly** é derivado e construído sobre a sólida fundação de código aberto do [**OpenOmniBot**](https://github.com/omnimind-ai/OpenOmniBot), desenvolvido pela [OmniMind AI](https://omnimind.com.cn).

Expressamos nosso sincero agradecimento e reconhecimento à equipe da OmniMind e aos colaboradores da comunidade OpenOmniBot pela concepção da arquitetura original de agente para Android e pelas integrações nativas de sistema que servem de base para este trabalho.
