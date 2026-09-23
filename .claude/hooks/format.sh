#!/usr/bin/env bash
# PostToolUse formatter for Edit|Write: ESLint --fix for TS/JS, then Prettier,
# on the written file only. Prettier runs last so ESLint's fixes cannot leave
# the file failing `npm run format:check`. Formatting must never fail the
# edit, so this always exits 0; problems surface at format:check or in CI.
# No `set -u`: nvm.sh is sourced below and is not nounset-safe.

command -v jq >/dev/null 2>&1 || exit 0
file_path=$(jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then exit 0; fi

# Resolve both sides so `..` segments, symlinks and a trailing slash cannot
# send the formatters to a file outside this repository.
root=$(realpath "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null) || exit 0
file=$(realpath "$file_path" 2>/dev/null) || exit 0
case "$file" in
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

case "$file" in
  *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs)
    # ESLint 9 resolves its flat config from the working directory, so run it
    # from the nearest directory that has one (Nx keeps one per project).
    dir=$(dirname "$file")
    while [ "$dir" != "$root" ] && ! ls "$dir"/eslint.config.* >/dev/null 2>&1; do
      dir=$(dirname "$dir")
    done
    (cd "$dir" && npx --no-install eslint --fix "$file" >/dev/null 2>&1)
    ;;
esac
(cd "$root" && npx --no-install prettier --write --ignore-unknown "$file" >/dev/null 2>&1)
exit 0
