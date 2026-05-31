# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 성격

코딩 **학습/연습용** 프로젝트다 (`ai_lecture/practice/part1_ch1`). 완성도보다 **개념을 또렷하게 보여주는 것**이 우선이다. 코드는 짧게 유지하고, 각 핵심 개념에 학습용 주석을 단다. 빌드 도구·프레임워크·패키지 매니저를 도입하지 않는다.

## 애플리케이션

`index.html` — "오늘 뭐 먹지?" 랜덤 식단 룰렛. **순수 HTML/CSS/JS 단일 파일** (빌드·의존성 없음).

### 실행
```bash
open index.html   # 브라우저로 바로 열어 확인 (서버 불필요)
```

### 구조 (`index.html` 한 파일 안에서)
- `<style>` — 룰렛/필터/결과/히스토리 스타일
- `<body>` — 룰렛 `<canvas>` + 결과 텍스트 + 돌리기 버튼 + 필터 영역 + 히스토리 목록
- `<script>` — ① `ALL_MENUS` 데이터 → ② `buildFilters()` → ③ `drawWheel()` → ④ `spin()` → ⑤ 히스토리 함수 순서로 읽도록 구성

### 핵심 동작 메커니즘 (수정 시 주의)
- **룰렛 좌표계**: `drawWheel()`은 칸을 `-Math.PI/2`(12시 방향)부터 그린다. `spin()`의 `winnerCenter = winnerIdx*arcDeg + arcDeg/2` 도 같은 **12시 기준 시계방향** 각도다. 두 좌표계는 일치해야 한다. 각도 계산을 건드릴 때 이 정합성을 반드시 유지할 것.
- **회전 = 결과 보장**: `(360 - winnerCenter)`만큼 회전시켜 당첨 칸을 포인터(▼, 12시) 아래로 보낸다. "화면에 멈춘 칸 = 표시되는 결과"가 이 앱의 핵심 불변식이다.
- **CSS transition 애니메이션**: 회전은 `transform: rotate()` + `transition`으로 구현한다. 애니메이션 시간(`4s`)과 결과 확정 타이밍이 연동되어야 한다.
- **선택 카테고리**: `selectedCats`(`Set`)로 관리하며 여러 카테고리 동시 선택을 지원한다. 최소 1개는 유지된다(전부 해제 방지).

## Claude Code 확장 (`.claude/`)

이 프로젝트는 Claude Code 확장 기능 자체를 **학습 소재로** 포함한다. 세 가지가 서로 연동된다.

- `.claude/skills/code-review/SKILL.md` — 코드 리뷰 기준(정확성·보안·가독성·구조·성능 5축)과 보고 형식을 정의하는 스킬.
- `.claude/agents/code-reviewer.md` — 위 `code-review` 스킬을 호출해 리뷰를 수행하는 읽기 전용 서브에이전트.
- `.claude/settings.json` + `.claude/hooks/lint-build-test.sh` — **Stop 훅**. 작업 종료 시 `npm run lint/build/test`를 순서대로 실행한다. `package.json`이 없으면(현재 상태) 안전하게 건너뛴다(exit 0). 단계 실패 시 exit 2로 차단한다.

> 주의: `.claude/`의 스킬·에이전트·훅을 새로 만들거나 수정하면 **Claude Code 세션을 재시작해야 등록·적용**된다. 같은 세션에서 즉시 검증하려면, 에이전트에게 `SKILL.md` 파일을 직접 읽혀 그 기준으로 동작하게 한다.

## bkit (`.bkit/`)

bkit 플러그인의 런타임·상태·감사 로그 저장소다. 직접 편집하지 않는다 (플러그인이 관리).

## 작업 원칙

- 기능을 추가할 때도 **학습 가치**를 우선한다. 과한 추상화·라이브러리 도입을 피하고, 새 개념에는 주석으로 *왜* 그런지 설명한다.
- LLM 코드 리뷰 결과는 false positive가 있을 수 있으므로, 채택 전 **줄 번호 근거로 직접 교차검증**한다.
- **외부로 나가거나 되돌리기 어려운 작업은 실행 전에 반드시 사용자 확인을 받는다.** `git push`·PR 생성·머지·force-push 등이 해당한다. 한번 원격에 올라간 내용은 삭제해도 캐싱·인덱싱될 수 있다. `git init`·`commit` 같은 로컬 작업은 확인 없이 진행해도 되지만, **원격에 발행하는 단계에서는 멈추고 물어본다.** 무엇을 포함/제외할지(예: `.gitignore` 대상)도 임의 판단하지 말고 확인한다.
