# Capturar as métricas com adb

As métricas mais úteis são gravadas com nível INFO no log do Android. Elas **não aparecem em nenhuma tela do app**, porque em `baselib/.../util/OmniLog.kt` apenas `e()` e `wtf()` gravam no `RuntimeLogStore` que a interface lê. Com ADB disponível, o `adb logcat` resolve. A seção 7 descreve o caminho sem notebook.

---

## 1. Preparar o aparelho

1. Ative **Opções do desenvolvedor** e **Depuração USB** no Android.
2. Conecte por USB e autorize o computador quando o aparelho perguntar.
3. Confirme:

```bash
adb devices
```

Deve listar o aparelho como `device`. Se aparecer `unauthorized`, aceite o diálogo no celular.

## 2. As linhas que interessam

| Linha no log | O que traz | Origem |
|---|---|---|
| `[TokenUsage] recording: model=..., prompt=..., completion=..., reasoning=..., text=..., cached=..., cacheCreation=..., stream=..., url=...` | **todos os campos de token de uma vez**, por chamada HTTP | `HttpController` |
| `round=N request_tools=M` | rodada do loop e quantas ferramentas foram enviadas | `AgentOrchestrator` |
| `registered_tools count=N ... names=[...]` | catálogo montado no turno, com os nomes | `AgentToolRegistry` |
| `round=N parsed_tool_calls=K finish_reason=...` | quantas tool calls o modelo pediu | `AgentOrchestrator` |
| `[TokenUsage] no usage object found` | o provedor não devolveu `usage` nessa chamada | `HttpController` |

## 3. Comandos

### Limpar e capturar em arquivo (recomendado)

Windows, PowerShell:

```powershell
adb logcat -c
adb logcat > medicao\logcat-teste1.txt
```

Deixe rodando, faça o teste no app, volte e feche com `Ctrl+C`.

Depois filtre:

```powershell
Select-String -Path medicao\logcat-teste1.txt -Pattern "TokenUsage|request_tools|registered_tools|parsed_tool_calls"
```

Linux ou macOS:

```bash
adb logcat -c
adb logcat | tee medicao/logcat-teste1.txt | grep -E "TokenUsage|request_tools|registered_tools|parsed_tool_calls"
```

### Filtrar ao vivo, sem salvar

```powershell
adb logcat -c
adb logcat | findstr /C:"TokenUsage" /C:"request_tools" /C:"registered_tools"
```

### Reduzir o ruído

O app usa a tag global `[Omni]` mais a tag do componente. Para ver só INFO e acima:

```bash
adb logcat *:I
```

## 4. Salvar o `requestJson` para o analisador

Duas formas.

**Pela tela do app**, mais simples: Eu > Sobre > logs de requisição de IA, abra a entrada, toque no botão de copiar, e cole em um arquivo `.json` no notebook. Lembre que só as dez últimas chamadas ficam guardadas.

**Pelo log**, se o corpo aparecer nele: procure o trecho do corpo da requisição na captura e salve em `.json`. Atenção: o `requestJson` guardado no log do app passa por `prettyJsonOrRaw`, ou seja, está indentado. O tamanho em bytes dele **não é** o tamanho exato do que foi enviado no fio. Use os bytes só para proporção; a verdade de custo é `usage.prompt_tokens`.

## 5. Rodar o analisador

```bash
python medicao\analisar_request.py medicao\req-teste1.json
python medicao\analisar_request.py medicao\req-teste3-*.json     # varios turnos
python medicao\analisar_request.py --response medicao\resp-teste1.json
```

A saída mostra:

- quantos tokens estão em `tools`, em cada papel de mensagem, e a proporção de cada bloco;
- as dez ferramentas mais caras do catálogo;
- sinais de duplicação nos resultados de ferramenta, incluindo campo contido em outro campo e string contendo JSON.

Com `--response`, mostra o `usage` real, com a porcentagem do prompt que veio de cache.

## 6. Sequência completa de um teste

```powershell
adb logcat -c
# no celular: conversa nova, envie "oi" em Agent Mode, espere a resposta
adb logcat -d > medicao\logcat-teste1.txt
Select-String -Path medicao\logcat-teste1.txt -Pattern "TokenUsage|request_tools"
# no celular: Eu > Sobre > logs de requisicao de IA > copiar
# cole em medicao\req-teste1.json e em medicao\resp-teste1.json
python medicao\analisar_request.py medicao\req-teste1.json
python medicao\analisar_request.py --response medicao\resp-teste1.json
```

`adb logcat -d` despeja o buffer e sai, sem precisar de `Ctrl+C`.

## 7. Se o aparelho não estiver disponível

Sem `adb`, a tela de logs do app ainda dá `requestJson` e `responseJson` das dez últimas chamadas, e isso é suficiente para a tabela da etapa 0. O que você perde é a contagem de ferramentas por turno vinda do log de INFO, que pode ser recuperada contando o array `tools` com o analisador.

### Fluxo somente pelo celular

1. Execute um teste por vez e abra imediatamente **Eu > Sobre > logs de
   requisição de IA**.
2. Copie o `requestJson` e o `responseJson` para arquivos separados no celular.
3. Envie esses arquivos para o ambiente de desenvolvimento executar
   `analisar_request.py`; não é necessário instalar Python no aparelho.
4. Não faça outro teste antes de salvar os arquivos, pois o app mantém somente
   as dez chamadas mais recentes.

Esse fluxo mede tokens, cache, tamanho do catálogo, chamadas de ferramenta e
payloads. Ele não captura outras linhas INFO do processo; marque esses campos
como “não capturado”, sem estimá-los.
