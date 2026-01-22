# Powerlevel10k Configuration - The Nix Way
# Declarative prompt configuration using Nix expressions
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.powerlevel10k;

  # Color palette - single source of truth
  colors = {
    # Status colors
    success = 76;
    warning = 178;
    error = 160;
    info = 37;

    # Greys
    grey_light = 250;
    grey_mid = 244;
    grey_dark = 240;

    # Directory colors
    dir_default = 31;
    dir_shortened = 103;
    dir_anchor = 39;

    # VCS colors
    vcs_clean = 76;
    vcs_modified = 178;
    vcs_untracked = 39;
    vcs_conflicted = 196;

    # Context colors
    context_root = 178;
    context_remote = 180;
    context_default = 180;

    # Shell indicators
    nix_shell = 74;
    direnv = 178;
  };

  # Generate POWERLEVEL9K variable assignments
  mkP9kVar = name: value: "typeset -g POWERLEVEL9K_${name}=${toString value}";

  # Generate array variable (for prompt elements)
  mkP9kArray = name: values: "typeset -g POWERLEVEL9K_${name}=(${lib.concatStringsSep " " values})";

  # Core configuration as Nix expressions
  coreConfig = ''
    # ═══════════════════════════════════════════════════════
    # Powerlevel10k Configuration (Nix-managed)
    # ═══════════════════════════════════════════════════════

    # Prompt segments
    ${mkP9kArray "LEFT_PROMPT_ELEMENTS" cfg.segments.left}
    ${mkP9kArray "RIGHT_PROMPT_ELEMENTS" cfg.segments.right}

    # Core settings
    ${mkP9kVar "MODE" "'nerdfont-v3'"}
    ${mkP9kVar "ICON_PADDING" "none"}
    ${mkP9kVar "PROMPT_ADD_NEWLINE" "false"}
    ${mkP9kVar "TRANSIENT_PROMPT" "'${cfg.transientPrompt}'"}
    ${mkP9kVar "INSTANT_PROMPT" "'${cfg.instantPrompt}'"}
    ${mkP9kVar "DISABLE_HOT_RELOAD" "true"}

    # Background color
    ${mkP9kVar "BACKGROUND" (toString colors.grey_dark)}

    # Separators
    ${mkP9kVar "LEFT_SUBSEGMENT_SEPARATOR" "'%${toString colors.grey_light}F\\uE0B1'"}
    ${mkP9kVar "RIGHT_SUBSEGMENT_SEPARATOR" "'%${toString colors.grey_light}F\\uE0B3'"}
    ${mkP9kVar "LEFT_SEGMENT_SEPARATOR" "'\\uE0B0'"}
    ${mkP9kVar "RIGHT_SEGMENT_SEPARATOR" "'\\uE0B2'"}
    ${mkP9kVar "LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL" "''"}
    ${mkP9kVar "RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL" "''"}

    # Directory configuration
    ${mkP9kVar "DIR_FOREGROUND" (toString colors.dir_default)}
    ${mkP9kVar "DIR_SHORTENED_FOREGROUND" (toString colors.dir_shortened)}
    ${mkP9kVar "DIR_ANCHOR_FOREGROUND" (toString colors.dir_anchor)}
    ${mkP9kVar "DIR_ANCHOR_BOLD" "true"}
    ${mkP9kVar "SHORTEN_STRATEGY" "truncate_to_unique"}
    ${mkP9kVar "SHORTEN_DELIMITER" "''"}
    ${mkP9kVar "DIR_MAX_LENGTH" "80"}
    ${mkP9kVar "DIR_MIN_COMMAND_COLUMNS" "40"}
    ${mkP9kVar "DIR_SHOW_WRITABLE" "v3"}

    # VCS (Git) configuration
    ${mkP9kVar "VCS_BRANCH_ICON" "''"}
    ${mkP9kVar "VCS_UNTRACKED_ICON" "'?'"}
    ${mkP9kVar "VCS_CLEAN_FOREGROUND" (toString colors.vcs_clean)}
    ${mkP9kVar "VCS_UNTRACKED_FOREGROUND" (toString colors.vcs_untracked)}
    ${mkP9kVar "VCS_MODIFIED_FOREGROUND" (toString colors.vcs_modified)}
    ${mkP9kVar "VCS_VISUAL_IDENTIFIER_COLOR" (toString colors.vcs_clean)}
    ${mkP9kVar "VCS_LOADING_VISUAL_IDENTIFIER_COLOR" (toString colors.grey_mid)}
    ${mkP9kArray "VCS_BACKENDS" [ "git" ]}
    ${mkP9kVar "VCS_DISABLED_WORKDIR_PATTERN" "'~'"}

    # VCS performance tuning (critical for large repositories)
    ${mkP9kVar "VCS_MAX_INDEX_SIZE_DIRTY" "4096"}
    ${mkP9kVar "VCS_STAGED_MAX_NUM" "100"}
    ${mkP9kVar "VCS_UNSTAGED_MAX_NUM" "100"}
    ${mkP9kVar "VCS_UNTRACKED_MAX_NUM" "100"}
    ${mkP9kVar "VCS_MAX_SYNC_LATENCY_SECONDS" "0.05"}
    ${mkP9kVar "VCS_RECURSE_UNTRACKED_DIRS" "false"}

    # Status segment
    ${mkP9kVar "STATUS_EXTENDED_STATES" "true"}
    ${mkP9kVar "STATUS_OK" "true"}
    ${mkP9kVar "STATUS_OK_FOREGROUND" (toString colors.success)}
    ${mkP9kVar "STATUS_OK_VISUAL_IDENTIFIER_EXPANSION" "'✓'"}
    ${mkP9kVar "STATUS_ERROR" "true"}
    ${mkP9kVar "STATUS_ERROR_FOREGROUND" (toString colors.error)}
    ${mkP9kVar "STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION" "'✗'"}

    # Command execution time
    ${mkP9kVar "COMMAND_EXECUTION_TIME_THRESHOLD" "5"}
    ${mkP9kVar "COMMAND_EXECUTION_TIME_PRECISION" "0"}
    ${mkP9kVar "COMMAND_EXECUTION_TIME_FOREGROUND" "248"}
    ${mkP9kVar "COMMAND_EXECUTION_TIME_FORMAT" "'d h m s'"}
    ${mkP9kVar "COMMAND_EXECUTION_TIME_VISUAL_IDENTIFIER_EXPANSION" "''"}

    # Background jobs
    ${mkP9kVar "BACKGROUND_JOBS_VERBOSE" "false"}
    ${mkP9kVar "BACKGROUND_JOBS_FOREGROUND" (toString colors.info)}

    # Direnv
    ${mkP9kVar "DIRENV_FOREGROUND" (toString colors.direnv)}

    # Nix shell
    ${mkP9kVar "NIX_SHELL_FOREGROUND" (toString colors.nix_shell)}

    # Context (user@host)
    ${mkP9kVar "CONTEXT_ROOT_FOREGROUND" (toString colors.context_root)}
    ${mkP9kVar "CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND" (toString colors.context_remote)}
    ${mkP9kVar "CONTEXT_FOREGROUND" (toString colors.context_default)}
    ${mkP9kVar "CONTEXT_ROOT_TEMPLATE" "'%B%n@%m'"}
    ${mkP9kVar "CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE" "'%n@%m'"}
    ${mkP9kVar "CONTEXT_TEMPLATE" "'%n@%m'"}
    # Hide context unless in SSH or root
    ${mkP9kVar "CONTEXT_{DEFAULT,SUDO}_{CONTENT,VISUAL_IDENTIFIER}_EXPANSION" "''"}

    # Disable configuration wizard (config managed by Nix)
    ${mkP9kVar "DISABLE_CONFIGURATION_WIZARD" "true"}

    # Terminal-specific optimizations
    # kitty >= 0.24.0: Prevents prompt corruption on resize
    if [[ "$TERM" == "xterm-kitty" ]]; then
      typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=true
    fi

    # Fix right prompt spacing (P10k respects ZLE_RPROMPT_INDENT, P9k doesn't)
    typeset -g ZLE_RPROMPT_INDENT=0

    ${cfg.extraConfig}
  '';
