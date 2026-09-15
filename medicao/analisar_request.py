#!/usr/bin/env python3
"""
Analisa um requestJson capturado do OpenOmniBot / Melly e mostra onde estao os tokens.

Uso:
    python analisar_request.py caminho/do/requestJson.json
    python analisar_request.py request1.json request2.json ...      (varios turnos)
    python analisar_request.py --response responseJson.json         (le o bloco usage)

De onde vem o arquivo:
  a) app: Eu > Sobre > logs de requisicao de IA > botao de copiar, cole em um .json
  b) adb: ver logcat.md

O estimador de token usa a MESMA heuristica do AgentContextBudget.kt do projeto
(ASCII vale 1/4 de token, nao-ASCII vale 6/4), para que os numberos daqui possam
ser comparados com os do app. E estimativa: a verdade de custo e o campo
usage.prompt_tokens da resposta.
"""

import json
import re
import sys
import os


def estimar_tokens(texto: str) -> int:
    """Porte fiel de AgentContextBudget.textTokens."""
    quartos = 0
    for ch in texto:
        quartos += 1 if ord(ch) <= 127 else 6
    return (quartos + 3) // 4


def tamanho(obj) -> int:
    if isinstance(obj, str):
        return len(obj.encode("utf-8"))
    return len(json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode("utf-8"))


def texto_de(obj) -> str:
    if obj is None:
        return ""
    if isinstance(obj, str):
        return obj
    if isinstance(obj, list):
        partes = []
        for bloco in obj:
            if isinstance(bloco, dict):
                if bloco.get("type") == "text":
                    partes.append(str(bloco.get("text", "")))
                elif bloco.get("type") in ("image_url", "image"):
                    partes.append("[IMAGEM]")
                else:
                    partes.append(json.dumps(bloco, ensure_ascii=False))
            else:
                partes.append(str(bloco))
        return "\n".join(partes)
    return json.dumps(obj, ensure_ascii=False)


def barra(fracao: float, largura: int = 28) -> str:
    cheio = int(round(fracao * largura))
    return "#" * cheio + "." * (largura - cheio)


def analisar_request(caminho: str) -> dict:
    with open(caminho, encoding="utf-8") as fh:
        req = json.load(fh)

    total_bytes = os.path.getsize(caminho)
    tools = req.get("tools") or []
    messages = req.get("messages") or []

    # ---- catalogo de ferramentas ----
    tools_bytes = tamanho(tools)
    tools_tokens = estimar_tokens(json.dumps(tools, ensure_ascii=False, separators=(",", ":")))
    por_ferramenta = []
    for t in tools:
        fn = (t or {}).get("function") or {}
        nome = fn.get("name", "?")
        por_ferramenta.append((nome, tamanho(t), estimar_tokens(
            json.dumps(t, ensure_ascii=False, separators=(",", ":")))))
    por_ferramenta.sort(key=lambda x: -x[1])

    # ---- mensagens por papel ----
    papeis = {}
    tool_msgs = []
    tool_calls = 0
    for m in messages:
        papel = (m or {}).get("role", "?")
        conteudo = texto_de(m.get("content"))
        tk = estimar_tokens(conteudo)
        bt = len(conteudo.encode("utf-8"))
        chamadas = m.get("tool_calls") or []
        tool_calls += len(chamadas)
        for c in chamadas:
            args = ((c or {}).get("function") or {}).get("arguments") or ""
            tk += estimar_tokens(str(args))
            bt += len(str(args).encode("utf-8"))
        d = papeis.setdefault(papel, {"n": 0, "tokens": 0, "bytes": 0})
        d["n"] += 1
        d["tokens"] += tk
        d["bytes"] += bt
        if papel == "tool":
            tool_msgs.append((tk, bt, conteudo))

    msgs_tokens = sum(v["tokens"] for v in papeis.values())
    est_total = tools_tokens + msgs_tokens

    # ---- deteccao de duplicacao dentro de resultado de ferramenta ----
    duplicados = []
    for tk, bt, conteudo in tool_msgs:
        try:
            payload = json.loads(conteudo)
        except (json.JSONDecodeError, TypeError):
            continue
        if not isinstance(payload, dict):
            continue
        campos = {k: v for k, v in payload.items()
                  if isinstance(v, str) and len(v) > 200}
        # a) campos identicos ou quase identicos
        vistos = {}
        for k, v in campos.items():
            chave = v[:400]
            vistos.setdefault(chave, []).append((k, len(v.encode("utf-8"))))
        for _, ocorr in vistos.items():
            if len(ocorr) > 1:
                duplicados.append(ocorr)
        # b) um campo CONTIDO em outro: pega terminalOutput dentro de rawResultJson
        # a comparacao ignora escape, espaco e pontuacao, para que
        # 'file "a.dart"' case com 'file \"a.dart\"'
        def assinatura(s: str) -> str:
            # remove sequencias de escape antes de reduzir a alfanumericos,
            # senao o \n escapado contribui a letra "n" e as assinaturas divergem
            limpo = re.sub(r'\\u[0-9a-fA-F]{4}|\\[nrtbf"\\/]', "", s)
            return "".join(ch for ch in limpo if ch.isalnum())

        itens = sorted(campos.items(), key=lambda kv: -len(kv[1]))
        assinaturas = {k: assinatura(v) for k, v in itens}
        for i, (k1, _) in enumerate(itens):
            for k2, v2 in itens[i + 1:]:
                amostra = assinaturas[k2][:200]
                if len(amostra) > 60 and amostra in assinaturas[k1]:
                    duplicados.append([
                        (f"{k2} CONTIDO em {k1}", len(v2.encode("utf-8"))),
                    ])
        # c) campos que sao string contendo JSON: escape duplo
        aninhados = [k for k, v in campos.items()
                     if v.lstrip().startswith(("{", "["))]
        if aninhados:
            duplicados.append([("STRING-DE-JSON (escape duplo): " + ", ".join(aninhados), 0)])

    print("=" * 74)
    print(f"ARQUIVO: {caminho}")
    print("=" * 74)
    print(f"modelo: {req.get('model', '?')}    stream: {req.get('stream')}")
    print(f"tamanho do arquivo: {total_bytes:,} bytes ({total_bytes/1024:.1f} KB)")
    print(f"mensagens: {len(messages)}    ferramentas: {len(tools)}    tool_calls: {tool_calls}")
    print()
    print("ONDE ESTAO OS TOKENS (estimativa, heuristica do AgentContextBudget)")
    print("-" * 74)
    linhas = [("tools (catalogo)", tools_tokens, tools_bytes)]
    for papel in ("system", "user", "assistant", "tool"):
        if papel in papeis:
            linhas.append((f"messages[{papel}]", papeis[papel]["tokens"], papeis[papel]["bytes"]))
    for papel, d in papeis.items():
        if papel not in ("system", "user", "assistant", "tool"):
            linhas.append((f"messages[{papel}]", d["tokens"], d["bytes"]))
    for nome, tk, bt in linhas:
        frac = tk / est_total if est_total else 0
        print(f"{nome:<22} {tk:>8,} tok  {bt:>9,} B  {frac*100:>5.1f}%  {barra(frac)}")
    print("-" * 74)
    print(f"{'TOTAL ESTIMADO':<22} {est_total:>8,} tok")
    print()

    if tools:
        print("10 FERRAMENTAS MAIS CARAS")
        print("-" * 74)
        for nome, bt, tk in por_ferramenta[:10]:
            print(f"  {nome:<34} {tk:>7,} tok  {bt:>8,} B")
        resto = sum(x[2] for x in por_ferramenta[10:])
        if resto:
            print(f"  {'(outras ' + str(len(por_ferramenta)-10) + ')':<34} {resto:>7,} tok")
        print()

    if duplicados:
        print("SINAIS DE DUPLICACAO EM RESULTADO DE FERRAMENTA")
        print("-" * 74)
        for ocorr in duplicados[:12]:
            if ocorr[0][1] == 0:
                print(f"  {ocorr[0][0]}")
            elif len(ocorr) == 1:
                k, b = ocorr[0]
                print(f"  {k}  ({b:,} B repetidos)")
            else:
                nomes = ", ".join(f"{k} ({b:,} B)" for k, b in ocorr)
                print(f"  mesmo conteudo em: {nomes}")
        print()
    elif tool_msgs:
        print("Nenhuma duplicacao obvia detectada nos resultados de ferramenta.\n")

    return {"arquivo": os.path.basename(caminho), "tools_n": len(tools),
            "tools_tokens": tools_tokens, "msgs_tokens": msgs_tokens,
            "est_total": est_total, "bytes": total_bytes, "tool_calls": tool_calls}


