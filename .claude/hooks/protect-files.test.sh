#!/usr/bin/env bash
# Table test for protect-files.sh. Run: bash .claude/hooks/protect-files.test.sh
# Each row is: expected exit code, then the file_path sent to the guard. The
# guard resolves the project directory, so the table runs against a real
# temporary one ($R); none of the files need to exist.
guard="$(cd "$(dirname "$0")" && pwd)/protect-files.sh"
R=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$R"' EXIT
mkdir -p "$R/apps/foo"
export CLAUDE_PROJECT_DIR=$R
fail=0

run() { # run <expected> <label> <json>
  printf '%s' "$3" | (cd "${4:-$R}" && bash "$guard") 2>/dev/null
  local got=$?
  if [ "$got" = "$1" ]; then echo "ok    $got $2"; else echo "FAIL  got $got want $1  $2"; fail=1; fi
}
check() { run "$1" "$2" "{\"tool_input\":{\"file_path\":\"$2\"}}" "$3"; }

check 2 "$R/.env"
check 2 "$R/apps/auth-service/.env.local"
check 2 "$R/.env.production"
check 2 "$R/.ENV"
check 2 "$R/.Env.Local"
check 0 "$R/.env.example"
check 0 "$R/apps/auth-service/.env.example"
check 2 "$R/package-lock.json"
check 2 "$R/Package-Lock.json"
check 2 "$R/node_modules/pkg/index.js"
check 2 "$R/Node_Modules/pkg/index.js"
check 2 "$R/apps/x/node_modules/y.js"
check 2 "$R/node_modules/pkg/.env.example"
check 2 "$R/dist/main.js"
check 2 "$R/DIST/main.js"
check 2 "$R/coverage/lcov.info"
check 0 "$R/apps/api/src/coverage/coverage.service.ts"
check 0 "$R/apps/auth-service/src/main.ts"
check 0 "$R/docs/distribution.md"
check 0 "$R/my.env.ts"
check 0 "$R/package.json"
check 0 /home/u/dist/other/file.ts

# The root itself in another case, or through a symlink, is still the root.
check 2 "$(printf '%s' "$R" | tr '[:lower:]' '[:upper:]')/dist/a.js"
ln -s "$R" "$R.link" && check 2 "$R.link/coverage/a" && rm "$R.link"

# Non-canonical forms are refused outright.
check 2 "$R/./dist/a.js"
check 2 "$R//coverage/a"
check 2 "$R/apps/../dist/a.js"

# Relative paths resolve against the working directory, not the root.
check 2 package-lock.json
check 2 dist/a.js
check 0 dist/a.js "$R/apps/foo"

# NotebookEdit sends notebook_path instead of file_path.
run 2 'notebook_path .env' "{\"tool_input\":{\"notebook_path\":\"$R/.env\"}}"
# Unreadable input is refused, not allowed; input without a path is allowed.
run 2 'invalid JSON' 'not json'
run 0 'no path' '{"tool_input":{}}'

# Without jq the guard fails closed.
printf '{"tool_input":{"file_path":"/r/a.ts"}}' | PATH=/nonexistent /bin/bash "$guard" 2>/dev/null
[ $? = 2 ] && echo "ok    2 jq missing" || { echo "FAIL  jq missing"; fail=1; }

exit $fail