in
{
  options.programs.powerlevel10k = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Powerlevel10k ZSH theme";
    };

    segments = {
      left = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "dir"
          "vcs"
        ];
        description = "Segments shown on the left side of the prompt";
        example = [
          "os_icon"
          "dir"
          "vcs"
          "prompt_char"
        ];
      };

      right = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "status"
          "command_execution_time"
          "background_jobs"
          "direnv"
          "nix_shell"
          "context"
        ];
        description = "Segments shown on the right side of the prompt";
        example = [
          "status"
          "time"
          "context"
        ];
      };
    };

    transientPrompt = lib.mkOption {
      type = lib.types.enum [
        "off"
        "always"
        "same-dir"
      ];
      default = "always";
      description = ''
        Transient prompt behavior. When enabled, previous prompts are
        trimmed down after command execution to save screen space.
      '';
    };

    instantPrompt = lib.mkOption {
      type = lib.types.enum [
        "off"
        "quiet"
        "verbose"
      ];
      default = "quiet";
      description = ''
        Instant prompt mode. Shows prompt before ZSH finishes loading.
        Set to "quiet" to suppress warnings from direnv/devenv.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = ''
                # ═══════════════════════════════════════════════════════════════
                # Background Processes (Expected Behavior)
                # ═══════════════════════════════════════════════════════════════
                #
                # Powerlevel10k spawns background processes for performance:
                #   - gitstatusd: Git status computation (one per repo)
                #   - zsh workers: Async prompt segment computation
                #
                # These processes:
                #   - Are NOT shared between shells (security)
                #   - Terminate automatically when parent shell exits
                #   - Use minimal resources (typically <1% CPU, <10MB RAM)
                #
                # To check: ps aux | grep -E 'gitstatusd|zsh.*p10k'
                #
                # This is NORMAL and EXPECTED behavior for fast prompt rendering.

                # ═══════════════════════════════════════════════════════════════
                # Configuration Wizard Override
                # ═══════════════════════════════════════════════════════════════
                #
                # Prevent 'p10k configure' from creating ~/.p10k.zsh which would
                # conflict with Nix-managed configuration.

                function p10k() {
                  if [[ "$1" == "configure" ]]; then
                    cat >&2 <<'EOF'
        ╔════════════════════════════════════════════════════════════════╗
        ║ Powerlevel10k Configuration Managed by Nix                     ║
        ╚════════════════════════════════════════════════════════════════╝

        Your Powerlevel10k configuration is managed declaratively via:
          ~/.config/nix/home/common/apps/powerlevel10k.nix

        To modify prompt:
          1. Edit the Nix configuration
          2. Run: nh os switch
          3. Restart shell: exec zsh

        Running 'p10k configure' would create ~/.p10k.zsh which will be
        ignored by your Nix configuration.

        Available commands:
          p10k reload              - Reload current configuration
          p10k segment -h          - Custom segment help
          p10k-show-config         - Show current settings
          p10k-validate-instant    - Validate instant prompt
          zsh-bench-startup        - Benchmark shell startup

        EOF
                    return 1
                  fi

                  # Pass through other p10k commands
                  command p10k "$@"
                }
      '';
      description = ''
        Additional Powerlevel10k configuration as shell code.
        This is an escape hatch for advanced customization.
        Variables should be set using typeset -g POWERLEVEL9K_*.
      '';
      example = ''
        # Custom git formatter
        typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096

        # Custom colors
        typeset -g POWERLEVEL9K_DIR_FOREGROUND=45
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure Powerlevel10k is available
    home.packages = [ pkgs.zsh-powerlevel10k ];

    # Pre-compile Zsh scripts for faster loading (5-15ms improvement per script)
    home.activation.compileZshScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.zsh}/bin/zsh -c '
        for script in \
          ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme \
          ${config.home.homeDirectory}/.config/zsh/zoxide-init.zsh \
          ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        do
          if [[ -f "$script" && (! -f "$script.zwc" || "$script" -nt "$script.zwc") ]]; then
            ${pkgs.zsh}/bin/zshcompile "$script" 2>/dev/null || true
          fi
        done
      '
    '';

    programs.zsh = {
      # Initialize instant prompt (before anything else)
      # Using lib.mkOrder 550 to run before completion init
      initContent = lib.mkOrder 550 ''
        # Powerlevel10k instant prompt initialization
        if [[ -o interactive && -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        ${coreConfig}

        # Load Powerlevel10k theme with error handling
        if [[ -o interactive ]]; then
          if [[ -f ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme ]]; then
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            
            # Reload if p10k is already loaded
            (( ! $+functions[p10k] )) || p10k reload
          else
            # Fallback: basic prompt if P10k fails to load
            print -P "%F{red}Warning: Powerlevel10k failed to load%f" >&2
            PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f %# '
          fi
        fi
      '';
    };
  };
}
