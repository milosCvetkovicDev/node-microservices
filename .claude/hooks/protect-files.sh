#!/usr/bin/env bash
# PreToolUse guard for Edit|Write (the matcher also reaches MultiEdit and
# NotebookEdit). Claude Code passes the tool call as JSON on stdin; only exit 2
# blocks the call (exit 1 is a non-blocking error), so every refusal exits 2.
# Anything the guard cannot read is refused rather than allowed.
#
# Protected: .env and .env.* except .env.example, package-lock.json, any
# node_modules/ directory, and the build outputs dist/ and coverage/ at the
# repo root. Matching is case-insensitive because APFS and NTFS are.
# Tests: .claude/hooks/protect-files.test.sh
set -o pipefail

block() {
  echo "BLOCK: $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || block 'jq is not installed, so the protected-file guard cannot read the path'

input=$(cat)
file_path=$(printf '%s' "$input" | jq -er '.tool_input.file_path // .tool_input.notebook_path // ""') ||
  block 'the tool input is not valid JSON'
[ -z "$file_path" ] && exit 0

# Compare paths relative to the project so a checkout that itself sits under a
# directory named dist or coverage is not blocked wholesale.
root=${CLAUDE_PROJECT_DIR:-$PWD}
root=${root%/}
rel=${file_path#"$root"/}
lower=$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')

case "/$lower" in
  */node_modules/*) block "$file_path is inside node_modules/" ;;
esac
case "$lower" in
  dist/* | coverage/*) block "$file_path is a build output under dist/ or coverage/" ;;
esac

name=$(basename -- "$lower")
case "$name" in
  .env.example) exit 0 ;;
  .env | .env.*) block "$file_path is an env file; only .env.example may be edited" ;;
  package-lock.json) block "$file_path is generated; change dependencies with npm instead" ;;
esac

exit 0
