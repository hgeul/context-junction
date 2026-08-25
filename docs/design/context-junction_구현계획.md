# AI Dev Router — Implementation Plan

> Version: v0.1 Planning Draft
>
> Date: 2026-08-24
>
> Primary Goal: Claude Code / Codex CLI와 ChatGPT 사이의 **외부 지식 조사 ↔ Repository 구현** 역할을 분리하고, 파일 기반 Handoff Protocol로 연결한다.

---

# 1. 배경

Claude Code나 Codex CLI로 실제 프로젝트를 작업하다 보면 아래 작업이 자주 섞인다.

- 현재 Repository 구조 분석
- 코드 수정
- 테스트 / 빌드
- 최신 프레임워크 문서 조사
- 공식 API / RFC 확인
- 라이브러리 비교
- deprecated 여부 검증
- 보안 권장 방식 확인
- 기술 선택 및 설계 판단

이 중 **Repository를 직접 읽고 수정해야 하는 작업**은 Claude Code / Codex가 가장 잘 처리한다.

반면 아래와 같은 **외부 지식이 필요한 작업**은 ChatGPT에서 별도로 조사하고 압축된 결과만 다시 개발 Agent에 전달하는 편이 효율적이다.

- 최신 공식 문서 검색
- 현재 버전 기준 API 정책 확인
- 기술 비교
- RFC / Specification 조사
- Cloud / Framework 최신 정책 확인
- 외부 사례 조사
- 설계 대안 비교

따라서 다음 역할 분리를 목표로 한다.

```text
Developer
   │
   ▼
Claude Code / Codex CLI
   │
   │ Repository 분석
   │
   ├── 외부 조사가 필요 없음 ────────────────┐
   │                                         │
   └── 외부 조사가 필요함                    │
          │                                  │
          ▼                                  │
   Research Request                          │
          │                                  │
          ▼                                  │
       ChatGPT                               │
   Web / Docs / Research                     │
          │                                  │
          ▼                                  │
   Research Result                           │
          │                                  │
          └───────────────┐                  │
                          ▼                  ▼
                    Claude / Codex
                          │
                  Repository와 결합
                          │
                          ▼
                    Implementation Plan
                          │
                          ▼
                   Code / Test / Build
```

---

# 2. 핵심 원칙

## 2.1 역할 분리

### ChatGPT

담당:

- Web Research
- 공식 문서 조사
- Framework / Library 정책 확인
- RFC / Specification 분석
- 기술 비교
- 최신 Best Practice 확인
- 외부 지식 기반 설계 대안 제시

담당하지 않음:

- 실제 Repository를 보지 않은 상태에서 최종 구현 계획 확정
- 프로젝트 코드 구조 추측
- 실제 코드 변경

---

### Claude Code / Codex CLI

담당:

- Repository 탐색
- 코드 구조 이해
- 관련 파일 식별
- 외부 조사가 필요한 질문 추출
- Research Request 생성
- Research Result와 실제 Repository 결합
- Implementation Plan 작성
- 코드 구현
- 테스트
- 빌드
- 린트
- Git diff 확인

---

# 3. 가장 중요한 규칙

```text
Research != Implementation Plan
```

외부 조사 결과는 최종 구현 명령이 아니다.

반드시 아래 흐름을 따른다.

```text
External Research
      +
Repository Context
      ↓
Claude Code / Codex
      ↓
Implementation Plan
      ↓
Implementation
```

ChatGPT가 작성한 일반적인 구현 예시나 추천안을 그대로 코드에 반영하지 않는다.

현재 프로젝트와 충돌하는 경우 **실제 Repository를 우선 확인**한다.

---

# 4. MVP 범위

v0.1에서는 자동 API 연동을 하지 않는다.

목표는 먼저 **Handoff Protocol 자체의 유용성을 검증**하는 것이다.

구현 범위:

```text
.ai/
├── README.md
│
├── context/
│   └── project.md
│
├── research/
│   ├── requests/
│   └── results/
│
├── plans/
│
├── decisions/
│
└── templates/
    ├── research-request.md
    ├── research-result.md
    ├── implementation-plan.md
    └── adr.md
```

추가:

