{
  pkgs,
  pog,
}:
pog.pog {
  name = "mercury-migrate";
  version = "1.0.0";
  description = "Backup and restore Mercury (macOS) for clean machine migration";

  arguments = [
    {
      name = "command";
      description = "Command to run: audit, backup, verify, restore";
      default = "help";
    }
  ];

  argumentCompletion = ''printf "%s\n" audit backup verify restore'';

  flags = [
    {
      name = "dry_run";
      short = "d";
      bool = true;
      description = "Show what would be done without making changes";
    }
    {
      name = "backup_dir";
      short = "b";
      description = "Backup directory path (default: /Volumes/Samsung/mercury-backup-YYYYMMDD)";
    }
  ];

  runtimeInputs = [
    pkgs.coreutils
    pkgs.rsync
    pkgs.git
    pkgs.gum
    pkgs.gnugrep
  ];

  script =
    helpers: with helpers; ''
      CMD="''${1:-help}"
      TODAY=$(date +%Y%m%d)
      # shellcheck disable=SC2154
      BACKUP="''${backup_dir:-/Volumes/Samsung/mercury-backup-$TODAY}"
      NIX_CONFIG_DIR="$HOME/.config/nix"

      run_cmd() {
        if ${flag "dry_run"}; then
          debug "DRY RUN: $*"
        else
          "$@"
        fi
      }

      # ── Phase 1: Audit ──────────────────────────────────────────────
      do_audit() {
        blue "Phase 1: Pre-Backup Audit"

        cyan "Large directories:"
        du -sh ~/Documents ~/Music ~/Pictures ~/Desktop ~/Downloads ~/Movies 2>/dev/null || true

        echo ""
        cyan "Ableton projects & samples:"
        du -sh ~/Music/Ableton ~/Library/Application\ Support/Ableton 2>/dev/null || true

        cyan "Scanning for .als files outside ~/Music/Ableton..."
        STRAY_ALS=$(find ~ -name "*.als" -not -path "*/Library/Caches/*" -not -path "*/Music/Ableton/*" -maxdepth 5 2>/dev/null | head -20 || true)
        if [ -n "$STRAY_ALS" ]; then
          yellow "Found Ableton projects outside ~/Music/Ableton:"
          echo "$STRAY_ALS"
        else
          green "No stray .als files found"
        fi

        echo ""
        cyan "Dirty git repos:"
        for search_dir in ~/Code ~/Projects ~/Developer ~/src; do
          [ -d "$search_dir" ] || continue
          find "$search_dir" -name ".git" -maxdepth 3 2>/dev/null | while read -r d; do
            repo=$(dirname "$d")
            if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
              yellow "DIRTY: $repo"
            fi
          done
        done

        echo ""
        cyan "SOPS key:"
        if [ -f ~/Library/Application\ Support/sops-nix/key.txt ]; then
          green "Found: ~/Library/Application Support/sops-nix/key.txt"
          ls -la ~/Library/Application\ Support/sops-nix/key.txt
        else
          red "NOT FOUND — check sops-nix key location"
        fi

        echo ""
        cyan "SSH keys:"
        ls -la ~/.ssh/ 2>/dev/null || yellow "No ~/.ssh directory"

        echo ""
        cyan "GPG keys:"
        ls -la ~/.gnupg/ 2>/dev/null || yellow "No ~/.gnupg directory"

        echo ""
        cyan "Nix config git status:"
        git -C "$NIX_CONFIG_DIR" status --short
        git -C "$NIX_CONFIG_DIR" log --oneline -3

        echo ""
        cyan "Documents listing:"
        ls -la ~/Documents/ 2>/dev/null || true

        echo ""
        green "Audit complete. Review the output above before proceeding to backup."
      }

      # ── Phase 2: Backup ─────────────────────────────────────────────
      do_backup() {
        blue "Phase 2: Backup to $BACKUP"

        if ! ${flag "dry_run"}; then
          if [ ! -d "$(dirname "$BACKUP")" ]; then
            die "Parent directory $(dirname "$BACKUP") does not exist. Is the SSD mounted?"
          fi
          mkdir -p "$BACKUP"
        fi

        # Critical — Irreplaceable
        cyan "Backing up critical files..."

        cyan "  SSH keys"
        run_cmd rsync -av ~/.ssh/ "$BACKUP/ssh/"

        cyan "  GPG config"
        run_cmd rsync -av ~/.gnupg/ "$BACKUP/gnupg/"

        cyan "  SOPS key"
        if [ -f ~/Library/Application\ Support/sops-nix/key.txt ]; then
          run_cmd cp ~/Library/Application\ Support/sops-nix/key.txt "$BACKUP/sops-key.txt"
        else
          yellow "  SOPS key not found, skipping"
        fi

        cyan "  Obsidian vault"
        if [ -d ~/Documents/Obsidian\ Vault ]; then
          run_cmd rsync -av ~/Documents/Obsidian\ Vault/ "$BACKUP/obsidian-vault/"
        else
          yellow "  Obsidian vault not found, skipping"
        fi

        cyan "  Nix config (ensuring pushed)"
        if ! ${flag "dry_run"}; then
          if [ -n "$(git -C "$NIX_CONFIG_DIR" status --porcelain 2>/dev/null)" ]; then
            yellow "  Nix config has uncommitted changes — push manually before wiping!"
          else
            green "  Nix config is clean"
          fi
        fi

        # User Data
        echo ""
        cyan "Backing up user data..."

        cyan "  Documents (excluding Obsidian)"
        run_cmd rsync -av --exclude='Obsidian Vault' ~/Documents/ "$BACKUP/Documents/"

        cyan "  Pictures"
        run_cmd rsync -av ~/Pictures/ "$BACKUP/Pictures/"

        cyan "  Desktop"
        run_cmd rsync -av ~/Desktop/ "$BACKUP/Desktop/"

        cyan "  Downloads"
        run_cmd rsync -av ~/Downloads/ "$BACKUP/Downloads/"

        cyan "  Movies"
        run_cmd rsync -av ~/Movies/ "$BACKUP/Movies/" 2>/dev/null || true

        # Ableton / Music
        echo ""
        cyan "Backing up music production..."

        if [ -d ~/Music/Ableton ]; then
          cyan "  Ableton projects"
          run_cmd rsync -av ~/Music/Ableton/ "$BACKUP/Ableton/"
        fi

        if [ -d ~/Library/Application\ Support/Ableton ]; then
          cyan "  Ableton application support"
          run_cmd rsync -av ~/Library/Application\ Support/Ableton/ "$BACKUP/Ableton-AppSupport/"
        fi

        cyan "  Stray Ableton projects in home directory"
        find ~ -maxdepth 1 -type d -not -path "$HOME" -not -name ".*" 2>/dev/null | while read -r dir; do
          if find "$dir" -maxdepth 2 -name "*.als" 2>/dev/null | grep -q .; then
            proj_name=$(basename "$dir")
            cyan "    Found: $dir"
            run_cmd mkdir -p "$BACKUP/stray-projects/"
            run_cmd rsync -av "$dir/" "$BACKUP/stray-projects/$proj_name/"
          fi
        done

        cyan "  Other music (excluding Ableton)"
        run_cmd rsync -av --exclude='Ableton' ~/Music/ "$BACKUP/Music/" 2>/dev/null || true

        # Nice to Have
        echo ""
        cyan "Backing up extras..."

        cyan "  Atuin history"
        run_cmd rsync -av ~/.local/share/atuin/ "$BACKUP/atuin/" 2>/dev/null || true

        cyan "  ZSH history"
        [ -f ~/.zsh_history ] && run_cmd cp ~/.zsh_history "$BACKUP/zsh_history"

        cyan "  MCP data"
        run_cmd rsync -av ~/.local/share/mcp/ "$BACKUP/mcp/" 2>/dev/null || true

        cyan "  Custom fonts"
        run_cmd rsync -av ~/Library/Fonts/ "$BACKUP/Fonts/" 2>/dev/null || true

        echo ""
        if ${flag "dry_run"}; then
          green "DRY RUN complete — no files copied"
        else
          green "Backup complete!"
          du -sh "$BACKUP"
          cyan "Next: run 'mercury-migrate verify -b $BACKUP' to check"
        fi
      }

      # ── Phase 3: Verify ─────────────────────────────────────────────
      do_verify() {
        blue "Phase 3: Verify Backup at $BACKUP"

        if [ ! -d "$BACKUP" ]; then
          die "Backup directory not found: $BACKUP"
        fi

        ERRORS=0

        check_exists() {
          if [ -e "$BACKUP/$1" ]; then
            green "  ✓ $1"
          else
            red "  ✗ $1 MISSING"
            ERRORS=$((ERRORS + 1))
          fi
        }

        cyan "Critical files:"
        check_exists "sops-key.txt"
        check_exists "ssh/"
        check_exists "gnupg/"
        check_exists "obsidian-vault/"

        echo ""
        cyan "User data:"
        check_exists "Documents/"
        check_exists "Pictures/"
        check_exists "Desktop/"
        check_exists "Downloads/"

        echo ""
        cyan "Music production:"
        check_exists "Ableton/"
        check_exists "Ableton-AppSupport/"
        check_exists "Music/"

        echo ""
        cyan "Stray projects:"
        if [ -d "$BACKUP/stray-projects" ]; then
          green "  ✓ stray-projects/"
          ls "$BACKUP/stray-projects/"
        else
          yellow "  - stray-projects/ (none found)"
        fi

        echo ""
        cyan "Extras:"
        check_exists "atuin/"
        if [ -f "$BACKUP/zsh_history" ]; then green "  ✓ zsh_history"; else yellow "  - zsh_history (optional)"; fi

        echo ""
        cyan "Backup sizes:"
        du -sh "$BACKUP"/* 2>/dev/null | sort -rh

        echo ""
        cyan "Nix config status:"
        git -C "$NIX_CONFIG_DIR" status --short
        git -C "$NIX_CONFIG_DIR" log --oneline -3

        echo ""
        if [ "$ERRORS" -gt 0 ]; then
          red "$ERRORS critical item(s) missing — do NOT wipe yet!"
        else
          green "All critical items present. Safe to proceed."
          cyan "Reminder: check iCloud sync status in System Settings → Apple ID → iCloud"
        fi
      }

      # ── Phase 4: Restore ────────────────────────────────────────────
      do_restore() {
        blue "Phase 4: Restore from $BACKUP"

        if [ ! -d "$BACKUP" ]; then
          die "Backup directory not found: $BACKUP"
        fi

        # Secrets & keys first
        cyan "Restoring secrets & keys..."

        cyan "  SSH keys"
        run_cmd mkdir -p ~/.ssh
        run_cmd rsync -av "$BACKUP/ssh/" ~/.ssh/
        if ! ${flag "dry_run"}; then
          chmod 700 ~/.ssh
          find ~/.ssh -name "id_*" -not -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        fi

        cyan "  GPG config"
        run_cmd rsync -av "$BACKUP/gnupg/" ~/.gnupg/
        if ! ${flag "dry_run"}; then
          chmod 700 ~/.gnupg
        fi

        cyan "  SOPS key"
        if [ -f "$BACKUP/sops-key.txt" ]; then
          run_cmd mkdir -p ~/Library/Application\ Support/sops-nix/
          run_cmd cp "$BACKUP/sops-key.txt" ~/Library/Application\ Support/sops-nix/key.txt
        else
          yellow "  SOPS key not in backup, skipping"
        fi

        # User data
        echo ""
        cyan "Restoring user data..."

        cyan "  Obsidian vault"
        [ -d "$BACKUP/obsidian-vault/" ] && run_cmd rsync -av "$BACKUP/obsidian-vault/" ~/Documents/Obsidian\ Vault/

        cyan "  Documents"
        [ -d "$BACKUP/Documents/" ] && run_cmd rsync -av "$BACKUP/Documents/" ~/Documents/

        cyan "  Pictures"
        [ -d "$BACKUP/Pictures/" ] && run_cmd rsync -av "$BACKUP/Pictures/" ~/Pictures/

        cyan "  Desktop"
        [ -d "$BACKUP/Desktop/" ] && run_cmd rsync -av "$BACKUP/Desktop/" ~/Desktop/

        cyan "  Downloads"
        [ -d "$BACKUP/Downloads/" ] && run_cmd rsync -av "$BACKUP/Downloads/" ~/Downloads/

        # Music production
        echo ""
        cyan "Restoring music production..."

        [ -d "$BACKUP/Ableton/" ] && run_cmd rsync -av "$BACKUP/Ableton/" ~/Music/Ableton/
        [ -d "$BACKUP/Ableton-AppSupport/" ] && run_cmd rsync -av "$BACKUP/Ableton-AppSupport/" ~/Library/Application\ Support/Ableton/
        [ -d "$BACKUP/Music/" ] && run_cmd rsync -av "$BACKUP/Music/" ~/Music/

        if [ -d "$BACKUP/stray-projects" ]; then
          cyan "  Stray Ableton projects → home directory"
          for proj in "$BACKUP/stray-projects"/*/; do
            proj_name=$(basename "$proj")
            run_cmd rsync -av "$proj" ~/"$proj_name/"
          done
        fi

        # Extras
        echo ""
        cyan "Restoring extras..."

        [ -d "$BACKUP/atuin/" ] && run_cmd rsync -av "$BACKUP/atuin/" ~/.local/share/atuin/
        [ -f "$BACKUP/zsh_history" ] && run_cmd cp "$BACKUP/zsh_history" ~/.zsh_history

        echo ""
        if ${flag "dry_run"}; then
          green "DRY RUN complete — no files restored"
        else
          green "Restore complete!"
          echo ""
          cyan "Post-rebuild checklist:"
          echo "  [ ] darwin-rebuild switch --flake ~/.config/nix"
          echo "  [ ] gpg --card-status (YubiKey)"
          echo "  [ ] echo test | gpg --clearsign"
          echo "  [ ] ssh -T git@github.com"
          echo "  [ ] ssh jupiter"
          echo "  [ ] 1Password unlocks"
          echo "  [ ] Obsidian vault opens"
          echo "  [ ] Ableton finds projects"
          echo "  [ ] Ghostty launches"
          echo "  [ ] hx some-file.nix"
          echo "  [ ] atuin sync"
          echo "  [ ] iCloud signed in"
          echo "  [ ] Karabiner profile loads"
        fi
      }

      # ── Dispatch ─────────────────────────────────────────────────────
      case "$CMD" in
        audit)   do_audit   ;;
        backup)  do_backup  ;;
        verify)  do_verify  ;;
        restore) do_restore ;;
        *)
          cyan "Usage: mercury-migrate <command> [flags]"
          echo ""
          echo "Commands:"
          echo "  audit    Pre-backup checks (large dirs, dirty repos, keys)"
          echo "  backup   Backup to Samsung SSD"
          echo "  verify   Verify backup before wiping"
          echo "  restore  Restore on new machine"
          echo ""
          echo "Flags:"
          echo "  -d, --dry-run     Show what would be done"
          echo "  -b, --backup-dir  Override backup path"
          exit 1
          ;;
      esac
    '';
}
