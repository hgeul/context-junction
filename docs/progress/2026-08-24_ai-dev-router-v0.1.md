# 2026-08-24 AI Dev Router v0.1 프로토콜

> 상태: 완료
> 관련 작업: CJ-002 구현계획 기반 첫 기능 분해
> 관련 결정: ADR-001

## 목표

특정 Agent에 종속되지 않는 `.ai/` 작업공간과 외부 조사 인수인계 규칙으로, CLI 자동화에 앞서 v0.1 프로토콜을 세운다.

## 배경 및 사유

저장소 맥락과 최신 외부 지식은 진실 기준이 다르다. 이 프로토콜은 외부 질문을 조사하는 데 필요한 최소 맥락만 기록하게 하고, 구현 계획을 세우기 전에 저장소를 다시 확인하도록 강제한다.

## 진행 내용

- Git으로 추적하는 `.ai/`에 컨텍스트, 요청·결과, plan, decision, 템플릿 위치를 만들었다.
- `AGENTS.md`와 `CLAUDE.md`에 같은 외부 지식 정책 문구를 넣었다.
- 인수인계 프로토콜과 앞으로의 CLI 검증 대상을 SSOT 인덱스에 등록했다.
- v0.1 PowerShell CLI에 status와 research copy 명령을 추가했다. 조사 상태는 파일에서 도출하고, plan과 ADR은 총 개수만 센다.
- 격리된 통합 테스트를 추가했다. 테스트가 실제 클립보드를 건드리지 않도록 in-process `Set-Clipboard` shim을 함께 넣었다.

## 결정

조사는 요청·결과 ID가 짝을 이루는지로만 `WAITING` 또는 `DONE`이 된다. plan은 상태 스키마를 검증하기 전까지 총 개수만 센다. 이 선택은 ADR-001에 기록했다.

## 결과 및 검증

- 기준선: 프로토콜 기록이 생기기 전 `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` 통과 (`anchors_checked=0 drift=0`).
- status, copy, 실패 경로 커버리지를 추가한 뒤 `pwsh -NoProfile -File tests/ai-cli.tests.ps1`이 30개 단언으로 통과했다.
- 완성된 CLI의 저장소 smoke 검사와 anchor 검사는 `pwsh -NoProfile -File tools/ai/ai.ps1 status`, `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict`다.
- 프로토콜 최종 검토(2026-08-25): `pwsh -NoProfile -File tests/ai-cli.tests.ps1` 출력 `PASS: 30 assertions`, `pwsh -NoProfile -File .codex/scripts/test-anchors.ps1 -Strict` 출력 `anchors_checked=0 drift=0`, `git diff --check` 출력 없음. 하네스 검수 결과 `AGENTS.md`와 `CLAUDE.md`의 외부 지식 정책 본문이 동일했고, `.ai/templates/`에 민감정보 패턴이 없었으며, AI 인수인계 권위 원천을 `harness/ssot-index.md`에 등록했다.
- 계약 수정 최종 검토(2026-08-25): 주제 형식, 대체 slug, 요청·결과 디렉터리 생성, 요청 전용 ID 할당, 간결한 파일시스템·클립보드 실패까지 CLI 통합 커버리지를 48개 단언으로 늘렸다. CLI 테스트, 저장소 status smoke, strict anchor 검사, `git diff --check`가 모두 통과했다.

## 미완료 및 위험

- 전역 `ai` alias는 선택이며 사용자가 직접 관리한다. 저장소는 `tools/ai/ai.ps1`만 제공한다.
- 템플릿의 사용성과 최소 맥락 규칙은 API·MCP·자동화로 넓히기 전에 실제 Research Handoff 5~10건으로 dogfooding 해야 한다.
- 이번 기능 범위에서 ignore 규칙에 추가된 것은 `.ai/local/`뿐이다. `.worktrees/` 규칙은 그 전부터 있었다.

## 다음 작업

실제 v0.1 Research Handoff를 5~10건 돌린 뒤, 자동화를 더 붙일 이유가 있는지 판단한다.

## 관련 문서

- `.ai/README.md`
- `docs/decisions/ADR-001-ai-workspace-status.md`