- `CLAUDE.md`에 External Knowledge Policy 추가
- `AGENTS.md`에 동일 정책 추가
- PowerShell 기반 최소 CLI 제공

```text
ai status
ai research new
ai research list
ai research copy
```

---

# 5. 디렉터리 설계

## 5.1 `.ai/context/`

프로젝트의 장기적인 Context를 저장한다.

예:

```text
.ai/context/project.md
```

포함 내용:

- 프로젝트 목적
- 주요 기술 스택
- 주요 모듈
- Architecture
- 개발 규칙
- 테스트 전략
- 배포 구조
- 중요한 제약사항
- 인증/권한 구조
- DB / Messaging / External API 정보

이 파일은 일시적인 작업 로그가 아니다.

**다른 Agent가 프로젝트에 처음 들어왔을 때 빠르게 이해하기 위한 장기 Context**만 기록한다.

---

## 5.2 `.ai/research/requests/`

Claude / Codex가 외부 조사가 필요하다고 판단했을 때 생성한다.

파일명 규칙:

```text
RES-YYYYMMDD-NNN-short-topic.md
```

예:

```text
RES-20260824-001-spring-security-oauth2.md
```

---

## 5.3 `.ai/research/results/`

ChatGPT가 조사한 결과를 저장한다.

Request와 ID를 반드시 연결한다.

예:

```text
RES-20260824-001-spring-security-oauth2.md
```

Request와 Result는 같은 ID를 사용한다.

---

## 5.4 `.ai/plans/`

실제 Repository를 기준으로 한 구현 Plan을 저장한다.

파일명:

```text
PLAN-YYYYMMDD-NNN-short-topic.md
```

예:

```text
PLAN-20260824-001-spring-security-oauth2.md
```

---

## 5.5 `.ai/decisions/`

Architecture Decision Record를 저장한다.

파일명:

```text
ADR-NNN-short-title.md
```

예:

```text
ADR-005-oauth2-jwt-authentication.md
```

다음 내용을 기록한다.

- 어떤 결정을 했는가
- 왜 선택했는가
- 어떤 대안을 검토했는가
- 왜 다른 대안을 버렸는가
- 참고한 Research
- 향후 재검토 조건

---

# 6. Research Request 규격

Template:

```md
# Research Request

## ID

RES-YYYYMMDD-NNN

## Topic

조사 주제

## Goal

이 조사가 필요한 이유와 해결하려는 문제

## Project Context

현재 프로젝트의 관련 Context

예:

- Java 25
- Spring Boot 4.x
- PostgreSQL
- React SPA
- JWT 인증

## Current Implementation

현재 Repository에서 확인된 관련 구조

### Related Files

- path/to/FileA
- path/to/FileB

### Current Behavior

현재 코드가 어떻게 동작하는지 요약

## Questions

1. 반드시 확인해야 하는 질문
2. 버전별 차이
3. deprecated 여부
4. 권장 구현 방식
5. 보안/성능/운영 고려사항

## Source Requirements

우선순위:

1. Official documentation
2. Official repository
3. Official specification / RFC
4. Maintainer discussion
5. 신뢰도 높은 기술 자료

가능하면 일반 블로그를 근거로 사용하지 않는다.

## Version / Date Requirements

반드시 현재 프로젝트에서 사용하는 버전을 기준으로 확인한다.

최신 정보가 필요한 경우 조사 날짜를 명시한다.

## Expected Output

- 결론
- 권장 방식
- 현재 프로젝트에 적용할 때의 영향
- 변경 / Deprecated API
- Risks
- Alternatives
- Sources
```

---

# 7. Research Result 규격

Template:

```md
# Research Result

## Request

RES-YYYYMMDD-NNN

## Researched At

YYYY-MM-DD

## Conclusion

가장 중요한 결론.

## Recommended Approach

공식 자료를 기준으로 가장 권장되는 방식.

## Project Impact

현재 프로젝트 Context를 기준으로 예상되는 영향.

### Component A

...

### Component B

...

## Deprecated / Changed APIs

현재 버전 기준 변경되었거나 deprecated 된 내용.

## Risks

- Risk 1
- Risk 2

## Alternatives

### Option A

설명

장점:

- ...

단점:

- ...

### Option B

설명

장점:

- ...

단점:

- ...

## Recommendation

어떤 Option을 추천하는지와 이유.

## Open Questions

Repository를 실제로 확인해야만 결정 가능한 항목.

## Sources

공식 자료 우선.

각 Source는 가능한 경우 아래 정보를 포함한다.

- 문서명
- 제공 주체
- URL
- 버전
- 확인 날짜
```

