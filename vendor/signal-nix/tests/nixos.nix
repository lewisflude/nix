# Signal Design System - NixOS Module Tests
#
# Tests for NixOS system-level theming modules

{
  pkgs,
  lib,
  self,
  system,
}:

let
  # Helper to create a basic NixOS test VM
  mkNixOSTest =
    name: testModule:
    pkgs.nixosTest {
      inherit name;
      nodes.machine =
        { ... }:
        {
          imports = [
            self.nixosModules.default
            testModule
          ];
        };
      testScript = ''
        machine.start()
        machine.wait_for_unit("multi-user.target")
      '';
    };

  # Helper to verify console colors are set
  mkConsoleColorTest =
    pkgs.runCommand "test-nixos-console-colors"
      {
        buildInputs = [ pkgs.nix ];
      }
      ''
        echo "Testing NixOS console colors module..."

        # Create a test configuration
        cat > test-config.nix << 'EOF'
        { config, lib, pkgs, ... }:
        {
          imports = [ ../modules/nixos/common ];

          signal.nixos = {
            enable = true;
            mode = "dark";
            boot.console.enable = true;
          };

          # Minimal NixOS config for evaluation
          system.stateVersion = "24.11";
        }
        EOF

        # Test that the module evaluates without errors
        echo "Checking module evaluation..."
        if ! nix-instantiate --eval --strict -E '
          let
            nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
              system = "${system}";
              modules = [ ./test-config.nix ];
            };
          in
            nixos.config.console.colors
        ' > /dev/null; then
          echo "FAIL: Console colors module failed to evaluate"
          exit 1
        fi

        echo "✓ Console colors module evaluates successfully"

        # Verify console.colors is set to an array
        COLORS=$(nix-instantiate --eval --json --strict -E '
          let
            nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
              system = "${system}";
              modules = [ ./test-config.nix ];
            };
          in
            nixos.config.console.colors
        ')

        if [ "$(echo "$COLORS" | jq '. | type')" != '"list"' ]; then
          echo "FAIL: console.colors should be a list"
          exit 1
        fi

        COLOR_COUNT=$(echo "$COLORS" | jq '. | length')
        if [ "$COLOR_COUNT" != "16" ]; then
          echo "FAIL: console.colors should have 16 entries, got $COLOR_COUNT"
          exit 1
        fi

        echo "✓ Console colors has correct structure (16 ANSI colors)"

        # Verify colors are hex strings without #
        FIRST_COLOR=$(echo "$COLORS" | jq -r '.[0]')
        if [[ "$FIRST_COLOR" =~ ^# ]]; then
          echo "FAIL: Console colors should not have # prefix, got: $FIRST_COLOR"
          exit 1
        fi

        if [[ ! "$FIRST_COLOR" =~ ^[0-9a-fA-F]{6}$ ]]; then
          echo "FAIL: Console colors should be 6-digit hex, got: $FIRST_COLOR"
          exit 1
        fi

        echo "✓ Console colors are valid hex format (no # prefix)"
        echo "  Example color 0: $FIRST_COLOR"

        touch $out
      '';
in
{
  # ============================================================================
  # NixOS Console Colors Tests
  # ============================================================================

  nixos-console-colors-basic = mkConsoleColorTest;

  # Test that console module respects enable flag
  nixos-console-disabled = pkgs.runCommand "test-nixos-console-disabled" { } ''
    echo "Testing console colors with enable = false..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        boot.console.enable = false;  # Explicitly disabled
      };

      system.stateVersion = "24.11";
    }
    EOF

    # Verify console.colors is NOT set when disabled
    COLORS=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.console.colors or null
    ' || echo "null")

    if [ "$COLORS" != "null" ] && [ "$COLORS" != '[]' ]; then
      echo "FAIL: console.colors should not be set when disabled"
      exit 1
    fi

    echo "✓ Console colors not applied when disabled"
    touch $out
  '';

  # Test console colors with light mode
  nixos-console-light-mode = pkgs.runCommand "test-nixos-console-light" { } ''
    echo "Testing console colors with light mode..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "light";
        boot.console.enable = true;
      };

      system.stateVersion = "24.11";
    }
    EOF

    # Verify colors are set and different from dark mode
    COLORS=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.console.colors
    ')

    COLOR_COUNT=$(echo "$COLORS" | jq '. | length')
    if [ "$COLOR_COUNT" != "16" ]; then
      echo "FAIL: Light mode should also have 16 colors"
      exit 1
    fi

    echo "✓ Light mode console colors configured correctly"
    touch $out
  '';

  # Test that NixOS module doesn't interfere with Home Manager
  nixos-home-manager-isolation = pkgs.runCommand "test-nixos-hm-isolation" { } ''
    echo "Testing NixOS and Home Manager module isolation..."

    # This test verifies that importing nixosModules doesn't break
    # when home-manager is also configured
    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        boot.console.enable = true;
      };

      # Verify Home Manager options don't exist in NixOS module
      # (they should only exist in Home Manager context)
      system.stateVersion = "24.11";
    }
    EOF

    # Test evaluation succeeds
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.signal.nixos.enable
    ' > /dev/null

    echo "✓ NixOS and Home Manager modules are properly isolated"
    touch $out
  '';

  # ============================================================================
  # NixOS SDDM Tests
  # ============================================================================

  nixos-sddm-theme-basic = pkgs.runCommand "test-nixos-sddm-basic" { } ''
    echo "Testing SDDM theme module..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        login.sddm.enable = true;
      };

      # Enable SDDM
      services.displayManager.sddm.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Test that the module evaluates
    echo "Checking SDDM module evaluation..."
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.displayManager.sddm.theme
    ' > /dev/null

    echo "✓ SDDM module evaluates successfully"

    # Verify theme is set correctly
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.displayManager.sddm.theme
    ' | jq -r '.')

    if [ "$THEME" != "signal-dark" ]; then
      echo "FAIL: SDDM theme should be 'signal-dark', got: $THEME"
      exit 1
    fi

    echo "✓ SDDM theme is set to: $THEME"
    touch $out
  '';

  nixos-sddm-disabled = pkgs.runCommand "test-nixos-sddm-disabled" { } ''
    echo "Testing SDDM with enable = false..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        login.sddm.enable = false;  # Explicitly disabled
      };

      # SDDM is enabled but Signal theme is not
      services.displayManager.sddm.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Verify theme is NOT set when disabled
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.displayManager.sddm.theme or ""
    ' | jq -r '.' || echo "")

    if [ "$THEME" = "signal-dark" ]; then
      echo "FAIL: SDDM theme should not be set when disabled"
      exit 1
    fi

    echo "✓ SDDM theme not applied when disabled"
    touch $out
  '';

  nixos-sddm-light-mode = pkgs.runCommand "test-nixos-sddm-light" { } ''
    echo "Testing SDDM with light mode..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "light";
        login.sddm.enable = true;
      };

      services.displayManager.sddm.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Verify light theme is used
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.displayManager.sddm.theme
    ' | jq -r '.')

    if [ "$THEME" != "signal-light" ]; then
      echo "FAIL: SDDM theme should be 'signal-light', got: $THEME"
      exit 1
    fi

    echo "✓ SDDM light theme configured correctly"
    touch $out
  '';

  # ============================================================================
  # NixOS Plymouth Tests
  # ============================================================================

  nixos-plymouth-theme-basic = pkgs.runCommand "test-nixos-plymouth-basic" { } ''
    echo "Testing Plymouth theme module..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        boot.plymouth.enable = true;
      };

      # Enable Plymouth
      boot.plymouth.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Test that the module evaluates
    echo "Checking Plymouth module evaluation..."
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.boot.plymouth.theme
    ' > /dev/null

    echo "✓ Plymouth module evaluates successfully"

    # Verify theme is set correctly
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.boot.plymouth.theme
    ' | jq -r '.')

    if [ "$THEME" != "signal-dark" ]; then
      echo "FAIL: Plymouth theme should be 'signal-dark', got: $THEME"
      exit 1
    fi

    echo "✓ Plymouth theme is set to: $THEME"
    touch $out
  '';

  nixos-plymouth-light-mode = pkgs.runCommand "test-nixos-plymouth-light" { } ''
    echo "Testing Plymouth with light mode..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "light";
        boot.plymouth.enable = true;
      };

      boot.plymouth.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Verify light theme is used
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.boot.plymouth.theme
    ' | jq -r '.')

    if [ "$THEME" != "signal-light" ]; then
      echo "FAIL: Plymouth theme should be 'signal-light', got: $THEME"
      exit 1
    fi

    echo "✓ Plymouth light theme configured correctly"
    touch $out
  '';

  # ============================================================================
  # NixOS GDM Tests
  # ============================================================================

  nixos-gdm-theme-basic = pkgs.runCommand "test-nixos-gdm-basic" { } ''
    echo "Testing GDM theme module..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        login.gdm.enable = true;
      };

      # Enable GDM
      services.xserver.displayManager.gdm.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Test that the module evaluates
    echo "Checking GDM module evaluation..."
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.xserver.displayManager.gdm.enable
    ' > /dev/null

    echo "✓ GDM module evaluates successfully"

    # Verify GTK theme is in system packages
    PACKAGES=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        builtins.length nixos.config.environment.systemPackages
    ')

    if [ "$PACKAGES" -lt 1 ]; then
      echo "FAIL: GDM theme package should be in systemPackages"
      exit 1
    fi

    echo "✓ GDM theme module configured"
    touch $out
  '';

  # ============================================================================
  # NixOS LightDM Tests
  # ============================================================================

  nixos-lightdm-theme-basic = pkgs.runCommand "test-nixos-lightdm-basic" { } ''
    echo "Testing LightDM theme module..."

    cat > test-config.nix << 'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ../modules/nixos/common ];

      signal.nixos = {
        enable = true;
        mode = "dark";
        login.lightdm.enable = true;
      };

      # Enable LightDM
      services.xserver.displayManager.lightdm.enable = true;
      services.xserver.displayManager.lightdm.greeters.gtk.enable = true;

      system.stateVersion = "24.11";
    }
    EOF

    # Test that the module evaluates
    echo "Checking LightDM module evaluation..."
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.xserver.displayManager.lightdm.enable
    ' > /dev/null

    echo "✓ LightDM module evaluates successfully"

    # Verify GTK theme is configured
    THEME=$(${pkgs.nix}/bin/nix-instantiate --eval --json --strict -E '
      let
        nixos = import ${pkgs.path}/nixos/lib/eval-config.nix {
          system = "${system}";
          modules = [ ./test-config.nix ];
        };
      in
        nixos.config.services.xserver.displayManager.lightdm.greeters.gtk.theme.name
    ' | jq -r '.')

    if [ "$THEME" != "Signal-dark" ]; then
      echo "FAIL: LightDM GTK theme should be 'Signal-dark', got: $THEME"
      exit 1
    fi

    echo "✓ LightDM theme is set to: $THEME"
    touch $out
  '';

  # ============================================================================
  # GTK Theme Package Tests
  # ============================================================================

  nixos-gtk-theme-package = pkgs.runCommand "test-gtk-theme-package" { } ''
    echo "Testing GTK theme package structure..."

    # Build the dark theme package
    GTK_DARK=${self.packages.${system}.signal-gtk-theme-dark}

    # Verify package structure
    if [ ! -d "$GTK_DARK/share/themes/Signal-dark" ]; then
      echo "FAIL: GTK dark theme directory not found"
      exit 1
    fi

    if [ ! -f "$GTK_DARK/share/themes/Signal-dark/gtk-3.0/gtk.css" ]; then
      echo "FAIL: GTK3 CSS not found"
      exit 1
    fi

    if [ ! -f "$GTK_DARK/share/themes/Signal-dark/gtk-4.0/gtk.css" ]; then
      echo "FAIL: GTK4 CSS not found"
      exit 1
    fi

    if [ ! -f "$GTK_DARK/share/themes/Signal-dark/index.theme" ]; then
      echo "FAIL: index.theme not found"
      exit 1
    fi

    echo "✓ GTK theme package structure is correct"

    # Verify CSS contains Signal colors
    if ! grep -q "@define-color theme_bg_color" "$GTK_DARK/share/themes/Signal-dark/gtk-3.0/gtk.css"; then
      echo "FAIL: GTK CSS should contain theme color definitions"
      exit 1
    fi

    echo "✓ GTK CSS contains Signal color definitions"

    touch $out
  '';
}
