# Common Zsh functions

function gclone() {
  [[ -z "$1" ]] && { echo "Usage: gclone <repo-url>"; return 1; }
  git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

function gacp() {
  [[ -z "$1" ]] && { echo "Usage: gacp <commit-message>"; return 1; }
  git add . && git commit -m "$1" && git push || return 1
}

function gnew() {
  [[ -z "$1" ]] && { echo "Usage: gnew <branch-name>"; return 1; }
  git checkout -b "$1" && git push -u origin "$1" || return 1
}

function mkcd() {
  [[ -z "$1" ]] && { echo "Usage: mkcd <directory>"; return 1; }
  mkdir -p "$1" && cd "$1" || return 1
}

function cdf() {
  local file=$(fzf)
  [[ -z "$file" ]] && { echo "No file selected"; return 1; }
  cd "$(dirname "$file")" || return 1
}

function up() {
  local levels=''${1:-1}
  [[ ! "$levels" =~ ^[0-9]+$ ]] && { echo "Usage: up [number]"; return 1; }
  local path=""
  for ((i=1; i<=levels; i++)); do
    path="../$path"
  done
  cd "$path" || return 1
}

function bk() { cd "$OLDPWD" || return 1 }

function cdl() {
  [[ -z "$1" ]] && { echo "Usage: cdl <directory>"; return 1; }
  cd "$1" && eza || return 1
}

# Directory stack jump helpers
function cd1() { cd -1 2>/dev/null || { echo "Directory stack entry 1 not found"; return 1; } }
function cd2() { cd -2 2>/dev/null || { echo "Directory stack entry 2 not found"; return 1; } }
function cd3() { cd -3 2>/dev/null || { echo "Directory stack entry 3 not found"; return 1; } }
function cd4() { cd -4 2>/dev/null || { echo "Directory stack entry 4 not found"; return 1; } }
function cd5() { cd -5 2>/dev/null || { echo "Directory stack entry 5 not found"; return 1; } }

# Find helpers
function findcode() {
  print -l **/*.(js|ts|jsx|tsx|py|go|rs|c|cpp|h|hpp|java|php|rb|swift|kt)~*/(node_modules|target|build|dist|vendor)/*
}
function findconfig() {
  print -l **/*.(json|yaml|yml|toml|ini|conf|cfg|env)~*/(node_modules|target|build|dist|vendor)/*
}
function finddocs() {
  print -l **/*.(md|txt|rst|adoc|tex|pdf)~*/(node_modules|target|build|dist|vendor)/*
}
function findlarge() { print -l **/*(.Lm+10) }
function findrecent() { print -l **/*(.mm-7) }
function findold() { print -l **/*(.mm+30) }

# Archive helpers
function extract() {
  [[ -z "$1" ]] && { echo "Usage: extract <file>"; return 1; }
  [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
  case "$1" in
    *.tar.bz2)   tar xjf "$1" || return 1 ;;
    *.tar.gz)    tar xzf "$1" || return 1 ;;
    *.bz2)       bunzip2 "$1" || return 1 ;;
    *.rar)       unrar x "$1" || return 1 ;;
    *.gz)        gunzip "$1" || return 1 ;;
    *.tar)       tar xf "$1" || return 1 ;;
    *.tbz2)      tar xjf "$1" || return 1 ;;
    *.tgz)       tar xzf "$1" || return 1 ;;
    *.zip)       unzip "$1" || return 1 ;;
    *.Z)         uncompress "$1" || return 1 ;;
    *.7z)        7z x "$1" || return 1 ;;
    *.xz)        unxz "$1" || return 1 ;;
    *.exe)       cabextract "$1" || return 1 ;;
    *)           echo "Error: '$1' cannot be extracted via extract()"; return 1 ;;
  esac
  echo "Successfully extracted '$1'"
}

function mktmp() {
  local tmp_dir=$(mktemp -d) || { echo "Failed to create temporary directory"; return 1; }
  echo "Created: $tmp_dir"
  cd "$tmp_dir" || return 1
}

function backup() {
  [[ -z "$1" ]] && { echo "Usage: backup <file>"; return 1; }
  [[ ! -f "$1" ]] && { echo "Error: '$1' is not a valid file"; return 1; }
  local backup_name="$1.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$1" "$backup_name" || return 1
  echo "Backup created: $backup_name"
}

# Port helpers
function port() {
  [[ -z "$1" ]] && { echo "Usage: port <port-number>"; return 1; }
  [[ ! "$1" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
  lsof -ti:"$1" || { echo "No process found on port $1"; return 1; }
}

function killport() {
  [[ -z "$1" ]] && { echo "Usage: killport <port-number>"; return 1; }
  [[ ! "$1" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
  local pid=$(lsof -ti:"$1")
  [[ -z "$pid" ]] && { echo "No process found on port $1"; return 1; }
  kill -9 "$pid" || return 1
  echo "Killed process $pid on port $1"
}

# Misc helpers
function weather() {
  local location=''${1:-""}
  curl -s "wttr.in/$location" || { echo "Failed to fetch weather data"; return 1; }
}

function serve() {
  local port=''${1:-8000}
  [[ ! "$port" =~ ^[0-9]+$ ]] && { echo "Error: Port must be a number"; return 1; }
  command -v python >/dev/null 2>&1 || { echo "Python not found"; return 1; }
  echo "Starting server on port $port..."
  python -m http.server "$port" || return 1
}

function nix-dev() {
  if [[ -f shell.nix || -f .envrc ]]; then
    nix-shell || return 1
  else
    echo "No shell.nix or .envrc found in current directory"
    return 1
  fi
}

function flake-init() {
  [[ -z "$1" ]] && { echo "Usage: flake-init <template-name>"; return 1; }
  nix flake init --template "github:nix-community/templates#$1" || return 1
  echo "Initialized flake with template: $1"
}
