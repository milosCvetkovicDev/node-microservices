#!/usr/bin/env bash
# PreToolUse guard for Edit|Write. Claude Code passes the tool call as JSON on
# stdin; only exit 2 blocks the call (exit 1 is a non-blocking error), so every
# refusal below exits 2. Without jq the path cannot be read, so fail closed.
set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo 'BLOCK: jq is not installed, so the protected-file guard cannot read the path' >&2
  exit 2
fi

file_path=$(jq -r '.tool_input.file_path // empty')
[ -z "$file_path" ] && exit 0

name=$(basename "$file_path")
case "$name" in
  .env.example) exit 0 ;;
  .env | .env.*)
    echo "BLOCK: $file_path is an env file; only .env.example may be edited" >&2
    exit 2
    ;;
  package-lock.json)
    echo "BLOCK: $file_path is generated; change dependencies with npm instead" >&2
    exit 2
    ;;
esac

case "/$file_path" in
  */node_modules/* | */dist/* | */coverage/*)
    echo "BLOCK: $file_path is inside node_modules/, dist/ or coverage/" >&2
    exit 2
    ;;
esac

exit 0
