{
  pkgs,
  pog,
}:
pog.pog {
  name = "cleanup-duplicates";
  version = "1.0.0";
  description = "Remove old/unused package versions from Nix store while keeping latest versions";

  flags = [
    {
      name = "auto-confirm";
      short = "y";
      bool = true;
      description = "Non-interactive mode (auto-confirm all prompts)";
    }
    {
      name = "dry_run";
      short = "d";
      bool = true;
      description = "Show what would be deleted without making changes";
    }
  ];

  runtimeInputs = with pkgs; [
    coreutils
    bc
    gnumake
  ];

  script =
    helpers: with helpers; ''

      if [ -L /run/current-system ]; then
        CURRENT_SYSTEM=$(readlink -f /run/current-system)
      else

        yellow "Warning: /run/current-system not found, trying to detect..."
        CURRENT_SYSTEM=$(find /nix/store -maxdepth 1 -name "*-nixos-system-*" -type l 2>/dev/null | head -1 || echo "")
        if [ -z "$CURRENT_SYSTEM" ]; then
          die "Could not determine current system. Please run this script on a NixOS system."
        fi
      fi

      blue "=== Nix Store Cleanup Script ==="
      echo ""
      echo "Current system: $CURRENT_SYSTEM"
      echo ""


      is_referenced() {
        local path="$1"

        nix-store -qR "$CURRENT_SYSTEM" 2>/dev/null | grep -q "^$path$" && return 0

        for profile in /nix/var/nix/profiles/per-user/*/*; do
          if [ -L "$profile" ]; then
            nix-store -qR "$(readlink -f "$profile")" 2>/dev/null | grep -q "^$path$" && return 0
          fi
        done
        return 1
      }


      cyan "=== Step 1: Running garbage collection ==="
      echo "This will remove all paths not referenced by any profile..."
      echo ""

      if ${flag "dry_run"}; then
        debug "DRY RUN: Would run nix-store --gc"
      elif ${flag "auto-confirm"} || ${confirm { prompt = "Continue with garbage collection?"; }}; then
        debug "Running nix-store --gc..."
        nix-store --gc 2>&1 | tail -5
        echo ""
      else
        yellow "Skipping garbage collection."
        echo ""
      fi


      cyan "=== Step 2: Removing specific old package versions ==="
      echo ""


      PATHS_TO_DELETE=()


      debug "Analyzing LibreOffice..."
      for path in /nix/store/*libreoffice*24.8.7.2* /nix/store/7mspwdd46kar6x9sj3pgkf9v2zzpyaq8-libreoffice-25.2.6.2 /nix/store/lnm88zzb3iqb5k3pwg8fgvx3b0750b9g-libreoffice-25.2.6.2; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing Ollama..."
      for path in /nix/store/*ollama-0.12.5* /nix/store/kkyw934ba0zhsskchr1jvsy9dl6jqr2x-ollama-0.12.6; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing NVIDIA drivers..."
      for path in /nix/store/*nvidia-x11-580.95.05-6.6.101-rt59* /nix/store/*nvidia-x11-565.77-6.6.76*; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing LLVM/Clang..."
      for path in /nix/store/*clang-21.1.1-lib* /nix/store/*clang-19.1.7-lib* /nix/store/*llvm-21.1.1-lib* /nix/store/*llvm-20.1.8-lib* /nix/store/*llvm-18.1.8-lib* /nix/store/*llvm-19.1.7-lib* /nix/store/*llvm-18.1.7-lib* /nix/store/*llvm-20.1.6-lib*; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing OpenJDK..."
      for path in /nix/store/0x556ql275jkl46k6lklpyvwn5c4p244-openjdk-21.0.8+9 /nix/store/zxz5fgdkwxizvq3hyq98bwha5fifvnni-openjdk-minimal-jre-21.0.7+6 /nix/store/4s8x41xzb6p2qwd6lbhzdrddwpjmkh27-openjdk-minimal-jre-21.0.8+9; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing Iosevka fonts..."
      for path in /nix/store/kazq51c124yrcmj28nhh37664il6c208-Iosevka-33.3.1 /nix/store/k3l8d2z7g7vhrp4c2flxbvbs1hwk389i-Iosevka-33.2.5 /nix/store/j6lrwr1iznpwjrw7f55wdm83c9vrn2wm-Iosevka-33.3.2 /nix/store/6802if909gc6xz2d8yy1kl9b3zz9zx3a-Iosevka-33.2.6; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing cmake debug..."
      for path in /nix/store/*cmake*debug*; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing other debug packages..."
      for path in /nix/store/*-debug; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing duplicate CUDA libraries..."
      CUDA_LIBS=$(du -sh /nix/store/*libcublas* 2>/dev/null | sort -rh | head -3)
      if [ -n "$CUDA_LIBS" ]; then

        KEEP_LIB=$(echo "$CUDA_LIBS" | head -1 | awk '{print $2}')
        for path in /nix/store/*libcublas*; do
          [ -e "$path" ] || continue
          [ "$path" = "$KEEP_LIB" ] && continue
          if ! is_referenced "$path"; then
            PATHS_TO_DELETE+=("$path")
            debug "  Will delete: $(basename $path)"
          else
            debug "  Keep (referenced): $(basename $path)"
          fi
        done
      fi


      debug "Analyzing Linux firmware..."
      for path in /nix/store/p3hcgmhfqi28s0ipk989557rfymzh0m8-linux-firmware-20250109-zstd; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing Zoom..."
      for path in /nix/store/6h0l4clamp84rz13xyhx6g1i751zlcra-zoom-6.6.0.4410 /nix/store/xxsahv5pmfpyrfrlf3rfncqs3cr39jkp-zoom-6.4.10.2027 /nix/store/aky8mjyy7rajw33738sa9sq9ay4cvci4-zoom-6.5.3.2773; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done


      debug "Analyzing Rust..."
      for path in /nix/store/*rustc-1.78.0 /nix/store/*rustc-1.88.0 /nix/store/*rustc-wrapper-1.88.0-doc* /nix/store/*rust-docs-1.90*; do
        [ -e "$path" ] || continue
        if ! is_referenced "$path"; then
          PATHS_TO_DELETE+=("$path")
          debug "  Will delete: $(basename $path)"
        else
          debug "  Keep (referenced): $(basename $path)"
        fi
      done

      echo ""
      cyan "=== Summary ==="
      echo "Found ''${
      echo ""


      TOTAL_SIZE=0
      for path in "''${PATHS_TO_DELETE[@]}"; do
        if [ -e "$path" ]; then
          SIZE=$(du -sk "$path" 2>/dev/null | cut -f1 || echo "0")
          TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        fi
      done
      if command -v bc >/dev/null 2>&1; then
        TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
      else
        TOTAL_SIZE_GB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE / 1024 / 1024}")
      fi

      echo "Estimated space to free: ''${TOTAL_SIZE_GB}GB"
      echo ""

      if ${flag "dry_run"}; then
        cyan "DRY RUN MODE - No changes will be made"
        echo "Paths that would be deleted:"
        for path in "''${PATHS_TO_DELETE[@]}"; do
          echo "  - $(basename "$path")"
        done
        exit 0
      fi

      if [ "''${
        green "No duplicates found to clean up"
        exit 0
      fi

      if ! ${flag "auto-confirm"}; then
        if ! ${confirm { prompt = "Do you want to proceed with deletion?"; }}; then
          yellow "Aborted."
          exit 0
        fi
      fi

      echo ""
      cyan "=== Deleting packages ==="
      DELETED=0
      FAILED=0

      for path in "''${PATHS_TO_DELETE[@]}"; do
        if [ -e "$path" ]; then
          debug "Deleting: $(basename $path)"
          if nix-store --delete "$path" 2>/dev/null; then
            DELETED=$((DELETED + 1))
          else
            yellow "  Failed (may be referenced elsewhere)"
            FAILED=$((FAILED + 1))
          fi
        fi
      done

      echo ""
      cyan "=== Cleanup complete ==="
      echo "Deleted: $DELETED packages"
      echo "Failed: $FAILED packages"
      echo ""
      debug "Running final garbage collection..."
      nix-store --gc

      echo ""
      debug "Optimizing store..."
      nix-store --optimise

      echo ""
      cyan "=== Final store size ==="
      du -sh /nix/store

      green "? Cleanup completed!"
    '';
}
