# Context Junction

Claude Code, Codex CLI 같은 저장소 작업 Agent와 ChatGPT 같은 외부 조사 Agent의 역할을 나누고, 그 사이를 파일로 잇는 인수인계 프로토콜이다. 조사 결과를 대화창에서 흘려보내지 않고 `RES-` ID가 붙은 파일로 남겨, 나중에 구현·리뷰·재검토에서 다시 꺼내 쓴다.

- 저장소를 읽고 고치는 일: 작업 Agent
- 최신 문서, 공식 스펙, 버전별 동작처럼 저장소 밖 지식: 외부 조사 Agent
- 둘 사이 전달: `.ai/`에 남는 Research Request와 Research Result

현재 v0.1이다. 자동화보다 프로토콜 자체를 검증하는 단계이며, CLI는 Windows PowerShell 7을 대상으로 한다.

## 빠른 시작

저장소 루트에서 실행한다.

```powershell
# 1. 조사 요청 파일 생성
pwsh -NoProfile -File tools/ai/ai.ps1 research new "Spring Security OAuth2"
# -> .ai/research/requests/RES-20260825-001-spring-security-oauth2.md
```

2. 생성된 요청서의 빈 절을 채운다. 목표, 프로젝트 맥락, 현재 구현, 질문, 출처 요건, 버전·날짜 요건, 기대 산출물. ID와 주제는 CLI가 이미 채워 둔다.

```powershell
# 3. 요청서 원문을 클립보드로 복사해 외부 조사 Agent에 붙여넣는다
pwsh -NoProfile -File tools/ai/ai.ps1 research copy                    # 가장 최근 WAITING 요청
pwsh -NoProfile -File tools/ai/ai.ps1 research copy RES-20260825-001   # ID 지정
```

4. 답변을 `.ai/templates/research-result.md` 형식으로 `.ai/research/results/`에 저장한다. 파일명 앞부분을 요청과 같은 ID로 맞춘다.

```text
.ai/research/requests/RES-20260825-001-spring-security-oauth2.md
.ai/research/results/RES-20260825-001-spring-security-oauth2.md
```

```powershell
# 5. 상태 확인
pwsh -NoProfile -File tools/ai/ai.ps1 research list   # ID, WAITING 또는 DONE, 주제
pwsh -NoProfile -File tools/ai/ai.ps1 status          # 대기·완료 수, plan·decision 총계
```

6. 저장소를 다시 확인한 뒤 `.ai/templates/implementation-plan.md`로 구현 계획을 쓰고, 구현하고 테스트한다. 오래 갈 선택은 `docs/decisions/`에 ADR로 남긴다.

## 규칙

- 조사 결과는 구현 지시가 아니다.
- 구현 세부의 진실 기준은 저장소 상태다.
- 조사 결과가 현재 저장소와 충돌하면 조용히 적용하지 않고 충돌과 영향, 대안을 보고한다.
- API key, password, token, 개인정보, 원본 민감 payload는 문서·로그·커밋에 남기지 않는다. 로컬 전용 자료는 Git이 무시하는 `.ai/local/`에 둔다.

전문은 `AGENTS.md`의 외부 지식 정책에 있다. `CLAUDE.md`는 같은 본문을 담은 사본이다.

## 디렉터리

| 경로 | 내용 |
|---|---|
| `.ai/context/project.md` | 프로젝트 목적, 범위, 저장소 규약 |
| `.ai/research/requests/` | Research Request. `RES-YYYYMMDD-NNN-slug.md` |
| `.ai/research/results/` | Research Result. 요청과 같은 ID |
| `.ai/plans/` | 구현 계획. `PLAN-YYYYMMDD-NNN-slug.md` |
| `.ai/templates/` | 위 문서들의 템플릿 |
| `tools/ai/ai.ps1` | v0.1 PowerShell CLI |
| `tests/ai-cli.tests.ps1` | CLI 통합 테스트 |
| `harness/` | 하네스 계약, SSOT 인덱스, 커밋 규약, 검수 계약 |
| `docs/` | 백로그, 진행기록, ADR |

## 문서

| 문서 | 역할 |
|---|---|
| `.ai/README.md` | 인수인계 순서와 CLI 동작 상세 |
| `AGENTS.md`, `CLAUDE.md` | Agent 지침. 언제 외부 조사를 요청하고 언제 하지 않는가 |
| `harness/README.md` | 하네스 계약과 프로젝트 초기화 순서 |
| `harness/ssot-index.md` | 도메인별 권위 원천과 검증 방법 |
| `harness/commit-convention.md` | 커밋 메시지 규약 |
| `docs/backlog/작업목록.md` | 결정됐지만 끝나지 않은 작업 |
| `docs/progress/` | 작업별 진행기록 |
| `docs/decisions/` | ADR. 저장소 결정의 유일한 위치이며 템플릿은 `_TEMPLATE.md` |

구현계획 원문은 저장소 밖 `../docs/context-junction_구현계획.md`에 두며 Git에 추가하지 않는다.

## 검증

```powershell
pwsh -NoProfile -File tests/ai-cli.tests.ps1                 # CLI 통합 테스트
pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict # 문서 앵커 드리프트
pwsh -NoProfile -File tools/ai/ai.ps1 status                  # 저장소 smoke
```

## 알아둘 점

- 조사 상태는 요청과 결과 파일명의 ID가 짝을 이루는지로만 판정한다. 결과가 없으면 `WAITING`, 있으면 `DONE`이다. plan과 ADR은 상태를 해석하지 않고 Markdown 파일 개수만 센다. 근거는 `docs/decisions/ADR-001-ai-workspace-status.md`에 있다.
- 결과 파일은 CLI가 만들지 않는다. `research new`는 요청 파일과 빈 결과 디렉터리까지만 만든다. 결과를 직접 저장해야 `DONE`이 된다.
- 한글 주제는 파일명 slug가 `research`로 떨어진다. slug는 `a-z0-9`만 남기기 때문이다. 파일명으로 주제를 구분하려면 영문 주제를 쓰거나, 만든 뒤 ID 앞부분만 유지한 채 파일명을 바꾼다.
- ADR은 `docs/decisions/` 한 곳에만 둔다. `status`의 `Decisions Total`도 그 디렉터리를 세며 `_`로 시작하는 템플릿은 제외한다. 근거는 `docs/decisions/ADR-002-adr-location.md`에 있다.
- 전역 `ai` alias는 저장소가 제공하지 않는다. 필요하면 각자 PowerShell 프로필에 함수를 만들어 쓴다.