---

# 8. Implementation Plan 규격

Research Result는 최종 구현 Plan이 아니다.

Claude / Codex는 반드시 Repository를 다시 확인하고 Plan을 작성한다.

Template:

```md
# Implementation Plan

## ID

PLAN-YYYYMMDD-NNN

## Goal

구현 목표

## Related Research

- RES-YYYYMMDD-NNN

## Related Decisions

- ADR-NNN

## Current State

Repository에서 실제로 확인한 현재 구조.

## Target State

구현 후 목표 구조.

## Affected Files

### Modify

- path/to/FileA
- path/to/FileB

### Add

- path/to/NewFile

### Delete

- 필요할 경우

## Implementation Steps

### Step 1

작업 내용

### Step 2

작업 내용

### Step 3

작업 내용

## Migration / Compatibility

기존 코드/데이터와의 호환성.

## Test Plan

### Unit

- ...

### Integration

- ...

### Manual

- ...

## Verification

예:

```bash
./gradlew test
./gradlew build
```

## Risks

- ...

## Rollback

문제 발생 시 되돌리는 방법.

## Done Criteria

- [ ] 구현 완료
- [ ] Unit Test 통과
- [ ] Integration Test 통과
- [ ] Build 성공
- [ ] 기존 기능 Regression 없음
- [ ] 관련 문서 수정
```

---

# 9. ADR 규격

Template:

```md
# ADR-NNN: Decision Title

## Status

Proposed | Accepted | Deprecated | Superseded

## Date

YYYY-MM-DD

## Context

왜 이 결정이 필요한가.

## Decision

최종적으로 어떤 방식을 선택했는가.

## Alternatives

### Option A

...

### Option B

...

## Rationale

선택한 이유.

## Consequences

### Positive

- ...

### Negative

- ...

## Related Research

- RES-YYYYMMDD-NNN

## Revisit When

아래 조건이 발생하면 다시 검토한다.

- Framework major version 변경
- Scale 조건 변경
- 보안 정책 변경
```

---

# 10. Claude Code / Codex External Knowledge Policy

`CLAUDE.md`와 `AGENTS.md`에 동일한 정책을 추가한다.

초안:

```text
# External Knowledge Policy

Repository knowledge and external knowledge must be handled separately.

Before requesting external research:

1. Inspect the repository.
2. Determine whether the required information already exists locally.
3. Identify the minimum external questions that block implementation.

External research should be requested when the task depends on current or authoritative information such as:

- latest framework documentation
- library version behavior
- deprecated API verification
- official API specifications
- RFC / protocol behavior
- security recommendations
- cloud provider behavior
- recent breaking changes
- technology comparison
- current best practices

Do NOT request external research for information that can be determined from:

- repository source code
- local documentation
- configuration files
- existing tests
- lock files
- build files
- project history available locally

When external research is required:

1. Inspect all relevant repository files first.
2. Create a Research Request under:

   .ai/research/requests/

3. Include:
   - project context
   - current implementation
   - related files
   - exact questions
   - version requirements

4. Continue any work that does not depend on the research result.

5. When a matching Research Result exists:

   .ai/research/results/

   re-check the actual repository before creating an implementation plan.

6. Never treat Research Result as an implementation instruction.

7. Repository state is the source of truth for implementation details.

8. If Research Result conflicts with the current repository:
   - report the conflict
   - explain the impact
   - propose alternatives
   - do not silently apply assumptions
```

---

# 11. Research가 필요한 조건

다음은 Research Request 후보이다.

