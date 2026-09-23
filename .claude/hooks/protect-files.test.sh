#!/usr/bin/env bash
# Table test for protect-files.sh. Run: bash .claude/hooks/protect-files.test.sh
# Each row is: expected exit code, then the file_path sent to the guard.
cd "$(dirname "$0")" || exit 1
export CLAUDE_PROJECT_DIR=/repo
fail=0

check() {
  local want=$1 path=$2 got
  printf '{"tool_input":{"file_path":"%s"}}' "$path" | bash ./protect-files.sh 2>/dev/null
  got=$?
  if [ "$got" = "$want" ]; then echo "ok    $got $path"; else echo "FAIL  got $got want $want  $path"; fail=1; fi
}

check 2 /repo/.env
check 2 /repo/apps/auth-service/.env.local
check 2 /repo/.env.production
check 2 /repo/.ENV
check 2 /repo/.Env.Local
check 0 /repo/.env.example
check 0 /repo/apps/auth-service/.env.example
check 2 /repo/package-lock.json
check 2 /repo/Package-Lock.json
check 2 package-lock.json
check 2 /repo/node_modules/pkg/index.js
check 2 /repo/Node_Modules/pkg/index.js
check 2 /repo/apps/x/node_modules/y.js
check 2 /repo/node_modules/pkg/.env.example
check 2 /repo/dist/main.js
check 2 /repo/DIST/main.js
check 2 /repo/coverage/lcov.info
check 0 /repo/apps/api/src/coverage/coverage.service.ts
check 0 /repo/apps/auth-service/src/main.ts
check 0 /repo/docs/distribution.md
check 0 /repo/my.env.ts
check 0 /repo/package.json
check 0 /home/u/dist/other/file.ts

# NotebookEdit sends notebook_path instead of file_path.
printf '{"tool_input":{"notebook_path":"/repo/.env"}}' | bash ./protect-files.sh 2>/dev/null
[ $? = 2 ] && echo "ok    2 notebook_path .env" || { echo "FAIL  notebook_path .env"; fail=1; }

# Unreadable input is refused, not allowed.
printf 'not json' | bash ./protect-files.sh 2>/dev/null
[ $? = 2 ] && echo "ok    2 invalid JSON" || { echo "FAIL  invalid JSON"; fail=1; }

# Input without a path (another tool) is allowed.
printf '{"tool_input":{}}' | bash ./protect-files.sh 2>/dev/null
[ $? = 0 ] && echo "ok    0 no path" || { echo "FAIL  no path"; fail=1; }

# Without jq the guard fails closed.
printf '{"tool_input":{"file_path":"/repo/a.ts"}}' | PATH=/nonexistent /bin/bash ./protect-files.sh 2>/dev/null
[ $? = 2 ] && echo "ok    2 jq missing" || { echo "FAIL  jq missing"; fail=1; }

exit $fail
