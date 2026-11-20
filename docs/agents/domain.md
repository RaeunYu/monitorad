# Domain Docs

도메인을 탐색하기 전에 읽는 소비 규칙이다.

## 먼저 읽을 것

- **`docs/product/brief.md`**: 제품 목적·범위·로드맵.
- 루트 **`CONTEXT.md`**, 또는 루트에 **`CONTEXT-MAP.md`**가 있으면 그 파일이 가리키는 context별 `CONTEXT.md` 중 작업과 관련된 것.
- **`docs/adr/`**: 작업 영역에 닿는 ADR.

이미 있는 파일은 읽고, 없으면 조용히 넘어간다. 없음을 지적하거나 먼저 만들자고 제안하지 않는다. 새 용어·결정은 `/domain-modeling`(← `/grill-with-docs`, `/improve-codebase-architecture`)으로 추가하고 해당 파일을 갱신한다.

## 레이아웃: 단일 컨텍스트

이 레포는 모노레포 신호가 없어 단일 컨텍스트다.

```
/
├── CONTEXT.md
├── docs/
│   ├── adr/
│   │   ├── 0001-....md
│   │   └── 0002-....md
│   └── product/
│       └── brief.md
└── src/
```

멀티 컨텍스트로 바뀌면 루트 `CONTEXT-MAP.md` + `src/<context>/CONTEXT.md` + `src/<context>/docs/adr/` 구조로 전환한다.

## 어휘 사용

- 출력(이슈 제목·리팩터 제안·가설·테스트 이름)에 도메인 개념을 쓸 때 `CONTEXT.md`에 정의된 용어를 그대로 쓴다. 글로서리가 피하는 동의어로 바꾸지 않는다.
- 필요한 개념이 글로서리에 없으면 신호다: 프로젝트가 쓰지 않는 언어를 만든 건지 재고하고, 실제 공백이면 `/domain-modeling`에 넘긴다.

## ADR 충돌 표시

ADR과 모순되는 출력은 조용히 덮지 말고 명시한다.

> _ADR-0007(event-sourced orders)과 모순되지만, … 때문에 재검토할 가치가 있음._

## 프로젝트 목적

제품 목적·범위는 `docs/product/brief.md`, 도메인 용어는 `CONTEXT.md`, 주요 결정은 `docs/adr/`에 있다. 새 용어·결정은 `/domain-modeling`(← `/grill-with-docs`)으로 추가하고 해당 파일을 갱신한다.