```text
"Spring Boot 4에서 이 API가 deprecated 되었나?"
"AWS 공식 권장 설정은 무엇인가?"
"OAuth 2.1 최신 정책은 어떻게 바뀌었는가?"
"현재 PostgreSQL 버전에서 이 기능이 지원되는가?"
"이 CVE가 현재 사용하는 라이브러리에 영향이 있는가?"
"Kafka 공식 문서 기준 권장 설정은 무엇인가?"
"OpenAI 최신 API 사용법은 무엇인가?"
```

---

# 12. Research가 필요하지 않은 조건

다음은 먼저 Repository에서 해결한다.

```text
"현재 로그인 처리는 어디서 하는가?"
"이 프로젝트가 어떤 DB를 사용하는가?"
"이 메서드를 누가 호출하는가?"
"이 테스트가 왜 실패하는가?"
"현재 application.yml 설정값은 무엇인가?"
"JWT TokenProvider가 어디에 있는가?"
"이 DTO를 사용하는 Controller는 무엇인가?"
```

---

# 13. Research 요청 판단 Flow

```text
Question
   │
   ▼
Repository에서 확인 가능한가?
   │
 ┌─┴─┐
YES  NO
 │    │
 ▼    ▼
로컬   최신/외부 권위 정보가 필요한가?
조사       │
          ┌─┴─┐
         NO  YES
          │    │
          ▼    ▼
        추론   Research Request
        가능
```

단, 추론으로 확실하지 않은 내용을 사실처럼 확정하지 않는다.

---

# 14. PowerShell CLI v0.1

CLI 이름:

```text
ai
```

우선 PowerShell 7을 기준으로 구현한다.

## 14.1 `ai status`

출력 예:

```text
AI Workspace

Project
  name: sample-project
  branch: feature/oauth2

Research
  Pending: 1
  Done:    4

Plans
  Draft:   1
  Active:  1

Decisions
  Total:   5

Latest Pending Research
  RES-20260824-001
  Spring Security OAuth2
```

필요 기능:

- 현재 Git branch 확인
- Request 수 확인
- Result 존재 여부로 상태 계산
- Plan 수 확인
- ADR 수 확인

---

## 14.2 `ai research new`

새 Research Request를 만든다.

예:

```powershell
ai research new "Spring Security OAuth2"
```

결과:

```text
.ai/research/requests/RES-20260824-001-spring-security-oauth2.md
```

Template을 복사한다.

---

## 14.3 `ai research list`

예:

```text
ID                   STATUS      TOPIC
----------------------------------------------------
RES-20260824-001     WAITING     Spring Security OAuth2
RES-20260823-002     DONE        PostgreSQL JSONB index
```

상태 정의:

```text
WAITING
```

Request만 존재.

```text
DONE
```

동일 ID Result 존재.

---

## 14.4 `ai research copy`

가장 최근 WAITING Request 내용을 Clipboard에 복사한다.

PowerShell에서는:

```powershell
Set-Clipboard
```

사용 가능.

명시적 ID도 지원한다.

```powershell
ai research copy RES-20260824-001
```

---

# 15. CLI 구현 구조 제안

초기에는 복잡한 언어를 사용하지 않는다.

PowerShell Script 기반으로 시작한다.

예:

```text
tools/
└── ai/
    ├── ai.ps1
    ├── commands/
    │   ├── status.ps1
    │   └── research.ps1
    └── lib/
        ├── paths.ps1
        ├── ids.ps1
        └── git.ps1
```

또는 MVP에서는 단일 `ai.ps1`도 허용한다.

중요한 것은 코드 구조보다 **Handoff Protocol 검증**이다.

---

# 16. Git 정책

`.ai/`는 기본적으로 Git에 포함한다.

이유:

- Research 기록 공유
- 기술 결정 히스토리 보존
- Claude / Codex 간 Context 공유
- Branch 별 Plan 관리
- 향후 Agent 변경에도 지식 유지

단, 다음은 저장하지 않는다.

- API Key
- Password
- Token
- 개인 인증 정보
- 고객 개인정보
- 민감한 Production Credential

필요하면:

```text
.ai/local/
```

을 만들고 `.gitignore` 처리한다.

예:

```gitignore
.ai/local/
```

---

# 17. ID 정책

Research:

```text
RES-YYYYMMDD-NNN
```

Plan:

