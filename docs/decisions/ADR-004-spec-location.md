# ADR: 구현계획 원문을 저장소 안 `docs/design/`으로 옮긴다

> date: `2026-08-25` | status: 채택
> related progress: `docs/progress/2026-08-25_구현계획-저장소-편입.md`

## 맥락

CJ-001에서 구현계획 원문을 저장소 밖 `../docs/`에 두고 Git에서 제외하기로 했다. ADR-003에서 `docs/` 추적 정책을 바꿀 때도 이 부분은 유지했다.

그 배치에 문제가 하나 있다. `harness/project-context.md`는 권위 순서 1위를, `harness/ssot-index.md`는 "AI Dev Router 역할 분리"의 권위 원천을 `../docs/context-junction_구현계획.md`로 지정한다. 이 경로는 이 PC의 폴더 배치에서만 유효하다. 저장소를 clone하면 최상위 권위 문서가 존재하지 않아, 새로 합류한 사람이나 Agent는 SSOT가 가리키는 문서를 읽을 수 없다. 권위 원천이 저장소 밖에 있으면 SSOT 등록부가 검증 불가능한 경로를 가리키게 된다.

ADR-003으로 `docs/`가 기본 추적으로 바뀌면서, 저장소 안에 두되 공개 여부만 판단하면 되는 상태가 됐다. 이 저장소는 공개이므로 편입은 곧 공개다.

공개 적합성을 문서 전문을 읽어 확인했다. 구현계획 1,657줄과 실행계획 339줄 모두 설계 내용만 담고 있다. 예시는 Spring Security, PostgreSQL, Kafka 같은 일반 기술이고 고객사명, 사내 시스템명, 프로젝트 코드명, 자격 증명, 개인정보, URL, 이메일, 로컬 절대경로가 없다. `password`, `secret`, `token`이 등장하는 곳은 모두 "기록하지 말라"는 정책 문구다.

## 결정과 근거

| 결정 항목 | 결정안 | 근거 | 버린 대안 |
|---|---|---|---|
| 구현계획 원문 위치 | `docs/design/context-junction_구현계획.md` | SSOT가 가리키는 권위 원천이 clone 안에서 해결돼야 한다 | 저장소 밖 유지 |
| v0.1 실행계획 | 같은 `docs/design/`에 편입 | 구현계획과 짝이며 공개 부적합 내용이 없다 | `docs/local/`로 보내기 |
| SDD 작업 산출물 17개 | `docs/local/sdd/`로 이동 | 세션 부스러기라 정본이 아니다. 추적하면 소음이 된다 | 저장소에 추적, 또는 삭제 |
| 저장소 밖 `docs/` 폴더 | 제거 | 남은 파일이 없다 | 빈 폴더 유지 |

## 가정과 위험

- 구현계획이 공개된다. 앞으로 이 문서에 비공개 정보를 적으면 안 된다. 그런 내용은 `docs/local/`에 둔다.
- ADR-003의 "구현계획 원문은 저장소 밖 유지" 행을 이 ADR이 대체한다. ADR-003의 나머지 결정은 유효하다.
- `docs/design/ai-dev-router-v0.1-execution-plan.md`는 완료된 계획이며 본문의 경로 서술은 작성 당시 배치를 가리킨다. 본문을 고치지 않고 머리말에 주석만 달았다.

## 검증

- `harness/project-context.md`, `harness/ssot-index.md`, `AGENTS.md`, `README.md`의 경로를 `docs/design/`으로 갱신했다. `git grep '\.\./docs'` 결과 완료된 실행계획 본문의 과거 서술만 남는다.
- `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` 출력 `anchors_checked=0 drift=0`.
- `pwsh -NoProfile -File tests/ai-cli.tests.ps1` 출력 `PASS: 49 assertions`.
- `git check-ignore -v --no-index docs/local/sdd/x.md`가 `docs/local/`에 걸린다.

## 만료 조건

- 구현계획에 공개 부적합 내용을 넣어야 할 때. 그때는 해당 부분을 `docs/local/`로 분리한다.
- 저장소가 비공개로 바뀌어 공개 판단이 불필요해질 때.
