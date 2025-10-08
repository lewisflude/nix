{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellApplication {
      name = "system-update";
      runtimeInputs = [
        pkgs.bash
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
        pkgs.git
        pkgs.jq
        pkgs.nix
        pkgs.util-linux
        pkgs.nh
      ];
      text = ''
        #!${pkgs.bash}/bin/bash
        set -Eeuo pipefail

        die()  { echo "✖ $*" >&2; exit 1; }
        info() { echo "➤ $*"; }
        ok()   { echo "✓ $*"; }
        warn() { echo "⚠ $*" >&2; }

        trap 'warn "Update failed (line ${LINENO})"; exit 1' ERR

        # Defaults (overridable)
        FLAKE_DEFAULT="${HOME}/.config/nix"
        UPDATE_INPUTS=0
        RUN_GC=0
        RUN_OPTIMISE=0
        BUILD_ONLY=0
        DRY_RUN=0
        HOST_OVERRIDE=""

        usage() {
          cat <<USAGE
        system-update [options]

          --full           inputs + build/switch + nh clean
          --inputs         nix flake update
          --gc             nh clean (default: $CLEAN_ARGS)
          --optimise       nix store optimise
          --build-only     build but do not activate
          --dry-run        print the commands without executing
          --flake REF      override flake ref (path or URL) [default: ${FLAKE_DEFAULT}]
          --host NAME      override host name for flake outputs
          --help           show help
        USAGE
        }

        while [[ $# -gt 0 ]]; do
          case "$1" in
            --full)        UPDATE_INPUTS=1; RUN_GC=1; shift ;;
            --inputs)      UPDATE_INPUTS=1; shift ;;
            --gc)          RUN_GC=1; shift ;;
            --optimise)    RUN_OPTIMISE=1; shift ;;
            --build-only)  BUILD_ONLY=1; shift ;;
            --dry-run)     DRY_RUN=1; shift ;;
            --flake)       FLAKE_REF="$2"; shift 2 ;;
            --host)        HOST_OVERRIDE="$2"; shift 2 ;;
            --help|-h)     usage; exit 0 ;;
            *)             die "Unknown argument: $1 (use --help)";;
          esac
        done

        # OS detection
        IS_DARWIN=0
        if command -v darwin-rebuild >/dev/null 2>&1 || [[ "$(uname -s)" == "Darwin" ]]; then
          IS_DARWIN=1
        fi

        # Host detection (overridable)
        if [[ -n "$HOST_OVERRIDE" ]]; then
          HOST_NAME="$HOST_OVERRIDE"
        else
          if [[ $IS_DARWIN -eq 1 ]] && command -v scutil >/dev/null 2>&1; then
            HOST_NAME="$(scutil --get LocalHostName || hostname -s)"
          else
            HOST_NAME="$(hostname -s)"
          fi
        fi

        USER_NAME="${"USER:-$" (id - un)}"

        # Flake selectors
        FLAKE_SYSTEM="${FLAKE_REF}#${HOST_NAME}"
        FLAKE_HOME="${FLAKE_REF}#${USER_NAME}@${HOST_NAME}"

        # nh commands (nh provides diff/build-tree/confirm UX)
        if [[ $IS_DARWIN -eq 1 ]]; then
          CMD_BUILD_SYSTEM=( nh darwin build  --write-to-substituter https://lewisflude.cachix.org "$FLAKE_SYSTEM" )
          CMD_SWITCH_SYSTEM=( nh darwin switch --write-to-substituter https://lewisflude.cachix.org "$FLAKE_SYSTEM" )
        else
          CMD_BUILD_SYSTEM=( nh os build      --write-to-substituter https://lewisflude.cachix.org "$FLAKE_SYSTEM" )
          CMD_SWITCH_SYSTEM=( nh os switch    --write-to-substituter https://lewisflude.cachix.org "$FLAKE_SYSTEM" )
        fi
        CMD_BUILD_HOME=(  nh home build  "$FLAKE_HOME" )
        CMD_SWITCH_HOME=( nh home switch "$FLAKE_HOME" )

        run() {
          if [[ $DRY_RUN -eq 1 ]]; then
            printf '• %q ' "$@"; echo
          else
            "$@"
          fi
        }

        info "Platform: $([[ $IS_DARWIN -eq 1 ]] && echo Darwin || echo NixOS)"
        info "Host: ${HOST_NAME}"
        info "User: ${USER_NAME}"
        info "Flake (system): ${FLAKE_SYSTEM}"
        info "Flake (home)  : ${FLAKE_HOME}"

        if [[ $UPDATE_INPUTS -eq 1 ]]; then
          info "Updating flake inputs…"
          run nix flake update --flake "$FLAKE_REF"
          ok "Inputs updated"
        fi

        # Previous generation snapshots (for display/rollback hints)
        PREV_SYS_GEN=""
        PREV_HM_GEN=""
        if [[ $IS_DARWIN -eq 1 ]]; then
          PREV_SYS_GEN="$(darwin-rebuild --list-generations 2>/dev/null | tail -n 1 || true)"
        else
          PREV_SYS_GEN="$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations 2>/dev/null | tail -n 1 || true)"
        fi
        PREV_HM_GEN="$(home-manager generations 2>/dev/null | head -n 1 || true)"

        info "Building system…"
        run "''${CMD_BUILD_SYSTEM[@]}"; ok "System build complete"

        info "Building home…"
        run "''${CMD_BUILD_HOME[@]}"; ok "Home build complete"

        if [[ $BUILD_ONLY -eq 1 ]]; then
          ok "Build-only mode: no activation"
        else
          info "Switching system…"
          run "''${CMD_SWITCH_SYSTEM[@]}"; ok "System activated"

          info "Switching home…"
          run "''${CMD_SWITCH_HOME[@]}"; ok "Home activated"
        fi

        if [[ $RUN_GC -eq 1 ]]; then
          info "Cleaning store with nh…"
          run nh clean $CLEAN_ARGS
          ok "Cleaning complete"
        fi

        if [[ $RUN_OPTIMISE -eq 1 ]]; then
          info "Optimising store…"
          run nix store optimise || warn "Optimise failed"
          ok "Store optimisation done"
        fi

        echo
        ok "System update complete!"
        echo

        if [[ $IS_DARWIN -eq 1 ]]; then
          echo "Current darwin generation:"
          darwin-rebuild --list-generations | tail -n 1 || true
          echo "Rollback (darwin): nh darwin switch --rollback"
        else
          echo "Current system generation:"
          sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 1 || true
          echo "Rollback (NixOS): nh os switch --rollback"
        fi

        echo "Current home-manager generation:"
        home-manager generations | head -n 1 || true
        echo "Rollback (home): nh home switch --rollback"
      '';
    })
  ];
}
