# AI 작업공간

Git으로 추적하는 이 작업공간은 특정 Agent에 종속되지 않으며, 외부 지식과 저장소 구현 작업을 분리한다. `.ai/`에는 secret, 자격 증명, 개인정보, 원본 민감 payload를 두지 않는다. 로컬에서만 필요한 자료는 Git이 무시하는 `.ai/local/`에 둔다.

## 인수인계 순서

1. 저장소를 확인하고, Research Request에는 필요한 최소 맥락만 적는다.
2. 로컬 근거로 답할 수 없는 질문이 구현을 막을 때만 외부 조사를 요청한다.
3. 응답은 출처와 조사일을 붙여 같은 ID의 Research Result로 저장한다.
4. 저장소를 다시 확인한 뒤, 조사 결과와 실제 프로젝트 상태를 합쳐 Implementation Plan을 만든다.
5. 구현하고 테스트한 뒤, 오래 유지될 선택은 `docs/decisions/`에 ADR로 남긴다. 템플릿은 `docs/decisions/_TEMPLATE.md`다.

조사 결과는 구현 지시가 아니다. 구현 세부의 진실 기준은 저장소 상태다.

## 실행 방법

저장소 루트에서 v0.1 PowerShell CLI를 쓴다.

```powershell
pwsh -NoProfile -File tools/ai/ai.ps1 status
pwsh -NoProfile -File tools/ai/ai.ps1 research new "<주제>"
pwsh -NoProfile -File tools/ai/ai.ps1 research list
pwsh -NoProfile -File tools/ai/ai.ps1 research copy [RES-YYYYMMDD-NNN]
```

요청과 대응하는 결과는 같은 `RES-YYYYMMDD-NNN` ID를 쓴다. 대응하는 결과가 없는 요청은 `WAITING`, 있는 요청은 `DONE`이다. v0.1에서 plan에는 상태 스키마가 없어 전체 개수만 센다.

`status`는 저장소 이름, 브랜치, 대기·완료 조사 수, plan과 decision 총 개수를 출력하고, 대기 중인 요청이 있으면 가장 최근 것을 함께 출력한다. 대기와 완료는 요청·결과 파일명이 짝을 이루는지로만 판단한다. plan은 `.ai/plans/`, ADR은 `docs/decisions/`에서 세며, 상태를 해석하지 않고 Markdown 파일 개수로만 센다. `_`로 시작하는 템플릿 파일은 세지 않는다.

`research copy`는 지정한 `RES-YYYYMMDD-NNN` ID의 요청 원문을 그대로 복사한다. ID를 생략하면 가장 최근 `WAITING` 요청을 복사한다. 지정한 ID의 형식이 틀렸거나 대응하는 요청이 없을 때, ID를 생략했는데 대기 중인 요청이 없을 때, 시스템 클립보드를 쓸 수 없을 때는 실패한다.

전역 `ai` alias는 선택이며 사용자가 직접 관리한다. 저장소는 `tools/ai/ai.ps1`만 제공한다.
