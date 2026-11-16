# PR Workflow

PR을 열거나, 리뷰하거나, 머지할 때 읽는다. PR 절차의 단일 기준이다.

## 1. 초안 승인 (PR 생성 전)

1. `git-manager`가 `.github/pull_request_template.md` 형식으로 초안(제목·본문·변경 파일·테스트 계획·리스크)을 만든다.
2. Lead가 초안을 사용자에게 그대로 보여주고 명시적 승인을 요청한다.
3. 사용자가 "진행/열어/승인"으로 답하면 `git-manager`가 push + `gh pr create`를 실행한다.

완료: PR URL 확보.

- "좋아 보인다" 같은 모호한 반응은 승인으로 보지 않고 한 번 더 확인한다.
- 승인 전에는 push하지 않는다. 로컬 커밋은 가능하다.
- 수정 요청이 오면 초안을 고쳐 다시 승인받는다.

## 2. 리뷰 트리거

Phase 1에는 PR 오픈 웹훅이 없고 draft PR도 쓰지 않으므로, 리뷰는 아래 이벤트에서 시작한다.

| 조건 | 동작 |
|---|---|
| PR 생성 직후(초안 승인 후) | Lead가 `code-reviewer`를 스폰해 리뷰 1회 |
| 세션 시작 시 `ready-for-agent` 라벨 PR 발견 | `code-reviewer` 리뷰 1회 |
| 사용자 요청 | 리뷰 1회 |
| `REQUEST_CHANGES` 후 수정 커밋 | 재리뷰 1회 |
| `skip-agent-review` 라벨 | 리뷰 생략 |
| Phase 2: PR `ready_for_review` 전환 이벤트·웹훅 | Actions 자동 리뷰(예정) |

- push마다 자동 재리뷰하지 않는다.
- 리뷰는 PR당 **요약 코멘트 1건**을 유지한다. 재리뷰는 기존 코멘트를 수정(PATCH)하거나 같은 스레드에 코멘트 1건만 추가한다.
- **이슈 리뷰(코드 변경 없음)**: 사용자가 이슈에 `ready-for-agent` 라벨을 붙이거나 코멘트로 태그하면, 다음 세션 시작 시 Lead가 스캔해 `code-reviewer`에게 넘긴다.

## 3. 리뷰 기준과 포맷

- 2축 리뷰: **Spec**(연결 이슈의 수용 기준 충족?) + **Standards**(`AGENTS.md`·`docs/agents/` 규칙 준수?). `code-review` 스킬을 사용한다.
- `code-review` 스킬은 두 축을 병렬 서브에이전트로 수행한다. 하위 서브에이전트 스폰이 불가한 세션(Phase 1 팀원, delegation depth 0)이면 두 축을 인라인으로 수행한다.
- **심각도 기준**: Critical = 보안·데이터 손실·머지 반드시 차단. Major = 정책/정합성 위반으로 워크플로·동작이 왜곡됨. Minor = 개선·문구·문서화. Critical/Major가 남아 있으면 `REQUEST_CHANGES`.
- 결과는 PR 코멘트 1건:

```markdown
Verdict: APPROVE | REQUEST_CHANGES

## 요약
(한 단락)

| 심각도 | 위치 | 내용 |
|---|---|---|
| Critical | ... | ... |
| Major | ... | ... |

<details><summary>Minor</summary>

- ...

</details>
```

- 인라인 리뷰는 Phase 2(정식 리뷰 API·이벤트)에서 도입한다. Phase 1은 요약 코멘트 1건에 Critical/Major만 표로 남기고 Minor 이하·칭찬은 접기로 넣는다.
- Critical/Major가 남아 있으면 `REQUEST_CHANGES`, 아니면 `APPROVE`.
- 자기 PR에 대한 공식 GitHub approve는 불가능하다. **Verdict 코멘트가 승인 기록**이고, 최종 승인·머지 결정은 사용자가 한다. 사용자가 지시하면 `git-manager`가 머지한다.

## 4. 머지

- 전제: 사용자의 명시적 머지 지시 + 최신 커밋 기준 `Verdict: APPROVE`.
- `git-manager`가 `gh pr merge <번호> --squash --delete-branch`를 실행하고 `main`을 pull 한다.
- 사용자의 GitHub UI 직접 머지는 사용자 권한이며 에이전트 게이트(지시+APPROVE) 밖이다(허용).
- 완료: `main`에 squash 커밋 1개, 원격 브랜치 삭제.

## 5. 예외와 실패 처리

- 리뷰어가 없거나 팀 도구를 쓸 수 없으면 Lead가 `subagent`로 `code-reviewer` 계약을 실행한다.
- 리뷰 중 사용자가 중단을 요청하면 Verdict 없이 머지하지 않는다.
- PR이 400줄/20파일을 넘으면 리뷰어가 분할을 권고하고, 분할 여부는 사용자가 결정한다. 문서 전용 변경은 400줄을 넘어도 분할 의무가 없다(권고).
- **Phase 2(예정)**: GitHub Actions + `dsh --profile headless`로 `pull_request` 이벤트 자동 리뷰. 라벨·크기 게이트는 워크플로 `if:`로 구현하며, 크기 게이트는 자동 리뷰를 스킵·연기하는 기준이지 머지 차단이 아니다. Codex 보조 리뷰는 보류 중이며, 도입 시 보조 리뷰로만 쓴다.
