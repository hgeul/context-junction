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

Use the templates directly until the v0.1 PowerShell CLI is added:

```powershell
Copy-Item .ai/templates/research-request.md .ai/research/requests/RES-YYYYMMDD-NNN-short-topic.md
Copy-Item .ai/templates/research-result.md .ai/research/results/RES-YYYYMMDD-NNN-short-topic.md
Copy-Item .ai/templates/implementation-plan.md .ai/plans/PLAN-YYYYMMDD-NNN-short-topic.md
Copy-Item .ai/templates/adr.md .ai/decisions/ADR-NNN-short-title.md
```

Planned v0.1 commands are:

```powershell
ai status
ai research new "Topic"
ai research list
ai research copy [RES-YYYYMMDD-NNN]
```

Requests and matching results use the same `RES-YYYYMMDD-NNN` ID. `WAITING` means a request has no matching result; `DONE` means it does. Plans have no status schema in v0.1 and are counted in total only.
