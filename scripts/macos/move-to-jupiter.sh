#!/usr/bin/env bash
set -euo pipefail

JUPITER_HOST="${JUPITER_HOST:-jupiter}"
TRASH_ROOT="${HOME}/.Trash/jupiter-moved-$(date +%Y%m%d-%H%M%S)"

mode="dry-run"
only=""

usage() {
  cat <<'USAGE'
Move large, safe-to-archive Mac folders to Jupiter.

Default mode is a dry run. Nothing is copied or removed unless you choose a mode.

Usage:
  scripts/macos/move-to-jupiter.sh [--dry-run|--copy|--move] [--only TASK]

Modes:
  --dry-run   Show what would be transferred. This is the default.
  --copy      Copy to Jupiter with rsync. Keep local files in place.
  --move      Copy to Jupiter, then move safe local sources to ~/.Trash.

Options:
  --only TASK Run one task. Use --list to see task names.
  --list      Show configured tasks and exit.
  -h, --help  Show this help.

Environment:
  JUPITER_HOST Override SSH host. Default: jupiter

Notes:
  - Archive-only tasks are copied but never removed by --move.
  - Photos Library and Spotlight metadata are intentionally not included.
  - Use Ableton "Collect All and Save" on projects before relying on archives.
USAGE
}

# Format:
# task_name|local_source|remote_destination|cleanup_policy|description
# cleanup_policy:
#   safe       --move may move local source to Trash after a successful rsync
#   contents   --move may move the contents of local_source to Trash, not the folder
#   archive    never remove locally; copy-only archive
TASKS=(
  "ableton-projects|${HOME}/Music/Ableton/Projects|/home/lewisflude/Music/projects/from-mac-ableton-projects|safe|Ableton project archive"
  "ableton-bounced|${HOME}/Music/Ableton/Bounced|/home/lewisflude/Music/recordings/from-mac-bounced|safe|Ableton bounced audio"
  "roughstructure-project|${HOME}/Music/RoughStructure Project|/home/lewisflude/Music/projects/from-mac-ableton-projects/RoughStructure_Project|safe|Standalone Ableton project"
  "justwanted-project|${HOME}/Music/Ableton/JustWantedToGetAlong Project|/home/lewisflude/Music/projects/from-mac-ableton-projects/JustWantedToGetAlong_Project|safe|Standalone Ableton project"
  "nicotine-downloads|${HOME}/.local/share/nicotine/downloads|/mnt/storage/torrents/music-production/nicotine-from-mac|safe|Nicotine downloads"
  "icloud-downloads|${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Downloads|/mnt/storage/from-mac/macbook/icloud-downloads|contents|iCloud Drive Downloads contents"
  "icloud-document-backups|${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Documents/Backups|/mnt/storage/from-mac/macbook/icloud-documents-backups|safe|iCloud Drive document backups"
  "lightroom-originals|${HOME}/Pictures/Lightroom Library.lrlibrary/9f77c25a53aa4806b7dd5825df9f74a2/originals|/mnt/storage/from-mac/macbook/lightroom-originals|archive|Lightroom originals archive copy"
  "music-app-media|${HOME}/Music/Music/Media.localized/Music|/mnt/storage/media/music/from-mac-music-app|archive|Apple Music media archive copy"
)

if [[ "${EUID}" -eq 0 ]]; then
  cat >&2 <<'EOF'
ERROR: do not run this script with sudo.

It needs your normal SSH config and known_hosts entry for jupiter, and sudo may
create root-owned files or move sources into root-managed locations.

Run it as your normal user instead:
  scripts/macos/move-to-jupiter.sh --move
EOF
  exit 1
fi

remote_quote() {
  printf "'%s'" "$(printf "%s" "$1" | sed "s/'/'\\\\''/g")"
}

list_tasks() {
  printf "%-24s  %-8s  %s\n" "TASK" "CLEANUP" "DESTINATION"
  printf "%-24s  %-8s  %s\n" "----" "-------" "-----------"
  for task in "${TASKS[@]}"; do
    IFS='|' read -r name src dest cleanup desc <<<"$task"
    printf "%-24s  %-8s  %s\n" "$name" "$cleanup" "${JUPITER_HOST}:${dest}"
  done
}

