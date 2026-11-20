# AGENTS.md — monitorad 개발 워크플로 정책

> 이 파일은 이 레포에서 작업하는 모든 에이전트(Lead·팀원·서브에이전트)가 따르는 최상위 정책이다.
> 제품 목적·범위는 `docs/product/brief.md`, 도메인 용어는 `CONTEXT.md`, 주요 결정은 `docs/adr/`에 있다. 이 문서는 **개발 진행 방식**만 다룬다.
> 이 문서가 모든 세션에 자동 로드되므로, 상세 규칙은 아래 "문서 지도"의 파일로 밀어 두고 여기에는 트리거와 핵심만 둔다.

## 핵심 원칙

- **PR-only**: 모든 코드 변경은 PR로만 `main`에 반영한다. 브랜치 생성·push·PR·머지는 `git-manager`가 하고, 구현 커밋은 implementer/docs-writer가 작업 브랜치에 남긴다. `git-manager`가 이력을 정리해 push한다.
- **1 PR = 1 이슈**: 코드 PR은 이슈에 연결한다(`Closes #N`). chore/docs 변경은 이슈 없이 진행할 수 있다.
- **초안 승인 후 PR**: PR을 열기 전에 `git-manager`가 초안(제목·본문·변경 요약·테스트 계획)을 만들고, Lead가 사용자에게 제시해 **명시적 승인**을 받는다. 승인 전에는 push하지 않는다.
- **리뷰 1건**: `code-reviewer`는 PR당 요약 리뷰 코멘트 1건을 유지한다(재리뷰는 기존 코멘트 수정 또는 같은 스레드에 1건만 추가). push마다 재리뷰하지 않고, Verdict + 심각도 표로 남긴다.
- **직렬화**: 한 번에 하나의 쓰기 작업만 진행한다. checkout·브랜치 전환·push·머지 등 git 상태 변경은 `git-manager`만 하고, 작업 소유자는 자기 작업 브랜치에 커밋만 한다.
- **사용자 게이트**: 에이전트의 머지는 사용자의 명시적 지시와 최신 커밋 기준 `Verdict: APPROVE`가 모두 있을 때만 가능하다. 사용자의 GitHub UI 직접 머지는 사용자 권한이며 에이전트 게이트 밖이다(허용).

## 팀

Lead는 오케스트레이터이며 팀원을 스폰하고 사용자와 대화한다. 역할 책임·권한·스폰 규칙의 단일 기준은 `docs/agents/team.md`다.

| 역할 | 한 줄 책임 |
|---|---|
| implementer | 이슈 구현 + 테스트 작성, 작업 브랜치 커밋 |
| verifier | 구현과 분리된 독립 검증 |
| git-manager | 브랜치·커밋 이력 정리·push·PR·머지 |
| code-reviewer | 읽기 전용 PR/이슈 리뷰, Verdict 게시 |
| branch-strategist | 브랜치 전략 문서 + 이슈별 브랜치 계획 |
| issue-triager | 이슈 분류 + agent brief 작성 |
| docs-writer | `CONTEXT.md`/ADR/README 등 문서, 작업 브랜치 커밋 |

역할 분리는 하네스 ACL이 아니라 **프롬프트 계약 + 태스크 보드 소유권 + Lead 최종 검토**로 강제하고, GitHub ruleset은 `main` 보호(PR 필수·force-push 금지·삭제 금지·squash 전용)만 강제한다(`docs/agents/github-settings.md`). 필요한 역할만 스폰하며(최대 8명), 이름은 세션 동안 유지된다. 실패한 스폰의 이름은 다시 쓸 수 없으므로 새 이름으로 재시도한다. 같은 역할의 기존 팀원은 `send_message`로 재사용한다.

## 세션 시작

개발 작업 세션을 시작할 때:

1. `list_agents`로 Agent Teams 도구 가용성을 확인한다. 없으면 `subagent`/`workflow` 폴백을 사용자에게 알린다.
2. `gh pr list --state open`으로 `ready-for-agent` 라벨 PR과 리뷰 대기 PR을 확인한다.
3. `gh issue list --label ready-for-agent`로 리뷰·구현 대기 이슈를 확인한다.

완료: 사용자에게 "확인한 PR/이슈 목록"을 한 줄로 보고한다.

## 표준 개발 흐름