def analisar_response(caminho: str) -> None:
    with open(caminho, encoding="utf-8") as fh:
        bruto = fh.read()
    try:
        resp = json.loads(bruto)
    except json.JSONDecodeError:
        print(f"{caminho}: nao e JSON valido. Se for resposta em stream, procure o ultimo bloco usage.")
        return
    usage = None
    if isinstance(resp, dict):
        usage = resp.get("usage")
        if usage is None:
            for v in resp.values():
                if isinstance(v, dict) and "usage" in v:
                    usage = v["usage"]
                    break
    if not usage:
        print(f"{caminho}: nenhum bloco usage encontrado.")
        return
    pd = usage.get("prompt_tokens_details") or usage.get("input_tokens_details") or {}
    cd = usage.get("completion_tokens_details") or {}
    p = usage.get("prompt_tokens") or usage.get("input_tokens") or 0
    cached = pd.get("cached_tokens", 0)
    print("=" * 74)
    print(f"USAGE REAL: {caminho}")
    print("=" * 74)
    print(f"prompt_tokens        {p:,}")
    print(f"  cached_tokens      {cached:,}" + (f"   ({100*cached/p:.0f}% do prompt)" if p else ""))
    print(f"  cache_creation     {pd.get('cache_creation_tokens', 0):,}")
    print(f"completion_tokens    {usage.get('completion_tokens') or usage.get('output_tokens') or 0:,}")
    print(f"  reasoning_tokens   {cd.get('reasoning_tokens', 0):,}")
    print(f"  text_tokens        {cd.get('text_tokens', 0):,}")
    print()


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 1
    if args[0] == "--response":
        for c in args[1:]:
            analisar_response(c)
        return 0
    resumos = [analisar_request(c) for c in args if os.path.exists(c)]
    faltando = [c for c in args if not os.path.exists(c)]
    for c in faltando:
        print(f"AVISO: arquivo nao encontrado: {c}")
    if len(resumos) > 1:
        print("=" * 74)
        print("RESUMO DE TODOS OS TURNOS")
        print("=" * 74)
        print(f"{'arquivo':<26}{'tools':>7}{'tok tools':>11}{'tok msgs':>11}{'tok total':>11}")
        for r in resumos:
            print(f"{r['arquivo']:<26}{r['tools_n']:>7}{r['tools_tokens']:>11,}"
                  f"{r['msgs_tokens']:>11,}{r['est_total']:>11,}")
        print()
        print(f"chamadas ao modelo neste conjunto: {len(resumos)}")
        print(f"total de tool_calls: {sum(r['tool_calls'] for r in resumos)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
