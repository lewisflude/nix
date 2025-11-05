# Example: Gaming Feature Module
# This is a complete example of a well-structured feature module.
# Copy this as a template for creating new features.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Feature configuration shorthand
  cfg = config.features.gaming;

  # Import commonly used lib functions
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.lists) optionals;
in {
  # ============================================================================
  # OPTIONS DEFINITION
  # ============================================================================

  options.features.gaming = {
    # Main feature toggle
    enable =
      mkEnableOption "gaming support"
      // {
        description = ''
          Enable gaming features including Steam, game launchers,
          performance optimizations, and GPU driver enhancements.
        '';
      };

    # Sub-features with sensible defaults
    steam = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Steam gaming platform";
    };

    lutris = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Lutris game manager";
    };

    gamemode = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GameMode for performance optimization";
    };

    mangohud = mkOption {
      type = types.bool;
      default = true;
      description = "Enable MangoHud performance overlay";
    };

    # Advanced options
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional gaming-related packages to install";
      example = lib.literalExpression "[ pkgs.dolphin-emu pkgs.pcsx2 ]";
    };
  };

  # ============================================================================
  # CONFIGURATION IMPLEMENTATION
  # ============================================================================

  config = mkIf cfg.enable {
    # ------------------------------------------------------------------------
    # System Packages
    # ------------------------------------------------------------------------

    environment.systemPackages = with pkgs;
      [
        # Always include these when gaming is enabled
        protonup-qt
        wine
        winetricks
      ]
      # Conditional packages based on sub-features
      ++ optionals cfg.steam [
        steam
        steam-run
      ]
      ++ optionals cfg.lutris [lutris]
      ++ optionals cfg.gamemode [gamemode]
      ++ optionals cfg.mangohud [mangohud]
      # User-specified extra packages
      ++ cfg.extraPackages;

    # ------------------------------------------------------------------------
    # Steam Configuration
    # ------------------------------------------------------------------------

    programs.steam = mkIf cfg.steam {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    # ------------------------------------------------------------------------
    # GameMode Configuration
    # ------------------------------------------------------------------------

    programs.gamemode = mkIf cfg.gamemode {
      enable = true;
      settings = {
        general = {
          renice = 10;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };

    # ------------------------------------------------------------------------
    # Graphics Drivers & OpenGL
    # ------------------------------------------------------------------------

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true; # For 32-bit games
    };

    # ------------------------------------------------------------------------
    # Kernel & System Optimizations
    # ------------------------------------------------------------------------

    # Enable realtime priority for gaming processes
    security.pam.loginLimits = [
      {
        domain = "@users";
        type = "soft";
        item = "nice";
        value = "-20";
      }
      {
        domain = "@users";
        type = "hard";
        item = "nice";
        value = "-20";
      }
    ];

    # ------------------------------------------------------------------------
    # Networking (for multiplayer)
    # ------------------------------------------------------------------------

    networking.firewall = {
      # Common gaming ports (can be customized per game)
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };

    # ------------------------------------------------------------------------
    # Assertions & Warnings
    # ------------------------------------------------------------------------

    assertions = [
      {
        assertion = config.hardware.opengl.enable;
        message = "Gaming feature requires OpenGL to be enabled";
      }
    ];

    warnings = lib.optionals (!cfg.mangohud && cfg.gamemode) [
      "GameMode is enabled without MangoHud - consider enabling MangoHud for performance monitoring"
    ];
  };
}
