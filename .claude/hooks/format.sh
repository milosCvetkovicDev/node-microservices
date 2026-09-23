#!/usr/bin/env bash
# PostToolUse formatter for Edit|Write: Prettier on the written file, then
# ESLint --fix for TS/JS. Formatting must never fail the edit, so it always
# exits 0; a formatting problem surfaces at `npm run format` or in CI instead.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
file_path=$(jq -r '.tool_input.file_path // empty')
[ -z "$file_path" ] || [ ! -f "$file_path" ] && exit 0

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
case "$file_path" in
  "$root"/*) ;;
  *) exit 0 ;;
esac

# Non-interactive shells do not have nvm's node on PATH.
if ! command -v npx >/dev/null 2>&1; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
fi
command -v npx >/dev/null 2>&1 || exit 0

cd "$root" || exit 0
npx --no-install prettier --write --ignore-unknown "$file_path" >/dev/null 2>&1
case "$file_path" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs)
    npx --no-install eslint --fix "$file_path" >/dev/null 2>&1
    ;;
esac
exit 0
