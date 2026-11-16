# Branch Strategy

`branch-strategist`가 유지하는 문서다. 브랜치를 만들거나 PR을 열기 전에 읽는다. 변경은 PR로만 한다.

## 모델: 트렁크 기반

- `main`은 항상 배포 가능한 단일 trunk다. `develop`/`release` 상시 브랜치는 두지 않는다.
- 모든 작업은 `main`에서 만든 수명 짧은 작업 브랜치에서 한다.
- 머지는 squash 1커밋. 머지 후 브랜치를 삭제한다.

## 브랜치 네이밍

`{type}/{이슈번호}-{kebab-slug}`

| type | 용도 | 예 |
|---|---|---|
| feat | 기능 | `feat/12-agent-team-policy` |
| fix | 버그 | `fix/34-review-comment-dup` |
| chore | 설정·잡일 | `chore/5-setup-ci` |
| docs | 문서 | `docs/7-context-md` |
| refactor | 리팩터링 | `refactor/21-review-flow` |
| test | 테스트 보강 | `test/18-review-parser` |

- 이슈가 없는 chore/docs는 `{type}/{slug}`를 허용한다. 코드 PR은 이슈 번호가 필수다.
- 한 이슈에 PR이 여러 개 필요하면 `{type}/{이슈번호}-{slug}-{part}`를 쓴다.

## 이슈별 브랜치 계획

`issue-triager`가 `ready-for-agent` 브리프를 쓸 때 아래 블록을 포함한다.

```markdown
**Branch plan**
- branch: `feat/12-agent-team-policy`
- base: `main`
- scope: `docs/agents/**`, `AGENTS.md`
- 머지 기준: 문서 변경이라 테스트 불필요, 리뷰 APPROVE
```

`branch-strategist`는 이 계획이 전략과 맞는지 확인하고, 어긋나면 브리프를 고친다.

## 커밋

- Conventional Commits: `<type>(<scope>): <한국어 설명>`. 예: `feat(review): PR 리뷰 게이트 추가`
- 커밋은 논리 단위로 나누고, WIP 커밋은 PR 전에 정리한다.
- 커밋 메시지에는 변경 이유를 적는다.

## PR과 머지

- PR 제목도 Conventional Commits 형식을 따른다.
- base는 `main`. PR 전 `main` 최신화는 `git-manager`가 rebase 또는 merge로 처리한다.
- 머지: squash. `main` 직접 push·force-push·브랜치 강제 삭제는 금지한다.
- PR 크기: 400 changed lines/20 files 이하 권장. 넘으면 분할을 검토한다.

## 직렬화

- checkout·브랜치 전환은 `git-manager`만 한다. 다른 역할은 checkout하지 않는다.
- 동시에 하나의 쓰기 작업만 한다. 병렬이 필요하면 사용자와 상의해 worktree 도입을 결정한다.