```text
PLAN-YYYYMMDD-NNN
```

ADR:

```text
ADR-NNN
```

`NNN`은 같은 날짜 또는 같은 유형 내에서 증가한다.

예:

```text
RES-20260824-001
RES-20260824-002

PLAN-20260824-001

ADR-001
ADR-002
```

ID 생성은 CLI에서 자동화한다.

---

# 18. Status 정의

Research:

```text
WAITING
DONE
```

추후 확장:

```text
DRAFT
WAITING
DONE
STALE
SUPERSEDED
```

Plan:

```text
DRAFT
READY
ACTIVE
DONE
BLOCKED
```

ADR:

```text
PROPOSED
ACCEPTED
DEPRECATED
SUPERSEDED
```

v0.1에서는 가능한 한 최소 상태만 사용한다.

---

# 19. Stale Research

Research 결과는 시간이 지나면 유효하지 않을 수 있다.

특히 다음 영역:

- Cloud Provider
- AI API
- Framework
- Security
- SaaS API
- Pricing
- Library Version

향후 Research Result에 다음 Metadata를 추가할 수 있다.

```yaml
researched_at: 2026-08-24
valid_for_version: "Spring Security 7.x"
recheck_after: 2026-11-24
```

v0.1에서는 필수 구현 대상이 아니다.

---

# 20. Context 최소화 전략

Research Request에는 Repository 전체 내용을 넣지 않는다.

원칙:

```text
Minimum Sufficient Context
```

필요한 정보만 전달한다.

좋은 예:

```text
Java 25
Spring Boot 4
JWT 인증
SecurityConfig
JwtAuthenticationFilter
OAuth2SuccessHandler
```

나쁜 예:

```text
프로젝트 전체 소스 덤프
```

목표는 ChatGPT가 문제를 이해할 수 있을 만큼만 Context를 전달하는 것이다.

---

# 21. Source 정책

Research에서는 신뢰도 우선순위를 둔다.

```text
1. Official Documentation
2. Official Repository
3. Official Specification / RFC
4. Maintainer / Vendor Material
5. Academic / Standards Material
6. 신뢰 가능한 Secondary Source
7. 일반 Blog / Forum
```

일반 Blog / Stack Overflow / Reddit 등은:

- 보조 자료
- 실제 사례 탐색
- 공식 문서에서 부족한 edge case 탐색

용도로만 사용한다.

최종 결론은 가능하면 공식 자료를 기반으로 한다.

---

# 22. Security

Research Request 생성 시 다음 내용을 자동으로 포함하지 않는다.

- `.env`
- secret
- token
- password
- certificate private key
- production credential
- customer PII
- internal confidential identifiers

향후 CLI에서 Secret Pattern Scan을 추가할 수 있다.

v0.1에서는 Documentation Rule로만 시작한다.

---

# 23. 실패 케이스

## Case 1 — Agent가 Research를 너무 많이 요청

대응:

```text
Do NOT request research for information already available in repository.
```

규칙 강화.

---

## Case 2 — ChatGPT 결과가 일반론적

원인:

Research Request의 Project Context 부족.

대응:

- 관련 파일
- 현재 구현
- 실제 Version
- 구체적인 질문

을 Request에 포함한다.

---

## Case 3 — Research Result를 그대로 구현

금지한다.

반드시:

```text
Research
   +
Repository Verification
   ↓
Implementation Plan
```

단계를 거친다.

---

## Case 4 — Research가 오래되어 잘못된 정보 사용

Result에 조사 날짜 / 버전을 기록한다.

추후 STALE 상태 도입.

---

# 24. 구현 Phase

## Phase 0 — Repository 분석

Codex가 먼저 현재 프로젝트 구조를 확인한다.

확인:

- 기존 `CLAUDE.md`
- 기존 `AGENTS.md`
- scripts / tools 위치
- PowerShell 관련 기존 도구
- `.gitignore`
- README 구조

기존 정책을 깨지 않도록 통합한다.

---

## Phase 1 — `.ai` Protocol

구현:

```text
.ai/
├── README.md
├── context/
├── research/
│   ├── requests/
│   └── results/
├── plans/
├── decisions/
└── templates/
```

완료 조건:

