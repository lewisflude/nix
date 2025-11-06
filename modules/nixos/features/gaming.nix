{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.lists) optionals;
  cfg = config.host.features.gaming;
in
{
  config = mkIf cfg.enable {

    programs.steam = mkIf cfg.steam {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    services.sunshine = mkIf cfg.steam {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    services.udev = mkIf cfg.enable {
      packages = with pkgs; [
        game-devices-udev-rules
      ];
    };

    hardware.uinput.enable = mkIf cfg.enable true;

    boot.kernel.sysctl = mkIf cfg.performance {
      "vm.max_map_count" = 2147483642;
    };

    # Only use cachyos kernel if it's compatible with ZFS
    boot.kernelPackages = mkIf (
      cfg.performance
      && (
        let
          cachyosKernel = pkgs.linuxPackages_cachyos;
          zfsKernelModuleAttr = pkgs.zfs.kernelModuleAttribute;
          # Check if the attribute exists and is compatible
          hasZfsModule = builtins.hasAttr zfsKernelModuleAttr cachyosKernel;
          zfsModuleEval =
            if hasZfsModule then
              builtins.tryEval cachyosKernel.${zfsKernelModuleAttr}
            else
              {
                success = false;
                value = null;
              };
        in
        zfsModuleEval.success && (!(zfsModuleEval.value.meta.broken or false))
      )
    ) (mkForce pkgs.linuxPackages_cachyos);

    chaotic.mesa-git.enable = mkIf cfg.performance true;

    environment.systemPackages =
      with pkgs;
      [

        protonup-qt
        wine
        winetricks
      ]

      ++ optionals cfg.steam [
        steamcmd
        steam-run

        gamescope
      ]

      ++ optionals cfg.performance [
        mangohud
        gamemode
      ]

      ++ optionals cfg.lutris [
        lutris
      ]

      ++ optionals cfg.emulators [

      ];

    programs.gamemode = mkIf cfg.performance {
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

    hardware.graphics = mkIf cfg.enable {
      enable = true;
      enable32Bit = true;
    };

    assertions = [
      {
        assertion = cfg.emulators -> cfg.enable;
        message = "Emulators require gaming feature to be enabled";
      }
    ];
  };
}
