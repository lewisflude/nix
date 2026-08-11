# Powerlevel10k Diagnostic Functions
# Troubleshooting and validation utilities

# Validate instant prompt configuration and cache
function p10k-validate-instant() {
  local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  local issues=0
  
  print "=== Powerlevel10k Instant Prompt Validation ==="
  print
  
  # Check 1: Cache file exists
  if [[ -r "$cache_file" ]]; then
    print "✓ Instant prompt cache exists"
    local age=$(($(date +%s) - $(date -r "$cache_file" +%s 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)))
    print "  Age: ${age}s"
    [[ $age -lt 86400 ]] && print "  Status: Fresh" || print "  Status: Old (>24h)"
  else
    print "✗ Instant prompt cache missing"
    print "  Expected: $cache_file"
    ((issues++))
  fi
  
  # Check 2: Configuration
  print
  print "Configuration:"
  print "  Mode: ${POWERLEVEL9K_INSTANT_PROMPT:-not set}"
  [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "quiet" ]] && print "  ✓ Quiet mode (recommended)" || print "  ℹ Verbose mode enabled"
  
  # Check 3: Powerlevel10k loaded
  print
  print "Initialization:"
  if (( $+functions[p10k] )); then
    print "  ✓ Powerlevel10k loaded"
    print "  Version: ${P9K_VERSION:-unknown}"
  else
    print "  ✗ Powerlevel10k not loaded"
    ((issues++))
  fi
  
  # Check 4: Terminal compatibility  
  print
  print "Terminal:"
  print "  TERM: $TERM"
  print "  Colors: ${terminfo[colors]:-unknown}"
  [[ "${terminfo[colors]}" -ge 256 ]] && print "  ✓ 256+ colors" || print "  ⚠ <256 colors"
  print "  COLORTERM: ${COLORTERM:-not set}"
  
  # Check 5: Font support
  print
  print "Unicode support:"
  if echo '\u276F' 2>/dev/null | grep -q ❯; then
    print "  ✓ UTF-8 supported"
  else
    print "  ✗ UTF-8 not supported"
    ((issues++))
  fi
  
  print
  if [[ $issues -eq 0 ]]; then
    print "✓ All checks passed"
    return 0
  else
    print "✗ Found $issues issue(s)"
    return 1
  fi
}

# Test prompt width alignment (detects cursor position issues)
function p10k-test-width() {
  emulate -L zsh
  setopt err_return no_unset
  local text
  print -rl -- 'Select a part of your prompt from the terminal window and paste it below.' ''
  read -r '?Prompt: ' text
  local -i len=${(m)#text}
  local frame="+-${(pl.$len..-.):-}-+"
  print -lr -- $frame "| $text |" $frame
  
  print "\nDiagnosis:"
  print "- Aligned: Prompt width correct"
  print "- Too long: Terminal bug with ambiguous-width characters"
  print "- Too short + mangled: Terminal doesn't handle wide glyphs correctly"
  print "- Too short + clean: Locale misconfiguration"
}

# Test Unicode and terminal capabilities
function p10k-test-unicode() {
  print "Testing Unicode support..."
  print -n "Arrow glyph (U+276F): "
  echo '\u276F'
  [[ $? -eq 0 ]] && print "✓ UTF-8 supported" || print "✗ UTF-8 not supported"
  
  print "\nTerminal capabilities:"
  print "  Colors: $(print $terminfo[colors])"
  print "  LANG: $LANG"
  print "  LC_ALL: ${LC_ALL:-not set}"
  print "  COLORTERM: ${COLORTERM:-not set}"
}

# Show current Powerlevel10k configuration
function p10k-show-config() {
  print "Powerlevel10k Configuration:"
  print "  Instant Prompt: ${POWERLEVEL9K_INSTANT_PROMPT:-not set}"
  print "  Transient Prompt: ${POWERLEVEL9K_TRANSIENT_PROMPT:-not set}"
  print "  Hot Reload: $([ "$POWERLEVEL9K_DISABLE_HOT_RELOAD" = "true" ] && echo "DISABLED" || echo "ENABLED")"
  print "\nLeft segments: ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[@]}"
  print "Right segments: ${POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[@]}"
  print "\nP10k version: ${P9K_VERSION:-not loaded}"
  print "gitstatusd: $(command -v gitstatusd || echo "not found in PATH")"
}

# Benchmark Zsh startup time
function zsh-bench-startup() {
  local tmpfile=$(mktemp)
  local count=${1:-10}
  
  print "Benchmarking Zsh startup ($count iterations)..."
  print "This measures time until prompt appears.\n"
  
  for i in {1..$count}; do
    # Use time command if available, otherwise fallback
    if command -v time >/dev/null 2>&1; then
      /usr/bin/time -f "%E" zsh -i -c 'exit' 2>&1 | tee -a "$tmpfile"
    else
      ( time zsh -i -c 'exit' ) 2>&1 | grep real | awk '{print $2}' | tee -a "$tmpfile"
    fi
  done
  
  print "\nResults:"
  awk '{
    # Handle both formats: 0:00.05 and 0.05
    if (match($0, /([0-9]+:)?([0-9]+\.[0-9]+)/, arr)) {
      val = arr[2]
      if (arr[1] != "") {
        # Has minutes
        split(arr[1], min, ":")
        val = min[1] * 60 + arr[2]
      }
      sum += val
      if (NR == 1 || val < min_val) min_val = val
      if (NR == 1 || val > max_val) max_val = val
      count++
    }
  }
  END {
    if (count > 0) {
      printf "  Average: %.3fs\n", sum/count
      printf "  Min:     %.3fs\n", min_val
      printf "  Max:     %.3fs\n", max_val
    }
  }' "$tmpfile"
  
  rm "$tmpfile"
  
  print "\nTarget: <0.050s (50ms) with instant prompt"
  print "Check cache: ${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
}

# Toggle hot reload for development
function p10k-dev-mode() {
  if [[ "$POWERLEVEL9K_DISABLE_HOT_RELOAD" == "true" ]]; then
    export POWERLEVEL9K_DISABLE_HOT_RELOAD=false
    print "P10k hot reload: ENABLED (slightly slower prompt)"
  else
    export POWERLEVEL9K_DISABLE_HOT_RELOAD=true
    print "P10k hot reload: DISABLED (use 'p10k reload' after config changes)"
  fi
  p10k reload
}