- 모든 디렉터리 생성
- Template 4종 생성
- `.ai/README.md`에 사용 방법 기록

---

## Phase 2 — Agent Policy

구현:

- `CLAUDE.md`
- `AGENTS.md`

External Knowledge Policy 추가.

기존 문서가 존재하면 덮어쓰지 않는다.

관련 Section만 추가한다.

완료 조건:

- Claude와 Codex가 동일한 Handoff 규칙 사용

---

## Phase 3 — PowerShell CLI

구현:

```text
ai status
ai research new
ai research list
ai research copy
```

완료 조건:

- PowerShell 7에서 실행 가능
- Git repository root를 자동 탐색
- `.ai` 경로 자동 탐색
- Research ID 충돌 없음
- Clipboard 복사 가능

---

## Phase 4 — 테스트

테스트 시나리오:

### Scenario A

```text
ai research new "Spring Security OAuth2"
```

Request 생성 확인.

### Scenario B

```text
ai research list
```

WAITING 표시 확인.

### Scenario C

동일 ID Result 파일 생성.

```text
ai research list
```

DONE 표시 확인.

### Scenario D

```text
ai research copy RES-...
```

Clipboard 확인.

### Scenario E

```text
ai status
```

Git branch 및 Research 현황 확인.

---

## Phase 5 — 실제 Dogfooding

실제 개발 작업에서 최소 5~10개의 Research Handoff를 수행한다.

관찰할 것:

- Request 작성이 귀찮은가?
- ChatGPT에 제공되는 Context가 충분한가?
- Result format이 너무 긴가?
- Plan으로 다시 변환하는 과정이 유용한가?
- 동일 정보를 반복 조사하는가?
- Claude / Codex가 `.ai` 규칙을 잘 준수하는가?

이 단계 전에는 MCP/API 자동화에 들어가지 않는다.

---

# 25. 향후 확장

## v0.2

CLI UX 개선.

```text
ai research open
ai research import
ai plan new
ai adr new
```

---

## v0.3

Statusline 연동.

예:

```text
feature/oauth2 | RES 1 waiting | PLAN 1 active
```

Codex / shell prompt에 표시.

---

## v0.4

Claude Code / Codex hooks.

예:

외부 조사가 필요한 경우 자동으로 Research Request Template 생성.

---

## v0.5

MCP.

```text
research.create
research.list
research.read
research.result
```

형태로 노출.

---

## v1.0

AI Dev Router.

```text
Developer
   │
   ▼
Router
   │
   ├── Repository Work ───→ Claude / Codex
   ├── External Research ─→ ChatGPT / Search Agent
   ├── Architecture ──────→ Reasoning Agent
   └── Verification ──────→ Review Agent
```

자동화 여부는 v0.1~v0.4 사용 경험을 기준으로 결정한다.

---

# 26. MVP에서 하지 않을 것

다음은 의도적으로 제외한다.

- ChatGPT Web UI 자동 조작
- Browser Automation
- OpenAI API 자동 호출
- Claude API 자동 호출
- Multi-Agent Scheduler
- Vector DB
- RAG
- Database
- Web Dashboard
- Queue
- Background Worker
- MCP 자동 연결
- 복잡한 State Machine

이유:

초기 목표는 **Handoff Protocol 검증**이다.

---

# 27. 성공 기준

v0.1 성공 여부는 코드량이 아니라 아래 기준으로 판단한다.

### 목표 1

Claude / Codex가 외부 지식이 필요한 작업을 명확히 식별한다.

### 목표 2

Research Request만 ChatGPT에 전달해도 문제를 이해할 수 있다.

### 목표 3

ChatGPT Research Result를 Claude / Codex가 실제 Repository에 적용할 수 있다.

### 목표 4

Research와 Implementation Plan이 명확히 분리된다.

### 목표 5

동일한 Research를 반복하지 않는다.

### 목표 6

Claude ↔ Codex를 변경해도 `.ai` 지식이 유지된다.

### 목표 7

기존 개발 Workflow보다 사용량 / Context 낭비가 줄어든다.

---

# 28. Codex 구현 지침

이 문서를 받은 Codex는 바로 구현하지 말고 먼저 Repository를 분석한다.

