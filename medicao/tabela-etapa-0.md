# Etapa 0: tabela de resultados

Preencha e copie para `docs/05-ESTADO-ATUAL.md`, seção Medições.

**Aparelho:**
**Versão do Android:**
**Modelo configurado:**
**Data da medição:**
**Commit do fork usado:**

---

## Tabela principal

| Teste | Prompt | Cached | Completion | Request JSON | Tools | LLM calls | Iterações |
|---|---|---|---|---|---|---|---|
| oi, Agent | | | | | | | |
| oi, Chat | | | | | | | |
| navegador | | | | | | | |
| caso ~200k | | | | | | | |

Legenda: Prompt e Cached em tokens. Request JSON em KB. Tools é a quantidade de ferramentas enviadas.

## Complementares

| Teste | reasoningTokens | cacheCreation | Response JSON (KB) | Tamanho do array tools (KB) | tool calls |
|---|---|---|---|---|---|
| oi, Agent | | | | | |
| oi, Chat | | | | | |
| navegador | | | | | |
| caso ~200k | | | | | |

## Teste de cache

Teste 1 repetido duas vezes na mesma conversa:

| Chamada | promptTokens | cachedTokens | razão cached/prompt |
|---|---|---|---|
| primeira | | | |
| segunda | | | |

## Proporção dos blocos, saída do analisador

Cole aqui a seção "ONDE ESTAO OS TOKENS" de cada teste.

### Teste 1, oi em Agent

```text

```

### Teste 2, oi em Chat

```text

```

### Teste 3, abra o navegador

```text

```

### Teste 4, caso grande

```text

```

## Duplicação detectada

Cole a seção "SINAIS DE DUPLICACAO" onde ela aparecer.

```text

```

## Observações

Anote qualquer coisa fora do esperado: chamada que não gerou `usage`, turno que passou de dez chamadas e perdeu entradas, erro, comportamento diferente do descrito.

```text

```

## Ramo de decisão aplicável

Conforme a seção 10 do plano definitivo:

```text

```
