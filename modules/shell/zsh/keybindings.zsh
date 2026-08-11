# Keybindings.
#
# Only non-default bindings live here — zsh already handles arrows, Home and End
# via its own terminfo lookup. Plugin bindings (atuin, history-substring-search)
# are bound under zsh-defer in zsh.nix so they land after the plugins load.

typeset -g -A key
key[Backspace]="${terminfo[kbs]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"
key[Control-Delete]="${terminfo[kDC5]}"

[[ -n "${key[Backspace]}" ]]      && bindkey -- "${key[Backspace]}"      backward-delete-char
[[ -n "${key[Shift-Tab]}" ]]      && bindkey -- "${key[Shift-Tab]}"      reverse-menu-complete
[[ -n "${key[Control-Left]}" ]]   && bindkey -- "${key[Control-Left]}"   backward-word
[[ -n "${key[Control-Right]}" ]]  && bindkey -- "${key[Control-Right]}"  forward-word
[[ -n "${key[Control-Delete]}" ]] && bindkey -- "${key[Control-Delete]}" kill-word

bindkey '^H' backward-kill-word

# Ghostty multiline input: shift+enter is mapped to a literal newline by the
# terminal (see the keybind in modules/terminal.nix); the Kitty-protocol escape
# is bound too for terminals that send it instead.
function _ghostty_insert_newline() { LBUFFER+=$'\n' }
zle -N ghostty-insert-newline _ghostty_insert_newline
bindkey -M emacs $'\e[99997u' ghostty-insert-newline
bindkey -M viins $'\e[99997u' ghostty-insert-newline
bindkey -M emacs $'\e\r'      ghostty-insert-newline
bindkey -M viins $'\e\r'      ghostty-insert-newline
