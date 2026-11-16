# Issue tracker: GitHub

이 레포의 이슈와 스펙은 GitHub Issues에 있다. 모든 조작은 `gh` CLI로 한다. `gh`는 현재 디렉터리의 `git remote`에서 레포를 자동 추론한다.

## 규약

- **생성**: `gh issue create --title "..." --body "..."` — 여러 줄 본문은 heredoc을 쓴다.
- **조회**: `gh issue view <번호> --comments` — 라벨·댓글을 함께 읽고, 필요하면 `jq`로 필터한다.
- **목록**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` — `--label`/`--state`로 좁힌다.
- **코멘트**: `gh issue comment <번호> --body "..."`
- **라벨**: `gh issue edit <번호> --add-label "..."` / `--remove-label "..."`
- **닫기**: `gh issue close <번호> --comment "..."`

`triage` 스킬이 작성하는 모든 이슈/코멘트는 스킬 규칙에 따라 AI 생성 면책 문구로 시작한다.

## PRs as a request surface

**no.** 외부 PR을 기능 요청으로 트리아지하지 않는다. 이 플래그를 `yes`로 바꾸면 `/triage`가 PR도 이슈와 같은 상태 머신으로 다룬다.

## 스킬이 말하는 작업의 의미

- **"publish to the issue tracker"** → GitHub 이슈를 만든다.
- **"fetch the relevant ticket"** → `gh issue view <번호> --comments`를 실행한다.
- **"PR로 리뷰/수정 요청"** → `gh pr view <번호> --comments`, `gh pr diff <번호>`.

## 번호 해석

GitHub는 이슈와 PR이 하나의 번호 공간을 공유한다. `#42`는 `gh pr view 42`를 먼저 시도하고, 실패하면 `gh issue view 42`로 해석한다.

## Wayfinding (/wayfinder)

`/wayfinder`를 쓸 때의 규약이다.

- **Map**: `wayfinder:map` 라벨을 단 이슈 하나. Notes / Decisions-so-far / Fog 본문을 담는다.
- **Child ticket**: map에 GitHub sub-issue로 연결하고 `wayfinder:<type>`(`research`/`prototype`/`grilling`/`task`) 라벨을 붙인다. 착수 시 담당자를 assign한다.
- **Blocking**: GitHub native issue dependencies(`blocked_by`)를 우선 쓴다. 미지원이면 child 본문 맨 위에 `Blocked by: #N`을 적는다.
- **Frontier query**: map의 open child 중 blocker·assignee가 없는 첫 항목이 다음 작업이다.
- **Claim**: `gh issue edit <n> --add-assignee @me` — 세션의 첫 쓰기.
- **Resolve**: 답을 코멘트 → close → map의 Decisions-so-far에 링크를 덧붙인다.
