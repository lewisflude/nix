{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "system-health";
  version = "1.0.0";
  description = "Run comprehensive system diagnostics across journal, services, Nix, D-Bus, and Niri";

  flags = [
    {
      name = "all";
      short = "a";
      bool = true;
      description = "Run all diagnostic categories";
    }
    {
      name = "journal";
      short = "j";
      bool = true;
      description = "Check journal warnings and errors";
    }
    {
      name = "services";
      short = "s";
      bool = true;
      description = "Check for failed systemd services";
    }
    {
      name = "nix_check";
      short = "n";
      bool = true;
      description = "Run Nix flake check and dry build";
    }
    {
      name = "dbus";
      short = "d";
      bool = true;
      description = "Run D-Bus and XDG portal diagnostics";
    }
    {
      name = "niri";
      short = "r";
      bool = true;
      description = "Check Niri compositor runtime state";
    }
    {
      name = "verbose";
      short = "v";
      bool = true;
      description = "Show full output instead of summaries";
    }
  ];

  runtimeInputs = [
    pkgs.systemd
    pkgs.nix
    pkgs.dbus
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gawk
    pkgs.procps
  ];

  script =
    helpers: with helpers; ''
      FLAKE_DIR="${config-root}"
      PASSED=0
      FAILED=0
      WARNINGS=0

      check_pass() { green "  [PASS] $1"; ((PASSED++)) || true; }
      check_fail() { red "  [FAIL] $1"; ((FAILED++)) || true; }
      check_warn() { yellow "  [WARN] $1"; ((WARNINGS++)) || true; }

      # Determine which checks to run
      RUN_JOURNAL=false
      RUN_SERVICES=false
      RUN_NIX=false
      RUN_DBUS=false
      RUN_NIRI=false

      if ${flag "journal"} || ${flag "all"}; then RUN_JOURNAL=true; fi
      if ${flag "services"} || ${flag "all"}; then RUN_SERVICES=true; fi
      if ${flag "nix_check"} || ${flag "all"}; then RUN_NIX=true; fi
      if ${flag "dbus"} || ${flag "all"}; then RUN_DBUS=true; fi
      if ${flag "niri"} || ${flag "all"}; then RUN_NIRI=true; fi

      # If no specific flags, run everything
      if ! $RUN_JOURNAL && ! $RUN_SERVICES && ! $RUN_NIX && ! $RUN_DBUS && ! $RUN_NIRI; then
        RUN_JOURNAL=true
        RUN_SERVICES=true
        RUN_NIX=true
        RUN_DBUS=true
        RUN_NIRI=true
      fi

      blue "System Health Check"
      echo ""

      # ── Category 1: Journal Warnings/Errors ──────────────────────────────
      if $RUN_JOURNAL; then
        blue "Journal Diagnostics"

        USER_WARNS=$(journalctl --user -b -p warning --no-pager -q 2>/dev/null | wc -l)
        if [ "$USER_WARNS" -eq 0 ]; then
          check_pass "No user-session warnings this boot"
        elif [ "$USER_WARNS" -lt 20 ]; then
          check_warn "User session: $USER_WARNS warning(s) this boot"
        else
          check_fail "User session: $USER_WARNS warnings this boot (high count)"
        fi
        if ${flag "verbose"} && [ "$USER_WARNS" -gt 0 ]; then
          echo ""
          journalctl --user -b -p warning --no-pager -q 2>/dev/null | tail -10
          echo ""
        fi

        SYS_ERRS=$(journalctl -b -p err --no-pager -q 2>/dev/null | wc -l)
        if [ "$SYS_ERRS" -eq 0 ]; then
          check_pass "No system errors this boot"
        elif [ "$SYS_ERRS" -lt 10 ]; then
          check_warn "System: $SYS_ERRS error(s) this boot"
        else
          check_fail "System: $SYS_ERRS errors this boot (high count)"
        fi
        if ${flag "verbose"} && [ "$SYS_ERRS" -gt 0 ]; then
          echo ""
          journalctl -b -p err --no-pager -q 2>/dev/null | tail -10
          echo ""
        fi

        echo ""
      fi

      # ── Category 2: Failed Services ──────────────────────────────────────
      if $RUN_SERVICES; then
        blue "Service Health"

        USER_FAILED=$(systemctl --user --failed --no-legend --no-pager 2>/dev/null | grep -c "." || echo "0")
        if [ "$USER_FAILED" -eq 0 ]; then
          check_pass "No failed user services"
        else
          check_fail "$USER_FAILED failed user service(s)"
          systemctl --user --failed --no-pager 2>/dev/null | head -10
        fi

        SYS_FAILED=$(systemctl --failed --no-legend --no-pager 2>/dev/null | grep -c "." || echo "0")
        if [ "$SYS_FAILED" -eq 0 ]; then
          check_pass "No failed system services"
        else
          check_fail "$SYS_FAILED failed system service(s)"
          systemctl --failed --no-pager 2>/dev/null | head -10
        fi

        echo ""
      fi

      # ── Category 3: Nix Build/Eval Checks ───────────────────────────────
      if $RUN_NIX; then
        blue "Nix Configuration"
        cyan "  (this may take a moment...)"

        cd "$FLAKE_DIR" || die "Failed to change to flake directory: $FLAKE_DIR"

        if nix flake check --no-build 2>&1; then
          check_pass "nix flake check passed (eval only)"
        else
          check_fail "nix flake check found issues"
        fi

        HOSTNAME=$(hostname)
        if nix build ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel" --dry-run 2>&1; then
          check_pass "Dry build for $HOSTNAME succeeded"
        else
          check_warn "Dry build for $HOSTNAME had issues (may need network)"
        fi

        echo ""
      fi

      # ── Category 4: D-Bus/Portal Diagnostics ────────────────────────────
      if $RUN_DBUS; then
        blue "D-Bus and XDG Portals"

        if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
          check_pass "D-Bus session bus is available"
        else
          check_fail "DBUS_SESSION_BUS_ADDRESS is not set"
        fi

        if dbus-send --session --dest=org.freedesktop.portal.Desktop \
          --type=method_call --print-reply \
          /org/freedesktop/portal/desktop org.freedesktop.DBus.Properties.Get \
          string:org.freedesktop.portal.FileChooser string:version 2>/dev/null | grep -q "uint32"; then
          check_pass "XDG Desktop Portal is responding"
        else
          check_warn "XDG Desktop Portal not responding (file dialogs may not work)"
        fi

        for portal in org.freedesktop.impl.portal.Screenshot \
                      org.freedesktop.impl.portal.ScreenCast; do
          PORTAL_SHORT=$(echo "$portal" | awk -F. '{print $NF}')
          if dbus-send --session --dest="$portal" \
            --type=method_call --print-reply \
            / org.freedesktop.DBus.Peer.Ping 2>/dev/null; then
            check_pass "Portal: $PORTAL_SHORT is available"
          else
            check_warn "Portal: $PORTAL_SHORT not responding"
          fi
        done

        if pgrep -f "xdg-desktop-portal" >/dev/null 2>&1; then
          PORTAL_PROCS=$(pgrep -af "xdg-desktop-portal" 2>/dev/null | wc -l)
          check_pass "XDG portal processes running ($PORTAL_PROCS)"
        else
          check_fail "No xdg-desktop-portal processes found"
        fi

        echo ""
      fi

      # ── Category 5: Niri Runtime State ───────────────────────────────────
      if $RUN_NIRI; then
        blue "Niri Compositor"

        if ! command -v niri &>/dev/null; then
          check_warn "niri not found in PATH (not in a Niri session?)"
        elif [ -z "''${WAYLAND_DISPLAY:-}" ]; then
          check_warn "WAYLAND_DISPLAY not set (not in a Wayland session?)"
        else
          if OUTPUTS=$(niri msg outputs 2>&1); then
            OUTPUT_COUNT=$(echo "$OUTPUTS" | grep -c "Output" || echo "0")
            check_pass "Niri outputs accessible ($OUTPUT_COUNT output(s))"
            if ${flag "verbose"}; then
              echo ""
              echo "$OUTPUTS"
              echo ""
            fi
          else
            check_fail "niri msg outputs failed (compositor issue?)"
          fi

          if WORKSPACES=$(niri msg workspaces 2>&1); then
            WS_COUNT=$(echo "$WORKSPACES" | grep -c "Workspace" || echo "0")
            check_pass "Niri workspaces accessible ($WS_COUNT workspace(s))"
            if ${flag "verbose"}; then
              echo ""
              echo "$WORKSPACES"
              echo ""
            fi
          else
            check_fail "niri msg workspaces failed"
          fi

          if niri msg focused-window >/dev/null 2>&1; then
            check_pass "Niri IPC is healthy (focused-window responded)"
          else
            check_warn "niri msg focused-window returned no data (may be normal if no window focused)"
          fi
        fi

        echo ""
      fi

      # ── Summary ──────────────────────────────────────────────────────────
      blue "Summary"
      TOTAL=$((PASSED + FAILED + WARNINGS))
      echo "  Total checks: $TOTAL"
      green "  Passed:   $PASSED"
      yellow "  Warnings: $WARNINGS"
      red "  Failed:   $FAILED"
      echo ""

      if [ "$FAILED" -gt 0 ]; then
        red "Some checks failed. Investigate the failures above."
        exit 1
      elif [ "$WARNINGS" -gt 0 ]; then
        yellow "Some warnings detected. System is functional but review recommended."
        exit 0
      else
        green "All checks passed. System is healthy."
        exit 0
      fi
    '';
}
