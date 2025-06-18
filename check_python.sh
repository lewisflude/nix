
#!/bin/bash

echo "=== Diagnosing ZSH Codex Python Issue ==="
echo

# Check Python versions
echo "1. Checking Python versions:"
echo -n "   Default python: "
python --version 2>&1 || echo "Not found"

echo -n "   Default python3: "
python3 --version 2>&1 || echo "Not found"

echo -n "   Nix python3: "
/run/current-system/sw/bin/python3 --version 2>&1 || echo "Not found"

echo
echo "2. Checking which Python zsh_codex is using:"
grep -n "python" ~/.zshrc | grep -v "^#" || echo "No python references in .zshrc"

echo
echo "3. Looking for the zsh_codex script:"
find /nix/store -name "create_completion.py" -type f 2>/dev/null | head -1

echo
echo "4. Checking the shebang in create_completion.py:"
if [[ -f "/nix/store/8ivxlys902a1zvga3p9k7bxpn71gjkv4-source/create_completion.py" ]]; then
    head -1 "/nix/store/8ivxlys902a1zvga3p9k7bxpn71gjkv4-source/create_completion.py"
fi

echo
echo "=== Solution ==="
echo "The issue is that zsh_codex requires Python 3.10+ for the 'match' statement."
echo "We need to either:"
echo "1. Use a newer version of Python"
echo "2. Use an older version of zsh_codex that's compatible with your Python"
echo "3. Use a different AI completion tool"
