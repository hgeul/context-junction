# drift 계약

기존 진실 원천의 모순만 찾는다. 새 기준을 만들거나 자동 수정하지 않는다. 먼저 `harness/ssot-index.md`를 읽는다.

1. Tier 1 앵커: Markdown의 `File.ext:line`이 실제 파일·범위에 해석되는지 검사한다.
2. Tier 2 주장 모순: 권위 문서와 코드·외부 스펙·DB 양쪽 근거가 있을 때만 `DRIFT(contradiction)`으로 보고한다.
3. Tier 3 신선도: ADR 만료 조건, 오래된 다음 작업, 완료 항목이 남은 작업목록, 오래된 정책을 점검한다.

내부 동작은 코드, 외부 계약은 외부 스펙, 스키마는 DB/migration이 진실이다. marker 블록은 관리 도구 소유이므로 `INFO`만 보고한다.
