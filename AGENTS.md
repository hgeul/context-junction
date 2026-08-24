# Context Junction 작업 지침

매 세션에서 `harness/project-context.md`, `harness/ssot-index.md`, 최신 `docs/progress/`, `docs/backlog/작업목록.md`, 작업 관련 정본 순으로 읽는다. 구현계획 원문은 저장소 밖의 `../docs/context-junction_구현계획.md`에 두며, Git에 추가하지 않는다.

작업 후 실제 결과·검증·미완료·다음 작업을 progress에 남긴다. 여러 문서·구현에 영향을 주는 중요한 선택은 ADR로 남긴다. 완료 항목은 backlog에서 제거한다. API key, password, token, 개인정보, 원본 민감 payload는 문서·로그·커밋에 기록하지 않는다.

공통 검수 계약은 `harness/reviews/`다. `$grill`, `$dod`, `$drift`, `$policy-audit`을 상황에 맞게 사용한다.
