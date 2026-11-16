# Triage Labels

`triage` 스킬이 쓰는 5개 정규 라벨의 실제 문자열이다. 이 레포는 기본값을 그대로 쓴다.

| 역할 | 실제 라벨 | 의미 |
|---|---|---|
| needs-triage | `needs-triage` | 관리자가 평가해야 함 |
| needs-info | `needs-info` | 보고자 답변 대기 |
| ready-for-agent | `ready-for-agent` | 명세 완료, 에이전트가 작업 가능 |
| ready-for-human | `ready-for-human` | 사람이 직접 구현·판단해야 함 |
| wontfix | `wontfix` | 처리하지 않음 |

- 라벨이 없으면 `needs-triage`로 시작한다. `needs-info`는 보고자가 답하면 `needs-triage`로 되돌린다.
- 전이는 관리자(사용자)가 언제든 덮어쓸 수 있다. 이상해 보이는 전이는 진행 전에 확인한다.

## PR에서의 의미 (triage 스킬 정의)

- `ready-for-agent`: diff에 대한 다음 단계(수정·보완·리뷰)를 에이전트가 수행한다.
- `ready-for-human`: 머지 준비 완료. 사람이 머지한다.

## 에이전트 리뷰 전용 라벨

- `skip-agent-review`: 이 PR은 `code-reviewer` 리뷰를 생략한다. (트리거 규칙: `docs/agents/pr-workflow.md`)
