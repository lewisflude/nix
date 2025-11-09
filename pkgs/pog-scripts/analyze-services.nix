{
  pkgs,
  pog,
}:
pog.pog {
  name = "analyze-services";
  version = "1.0.0";
  description = "Analyze Nix store service usage to identify optimization opportunities";

  flags = [ ];

  runtimeInputs = with pkgs; [
    coreutils
    systemd
  ];

  script =
    helpers: with helpers; ''
      blue "=== Nix Store Service Usage Analyzer ==="
      echo ""
      echo "Analyzing your system to identify optimization opportunities..."
      echo ""


      cyan "=== Currently Running Services ==="
      RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | awk '{print $1}' | sed 's/\.service$//' || echo "")
      debug "Analyzing running services..."


      echo ""
      cyan "=== Configured Services (from your config) ==="


      declare -A SERVICES=(
          ["jellyseerr"]="826MB"
          ["jellyfin"]="~500MB"
          ["ollama"]="~1.8GB"
          ["open-webui"]="404MB"
          ["calcom"]="~300MB"
          ["home-assistant"]="345MB"
          ["radarr"]="~100MB"
          ["sonarr"]="~100MB"
          ["lidarr"]="~100MB"
          ["readarr"]="~100MB"
          ["prowlarr"]="~100MB"
          ["sabnzbd"]="~100MB"
      )


      USED_SERVICES=()
      UNUSED_SERVICES=()
      TOTAL_POTENTIAL_SAVINGS=0

      for service in "''${!SERVICES[@]}"; do
          size="''${SERVICES[$service]}"
          if echo "$RUNNING_SERVICES" | grep -qi "$service"; then
              USED_SERVICES+=("$service ($size)")
              green "  ✅ $service - RUNNING ($size)"
          else

              if systemctl list-unit-files --type=service 2>/dev/null | grep -q "$service"; then
                  UNUSED_SERVICES+=("$service ($size)")
                  yellow "  ⚠️  $service - CONFIGURED but NOT RUNNING ($size)"

                  if [[ $size =~ ([0-9]+) ]]; then
                      num="''${BASH_REMATCH[1]}"
                      if [[ $size =~ GB ]]; then
                          TOTAL_POTENTIAL_SAVINGS=$((TOTAL_POTENTIAL_SAVINGS + num * 1024))
                      elif [[ $size =~ MB ]]; then
                          TOTAL_POTENTIAL_SAVINGS=$((TOTAL_POTENTIAL_SAVINGS + num))
                      fi
                  fi
              else
                  echo "  ❌ $service - NOT CONFIGURED"
              fi
          fi
      done

      echo ""
      cyan "=== Service Status Summary ==="
      echo "✅ Running services: ''${#USED_SERVICES[@]}"
      echo "⚠️  Configured but not running: ''${#UNUSED_SERVICES[@]}"

      if [ ''${#UNUSED_SERVICES[@]} -gt 0 ]; then
          echo ""
          echo "Services you could disable to save space:"
          for service in "''${UNUSED_SERVICES[@]}"; do
              echo "  - $service"
          done
          echo ""
          echo "Estimated potential savings: ~$((TOTAL_POTENTIAL_SAVINGS / 1024))GB"
      fi


      echo ""
      cyan "=== Large Packages Analysis ==="
      echo "Checking for large packages that might be optional..."

      LARGE_PACKAGES=$(du -sh /nix/store/*/ 2>/dev/null | sort -rh | head -20)

      echo ""
      echo "Top 20 largest packages in store:"
      while IFS= read -r line; do
          size=$(echo "$line" | awk '{print $1}')
          name=$(echo "$line" | awk '{print $2}' | sed 's|/nix/store/||' | sed 's|/$||')


          if [ -L /run/current-system ]; then
              CURRENT_SYSTEM=$(readlink -f /run/current-system)
              if nix-store -qR "$CURRENT_SYSTEM" 2>/dev/null | grep -q "^/nix/store/.*$name"; then
                  echo "  📦 $size - $name (in use)"
              else
                  echo "  🗑️  $size - $name (possibly unused)"
              fi
          else
              echo "  📦 $size - $name"
          fi
      done <<< "$LARGE_PACKAGES"


      echo ""
      cyan "=== LibreOffice Analysis ==="
      LIBREOFFICE_VERSIONS=$(du -sh /nix/store/*libreoffice* 2>/dev/null | wc -l)
      if [ "$LIBREOFFICE_VERSIONS" -gt 1 ]; then
          echo "Found $LIBREOFFICE_VERSIONS LibreOffice installations"
          du -sh /nix/store/*libreoffice* 2>/dev/null | grep -E "(libreoffice-[0-9])" | head -5
          echo ""
          echo "💡 Tip: If you don't use LibreOffice, disable it:"
          echo "   productivity.office = false;"
      else
          green "✅ Only one LibreOffice version found"
      fi


      echo ""
      cyan "=== Ollama Analysis ==="
      OLLAMA_VERSIONS=$(du -sh /nix/store/*ollama* 2>/dev/null | grep -cE "ollama-[0-9]" || echo "0")
      if [ "$OLLAMA_VERSIONS" -gt 1 ]; then
          echo "Found $OLLAMA_VERSIONS Ollama versions"
          du -sh /nix/store/*ollama* 2>/dev/null | grep -E "ollama-[0-9]" | head -5
          echo ""
          if ! echo "$RUNNING_SERVICES" | grep -qi "ollama"; then
              yellow "⚠️  Ollama is NOT running!"
              echo "💡 Tip: Disable it to save ~1.8GB:"
              echo "   aiTools.enable = false;"
          else
              green "✅ Ollama is running (but has multiple versions)"
          fi
      else
          green "✅ Only one Ollama version found"
      fi


      echo ""
      cyan "=== Development Tools Analysis ==="
      RUST_VERSIONS=$(du -sh /nix/store/*rustc* 2>/dev/null | grep -cE "rustc-[0-9]" || echo "0")
      if [ "$RUST_VERSIONS" -gt 1 ]; then
          echo "Found $RUST_VERSIONS Rust versions"
          echo "💡 Tip: Consider using rustup in devShells instead of global rustc"
      fi


      echo ""
      cyan "=== Current Store Size ==="
      CURRENT_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}')
      echo "Current size: $CURRENT_SIZE"


      echo ""
      cyan "=== Recommendations ==="
      echo ""
      echo "1. ✅ Run cleanup script (already done!)"
      echo "2. Review services above - disable unused ones"
      echo "3. Consider disabling:"
      if [ ''${#UNUSED_SERVICES[@]} -gt 0 ]; then
          for service in "''${UNUSED_SERVICES[@]}"; do
              echo "   - $service"
          done
      fi

      if ! echo "$RUNNING_SERVICES" | grep -qi "ollama"; then
          echo "   - Ollama (~1.8GB) - not running"
      fi

      if [ "$LIBREOFFICE_VERSIONS" -gt 0 ]; then
          echo "   - LibreOffice (~1.3GB) - if not needed"
      fi

      echo ""
      echo "4. More aggressive GC settings:"
      echo "   - Reduce GC retention to 3 days"
      echo "   - Limit system generations to 5"

      echo ""
      cyan "=== To disable a service ==="
      echo "Edit hosts/jupiter/default.nix and set:"
      echo "  featureName.serviceName.enable = false;"
      echo ""
      echo "Then rebuild:"
      echo "  sudo nixos-rebuild switch --flake ~/.config/nix"
    '';
}
