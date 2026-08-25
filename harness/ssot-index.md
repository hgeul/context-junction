# Context Junction SSOT 인덱스

이 등록부는 새 기준을 만들지 않는다. `grill`, `dod`, `drift`, `policy-audit`가 권위 원천과 실제 산출물을 대조할 범위를 정한다.

## 진실 기준

- 내부 동작: 코드
- 외부 계약: 공식 외부 스펙
- 스키마: DB 또는 migration
- 구현계획: `docs/design/context-junction_구현계획.md`
- marker 블록: 관리 도구가 소유하며 `INFO`만 보고

## 등록부

| 도메인 | 권위 원천 | 진실 기준 | 대조 대상 | 검증 방법 |
|---|---|---|---|---|
| AI Dev Router 역할 분리 | `docs/design/context-junction_구현계획.md` | 코드와 공식 외부 스펙 | 구현, Research handoff 문서 | 관련 테스트·문서 검토 |
| AI 인수인계 프로토콜 | `.ai/README.md`, `.ai/context/project.md`, `.ai/templates/` | Git으로 추적하는 `.ai/` 기록과 템플릿 | Research request/result, 구현 계획, ADR | `.codex/scripts/test-anchors.ps1 -Strict`, PowerShell CLI 통합 테스트 |
| 운영 인수인계 | 현재 정본 | 현재 정본 | 작업목록, 진행기록, ADR | 상태·다음 작업·결정 링크 대조 |

## 문서 수명주기

| 문서 | 현재 정본 | drift 점검 | 완료 후 처리 |
|---|---|---|---|
| 프로젝트 컨텍스트·SSOT | 예 | 대상 | 현재 기준으로 갱신 |
| `docs/backlog/` | 작업 상태만 | 대상 | 완료 항목 제거 후 progress 연결 |
| `docs/progress/` | 아니오, 당시 사실 | 제외 | 시간순 보존 |
| `docs/decisions/` | 채택된 결정 | 대상 | 대체 ADR 연결·상태 변경 |

`docs/progress/`는 과거 사실의 앵커가 낡는 것이 정상이라 Tier 1 대상에서 제외한다.

## 알려진 드리프트

- 없음

## 갱신 규칙

- 새 정본·외부 Source·Schema·실험 산출물은 대조 대상과 검증 방법을 먼저 등록한다.
- 구현되지 않은 대조 대상은 `N/A`로 보고한다.
- 여러 문서·구현에 영향을 주는 해소 선택은 ADR에 기록한다.