1. **이슈 준비** — `issue-triager`가 `triage` 스킬로 분류하고, 필요 시 agent brief를 쓴다. 완료: 이슈 번호와 수용 기준이 정해졌다.
2. **브랜치 계획** — `issue-triager`가 이슈 브리프에 브랜치명·base·범위 **초안**을 적고, `branch-strategist`가 `docs/agents/branch-strategy.md` 규칙과 맞는지 확인·수정한다. 완료: 브리프에 확정된 브랜치 계획이 있다.
3. **구현·검증** — `implementer`가 작업 브랜치에서 구현+테스트하고, `verifier`가 독립 검증한다. 완료: 테스트 실행 결과가 기록되었다.
4. **PR 초안 승인** — `git-manager`가 초안을 쓰고 Lead가 사용자에게 제시한다. 완료: 사용자의 명시적 승인("진행/열어/승인")을 받았다.
5. **PR 생성** — `git-manager`가 push 후 `gh pr create`로 PR을 연다. 완료: PR URL이 생겼다.
6. **리뷰** — PR 생성 직후 Lead가 `code-reviewer`를 스폰해 1회 리뷰한다(`skip-agent-review` 라벨이면 생략). REQUEST_CHANGES면 작업 소유자가 수정하고 1회 재리뷰한다. 완료: `Verdict: APPROVE`.
7. **머지** — 사용자가 "머지해"라고 지시하고 APPROVE가 유효하면 `git-manager`가 squash merge 후 브랜치를 삭제한다. 사용자가 GitHub UI에서 직접 머지해도 된다. 완료: `main`에 반영되었다.

코드 변경이 없는 이슈 리뷰는 사용자가 이슈에 `ready-for-agent` 라벨을 붙이거나 코멘트로 태그하면, 다음 세션 시작 시 Lead가 스캔해 `code-reviewer`에게 넘긴다.

## 하드 가드레일

- force-push는 모든 브랜치에서 금지. `main` 직접 push, 브랜치 강제 삭제 금지. 브랜치 삭제는 `git-manager`가 머지 후에만 한다. `main` 최신화는 merge를 쓴다.
- 초안 승인 전 PR 생성 금지. 승인 없는 머지 금지.
- 비밀·토큰·`.env` 커밋 금지.
- `code-reviewer`는 코드를 수정하지 않는다(읽기 전용). `implementer`는 자기 PR을 리뷰하지 않는다.
- 한 PR에 여러 이슈를 섞지 않는다(chore/docs 예외).

## 문서 지도

작업 종류에 맞는 파일을 먼저 읽는다.

- **제품 목적·범위·로드맵** → `docs/product/brief.md`
- **도메인 용어(글로서리)** → `CONTEXT.md`
- **Tahoe HUD 실행가능성 조사 근거** → `docs/research/tahoe-hud-feasibility.md`
- **이슈 생성·조회·라벨·코멘트** → `docs/agents/issue-tracker.md`
- **트리아지 상태·라벨 문자열, PR에서의 의미** → `docs/agents/triage-labels.md`
- **도메인 용어·ADR 소비 규칙** → `docs/agents/domain.md`
- **팀 구성·역할·권한·스폰 규칙** → `docs/agents/team.md`
- **PR 초안 승인·리뷰 트리거/포맷·머지 절차** → `docs/agents/pr-workflow.md`
- **브랜치 모델·네이밍·커밋·머지 방식** → `docs/agents/branch-strategy.md`
- **DoD·테스트·CI·PR 크기** → `docs/agents/quality.md`
- **GitHub ruleset 실제 설정·라벨·재현 명령** → `docs/agents/github-settings.md`

## Agent skills

### Issue tracker

GitHub Issues(`gh` CLI)를 쓴다. PRs as a request surface는 **no**. See `docs/agents/issue-tracker.md`.

### Triage labels

5개 정규 라벨(`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`)을 기본 문자열로 쓴다. See `docs/agents/triage-labels.md`.

### Domain docs

단일 컨텍스트다. 루트 `CONTEXT.md` + `docs/adr/`를 소비하고, 파일은 필요할 때 스킬이 지연 생성한다. See `docs/agents/domain.md`.

## 단계와 예고

- **Phase 1(현재)**: 로컬 DSH 팀 + 사용자 GitHub 계정으로 리뷰 코멘트 게시. 자기 PR 공식 approve는 불가능하므로 Verdict 코멘트가 승인 기록이고, 최종 승인·머지 결정은 사용자가 한다.
- **Phase 2(스택·CI 확정 후)**: GitHub Actions + `dsh --profile headless`로 PR 리뷰를 자동화하고, main ruleset에 상태 체크를 추가한다. Codex 보조 리뷰는 보류 중이며, 도입 시 보조 리뷰로만 쓴다.
- 이 하네스에는 PR 오픈 웹훅이 없다. "자동" 트리거는 세션 시작 스캔 또는 Phase 2 Actions로 구현한다.
