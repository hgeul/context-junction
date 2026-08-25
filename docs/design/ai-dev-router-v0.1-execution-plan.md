# AI Dev Router v0.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a Git-tracked, agent-neutral file protocol for handing external research to repository work, with a small PowerShell 7 CLI for the initial research workflow.

**Architecture:** `.ai/` stores the protocol, templates, and shared records. `tools/ai/ai.ps1` is the sole CLI entry point; it discovers the Git root, operates only beneath `.ai/`, and owns `status` plus `research` subcommands. Tests invoke the entry point in disposable Git repositories, so behavior is verified without a PowerShell module or external service.

**Tech Stack:** Markdown, Git, PowerShell 7. No package manager, API client, browser automation, database, MCP server, or background process.

**Spec:** `docs/design/context-junction_구현계획.md`

> **Note (2026-08-25):** This plan is complete. Path references below describe the layout at the time of writing, when the spec was kept outside the repository. See ADR-004 for the move.

## Global Constraints

- Windows and PowerShell 7 are the supported runtime.
- `.ai/` is tracked; `.ai/local/` is ignored.
- Repository state is authoritative for implementation details; research results are inputs, never implementation instructions.
- Request, result, plan, and ADR IDs use the exact `RES-YYYYMMDD-NNN`, `PLAN-YYYYMMDD-NNN`, and `ADR-NNN` forms.
- v0.1 implements only `status`, `research new`, `research list`, and `research copy`.
- Never include credentials, tokens, passwords, private keys, PII, or raw sensitive payloads in generated records.
- Do not add a Claude/Codex/OpenAI API integration, MCP, web UI, vector store, queue, worker, or global shell-profile mutation.

---

## Repository Analysis

- The actual Git repository is `repository/`, currently on `main`; the source draft is intentionally outside it at `../docs/context-junction_구현계획.md` and is ignored by Git.
- The repository contains only the Context Junction harness: `AGENTS.md`, `harness/`, documentation templates, and a Markdown-anchor checker. There is no `CLAUDE.md`, application runtime, package manifest, existing PowerShell CLI, or existing `.ai/` workspace.
- `AGENTS.md` requires reading the harness and current backlog/progress first, preserving the external source draft, recording results in `docs/progress/`, and recording cross-cutting decisions as ADRs.
- CJ-001 is complete. This plan executes CJ-002. No existing code duplicates the requested protocol.

## Existing AI Configuration and Conflicts

- Add `CLAUDE.md`; none exists. Add the same External Knowledge Policy section to `AGENTS.md` without replacing its existing harness instructions.
- `.gitignore` currently ignores all `docs/**` except templates. It does not conflict with tracked `.ai/`; add only `.ai/local/`.
- The source draft's sample `Plans Draft/Active` counters have no plan-status metadata or state transition rule. v0.1 `status` will report `Plans Total` instead. Research retains the specified `WAITING` and `DONE` statuses because they can be derived from request/result filenames. Record this as ADR-001 during Task 1.
- The repository cannot make `ai` globally callable without changing a user PowerShell profile. v0.1 documents `pwsh -NoProfile -File tools/ai/ai.ps1 ...`; users who want `ai ...` may add their own local alias outside the repository.

## Proposed Changes

- Add the tracked `.ai/` handoff workspace, four record templates, one PowerShell entry point, integration tests, a Claude policy file, one ADR, and operational records.
- Modify only existing agent policy, ignore, SSOT, backlog, and progress files. Delete nothing.

## Directory Layout

```text
.ai/
  README.md
  context/project.md
  research/requests/
  research/results/
  plans/
  decisions/
  templates/research-request.md
  templates/research-result.md
  templates/implementation-plan.md
  templates/adr.md
  local/                         # ignored; never created by the CLI
tools/ai/ai.ps1
tests/ai-cli.tests.ps1
CLAUDE.md
docs/decisions/ADR-001-ai-workspace-status.md
docs/progress/2026-08-24_ai-dev-router-v0.1.md
```

## Research Request / Result / Plan / ADR Formats

The four templates preserve the source draft's required sections. Request and result use the same `RES` ID; a plan references related research/decisions; an ADR records the decision, alternatives, consequences, and review trigger. Task 1 creates these templates verbatim as the protocol contract.

## CLAUDE.md / AGENTS.md Changes

