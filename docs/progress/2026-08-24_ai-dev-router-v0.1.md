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
- Added the v0.1 PowerShell CLI status and research copy commands with file-derived research state and total-only plan/ADR counts.
- Added isolated integration coverage, including an in-process `Set-Clipboard` shim so tests never access the real clipboard.

## 결정

Research is `WAITING` or `DONE` solely from matching request/result IDs. Plans are total-counted until a status schema is validated; ADR-001 records this choice.

## 결과 및 검증

- Baseline: `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` passed before protocol records existed (`anchors_checked=0 drift=0`).
- `pwsh -NoProfile -File tests/ai-cli.tests.ps1` passed with 30 assertions after adding status, copy, and failure-path coverage.
- `pwsh -NoProfile -File tools/ai/ai.ps1 status` and `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` are the repository smoke and anchor checks for the completed CLI.
- Final protocol review (2026-08-25): `pwsh -NoProfile -File tests/ai-cli.tests.ps1` output `PASS: 30 assertions`; `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` output `anchors_checked=0 drift=0`; `git diff --check` had no output. Harness reviews found identical operative External Knowledge Policy text in `AGENTS.md` and `CLAUDE.md`, no sensitive-data pattern matches in `.ai/templates/`, and registered the AI handoff authority in `harness/ssot-index.md`.

## 미완료 및 위험

- The optional global `ai` alias is user-managed; this repository provides only `tools/ai/ai.ps1`.
- Template usability and the minimal-context rule need dogfooding with five to ten real Research Handoffs before any API, MCP, or automation expansion.
- The complete branch range also adds `.worktrees/` to `.gitignore` for isolated workspaces; `.ai/local/` is the only new ignore rule for local AI handoff material.

## 다음 작업

Run five to ten real v0.1 Research Handoffs, then evaluate whether additional automation is justified.

## 관련 문서

- `.ai/README.md`
- `docs/decisions/ADR-001-ai-workspace-status.md`
