#!/usr/bin/env bash
set -euo pipefail

MANIFEST="subtrees/README.md"
DRY_RUN=0
TARGET="all"

usage() {
  echo "Usage: $0 [--dry-run|-n] [all | <subtree-name>]"
  echo ""
  echo "Options:"
  echo "  -n, --dry-run   Preview the git subtree commands without making changes"
  echo "  -h, --help      Show this help message"
}

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n)
      DRY_RUN=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $arg"
      usage
      exit 1
      ;;
    *)
      TARGET="$arg"
      ;;
  esac
done

if [[ ! -f "$MANIFEST" ]]; then
  echo "Error: Could not find $MANIFEST. Run this script from the repository root."
  exit 1
fi

if [[ "$DRY_RUN" -eq 0 && -n "$(git status --porcelain)" ]]; then
  echo "Error: Your working tree has uncommitted changes. Commit or stash them before syncing subtrees."
  exit 1
fi

FOUND=0

while IFS='|' read -r _ col_dir col_url col_ref _; do
  PREFIX=$(echo "$col_dir" | tr -d ' `')
  PREFIX="${PREFIX%/}"
  REPO_URL=$(echo "$col_url" | tr -d ' `')
  REF=$(echo "$col_ref" | tr -d ' `')

  [[ "$PREFIX" != subtrees/* ]] && continue

  SHORT_NAME="${PREFIX#subtrees/}"
  if [[ "$TARGET" != "all" && "$TARGET" != "$SHORT_NAME" && "$TARGET" != "$PREFIX" ]]; then
    continue
  fi

  FOUND=1
  echo "========================================"
  echo "Target: $PREFIX"
  echo "Source: $REPO_URL ($REF)"

  if [[ -d "$PREFIX" ]]; then
    CMD=(git subtree pull --prefix="$PREFIX" "$REPO_URL" "$REF" --squash)
    ACTION="Pulling updates"
  else
    CMD=(git subtree add --prefix="$PREFIX" "$REPO_URL" "$REF" --squash)
    ACTION="Adding new subtree"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "Mode:   [DRY RUN] $ACTION"
    echo "Would run: ${CMD[*]}"
  else
    echo "Action: $ACTION..."
    "${CMD[@]}"
    echo "Done: $PREFIX"
  fi
done < "$MANIFEST"

if [[ "$FOUND" -eq 0 ]]; then
  echo "No matching subtree found in $MANIFEST for target: '$TARGET'"
  usage
  exit 1
fi

echo "========================================"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete. No changes were made."
else
  echo "All requested subtrees are up to date!"
fi