`CLAUDE.md` is new. `AGENTS.md` is extended in place. Both receive identical operative External Knowledge Policy rules: inspect repository context first, request only minimum blocking external research, store it as a request, re-check repository state before planning, and report rather than silently resolve conflicts.

## CLI Contract

- Invocation: `pwsh -NoProfile -File tools/ai/ai.ps1 <command> [arguments]` from any directory inside a Git worktree.
- The script locates the root with `git rev-parse --show-toplevel`; if unavailable, it writes one actionable error to stderr and exits nonzero.
- `status` reads only `.ai/` records and prints repository name, Git branch, Research `Pending`/`Done`, `Plans Total`, `Decisions Total`, and the latest waiting request's ID/topic when present.
- `research new <topic>` validates a nonblank topic, creates the request/result directories when absent, allocates the next unused same-day `RES` sequence by scanning request filenames, writes the request template with ID and topic substituted, and prints the request-relative path.
- Slugs are lowercase ASCII words joined by `-`; non-ASCII or punctuation-only topics use `research` so every request has a valid filename. The original Topic field preserves the supplied text.
- `research list` scans request files, extracts each request ID and Topic field, and prints `WAITING` when no result filename starts with the same ID; otherwise it prints `DONE`. Orphan results do not create rows.
- `research copy [RES-YYYYMMDD-NNN]` copies the explicit existing request, regardless of its result status. With no ID it copies the lexicographically newest waiting request. A missing target or no waiting request is a nonzero error. Clipboard access uses `Set-Clipboard` and does not print request contents.
- Unknown commands, malformed explicit IDs, missing topics, and filesystem/Git/clipboard failures exit nonzero with a concise stderr message. The CLI never reads `.env`, `.ai/local/`, or unrelated project files.

### Task 1: Add the shared protocol and policies

**Files:**
- Create: `.ai/README.md`, `.ai/context/project.md`, `.ai/templates/research-request.md`, `.ai/templates/research-result.md`, `.ai/templates/implementation-plan.md`, `.ai/templates/adr.md`, `CLAUDE.md`, `docs/decisions/ADR-001-ai-workspace-status.md`, `docs/progress/2026-08-24_ai-dev-router-v0.1.md`
- Modify: `AGENTS.md`, `.gitignore`, `docs/backlog/작업목록.md`, `harness/ssot-index.md`
- Test: `.codex/scripts/test-anchors.ps1`

**Interfaces:**
- Consumes: the source draft and existing harness contracts.
- Produces: tracked `.ai/` directories/templates and an identical External Knowledge Policy in `AGENTS.md` and `CLAUDE.md`.

- [ ] **Step 1: Create the failing protocol-anchor check.**

Run:

```powershell
pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict
```

Expected before adding documents: the check passes with no `.ai/` anchors because the protocol is absent; record this baseline in the progress document rather than treating it as feature proof.

- [ ] **Step 2: Create `.ai/` records and templates.**

Create all listed directories. Each template must contain the exact sections required by the source draft:

```text
research request: ID, Topic, Goal, Project Context, Current Implementation, Questions, Source Requirements, Version / Date Requirements, Expected Output
research result: Request, Researched At, Conclusion, Recommended Approach, Project Impact, Deprecated / Changed APIs, Risks, Alternatives, Recommendation, Open Questions, Sources
implementation plan: ID, Goal, Related Research, Related Decisions, Current State, Target State, Affected Files, Implementation Steps, Migration / Compatibility, Test Plan, Verification, Risks, Rollback, Done Criteria
ADR: Status, Date, Context, Decision, Alternatives, Rationale, Consequences, Related Research, Revisit When
```

Write `.ai/README.md` with the handoff sequence, safety rule, invocation form, and v0.1 command examples. Write `context/project.md` as a concise mutable project-context skeleton; it must not copy the whole repository or include secrets.

- [ ] **Step 3: Add policy and repository integration.**

Append the same External Knowledge Policy section to both root agent files. Add `.ai/local/` to `.gitignore`. Update the SSOT index to register `.ai/` protocol records as a shared handoff artifact and identify the CLI/tests as their verification target. Add ADR-001: `status` derives only Research `WAITING`/`DONE`; plans are total-counted until a status schema exists. Move CJ-002 to completed and add the next implementation task to the backlog. Create the progress record with goal, decision, planned verification, and follow-up dogfooding.

- [ ] **Step 4: Verify documentation links and tracked scope.**

