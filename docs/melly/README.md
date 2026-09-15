# Melly project documents

This directory preserves the approved architecture, audit and decision material
that predates the executable Git repository.

## Authority order

1. `../MELLY-EXECUTION-HANDOFF.md` is the live operational state.
2. `08-ADENDO-01.md` overrides the v1.0 plan where they disagree.
3. `06-REGISTRO-DE-DECISOES.md` records architectural decisions; A005 is now
   confirmed as authoritative policy in Kotlin.
4. `00-PLANO-DEFINITIVO.md` and the remaining numbered documents provide the
   original plan and evidence.
5. `reference/` contains provenance and historical review material, not current
   execution state.

The former pre-Git `05-ESTADO-ATUAL.md` was intentionally not imported because
its claims are obsolete and would compete with the live handoff. The incomplete
source-code snapshot from the original ZIP was also excluded; Git history is the
only source of code truth.

The executable device-measurement kit lives at the repository root in
`medicao/`.