순서:

```text
1. Repository 구조 확인
2. 기존 CLAUDE.md / AGENTS.md 확인
3. 기존 scripts / tools 구조 확인
4. 기존 규칙과 충돌 여부 확인
5. 이 문서의 설계를 현재 Repository에 맞게 조정
6. Implementation Plan 작성
7. 사용자에게 Plan 제시
8. 승인 또는 기존 workflow에 따라 구현
```

중요:

```text
DO NOT blindly create files before understanding the repository.
```

기존 구조가 이미 비슷한 기능을 제공하면 중복 구현하지 않는다.

---

# 29. Codex가 작성해야 하는 구현 Plan

최소 아래 항목을 포함한다.

```md
# AI Dev Router v0.1 Implementation Plan

## Repository Analysis

현재 Repository 구조

## Existing AI Configuration

CLAUDE.md
AGENTS.md
기존 Hooks / Scripts

## Proposed Changes

추가 파일
수정 파일
삭제 파일

## Directory Layout

최종 `.ai` 구조

## CLI Design

PowerShell command 구조

## Agent Policy Changes

CLAUDE.md
AGENTS.md

## Compatibility

Windows
PowerShell 7
Git

## Test Plan

기능별 테스트

## Risks

기존 workflow 충돌 가능성

## Implementation Order

Step 1
Step 2
...

## Done Criteria

완료 조건
```

---

# 30. Codex에게 전달할 최종 요청

아래 요청과 함께 이 문서를 Codex에 전달한다.

```text
이 문서는 AI Dev Router v0.1의 초기 설계안이다.

목표는 Claude Code / Codex CLI가 Repository 작업에 집중하고,
최신 공식 문서나 외부 지식 조사가 필요할 경우 ChatGPT로 넘길 수 있도록
파일 기반 Handoff Protocol을 만드는 것이다.

중요한 점:

- 지금 바로 구현하지 말 것.
- 먼저 현재 Repository 전체 구조와 기존 AI 관련 설정을 분석할 것.
- CLAUDE.md, AGENTS.md, hooks, scripts, tools, .gitignore를 확인할 것.
- 기존 구조와 중복되거나 충돌하는 부분을 찾아낼 것.
- 이 설계를 그대로 복사하지 말고 현재 Repository에 맞게 조정할 것.
- MVP 범위를 과도하게 확장하지 말 것.
- MCP, API, Browser Automation은 이번 버전에서 제외할 것.
- PowerShell 7 / Windows 환경을 우선 지원할 것.
- `.ai`는 특정 Agent 전용이 아니라 Claude Code / Codex / ChatGPT가 공유하는
  Agent-neutral workspace로 설계할 것.

먼저 구현 계획만 작성해라.

구현 계획에는 반드시 다음을 포함해라.

1. Repository 분석 결과
2. 기존 AI 설정과의 충돌 여부
3. 생성/수정할 파일 목록
4. 최종 디렉터리 구조
5. Research Request / Result / Plan / ADR 규격
6. CLAUDE.md / AGENTS.md 변경 방안
7. PowerShell CLI 구조
8. 테스트 계획
9. 위험 요소
10. 단계별 구현 순서
11. 완료 조건

아직 코드는 수정하지 말고 Plan만 제시해라.
```

---

# 31. 최종 방향

이 프로젝트의 목적은 AI Agent를 많이 붙이는 것이 아니다.

핵심은 다음 두 종류의 Context를 분리하는 것이다.

```text
Repository Context
        +
External Knowledge
```

그리고 필요한 순간에만 결합한다.

최종적으로 다음 Workflow가 자연스럽게 동작하면 성공이다.

```text
Claude / Codex
      │
      │ "외부 정보가 필요하다"
      ▼
Research Request
      │
      ▼
ChatGPT
      │
      │ 공식 자료 조사
      ▼
Research Result
      │
      ▼
Claude / Codex
      │
      │ 실제 Repository 재검증
      ▼
Implementation Plan
      │
      ▼
Code / Test / Build
```

v0.1에서는 이 Workflow를 **파일 기반으로 안정적으로 정착시키는 것**에 집중한다.
