# ADR: ADR 저장 위치를 `docs/decisions/`로 통합

> date: `2026-08-25` | status: 채택
> related progress: `docs/progress/2026-08-25_adr-위치-통합.md`

## 맥락

같은 ADR을 담는 위치가 둘로 공존했다. `.ai/decisions/`는 AI Dev Router 구현계획 5.5절에서, `docs/decisions/`는 Codex 하네스 초기화에서 왔다.

구현계획 5.5절은 `.ai/decisions/`를 "Architecture Decision Record를 저장한다"로만 정의했고 예시가 `ADR-005-oauth2-jwt-authentication.md`다. 조사 결과 전용 저장소가 아니라 일반 ADR 저장소였다. 실제 상태도 갈려 있었다. `.ai/decisions/`는 `.gitkeep`만 있는 빈 디렉터리였고, ADR-001과 `_TEMPLATE.md`는 `docs/decisions/`에 있었으며, `harness/reviews/grill.md`는 이미 "사용자가 답한 중요 결정은 `docs/decisions/` ADR에 남긴다"고 규정하고 있었다. CLI `status`는 `.ai/decisions/`만 세어 ADR이 하나 있는데도 `Decisions Total: 0`을 출력했다.

## 결정과 근거

| 결정 항목 | 결정안 | 근거 | 버린 대안 |
|---|---|---|---|
| ADR 저장 위치 | `docs/decisions/` 하나 | ADR-001과 하네스 검수 계약이 이미 이곳을 가리킨다. 진행기록·백로그와 같은 `docs/` 아래라 사람이 한 곳만 연다 | 용도별 분리. `.ai/`는 조사 기반 기술 선택, `docs/`는 운영 결정 |
| ADR 템플릿 | `docs/decisions/_TEMPLATE.md` 하나 | 저장 위치와 템플릿을 1대 1로 둔다 | `.ai/templates/adr.md` 유지 |
| `status` 집계 | `docs/decisions/`의 `*.md` 중 `_`로 시작하는 파일 제외 | 템플릿이 결정 수에 섞이지 않게 한다 | 전체 `*.md` 집계 |
| 추적 정책 | `.gitignore`에 `!docs/decisions/**` 추가 | ADR은 저장소 결정의 정본이라 `git add -f` 없이 추적한다 | 계속 강제 추가 |

용도별 분리를 버린 이유는 두 가지다. 어느 쪽에 쓸지 판단하는 규칙을 새로 만들어야 하고, 조사를 참고한 결정과 참고하지 않은 결정의 경계가 실제로는 흐리다. `.ai/templates/adr.md`에도 "관련 조사" 절이 있어 조사 링크는 한 템플릿 안에서 표현할 수 있다.

## 가정과 위험

- 조사 기반 기술 선택과 저장소 운영 결정이 한 디렉터리에 섞인다. 수가 늘면 접두사나 태그로 나눠야 할 수 있다.
- `docs/progress/`와 `docs/backlog/`는 여전히 `git add -f`가 필요하다. 추적 정책의 비대칭이 남는다.
- ADR-001은 `.ai/templates/adr.md` 구조로 작성됐다. 소급해서 바꾸지 않는다. 앞으로 쓰는 ADR만 `_TEMPLATE.md` 구조를 따른다.

## 검증

- `pwsh -NoProfile -File tests/ai-cli.tests.ps1` 출력 `PASS: 49 assertions`. 템플릿 파일을 제외하는 단언을 추가했다.
- `pwsh -NoProfile -File tools/ai/ai.ps1 status` 출력 `Decisions Total: 2`. `docs/decisions/`의 Markdown 3개 중 ADR-001과 ADR-002만 세고 `_TEMPLATE.md`는 세지 않는다. 통합 전에는 `.ai/decisions/`가 비어 있어 0이었다.
- `git check-ignore -v --no-index docs/decisions/ADR-002-adr-location.md`가 `!docs/decisions/**`에 걸린다. `docs/progress/`는 그대로 무시 대상이다.

## 만료 조건

- ADR이 늘어 운영 결정과 기술 선택을 나눠서 찾아야 할 때.
- plan 상태 스키마가 생겨 `status` 집계 규칙을 다시 정할 때.
