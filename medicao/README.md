# Etapa 0: protocolo de medição

**Objetivo:** descobrir empiricamente onde está o custo, antes de decidir o que mudar. O resultado desta pasta decide a ordem das etapas E3 e E4 do plano.

**Nada de código é alterado nesta etapa.**

---

## Por que esta etapa existe

A hipótese de que o catálogo de ferramentas domina o custo **não foi verificada**. Se o cache de prompt da DeepSeek estiver absorvendo o catálogo, o custo em dinheiro é uma fração da contagem de tokens, e a prioridade muda de "reduzir o catálogo" para "parar de duplicar resultado de ferramenta".

Duas afirmações feitas com confiança na análise já foram corrigidas por simulação. Uma terceira correção por medição é esperada.

## O que medir

| Dado | Onde está |
|---|---|
| `promptTokens`, `completionTokens` | `usage` da resposta, ou linha `[TokenUsage]` no logcat |
| `cachedTokens`, `cacheCreationTokens` | `usage.prompt_tokens_details`, ou a mesma linha do logcat |
| `reasoningTokens` | `usage.completion_tokens_details`, só se o modelo devolver |
| tamanho do `requestJson` e do `responseJson` | medidos pelo `analisar_request.py` |
| quantidade e tamanho das ferramentas | `analisar_request.py`, ou linha `request_tools=M` no logcat |
| chamadas ao modelo e iterações do loop | uma entrada de log por chamada; conte |
| tool calls | `analisar_request.py`, ou linha `parsed_tool_calls=K` |

`cacheCreationTokens` merece nota: o Kotlin envia esse campo pelo canal, mas o modelo Dart `TokenUsageRecord` não o lê, então nenhuma tela mostra. Ele aparece no `responseJson` bruto e na linha do logcat.

## Os quatro testes

Cada um em **conversa nova**. Testes 1 e 2 em sequência, sem nada no meio.

| # | Entrada | Modo |
|---|---|---|
| 1 | `oi` | Agent |
| 2 | `oi` | Chat |
| 3 | `abra o navegador` | Agent |
| 4 | o caso mais próximo do que chegou a cerca de 200 mil tokens | Agent |

**Teste extra, importante:** repita o teste 1 duas vezes na mesma conversa. A razão `cachedTokens / promptTokens` da segunda chamada é o que diz se o cache funciona.

## Sequência de cada teste

1. `adb logcat -c`
2. No celular: conversa nova, envie a mensagem, espere terminar.
3. `adb logcat -d > medicao\logcat-testeN.txt`
4. Filtre por `TokenUsage` e `request_tools`.
5. No app: Eu > Sobre > logs de requisição de IA. Copie `requestJson` e `responseJson` de cada chamada nova e salve em `medicao\req-testeN-1.json`, `resp-testeN-1.json`, e assim por diante.
6. Rode o analisador.
7. Preencha `tabela-etapa-0.md`.

Detalhe dos comandos em `logcat.md`.

## Cuidados que evitam medir a coisa errada

1. **Conversa nova sempre.** Histórico é a maior fonte de contaminação.
2. **Olhe os logs antes de mandar outra mensagem.** O app guarda só as dez últimas chamadas (`AiRequestLogStore.MAX_LOG_COUNT`). Turno longo apaga as primeiras. Por isso o logcat é a fonte principal.
3. **Bytes do log não são bytes do fio.** O `requestJson` guardado passa por `prettyJsonOrRaw` e está indentado. Use bytes para proporção, e `usage.prompt_tokens` como verdade de custo.
4. **Anote o modelo configurado.** `deepseek-chat` e um modelo de raciocínio devolvem campos diferentes.
5. **No teste 4, não tente copiar o JSON gigante.** Basta o bloco `usage` da resposta, que é pequeno, mais as linhas do logcat.

## Depois de preencher a tabela

Aplique a bifurcação da seção 10 do `00-PLANO-DEFINITIVO.md`:

| Resultado | Ordem |
|---|---|
| cache acima de 70% no teste 1 repetido | E1, E2, **E3**, E4, E5... |
| cache em zero | E1, E2, **E4**, E3, E5... e investigar por que o cache não pega |
| diferença pequena entre teste 1 e teste 2 | **pare e reporte.** A hipótese central está errada e o plano precisa de revisão |
| muitas iterações no teste 3 ou 4 | E1 fica mais urgente, inclua detecção de repetição já nela |
| um único resultado gigante no teste 4 | em E3, priorize teto por resultado com offload |

Cole a tabela preenchida em `docs/MELLY-EXECUTION-HANDOFF.md`, seção Medições,
e anote o ramo aplicável. O antigo `docs/05-ESTADO-ATUAL.md` era anterior ao
repositório Git e não é mais uma fonte de estado.
