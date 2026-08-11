# Make narrow SSH clients usable for long clickable links.
#
# Terminals that wrap OSC 8 hyperlinks across lines break the link; widening the
# reported column count keeps them on one line and therefore clickable.

function linkcols() {
  emulate -L zsh
  local cols="${1:-240}"

  if [[ "$cols" != <-> || "$cols" -lt 80 ]]; then
    print -u2 "usage: linkcols [columns>=80]"
    return 2
  fi

  command stty cols "$cols" 2>/dev/null || return
  export COLUMNS="$cols"
  print "Terminal columns set to $cols for this session"
}

if [[ -o interactive && ( -n "${SSH_TTY:-}" || -n "${ET_VERSION:-}" ) ]]; then
  () {
    local want="${PROMPT_LINK_COLS:-}"
    if [[ -z "$want" && "${COLUMNS:-0}" == <-> && "${COLUMNS:-0}" -lt 100 ]]; then
      want=240
    fi
    [[ -n "$want" && "$want" != 0 ]] && linkcols "$want" >/dev/null
  }
fi
