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

| 조건 | 동작 |
|---|---|
| PR이 ready_for_review로 전환 | `code-reviewer` 리뷰 1회 |
| `skip-agent-review` 라벨 | 리뷰 생략 |
| 세션 시작 시 `ready-for-agent` 라벨 PR 발견 | `code-reviewer` 리뷰 1회 |
| `REQUEST_CHANGES` 후 수정 커밋 push | 재리뷰 1회 |
| 사용자 요청 | 리뷰 1회 |

- push마다 자동 재리뷰하지 않는다.
- 리뷰는 PR당 코멘트 1건을 유지한다. 재리뷰 시 기존 코멘트를 갱신하거나 새 코멘트 1건만 남긴다.
- **이슈 리뷰(코드 변경 없음)**: 사용자가 이슈에 `ready-for-agent` 라벨을 붙이거나 코멘트로 태그하면, 다음 세션 시작 시 Lead가 스캔해 `code-reviewer`에게 넘긴다.

## 3. 리뷰 기준과 포맷

- 2축 리뷰: **Spec**(연결 이슈의 수용 기준 충족?) + **Standards**(`AGENTS.md`·`docs/agents/` 규칙 준수?). `code-review` 스킬을 사용한다.
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

- 인라인 코멘트는 Critical/Major만, 최대 10개. Minor 이하와 칭찬은 접기.
- Critical/Major가 남아 있으면 `REQUEST_CHANGES`, 아니면 `APPROVE`.
- GitHub은 자기 PR에 공식 approve를 허용하지 않는다. **Verdict 코멘트가 리뷰 승인 기록**이고, 공식 승인·머지는 사용자가 직접 한다. 사용자가 지시하면 `git-manager`가 머지한다.

## 4. 머지

- 전제: 사용자의 명시적 머지 지시 + 최신 커밋 기준 `Verdict: APPROVE`.
- `git-manager`가 `gh pr merge <번호> --squash --delete-branch`를 실행하고 `main`을 pull 한다.
- 사용자가 GitHub UI에서 직접 머지하는 것도 허용된다.
- 완료: `main`에 squash 커밋 1개, 원격 브랜치 삭제.

## 5. 예외와 실패 처리

- 리뷰어가 없거나 팀 도구를 쓸 수 없으면 Lead가 `subagent`로 `code-reviewer` 계약을 실행한다.
- 리뷰 중 사용자가 중단을 요청하면 Verdict 없이 머지하지 않는다.
- PR이 400줄/20파일을 넘으면 리뷰어가 분할을 권고하고, 분할 여부는 사용자가 결정한다.
- **Phase 2(예정)**: GitHub Actions + `dsh --profile headless`로 `pull_request` 이벤트 자동 리뷰. 라벨·크기 게이트는 워크플로 `if:`로 구현한다. Codex 보조 리뷰는 보류 중이며, 도입 시 보조 리뷰로만 쓴다.