Run:

```powershell
pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict
git check-ignore -v .ai/local/example.txt
git check-ignore -v .ai/README.md
```

Expected: anchor check exits 0; `.ai/local/example.txt` is ignored; `.ai/README.md` is not ignored.

- [ ] **Step 5: Commit the protocol.**

```powershell
git add .ai AGENTS.md CLAUDE.md .gitignore harness/ssot-index.md docs
git commit -m "feat(ai): 공유 조사 인수인계 프로토콜 추가"
```

### Task 2: Implement request creation and listing test-first

**Files:**
- Create: `tools/ai/ai.ps1`, `tests/ai-cli.tests.ps1`
- Test: `tests/ai-cli.tests.ps1`

**Interfaces:**
- Consumes: `.ai/templates/research-request.md` and request/result filename contract from Task 1.
- Produces: `research new` and `research list` behavior used by Task 3.

- [ ] **Step 1: Write failing integration cases in `tests/ai-cli.tests.ps1`.**

The test script creates a temporary Git repository, copies only `tools/ai/ai.ps1` and `.ai/templates/research-request.md`, then invokes the CLI in child PowerShell processes. Add cases that assert:

```powershell
research new 'Spring Security OAuth2'
# exits 0; prints .ai/research/requests/RES-20260824-001-spring-security-oauth2.md
# created document contains the exact generated ID and original Topic

research list
# initially includes RES-20260824-001 and WAITING

# create .ai/research/results/RES-20260824-001-spring-security-oauth2.md
research list
# same ID now includes DONE
```

Inject the test date through an environment variable read only by the CLI, e.g. `AI_TEST_DATE=2026-08-24`; production invocation uses the local date. Add a second `research new` assertion for `RES-20260824-002` to prove collision-free allocation.

- [ ] **Step 2: Run the new tests and observe the expected failure.**

Run:

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1
```

Expected: FAIL because `tools/ai/ai.ps1` does not yet exist or cannot dispatch `research new`.

- [ ] **Step 3: Implement the minimal entry point.**

Implement `tools/ai/ai.ps1` as one focused script. Parse `$args` into `status` or `research`; provide helpers inside the script for Git-root discovery, `.ai` path construction, strict ID validation, same-day sequence allocation, Topic extraction, and formatted errors. Use `Set-Content -NoNewline`/UTF-8 for templates and `Get-ChildItem -File` constrained to `.ai/research/requests` and `.ai/research/results`. Replace only `RES-YYYYMMDD-NNN` and the Topic placeholder in a template; do not execute template text.

- [ ] **Step 4: Run tests and verify green.**

Run:

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1
```

Expected: all Task 2 cases pass with exit code 0.

- [ ] **Step 5: Commit the request workflow.**

```powershell
git add tools/ai/ai.ps1 tests/ai-cli.tests.ps1
git commit -m "feat(ai): 조사 요청 생성과 조회 추가"
```

### Task 3: Add status, copy, and failure-path coverage test-first

**Files:**
- Modify: `tools/ai/ai.ps1`, `tests/ai-cli.tests.ps1`, `.ai/README.md`, `docs/progress/2026-08-24_ai-dev-router-v0.1.md`
- Test: `tests/ai-cli.tests.ps1`

**Interfaces:**
- Consumes: request/result behavior from Task 2.
- Produces: complete v0.1 CLI contract.

- [ ] **Step 1: Write failing test cases.**

Extend the test script with isolated repository cases that assert:

```powershell
status
# prints the temporary repository name, current branch,
# Research Pending: 1, Done: 1, Plans Total: 1, Decisions Total: 1,
# and the latest waiting request ID/topic

research copy RES-20260824-001
# calls a test-local Set-Clipboard shim with exactly the request text

research copy
# selects the newest WAITING request

research new '' ; research copy RES-20260824-999 ; unknown
# each exits nonzero and writes a specific concise error
```

Run `ai.ps1` in-process only for copy tests so the test-local `Set-Clipboard` shim is visible; all other cases remain child-process integration tests. This is the smallest seam that avoids writing to the real clipboard.

- [ ] **Step 2: Run the tests and observe the expected failure.**

