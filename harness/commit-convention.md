# 커밋 메시지 규약

Conventional Commits 형식을 쓴다.

```text
<type>(<scope>): <설명>
```

- `scope`은 선택이다. 범위가 명확할 때만 쓴다.
- `scope`은 기술명·도구명·Agent 정체성이 아니라 변경 기능의 도메인을 쓴다. `ai`, `app`, `common`, `misc`처럼 범위를 설명하지 못하는 값은 쓰지 않는다.
- Research Request/Result, Handoff Protocol, 관련 CLI 변경의 scope은 `research-handoff`를 쓴다. 다른 기능은 그 기능의 사용자·도메인 경계를 나타내는 scope을 선택한다.
- 설명은 한글로 쓴다. 제품·도구 이름, 코드 식별자, 파일 경로, CLI 명령은 영어 원문을 유지한다.
- AI 도구 언급, `Co-Authored-By`, 이모지는 쓰지 않는다.

허용 type: `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `chore`.
