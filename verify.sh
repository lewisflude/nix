
#!/bin/bash

echo "=== ZSH Plugin Verification ==="
echo "Current shell: $SHELL"
echo "ZSH version: $(zsh --version)"
echo

# Test in a fresh zsh session
zsh -ic '
echo "=== 1. Plugin Loading Status ==="

# Check autosuggestions
echo -n "✓ Autosuggestions: "
if (( $+functions[_zsh_autosuggest_start] )); then
    echo "LOADED ✅"
    echo "  - Try typing a command you used before"
    echo "  - You should see gray suggestions appear"
else
    echo "NOT LOADED ❌"
fi

# Check syntax highlighting
echo -n "✓ Syntax Highlighting: "
if (( $+functions[_zsh_highlight] )); then
    echo "LOADED ✅"
    echo "  - Commands should be colored as you type"
    echo "  - Valid commands = green, invalid = red"
else
    echo "NOT LOADED ❌"
fi

# Check Powerlevel10k
echo -n "✓ Powerlevel10k: "
if [[ -n "$POWERLEVEL9K_VERSION" ]] || [[ -n "$POWERLEVEL10K_VERSION" ]]; then
    echo "LOADED ✅ (version: ${POWERLEVEL9K_VERSION:-$POWERLEVEL10K_VERSION})"
    echo "  - You should see a fancy prompt"
else
    echo "NOT LOADED ❌"
fi

# Check zsh_codex (if installed)
echo -n "✓ ZSH Codex: "
if command -v create_completion &> /dev/null || [[ -n "$(declare -f create_completion 2>/dev/null)" ]]; then
    echo "LOADED ✅"
    echo "  - Try pressing Ctrl+X to trigger AI completion"
else
    echo "NOT LOADED ❓ (might be okay if not configured)"
fi

echo
echo "=== 2. Alias Verification ==="

# Test aliases
echo -n "✓ Alias '\''ls'\'': "
if alias ls &> /dev/null; then
    alias ls
    command -v lsd &> /dev/null && echo "  → lsd is installed ✅" || echo "  → lsd NOT installed ❌"
else
    echo "NOT SET ❌"
fi

echo -n "✓ Alias '\''cd'\'': "
if alias cd &> /dev/null; then
    alias cd
    command -v zoxide &> /dev/null && echo "  → zoxide is installed ✅" || echo "  → zoxide NOT installed ❌"
else
    echo "NOT SET ❌"
fi

echo -n "✓ Alias '\''switch'\'': "
alias switch &> /dev/null && echo "SET ✅" || echo "NOT SET ❌"

echo
echo "=== 3. Environment Variables ==="
echo -n "✓ SSH_AUTH_SOCK: "
[[ -n "$SSH_AUTH_SOCK" ]] && echo "SET ✅" || echo "NOT SET ❌"

echo -n "✓ OPENAI_API_KEY: "
[[ -n "$OPENAI_API_KEY" ]] && echo "SET ✅ (hidden)" || echo "NOT SET ❌"

echo
echo "=== 4. Configuration Files ==="
echo -n "✓ ~/.zshrc: "
if [[ -L ~/.zshrc ]]; then
    echo "Symlink ✅ -> $(readlink ~/.zshrc | sed "s|/nix/store/[^/]*|/nix/store/...|")"
else
    echo "Not managed by nix ❌"
fi

echo -n "✓ ~/.p10k.zsh: "
[[ -f ~/.p10k.zsh ]] && echo "EXISTS ✅" || echo "MISSING ❌ (run '\''p10k configure'\'' after fixing)"

echo -n "✓ ~/.config/zsh/.zshenv.local: "
[[ -f ~/.config/zsh/.zshenv.local ]] && echo "EXISTS ✅" || echo "MISSING ❓ (for API keys)"
'

echo
echo "=== 5. Interactive Tests ==="
echo
echo "Test these manually in your terminal:"
echo
echo "1. AUTOSUGGESTIONS:"
echo "   - Type 'ls' and press space"
echo "   - If you've used 'ls -la' before, it should appear in gray"
echo "   - Press → (right arrow) to accept the suggestion"
echo
echo "2. SYNTAX HIGHLIGHTING:"
echo "   - Type: echoo hello  (with typo)"
echo "   - 'echoo' should be RED (invalid command)"
echo "   - Fix it to: echo hello"
echo "   - 'echo' should turn GREEN (valid command)"
echo
echo "3. POWERLEVEL10K:"
echo "   - Your prompt should look fancy with icons/colors"
echo "   - If not, run: p10k configure"
echo
echo "4. ALIASES:"
echo "   - Try: ls (should use lsd with icons)"
echo "   - Try: cd /tmp then cd - (should use zoxide)"
echo "   - Try: switch (should run darwin-rebuild)"
echo
echo "5. ZSH_CODEX (if configured):"
echo "   - Type: # create a function to calculate fibonacci"
echo "   - Press Ctrl+X"
echo "   - Should generate code completion"

echo
echo "=== 6. Troubleshooting Commands ==="
echo
echo "If something isn't working, try:"
echo "  1. exec zsh                    # Reload shell"
echo "  2. source ~/.zshrc             # Reload config"
echo "  3. echo \$fpath                # Check function path"
echo "  4. print -l \$plugins          # List loaded plugins"
echo "  5. zsh -xivc exit 2>&1 | grep -E '(source|plugin)' # Debug sourcing"