Run:

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1
```

Expected: FAIL because `status` and `research copy` are unimplemented.

- [ ] **Step 3: Implement the minimal commands.**

Add `status` and `research copy` without changing Task 2 behavior. Count only request files for pending/done research; count plan and ADR markdown files for totals. Resolve explicit IDs only against request files. With no ID choose the newest `WAITING` ID. Call `Set-Clipboard -Value $requestText`; preserve error exit semantics if the clipboard is unavailable. Add usage and failure behavior to `.ai/README.md`.

- [ ] **Step 4: Run full CLI tests and direct smoke checks.**

Run:

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1
pwsh -NoProfile -File tools/ai/ai.ps1 status
pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict
```

Expected: all test assertions pass; the repository smoke check exits 0 and reports zero records before dogfooding; anchor check exits 0.

- [ ] **Step 5: Record verified results and commit.**

Update the progress record with exact commands/results, known limitation that the global `ai` alias is user-managed, and next dogfooding work. Commit:

```powershell
git add tools/ai/ai.ps1 tests/ai-cli.tests.ps1 .ai/README.md docs/progress
git commit -m "feat(ai): 조사 상태와 복사 명령 추가"
```

### Task 4: Final protocol review and handoff

**Files:**
- Modify: `docs/progress/2026-08-24_ai-dev-router-v0.1.md`, `docs/backlog/작업목록.md` only if status changes are needed.
- Test: `tests/ai-cli.tests.ps1`, `.codex/scripts/test-anchors.ps1`

**Interfaces:**
- Consumes: all v0.1 protocol files and CLI behavior.
- Produces: verified implementation record and dogfooding-ready backlog.

- [ ] **Step 1: Run the full verification set.**

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1
pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict
git diff --check
git status --short
```

Expected: test and anchor scripts exit 0; `git diff --check` has no output; status contains only intended tracked changes.

- [ ] **Step 2: Perform the harness reviews.**

Apply `harness/reviews/grill.md`, `dod.md`, `drift.md`, and `policy-audit.md` to the complete diff. Confirm the policies have identical operative rules, `.ai/local/` is the only new ignore rule, no template includes sensitive data, and each created authority is registered in `harness/ssot-index.md`.

- [ ] **Step 3: Write the final operational record.**

Set the progress record to complete, list test evidence and unresolved limits, and add the next backlog item: run 5–10 real Research Handoffs before considering any API, MCP, or automation expansion.

- [ ] **Step 4: Commit verification records.**

```powershell
git add docs
git commit -m "docs(ai): v0.1 검증 결과 기록"
```

## Compatibility

- Uses PowerShell 7 and Git already required by the source draft.
- Introduces no application API, persistent database schema, global machine configuration, or migration.
- Existing harness documents remain authoritative; the new policy is appended, not substituted.

## Test Plan

- Disposable-repository integration tests cover request creation, deterministic IDs, `WAITING`/`DONE`, status counts, copy selection, and nonzero errors.
- The copy test replaces `Set-Clipboard` in-process; no test writes to the user clipboard.
- The existing strict anchor checker, `git diff --check`, and direct CLI smoke check cover documentation and repository hygiene.

## Implementation Order

1. Establish the protocol, policy, ADR, and operational records.
2. Test-drive request creation and listing.
3. Test-drive status, copying, and errors.
4. Run full verification and harness reviews; prepare 5–10 real handoffs as the next work item.

## Risks and Rollback

- `Set-Clipboard` may be unavailable in noninteractive/headless sessions. The command must fail clearly; all other commands remain usable.
- Filename-derived state can be malformed by manual edits. The CLI must ignore nonmatching filenames and never infer a result from file content.
- Templates are shared records; users must review them before placing sensitive content in a request.
- Rollback is one revert of the v0.1 commits. Remove the tracked `.ai/` files only through Git; retain no external state except a user clipboard value.

## Done Criteria

- [ ] `.ai/` protocol, templates, README, and `.ai/local/` ignore rule exist and are tracked correctly.
- [ ] `AGENTS.md` and `CLAUDE.md` contain the same External Knowledge Policy.
- [ ] `research new`, `research list`, `research copy`, and `status` meet the CLI contract.
- [ ] Tests demonstrate `WAITING`, `DONE`, sequential IDs, status counts, copying, and error exits.
- [ ] Documentation anchors, CLI tests, and `git diff --check` pass.
- [ ] Progress, backlog, SSOT index, and ADR record the result and the status-count decision.
- [ ] No excluded automation/API/MCP feature is introduced.
