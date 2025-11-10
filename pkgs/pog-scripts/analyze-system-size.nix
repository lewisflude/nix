{
  pkgs,
  pog,
}:
pog.pog {
  name = "analyze-system-size";
  version = "1.0.0";
  description = "Analyze largest packages in NixOS system closure";

  flags = [
    {
      name = "top";
      short = "n";
      description = "Number of top packages to show (default: 30)";
      type = "int";
      default = 30;
    }
    {
      name = "min_size";
      short = "m";
      description = "Minimum size in MB to show (default: 50)";
      type = "int";
      default = 50;
    }
  ];

  runtimeInputs = with pkgs; [
    coreutils
    gnumake
    bc
  ];

  script =
    helpers: with helpers; ''
      if [ ! -L /run/current-system ]; then
        die "Not running on NixOS or /run/current-system not found"
      fi

      CURRENT_SYSTEM=$(readlink -f /run/current-system)
      TOP_N=${flag "top"}
      MIN_SIZE_MB=${flag "min_size"}

      blue "=== Analyzing System Closure Size ==="
      echo ""
      echo "Current system: $(basename "$CURRENT_SYSTEM")"
      echo ""

      cyan "=== Calculating closure size ==="
      echo "This may take a minute..."
      echo ""

      # Get all paths in closure with sizes
      nix-store -q --size "$CURRENT_SYSTEM" 2>/dev/null | sort -rn > /tmp/system-closure-sizes.txt

      TOTAL_SIZE=$(awk '{sum+=$1} END {print sum}' /tmp/system-closure-sizes.txt)
      TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024 / 1024" | bc)

      echo "Total system closure size: ''${TOTAL_SIZE_GB} GB"
      echo ""

      cyan "=== Top $TOP_N Largest Packages (>= ''${MIN_SIZE_MB}MB) ==="
      echo ""

      COUNT=0
      while IFS= read -r line; do
        SIZE_BYTES=$(echo "$line" | awk '{print $1}')
        PATH=$(echo "$line" | awk '{print $2}')

        SIZE_MB=$(echo "scale=2; $SIZE_BYTES / 1024 / 1024" | bc)
        SIZE_GB=$(echo "scale=2; $SIZE_BYTES / 1024 / 1024 / 1024" | bc)

        # Only show if >= MIN_SIZE_MB
        if (( $(echo "$SIZE_MB >= $MIN_SIZE_MB" | bc -l) )); then
          COUNT=$((COUNT + 1))

          # Extract package name from path
          PKG_NAME=$(basename "$PATH" | sed 's/^[a-z0-9]*-//' | sed 's/-[0-9].*$//' | head -c 50)

          if (( $(echo "$SIZE_GB >= 1" | bc -l) )); then
            printf "%-50s %8.2f GB\n" "$PKG_NAME" "$SIZE_GB"
          else
            printf "%-50s %8.2f MB\n" "$PKG_NAME" "$SIZE_MB"
          fi

          if [ $COUNT -ge $TOP_N ]; then
            break
          fi
        fi
      done < /tmp/system-closure-sizes.txt

      echo ""
      cyan "=== Summary by Category ==="
      echo ""

      # Categorize packages
      RUST_SIZE=$(grep -E "(rustc|rust-|cargo)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      PYTHON_SIZE=$(grep -E "(python|pip|poetry)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      NODE_SIZE=$(grep -E "(nodejs|node-|npm)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      LLVM_SIZE=$(grep -E "(llvm|clang)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      STEAM_SIZE=$(grep -E "(steam|proton|wine)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      NVIDIA_SIZE=$(grep -E "(nvidia)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      FIRMWARE_SIZE=$(grep -E "(firmware)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      HOMEASSISTANT_SIZE=$(grep -E "(home-assistant|homeassistant)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      CHROMIUM_SIZE=$(grep -E "(chromium)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      LIBREOFFICE_SIZE=$(grep -E "(libreoffice)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      MEDIA_SIZE=$(grep -E "(jellyfin|jellyseerr|ollama)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')
      MESA_SIZE=$(grep -E "(mesa|libgl)" /tmp/system-closure-sizes.txt | awk '{sum+=$1} END {print sum/1024/1024/1024}')

      printf "%-30s %8.2f GB\n" "Rust toolchain:" "$RUST_SIZE"
      printf "%-30s %8.2f GB\n" "Python toolchain:" "$PYTHON_SIZE"
      printf "%-30s %8.2f GB\n" "Node.js toolchain:" "$NODE_SIZE"
      printf "%-30s %8.2f GB\n" "LLVM/Clang:" "$LLVM_SIZE"
      printf "%-30s %8.2f GB\n" "Steam/Gaming:" "$STEAM_SIZE"
      printf "%-30s %8.2f GB\n" "NVIDIA drivers:" "$NVIDIA_SIZE"
      printf "%-30s %8.2f GB\n" "Linux firmware:" "$FIRMWARE_SIZE"
      printf "%-30s %8.2f GB\n" "Home Assistant:" "$HOMEASSISTANT_SIZE"
      printf "%-30s %8.2f GB\n" "Chromium:" "$CHROMIUM_SIZE"
      printf "%-30s %8.2f GB\n" "LibreOffice:" "$LIBREOFFICE_SIZE"
      printf "%-30s %8.2f GB\n" "Media services:" "$MEDIA_SIZE"
      printf "%-30s %8.2f GB\n" "Mesa/OpenGL:" "$MESA_SIZE"

      echo ""
      green "? Analysis complete!"
      echo ""
      echo "?? Tip: Use --top N to show more packages"
      echo "?? Tip: Use --min_size N to filter by minimum size (MB)"
    '';
}
