{
  inputs,
  hosts,
}: let
  inherit (inputs) nixpkgs pre-commit-hooks home-manager;
  virtualisationLib = import ./virtualisation.nix {inherit (nixpkgs) lib;};
  systems = builtins.attrValues (builtins.mapAttrs (_name: host: host.system) hosts);
in {
  mkFormatters = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.alejandra);
  mkChecks = nixpkgs.lib.genAttrs systems (system: {
    pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        deadnix.enable = true;
        statix.enable = true;
      };
    };

    # nixosTests-mcp = import ../tests/integration/mcp.nix {
    #   inherit pkgs;
    #   lib = nixpkgs.lib;
    #   inputs = inputs;
    # };
  });
  mkDevShells = let
    hostsBySystem = nixpkgs.lib.groupBy (hostConfig: hostConfig.system) (builtins.attrValues hosts);
  in
    builtins.mapAttrs (
      system: _hostGroup: let
        pkgs = nixpkgs.legacyPackages.${system};
        shellsConfig = import ../shells {
          inherit pkgs;
          inherit (pkgs) lib;
          inherit system;
        };
        preCommitCheck = inputs.self.checks.${system}.pre-commit-check or {};
      in
        shellsConfig.devShells
        // {
          default = pkgs.mkShell {
            shellHook = preCommitCheck.shellHook or "";
            buildInputs =
              (preCommitCheck.enabledPackages or [])
              ++ (with pkgs; [
                jq
                yq
                git
                gh
                direnv
                nix-direnv
              ]);
          };
        }
    )
    hostsBySystem;
  mkHomeConfigurations =
    builtins.mapAttrs (
      _name: hostConfig: let
        pkgs = import nixpkgs {
          inherit (hostConfig) system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = _: true;
            allowUnsupportedSystem = false;
            permittedInsecurePackages = [
              "mbedtls-2.28.10"
            ];
          };
          overlays = nixpkgs.lib.attrValues (
            import ../overlays {
              inherit inputs;
              inherit (hostConfig) system;
            }
          );
        };
      in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs =
            inputs
            // hostConfig
            // {
              host = hostConfig;
              hostSystem = hostConfig.system;
              modulesVirtualisation = virtualisationLib.mkModulesVirtualisationArgs {
                hostVirtualisation = hostConfig.virtualisation or {};
              };
            };
          modules = [
            ../home
            inputs.niri.homeModules.niri
            inputs.sops-nix.homeManagerModules.sops
            inputs.catppuccin.homeModules.catppuccin
            {_module.args = {inherit inputs;};}
          ];
        }
    )
    hosts;

  # Expose runnable apps via `nix run .#<app-name>` per system
  mkApps = let
    hostsBySystem = nixpkgs.lib.groupBy (hostConfig: hostConfig.system) (builtins.attrValues hosts);
  in
    builtins.mapAttrs (
      system: _hostGroup: let
        pkgs = nixpkgs.legacyPackages.${system};

        # This derivation declaratively fetches the VIAL QMK firmware fork
        # (with submodules!) and copies your keymap into it.
        # This is built *once* and stored in the Nix store.
        qmkHomeWithKeymap = pkgs.stdenv.mkDerivation {
          name = "vial-qmk-home-with-mnk88-vial-keymap";

          # Fetch VIAL QMK source (which includes MNK88 support).
          src = pkgs.fetchFromGitHub {
            owner = "vial-kb";
            repo = "vial-qmk";
            # Using the vial branch (latest commit as of 2025)
            rev = "b3c966238bf74850024d5d424c1c078e62780229";
            fetchSubmodules = true; # CRITICAL: This gets all the submodules
            hash = "sha256-tO0MruivFTnm9cU/GBWZO8/xKRytFLvZ2qntlOBZsrY=";
          };

          # We only need to copy sources + our keymap; do not build
          dontConfigure = true;
          dontBuild = true;

          # This build phase just copies the source and adds our keymap
          installPhase = ''
            # Copy the entire QMK source to the output path
            cp -r . $out

            # Define where our keymap files live
            keymapSrcDir="${inputs.self}/docs/reference/qmk/mnk88/vial"
            keymapDestDir="$out/keyboards/kopibeng/mnk88/keymaps/vial"

            # Create the destination and copy our files
            mkdir -p "$keymapDestDir"
            cp "$keymapSrcDir/keymap.c" "$keymapDestDir/keymap.c"
            cp "$keymapSrcDir/rules.mk" "$keymapDestDir/rules.mk"
            cp "$keymapSrcDir/config.h" "$keymapDestDir/config.h"
            cp "$keymapSrcDir/vial.json" "$keymapDestDir/vial.json"
          '';
        };

        # Complete Python env with all QMK dependencies
        pythonEnv = pkgs.python3.withPackages (
          ps:
            with ps; [
              # Core QMK dependencies
              setuptools
              appdirs
              colorama
              dotty-dict
              hjson
              jsonschema
              milc
              pygments
              psutil
              prompt-toolkit
              # Additional dependencies QMK might need
              pyserial
              pyusb
              hid
              pillow
              # Build system dependencies
              pyyaml
              wheel
              # Try to include qmk package if available
              # (ps.qmk or null)
            ]
        );

        flashMnk88 = pkgs.writeShellApplication {
          name = "flash-mnk88";
          runtimeInputs = with pkgs; [
            qmk
            dfu-util
            gcc-arm-embedded
            gnumake
            git
            coreutils
            gnugrep
            findutils
            pythonEnv
          ];
          text = ''
                                    set -euo pipefail

                                    # --- Simplified Argument Parsing ---
                                    KEYMAP_NAME="vial"
                                    MAKE_DEFINES=()
                                    USER_SET_VIAL="no"

                                    # Process arguments
                                    while [ $# -gt 0 ]; do
                                      case "$1" in
                                        -km|--keymap)
                                          KEYMAP_NAME="$2"
                                          shift 2
                                          ;;
                                        -e)
                                          if [[ "''${2:-}" == VIAL_ENABLE* ]]; then
                                            USER_SET_VIAL="yes"
                                          fi
                                          # For GNU Make, collect VAR=VALUE definitions
                                          if [[ "''${2:-}" == *=* ]]; then
                                            MAKE_DEFINES+=("$2")
                                          fi
                                          shift 2
                                          ;;
                                        *)
                                          shift
                                          ;;
                                      esac
                                    done

                                    # Defaults for GNU Make if user didn't provide -e VIAL_ENABLE=...
                                    if [ "$USER_SET_VIAL" = "no" ]; then
                                      MAKE_DEFINES+=("VIAL_ENABLE=yes")
                                    fi

                                    # --- Improved QMK_HOME Setup ---
                                    # Determine QMK_HOME: prefer existing env, then ./qmk_firmware
                                    if [ -n "''${QMK_HOME:-}" ]; then
                                      QMK_HOME_DIR="$QMK_HOME"
                                    elif [ -d "./qmk_firmware" ]; then
                                      QMK_HOME_DIR="$(pwd)/qmk_firmware"
                                    else
                                      # This is the new, faster fallback:
                                      TMPDIR_SETUP="$(mktemp -d)"
                                      QMK_HOME_DIR="$TMPDIR_SETUP/qmk_firmware"
                                      echo "🔧 Setting up QMK environment in $QMK_HOME_DIR"

                          # Copy from our pre-built, read-only store path.
                          # This is local and extremely fast.
                          cp -r "${qmkHomeWithKeymap}/." "$QMK_HOME_DIR"
                          # Make the directory writable so QMK can create build directories
                          chmod -R u+w "$QMK_HOME_DIR"
                          # Initialize as git repo to avoid git errors
                          cd "$QMK_HOME_DIR"
                          git init . >/dev/null 2>&1
                          git config user.email "test@example.com"
                          git config user.name "Test User"
                          git add . >/dev/null 2>&1
                          git commit -m "Initial commit" >/dev/null 2>&1
                          export QMK_HOME="$QMK_HOME_DIR"
                                    fi
                                    export QMK_HOME="$QMK_HOME_DIR"
                                    # Ensure QMK's vendored python modules + our site-packages are importable
                                    export PYTHONNOUSERSITE=1
                                    export PYTHONPATH="$QMK_HOME_DIR/lib/python${"PYTHONPATH:+:$PYTHONPATH"}"
                                    # Force the Python used by Make to be our dependency-rich interpreter
                                    export PYTHON="${pythonEnv}/bin/python3"

                                    # --- No Keymap Installation Needed ---
                                    # The "Keymap Installation" block from your original script
                                    # is no longer needed because the `qmkHomeWithKeymap`
                                    # derivation *already* copied the 'vial' keymap.

                                    echo "Keymap '$KEYMAP_NAME' is ready in $QMK_HOME_DIR."

                         # Debug: Check if the keyboard actually exists
                         if [ -d "$QMK_HOME_DIR/keyboards/kopibeng/mnk88" ]; then
                           echo "✓ Found MNK88 keyboard at keyboards/kopibeng/mnk88"
                           ls -la "$QMK_HOME_DIR/keyboards/kopibeng/mnk88/keymaps/" 2>/dev/null || echo "No keymaps directory found"
                         else
                           echo "✗ MNK88 keyboard NOT found at keyboards/kopibeng/mnk88"
                           echo "Available keyboards under kopibeng:"
                           ls -la "$QMK_HOME_DIR/keyboards/kopibeng/" 2>/dev/null || echo "kopibeng directory not found"
                         fi

                        # Create a tiny shim for QMK_BIN so Makefile's "qmk hello" check succeeds
                        QMK_SHIM="$(mktemp -t qmk-shim.XXXXXX)"
                        cat > "$QMK_SHIM" << 'EOSHIM'
            #!/usr/bin/env bash
            set -euo pipefail
            case "''${1:-}" in
              hello)
                echo "hello";;
              --version|-V)
                echo "qmk-shim 0.0.1";;
            esac
            exit 0
            EOSHIM
                        chmod +x "$QMK_SHIM"

                         echo "🧱 Compiling MNK88 (kopibeng/mnk88) via direct make"

                         # Setup build environment
                         cd "$QMK_HOME_DIR"
                         export PATH="${pythonEnv}/bin:${pkgs.gcc-arm-embedded}/bin:${pkgs.gnumake}/bin:$PATH"
                         export PYTHONPATH="$QMK_HOME_DIR/lib/python''${PYTHONPATH:+:$PYTHONPATH}"
                         export QMK_HOME="$QMK_HOME_DIR"
                         export SKIP_GIT=yes
                         export SKIP_VERSION=yes

                         # Try direct make command for VIAL
                         echo "Attempting direct make build..."
                         make clean kopibeng/mnk88:vial VIAL_ENABLE=yes

                         echo "⚡ Flashing MNK88 (put board in DFU/bootloader mode)"
                         set +e
                         # Try to flash with dfu-util directly
                         FIRMWARE_FILE="$QMK_HOME_DIR/.build/kopibeng_mnk88_vial.bin"
                         if [ ! -f "$FIRMWARE_FILE" ]; then
                           FIRMWARE_FILE="$QMK_HOME_DIR/kopibeng_mnk88_vial.bin"
                         fi
                         if [ ! -f "$FIRMWARE_FILE" ]; then
                           # Try with vial in the name
                           FIRMWARE_FILE="$QMK_HOME_DIR/.build/kopibeng_mnk88_vial_vial.bin"
                         fi

                         if [ -f "$FIRMWARE_FILE" ]; then
                           echo "Found firmware file: $FIRMWARE_FILE"
                           echo "Flashing with dfu-util..."
                           dfu-util -a 0 -s 0x08000000:leave -D "$FIRMWARE_FILE"
                           rc=$?
                         else
                           echo "Firmware file not found. Checking build directory contents:"
                           ls -la "$QMK_HOME_DIR/.build/" 2>/dev/null || echo "No .build directory"
                           # Use glob instead of ls | grep to satisfy shellcheck
                           for f in "$QMK_HOME_DIR"/*.{bin,hex}; do
                             [ -e "$f" ] && echo "Found: $f"
                           done 2>/dev/null || echo "No firmware files in root"
                           rc=1
                         fi
                         if [ $rc -ne 0 ]; then
                           echo "dfu flash failed (rc=$rc). Checking for firmware file..."
                           FIRMWARE_FILE="$QMK_HOME_DIR/.build/kopibeng_mnk88_$KEYMAP_NAME.bin"
                           if [ -f "$FIRMWARE_FILE" ]; then
                             echo "Firmware file found: $FIRMWARE_FILE"
                             echo "Attempting manual DFU flash..."
                             dfu-util -a 0 -s 0x08000000:leave -D "$FIRMWARE_FILE"
                             rc=$?
                           else
                             echo "No firmware file found at $FIRMWARE_FILE"
                             rc=1
                           fi
                         fi
                         set -e
                         exit $rc
          '';
        };
      in {
        flash-mnk88 = {
          type = "app";
          program = "${flashMnk88}/bin/flash-mnk88";
        };
      }
    )
    hostsBySystem;
}
