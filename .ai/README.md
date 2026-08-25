# AI Workspace

This tracked, agent-neutral workspace separates external knowledge from repository implementation work. Do not put secrets, credentials, personal data, or raw sensitive payloads in `.ai/`; use ignored `.ai/local/` for local-only material when necessary.

## Handoff sequence

1. Inspect the repository and record only the minimum context needed in a Research Request.
2. Request external, authoritative research only when local evidence cannot answer the blocking question.
3. Save the response as the matching Research Result with sources and its research date.
4. Re-check the repository, then create an Implementation Plan that combines the result with actual project state.
5. Implement, test, and record durable choices in an ADR.

Research is not an implementation instruction. Repository state remains authoritative for implementation details.

## Invocation

Use the v0.1 PowerShell CLI from the repository root:

```powershell
pwsh -NoProfile -File tools/ai/ai.ps1 status
pwsh -NoProfile -File tools/ai/ai.ps1 research new "Topic"
pwsh -NoProfile -File tools/ai/ai.ps1 research list
pwsh -NoProfile -File tools/ai/ai.ps1 research copy [RES-YYYYMMDD-NNN]
```

Requests and matching results use the same `RES-YYYYMMDD-NNN` ID. `WAITING` means a request has no matching result; `DONE` means it does. Plans have no status schema in v0.1 and are counted in total only.

`status` prints the repository, branch, pending and done research counts, plan and decision totals, and the newest waiting request when one exists. Pending and done are derived only from matching request/result filenames; plans and ADRs are counted as Markdown files without a status interpretation.

`research copy` copies the exact request text for a supplied `RES-YYYYMMDD-NNN` ID. Without an ID, it copies the newest `WAITING` request. The command fails when a supplied ID is malformed or has no matching request, when an omitted ID finds no waiting request, or when the system clipboard is unavailable.

The optional global `ai` alias is user-managed; the repository only provides `tools/ai/ai.ps1`.
