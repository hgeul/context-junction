# 2026-08-24 AI Dev Router v0.1 Protocol

> 상태: 완료
> 관련 작업: CJ-002 구현계획 기반 첫 기능 분해
> 관련 결정: ADR-001

## 목표

Agent-neutral `.ai/` workspace and external-research handoff rules establish the v0.1 protocol before CLI automation.

## 배경 및 사유

Repository context and current external knowledge require different sources of truth. The protocol records the minimum context needed to research an external question, then requires repository verification before implementation planning.

## 진행 내용

- Created tracked `.ai/` context, request/result, plan, decision, and template locations.
- Added matching External Knowledge Policy text to `AGENTS.md` and `CLAUDE.md`.
- Registered the handoff protocol and its future CLI verification target in the SSOT index.

## 결정

Research is `WAITING` or `DONE` solely from matching request/result IDs. Plans are total-counted until a status schema is validated; ADR-001 records this choice.

## 결과 및 검증

- Baseline: `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` passed before protocol records existed (`anchors_checked=0 drift=0`).
- Planned final verification: strict anchor check and Git ignore checks for `.ai/local/example.txt` and `.ai/README.md`.

## 미완료 및 위험

- The PowerShell `ai` CLI is the next implementation task.
- Template usability and the minimal-context rule need dogfooding with real research handoffs.

## 다음 작업

Implement and dogfood the v0.1 PowerShell CLI, then evaluate five to ten handoffs before expanding automation.

## 관련 문서

- `.ai/README.md`
- `docs/decisions/ADR-001-ai-workspace-status.md`