log() {
  printf "\n==> %s\n" "$*"
}

warn() {
  printf "WARN: %s\n" "$*" >&2
}

die() {
  printf "ERROR: %s\n" "$*" >&2
  exit 1
}

has_task() {
  local wanted="$1"
  local task name src dest cleanup desc
  for task in "${TASKS[@]}"; do
    IFS='|' read -r name src dest cleanup desc <<<"$task"
    [[ "$name" == "$wanted" ]] && return 0
  done
  return 1
}

cleanup_source() {
  local src="$1"
  local cleanup="$2"
  local name="$3"
  local trash_dest="${TRASH_ROOT}/${name}"

  case "$cleanup" in
    safe)
      mkdir -p "$TRASH_ROOT"
      mv "$src" "$trash_dest"
      printf "Moved local source to Trash staging: %s\n" "$trash_dest"
      ;;
    contents)
      mkdir -p "$trash_dest"
      shopt -s dotglob nullglob
      local entries=("$src"/*)
      shopt -u dotglob nullglob
      if ((${#entries[@]} == 0)); then
        printf "No local contents left to move for %s\n" "$src"
      else
        mv "${entries[@]}" "$trash_dest/"
        printf "Moved local contents to Trash staging: %s\n" "$trash_dest"
      fi
      ;;
    archive)
      printf "Archive-only task; keeping local source in place: %s\n" "$src"
      ;;
    *)
      die "unknown cleanup policy '${cleanup}' for ${name}"
      ;;
  esac
}

run_task() {
  local name="$1"
  local src="$2"
  local dest="$3"
  local cleanup="$4"
  local desc="$5"

  if [[ ! -e "$src" ]]; then
    warn "Skipping ${name}; source does not exist: ${src}"
    return 0
  fi

  log "${name}: ${desc}"
  printf "Source:      %s\n" "$src"
  printf "Destination: %s:%s\n" "$JUPITER_HOST" "$dest"
  printf "Policy:      %s\n" "$cleanup"

  ssh "$JUPITER_HOST" "mkdir -p $(remote_quote "$dest")"

  local rsync_args=(-a --partial --human-readable --info=progress2,stats1 --timeout=120)
  if [[ "$mode" == "dry-run" ]]; then
    rsync_args+=(--dry-run)
  fi

  # Trailing slashes copy the contents into the destination directory.
  rsync "${rsync_args[@]}" "${src}/" "${JUPITER_HOST}:${dest}/"

  if [[ "$mode" == "move" ]]; then
    cleanup_source "$src" "$cleanup" "$name"
  fi
}

while (($#)); do
  case "$1" in
    --dry-run)
      mode="dry-run"
      ;;
    --copy)
      mode="copy"
      ;;
    --move)
      mode="move"
      ;;
    --only)
      shift
      [[ $# -gt 0 ]] || die "--only requires a task name"
      only="$1"
      ;;
    --list)
      list_tasks
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

if [[ -n "$only" ]] && ! has_task "$only"; then
  list_tasks >&2
  die "unknown task for --only: ${only}"
fi

if [[ "$mode" == "move" ]]; then
  cat <<EOF
Running in --move mode.

After each successful transfer, safe local sources will be moved to:
  ${TRASH_ROOT}

This does not immediately free disk space until Trash is emptied.
Archive-only tasks will not be removed locally.
EOF
fi

ssh -o BatchMode=yes -o ConnectTimeout=10 "$JUPITER_HOST" "true" \
  || die "cannot connect to ${JUPITER_HOST} with SSH"

for task in "${TASKS[@]}"; do
  IFS='|' read -r name src dest cleanup desc <<<"$task"
  if [[ -n "$only" && "$name" != "$only" ]]; then
    continue
  fi
  run_task "$name" "$src" "$dest" "$cleanup" "$desc"
done

log "Done"
case "$mode" in
  dry-run)
    printf "Dry run only. Re-run with --copy to transfer, or --move to transfer and stage safe local sources in Trash.\n"
    ;;
  copy)
    printf "Copied files to Jupiter. Local files were left in place.\n"
    ;;
  move)
    printf "Transferred files and staged safe local sources in Trash. Check Jupiter before emptying Trash.\n"
    ;;
esac
