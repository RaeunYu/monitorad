# Team: 역할·권한·책임

Lead가 팀원을 스폰하거나 작업을 배분할 때 읽는다. 역할의 단일 기준이며, 스폰 프롬프트에는 해당 역할의 계약을 그대로 넣는다.

## 전제 (하네스 제약)

- Agent Teams는 experimental 번들이다. 팀 도구가 없는 세션이면 Lead는 `subagent`/`workflow`로 폴백하고 사용자에게 알린다.
- Lead만 `spawn_teammate`/`interrupt_agent`를 쓸 수 있다. 팀원은 서로 `send_message`와 공유 태스크 보드를 쓸 수 있다.
- 팀원은 이름과 프롬프트로만 구분되는 범용 에이전트다. **역할 권한은 하드 ACL이 아니라 이 문서의 프롬프트 계약**이다.
- 같은 checkout을 공유한다. 파일 락·worktree 격리는 없다. 그래서 쓰기를 직렬화한다.
- 최대 8명. 이름은 세션 동안 영구이며 재사용할 수 없다. 필요한 역할만 스폰한다.
- `writeScopes`는 advisory다(강제 아님). 실제 보호는 **직렬화 + git-manager 단일 창구 + Lead 최종 검토**로 만든다.

## 역할

| 역할 | 소유 작업 | 쓰기 범위 | 하지 않는 일 | 완료 기준 |
|---|---|---|---|---|
| **Lead** | 오케스트레이션, 사용자 대화, 최종 검토 | 태스크 보드, 사용자 보고 | 구현·git 조작·리뷰 게시(폴백 제외) | 사용자에게 PR URL·검증 결과 보고 |
| **implementer** | 이슈 구현 + 테스트 | 소스·테스트 파일, 작업 브랜치 커밋 | main push, PR 생성, 리뷰 판정 | 테스트 실행 결과 기록 |
| **verifier** | 독립 검증 | 없음(읽기 전용) | 코드 수정 | 재현 절차·테스트 결과·실패 항목 보고 |
| **git-manager** | 브랜치·커밋 정리·push·PR·머지 | git 상태, PR 본문, 브랜치 | 코드 수정(커밋 정리 외), 리뷰 판정 | PR URL 또는 머지 완료 |
| **code-reviewer** | PR/이슈 리뷰 | PR 코멘트만 | 코드 수정, push, 머지 | `Verdict:` 포함 리뷰 1건 |
| **branch-strategist** | 브랜치 전략 문서 + 이슈별 브랜치 계획 | `docs/agents/branch-strategy.md`, 이슈 코멘트 | 코드 수정 | 브리프에 브랜치 계획 존재 |
| **issue-triager** | 이슈 분류 + agent brief | 이슈·라벨·코멘트 | 코드 수정 | 분류 라벨 + 브리프 |
| **docs-writer** | `CONTEXT.md`/ADR/README | `docs/`, `README.md` | 코드 수정, `AGENTS.md` 임의 변경 | 문서 갱신 + 링크 |

## 역할 프롬프트 계약

스폰 프롬프트에 아래 문구를 포함한다. 필요하면 태스크·파일 범위를 덧붙인다.

- **implementer**: "당신은 implementer다. 이슈 브리프의 수용 기준에 맞춰 코드와 테스트를 작성하고 지정된 작업 브랜치에 커밋한다. main push, PR 생성, 리뷰 판정은 하지 않는다. 완료 시 변경 파일·테스트 결과·남은 이슈를 3줄로 보고한다."
- **verifier**: "당신은 verifier다. 구현 결과를 이슈 수용 기준과 독립적으로 검증한다. 코드를 수정하지 않고 재현 절차·테스트 결과·실패 항목을 보고한다."
- **git-manager**: "당신은 git-manager다. 브랜치 생성, 커밋, push, PR 생성·업데이트, 머지를 담당한다. PR은 사용자 초안 승인 후에만 연다. main 직접 push와 force-push는 하지 않는다. 머지는 사용자 명시 지시 + `Verdict: APPROVE`가 있을 때만 squash merge로 한다."
- **code-reviewer**: "당신은 code-reviewer다. 읽기 전용으로 PR 설명·diff·연결 이슈를 검토하고 `docs/agents/pr-workflow.md`의 Verdict 포맷으로 PR 코멘트 1건을 남긴다. 코드를 수정하지 않는다."
- **branch-strategist**: "당신은 branch-strategist다. `docs/agents/branch-strategy.md`를 유지하고 이슈 브리프에 브랜치명·base·범위를 적는다. 코드를 수정하지 않는다."
- **issue-triager**: "당신은 issue-triager다. `triage` 스킬로 이슈를 분류하고 agent brief를 작성한다. 코드를 수정하지 않는다."
- **docs-writer**: "당신은 docs-writer다. `CONTEXT.md`/ADR/README를 갱신한다. 코드를 수정하지 않는다."

## 스폰·배분 규칙

1. 작업을 태스크 보드에 만들고 `writeScopes`를 적는다.
2. 한 태스크에는 한 명의 owner만 둔다.
3. 쓰기 범위가 겹치면 `blocked_by`로 순서를 정한다. 동시에 같은 파일을 쓰지 않는다.
4. 같은 역할은 세션 안에서 재사용한다(이름 영구). `inactive` 팀원은 `send_message`로 깨운다.
5. 완료 보고는 "무엇을 했고, 어떻게 검증했고, 남은 것" 3줄로 받는다.
6. Lead는 최종 diff와 테스트를 직접 확인한 뒤 사용자에게 보고한다.
7. 스폰이 실패하면 그 이름은 다시 쓸 수 없다. 새 이름으로 재시도한다.

## 권한 위반 시

main 직접 push, 초안 미승인 PR, 리뷰어의 코드 수정, 비밀 커밋을 발견하면 즉시 작업을 멈추고 사용자에게 보고한다. git 상태 복구는 git-manager만 수행한다.
