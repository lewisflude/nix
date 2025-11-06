{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.features.gaming;

  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.lists) optionals;
in
{

  options.features.gaming = {

    enable = mkEnableOption "gaming support" // {
      description = ''
        Enable gaming features including Steam, game launchers,
        performance optimizations, and GPU driver enhancements.
      '';
    };

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

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional gaming-related packages to install";
      example = lib.literalExpression "[ pkgs.dolphin-emu pkgs.pcsx2 ]";
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      with pkgs;
      [

        protonup-qt
        wine
        winetricks
      ]

      ++ optionals cfg.steam [
        steam
        steam-run
      ]
      ++ optionals cfg.lutris [ lutris ]
      ++ optionals cfg.gamemode [ gamemode ]
      ++ optionals cfg.mangohud [ mangohud ]

      ++ cfg.extraPackages;

    programs.steam = mkIf cfg.steam {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

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

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

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

    networking.firewall = {

      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };

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
