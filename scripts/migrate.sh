#!/usr/bin/env bash
  # migration-script.sh
  set -euo pipefail

  OLD_HOME="/home/lewis"
  NEW_HOME="/home/lewisflude"
  LOG_FILE="$NEW_HOME/migration-$(date +%Y%m%d-%H%M%S).log"

  echo "Starting migration at $(date)" | tee -a "$LOG_FILE"

  # Files/dirs to SKIP (NixOS-managed or unnecessary)
  EXCLUDE_FILE=$(mktemp)
  cat > "$EXCLUDE_FILE" << 'EOF'
.gtkrc-2.0
.p10k.zsh
.Xresources
.zshenv
.zlogin
.zshrc
.nix-profile
.nix-defexpr
10GB.zip
*.tmp
*.log
.bash_history-*.tmp
.cache/
nix-signal.code-workspace
EOF

  # Critical directories to migrate
  CRITICAL_DIRS=(
      ".ssh"
      ".gnupg"
      "Documents"
      "Downloads"
      "Pictures"
      "Videos"
      "Code"
      "Obsidian Vault"
      "Games"
  )

  # Development directories
  DEV_DIRS=(
      "beat-dungeon-sim"
      "beat-dungeon-sprites"
      ".cargo"
      ".rustup"
      "go"
      ".npm-global"
      ".npm-packages"
  )

  # Application data
  APP_DIRS=(
      ".mozilla"
      ".thunderbird"
      ".config"
      ".local"
      ".steam"
      ".cursor"
      ".var"
      ".wine"
  )

  echo "=== Phase 1: Copying critical directories ===" | tee -a "$LOG_FILE"
  for dir in "${CRITICAL_DIRS[@]}"; do
      if sudo test -e "$OLD_HOME/$dir"; then
          echo "Copying $dir..." | tee -a "$LOG_FILE"
          sudo rsync -av --progress \
              --exclude-from="$EXCLUDE_FILE" \
              "$OLD_HOME/$dir/" "$NEW_HOME/$dir/" 2>&1 | tee -a "$LOG_FILE"
      fi
  done

  echo "=== Phase 2: Copying development directories ===" | tee -a "$LOG_FILE"
  for dir in "${DEV_DIRS[@]}"; do
      if sudo test -e "$OLD_HOME/$dir"; then
          echo "Copying $dir..." | tee -a "$LOG_FILE"
          sudo rsync -av --progress \
              --exclude-from="$EXCLUDE_FILE" \
              "$OLD_HOME/$dir/" "$NEW_HOME/$dir/" 2>&1 | tee -a "$LOG_FILE"
      fi
  done

  echo "=== Phase 3: Copying application data ===" | tee -a "$LOG_FILE"
  for dir in "${APP_DIRS[@]}"; do
      if sudo test -e "$OLD_HOME/$dir"; then
          echo "Copying $dir..." | tee -a "$LOG_FILE"
          sudo rsync -av --progress \
              --exclude-from="$EXCLUDE_FILE" \
              "$OLD_HOME/$dir/" "$NEW_HOME/$dir/" 2>&1 | tee -a "$LOG_FILE"
      fi
  done

  echo "=== Phase 4: Copying remaining files (selective) ===" | tee -a "$LOG_FILE"
  # Copy important dotfiles
  DOTFILES=(
      ".bash_history"
      ".zsh_history"
      ".gitconfig"
      ".npmrc"
      ".netrc"
      ".wget-hsts"
  )

  for file in "${DOTFILES[@]}"; do
      if sudo test -f "$OLD_HOME/$file"; then
          echo "Copying $file..." | tee -a "$LOG_FILE"
          sudo cp -av "$OLD_HOME/$file" "$NEW_HOME/$file" 2>&1 | tee -a "$LOG_FILE"
      fi
  done

  echo "=== Phase 5: Fixing permissions ===" | tee -a "$LOG_FILE"
  sudo chown -R lewisflude:users "$NEW_HOME" 2>&1 | tee -a "$LOG_FILE"
  sudo chmod 700 "$NEW_HOME" 2>&1 | tee -a "$LOG_FILE"
  sudo chmod 700 "$NEW_HOME/.ssh" 2>&1 | tee -a "$LOG_FILE"
  sudo chmod 700 "$NEW_HOME/.gnupg" 2>&1 | tee -a "$LOG_FILE"

  rm -f "$EXCLUDE_FILE"
  echo "Migration completed at $(date)" | tee -a "$LOG_FILE"
  echo "Log saved to: $LOG_FILE"
