# GitHub Settings: ruleset·라벨 스냅샷

`AGENTS.md`가 말하는 "무엇이 실제로 강제되는가"를 검증하는 단일 기준이다. GitHub UI 상태에 의존하면 설정이 문서와 어긋나므로(drift), 현재 값을 이 파일에 스냅샷하고 재현 명령을 함께 둔다. 설정이 바뀌면 같은 PR에서 이 문서를 갱신한다.

스냅샷 기준: **2026-11-16**, 레포 `RaeunYu/monitorad`.

## main ruleset

- 이름: `main protection`
- ID: `27353999` (`target: branch`)
- 대상: `~DEFAULT_BRANCH` → `main`
- `enforcement: active`, bypass actor 없음(`current_user_can_bypass: never`)
- classic branch protection은 쓰지 않는다(`gh api .../branches/main/protection` → 404). 보호는 ruleset 하나로만 건다.

### 실제 rules (API 스냅샷)

```json
{
  "id": 27353999,
  "name": "main protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "require_extra_approval_for_unattributed_changes": true,
        "required_reviewers": [],
        "allowed_merge_methods": ["squash"]
      }
    },
    { "type": "non_fast_forward" },
    { "type": "deletion" }
  ],
  "bypass_actors": [],
  "current_user_can_bypass": "never"
}
```

### ruleset이 실제로 강제하는 것

| ruleset 규칙 | 설정 값 | 실제 효과 |
|---|---|---|
| `pull_request` | approvals `0`, `allowed_merge_methods: ["squash"]` | `main` 직접 push 불가, PR 경유 필수, **머지는 squash만** 허용. 단 리뷰 승인 0건이라 "승인 필수"는 아니다 |
| `non_fast_forward` | — | **`main`에서** force-push 차단 |
| `deletion` | — | `main` 삭제 차단 |

`pull_request`의 `require_extra_approval_for_unattributed_changes: true`는 값만 기록해 둔다. Phase 1 커밋은 사용자 계정에 귀속되므로 이 파라미터의 추가 승인 요구는 발생하지 않고, `required_approving_review_count: 0`이라 일반 리뷰 승인 요구도 없다. Phase 1은 단일 사용자 계정이라 승인 수를 올려도 자기 PR approve가 불가능하므로 0으로 둔다.

## ruleset 강제 vs 정책 전용

역할 분리·리뷰 1건 같은 워크플로 규칙은 ruleset이 아니라 **프롬프트 계약 + 태스크 보드 소유권 + Lead 최종 검토**로 지킨다.

| 규칙 | 강제 수단 | ruleset 강제? |
|---|---|---|
| `main` PR 필수 | ruleset `pull_request` | **예** |
| 머지 방식 squash 전용 | ruleset `allowed_merge_methods` | **예** |
| `main` force-push·삭제 차단 | ruleset `non_fast_forward`/`deletion` | **예** |
| force-push 전면 금지(작업 브랜치 포함) | 프롬프트 계약(`git-manager`) | 아니오 — ruleset은 `main`만 차단 |
| 역할 분리·권한(누가 무엇을 쓰는가) | 프롬프트 계약 + `writeScopes` + Lead 최종 검토 | 아니오 |
| 구현/문서 커밋은 작업 소유자, push·머지는 `git-manager` | 프롬프트 계약 | 아니오(같은 계정·같은 토큰) |
| 리뷰 코멘트 1건·Verdict 포맷·심각도 기준 | `code-reviewer` 계약 | 아니오 |
| 라벨 게이트(`ready-for-agent`, `skip-agent-review`) | 워크플로 규칙 | 아니오 |
| PR 크기 400줄/20파일 | 리뷰 권고(문서 전용 예외) | 아니오 |
| 리뷰 승인 필수 | Phase 1에서는 정책 전용(Verdict 코멘트가 승인 기록) | 아니오 |

## 레포 머지 설정 (참고)

```bash
gh api repos/RaeunYu/monitorad --jq '{default_branch,allow_merge_commit,allow_rebase_merge,allow_squash_merge,delete_branch_on_merge}'
# {"default_branch":"main","allow_merge_commit":true,"allow_rebase_merge":true,"allow_squash_merge":true,"delete_branch_on_merge":false}
```

- 레포 설정은 merge/rebase/squash를 모두 허용하지만, ruleset이 `squash`만 허용하므로 **실효 머지 방식은 squash**다.
- `delete_branch_on_merge: false` → 머지 후 브랜치 삭제는 `git-manager`가 수행한다.

## 라벨

`gh label list --limit 100` 기준. 워크플로가 의존하는 라벨만 적는다.

| 라벨 | 용도 |
|---|---|
| `needs-triage`·`needs-info`·`ready-for-agent`·`ready-for-human`·`wontfix` | triage 5종 정규 라벨 (`docs/agents/triage-labels.md`) |
| `skip-agent-review` | `code-reviewer` 리뷰 생략 (`docs/agents/pr-workflow.md`) |

GitHub 기본 라벨(`bug`, `documentation`, `enhancement` 등)도 남아 있지만 에이전트 워크플로는 의존하지 않는다.

## 재현·점검 명령

```bash
# ruleset 목록·ID·enforcement
gh api repos/RaeunYu/monitorad/rulesets --jq '.[] | {id,name,target,enforcement}'

# ruleset 상세(전체 JSON)
gh api repos/RaeunYu/monitorad/rulesets/27353999

# 요약(rules 배열)
gh api repos/RaeunYu/monitorad/rulesets/27353999 --jq '{id,name,enforcement,rules}'

# 라벨
gh label list --limit 100

# classic branch protection 사용 여부(404 = 미사용)
gh api repos/RaeunYu/monitorad/branches/main/protection
```

## 변경 절차

- ruleset·라벨 변경은 사용자 승인 후 `git-manager`(또는 사용자)가 `gh api`로 적용하고, **같은 PR에서 이 문서를 갱신**한다.
- GitHub UI에서 직접 바꿨다면 이 문서를 스냅샷에 맞추는 후속 PR을 낸다.
- Phase 2에서 CI 상태 체크를 붙이면 `pull_request` ruleset에 required status check를 추가하고 위 표를 갱신한다.
