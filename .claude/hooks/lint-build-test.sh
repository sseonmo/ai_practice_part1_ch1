#!/usr/bin/env bash
#
# Stop 훅 스크립트: Claude가 작업을 마칠 때 lint → build → test 를 순서대로 돌린다.
# (git pre-commit 훅과 비슷한 "마무리 검증" 역할)
#
# 동작 규칙:
#   - package.json 이 없으면 검사할 게 없으므로 통과(exit 0).
#   - package.json 에 해당 npm 스크립트가 없으면 그 단계만 건너뛴다.
#   - 하나라도 실패하면 exit 2 로 끝낸다.
#       → Stop 훅에서 exit 2 는 stderr 내용을 Claude에게 전달하고 멈추지 못하게 한다.
#         (즉 "검증 실패했으니 고쳐라"라는 신호)

set -uo pipefail

# Claude Code가 넣어주는 프로젝트 루트 경로로 이동(없으면 현재 위치)
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# 빌드 시스템이 없으면 조용히 통과
if [ ! -f package.json ]; then
  echo "[hook] package.json 없음 → lint/build/test 건너뜀" >&2
  exit 0
fi

# package.json 의 scripts 에 해당 이름이 있는지 확인
has_script() {
  node -e "process.exit(require('./package.json').scripts?.['$1'] ? 0 : 1)" 2>/dev/null
}

# 스크립트가 있으면 실행하고, 실패하면 1을 반환
run_step() {
  local name="$1"
  if ! has_script "$name"; then
    echo "[hook] '$name' 스크립트 없음 → 건너뜀" >&2
    return 0
  fi
  echo "[hook] ▶ npm run $name" >&2
  if ! npm run "$name" --silent; then
    echo "[hook] ❌ '$name' 실패" >&2
    return 1
  fi
  echo "[hook] ✅ '$name' 통과" >&2
  return 0
}

fail=0
run_step lint  || fail=1
run_step build || fail=1
run_step test  || fail=1

if [ "$fail" -ne 0 ]; then
  echo "[hook] 🚨 검증 실패 — 위 오류를 수정한 뒤 다시 마무리하세요." >&2
  exit 2
fi

echo "[hook] 🎉 lint/build/test 모두 통과" >&2
exit 0
