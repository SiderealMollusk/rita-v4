#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_host_terminal
runbook_require_cmd git
runbook_require_cmd date

SNAPSHOT_SCRIPT="$SCRIPT_DIR/35-snapshot-nextcloud-pair.sh"
PROGRESS_DIR="$REPO_ROOT/docs/progress_log"

[ -x "$SNAPSHOT_SCRIPT" ] || runbook_fail "missing executable snapshot script: $SNAPSHOT_SCRIPT"
[ -d "$PROGRESS_DIR" ] || runbook_fail "missing progress log dir: $PROGRESS_DIR"

CHECKPOINT_LABEL="${CHECKPOINT_LABEL:-floating-checkpoint}"
CHECKPOINT_SUMMARY="${CHECKPOINT_SUMMARY:-Reached stable baseline after latest validation pass.}"
CHECKPOINT_COMMANDS="${CHECKPOINT_COMMANDS:-}"
CHECKPOINT_INCLUDE_GIT_STATUS="${CHECKPOINT_INCLUDE_GIT_STATUS:-1}"

usage() {
  cat <<'EOF'
Usage:
  40-floating-checkpoint.sh [options]

Options:
  --label <slug>            Baseline label used in snapshot/doc naming
  --summary <text>          One-line baseline summary for progress note
  --commands <text>         Optional semicolon-delimited command list for note
  --no-git-status           Skip embedding git status in progress note
  --help                    Show help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --label) CHECKPOINT_LABEL="${2:-}"; shift 2 ;;
    --summary) CHECKPOINT_SUMMARY="${2:-}"; shift 2 ;;
    --commands) CHECKPOINT_COMMANDS="${2:-}"; shift 2 ;;
    --no-git-status) CHECKPOINT_INCLUDE_GIT_STATUS="0"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) runbook_fail "Unknown argument: $1" ;;
  esac
done

sanitize_token() {
  local value="$1"
  value="$(printf "%s" "$value" | tr '[:upper:]' '[:lower:]')"
  value="$(printf "%s" "$value" | tr -cs 'a-z0-9._-' '-')"
  value="${value#-}"
  value="${value%-}"
  printf "%s" "$value"
}

safe_label="$(sanitize_token "$CHECKPOINT_LABEL")"
[ -n "$safe_label" ] || safe_label="floating-checkpoint"

script_base="$(basename "$0" .sh)"
script_num="$(printf "%s" "$script_base" | sed -E 's/^([0-9]+).*/\1/')"
[ -n "$script_num" ] || script_num="0000"

timestamp_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
date_today="$(date +%Y-%m-%d)"

current_max="$(ls -1 "$PROGRESS_DIR"/*.md 2>/dev/null | xargs -n1 basename | sed -E 's/^([0-9]+).*/\1/' | sort -n | tail -n1)"
[ -n "${current_max:-}" ] || current_max=0
next_num=$((current_max + 10))
doc_num="$(printf "%04d" "$next_num")"
doc_slug="$(sanitize_token "$safe_label-baseline")"
doc_file="$PROGRESS_DIR/${doc_num}-${doc_slug}.md"

echo "[INFO] Creating checkpoint snapshot"
snapshot_output="$(
  NEXTCLOUD_SNAPSHOT_CHANGE_ID="${safe_label}" \
    "$SNAPSHOT_SCRIPT" --description "checkpoint baseline ${safe_label} (${timestamp_iso})"
)"
printf '%s\n' "$snapshot_output"

snapshot_tag="$(printf '%s\n' "$snapshot_output" | sed -n 's/^\[OK\] Snapshot complete\. tag=//p' | tail -n1)"
[ -n "$snapshot_tag" ] || runbook_fail "failed to parse snapshot tag from output"

git_sha="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || true)"
[ -n "$git_sha" ] || git_sha="unknown"

git_status_block=""
if [ "$CHECKPOINT_INCLUDE_GIT_STATUS" = "1" ]; then
  git_status_block="$(git -C "$REPO_ROOT" status --short 2>/dev/null || true)"
  [ -n "$git_status_block" ] || git_status_block="clean"
fi

commands_md=""
if [ -n "$CHECKPOINT_COMMANDS" ]; then
  IFS=';' read -r -a cmd_items <<<"$CHECKPOINT_COMMANDS"
  idx=1
  for c in "${cmd_items[@]}"; do
    c="$(printf "%s" "$c" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -n "$c" ] || continue
    commands_md="${commands_md}${idx}. \`${c}\`\n"
    idx=$((idx + 1))
  done
fi

cat > "$doc_file" <<EOF
# ${doc_num} - ${safe_label} Baseline Checkpoint

Date: ${date_today}
Generated: ${timestamp_iso}

## Summary

${CHECKPOINT_SUMMARY}

## Snapshot Baseline

1. Script lane checkpoint: \`${script_base}.sh\`
2. Snapshot tag: \`${snapshot_tag}\`
3. Git commit: \`${git_sha}\`

## Operator Commands

${commands_md:-1. (none provided)}

## Git Status At Checkpoint

\`\`\`text
${git_status_block}
\`\`\`

## Notes

1. This is an auto-generated floating checkpoint note.
2. Rename/re-number this script over time as your intentional save-point marker advances.
EOF

echo "[OK] Checkpoint progress note created: $doc_file"
echo "[OK] Floating checkpoint complete. snapshot_tag=$snapshot_tag"
