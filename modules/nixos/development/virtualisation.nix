{
  pkgs,
  lib,
  system,
  config,
  username,
  virtualisation ? {},
  ...
}: let
  platformLib = import ../../../lib/functions.nix {inherit lib system;};
  virtualisationLib = import ../../../lib/virtualisation.nix {inherit lib;};
  hostDockerDefault = platformLib.getVirtualisationFlag {
    modulesVirtualisation = {};
    inherit virtualisation;
    flagName = "enableDocker";
    default = true;
  };
  hostPodmanDefault = platformLib.getVirtualisationFlag {
    modulesVirtualisation = {};
    inherit virtualisation;
    flagName = "enablePodman";
    default = true;
  };
  cfg = config.modules.virtualisation;
  dockerEnabled = cfg.enableDocker;
  podmanEnabled = cfg.enablePodman;
  containersEnabled = dockerEnabled || podmanEnabled;
  enabledStacks = lib.filterAttrs (_: stack: stack.enable) cfg.stacks;
  stackList = lib.attrValues enabledStacks;
  stackUnits =
    lib.mapAttrs'
    (
      name: stack: let
        inherit (stack) composeFile;
        usingPodman = stack.usePodman && podmanEnabled;
        execBinary =
          if usingPodman
          then "${pkgs.podman}/bin/podman"
          else "${pkgs.docker}/bin/docker";
        composeCmd = "${execBinary} compose -f ${composeFile}";
        requiredService =
          if usingPodman
          then "podman.service"
          else "docker.service";
      in {
        name = "docker-compose-${name}";
        value = {
          description = "Compose stack ${name}";
          wantedBy = ["multi-user.target"];
          after = [requiredService];
          requires = [requiredService];
          serviceConfig = {
            Type = "oneshot";
            WorkingDirectory = stack.path;
            ExecStart = composeCmd + " up -d";
            ExecStop = composeCmd + " down";
            RemainAfterExit = true;
          };
        };
      }
    )
    enabledStacks;
  modulesVirtualisationArgs = virtualisationLib.mkModulesVirtualisationArgs {
    hostVirtualisation = virtualisation;
    overrides = {
      enableDocker = dockerEnabled;
      enablePodman = podmanEnabled;
    };
  };
in {
  options.modules.virtualisation = {
    enableDocker = lib.mkOption {
      type = lib.types.bool;
      default = hostDockerDefault;
      description = ''Enable Docker daemon and related tooling.'';
    };
    enablePodman = lib.mkOption {
      type = lib.types.bool;
      default = hostPodmanDefault;
      description = ''Enable Podman and use it as the oci-containers backend.'';
    };
    stacks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          enable = lib.mkEnableOption ''Manage the stack via systemd'' // {default = true;};
          path = lib.mkOption {
            type = lib.types.str;
            description = ''Filesystem location of the compose project.'';
          };
          composeFile = lib.mkOption {
            type = lib.types.str;
            default = "docker-compose.yml";
            description = ''Compose file relative to the stack path.'';
          };
          usePodman = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''Run the stack with podman compose instead of Docker.'';
          };
        };
      }));
      default = {};
      description = ''Managed container stacks launched via systemd.'';
    };
  };
  config = lib.mkMerge [
    (lib.mkIf containersEnabled {
      networking.nat = {
        enable = true;
        internalInterfaces = ["ve-+"];
        externalInterface = "ens3";
        enableIPv6 = true;
      };
      virtualisation.oci-containers.backend = lib.mkDefault (
        if podmanEnabled
        then "podman"
        else "docker"
      );
    })
    (lib.mkIf podmanEnabled {
      virtualisation.podman = {
        enable = lib.mkDefault true;
        dockerCompat = lib.mkDefault false;
        defaultNetwork.settings.dns_enabled = lib.mkDefault true;
      };
    })
    (lib.mkIf dockerEnabled {
      virtualisation.docker = {
        package = lib.mkDefault pkgs.docker_28;
        enable = lib.mkDefault true;
        enableOnBoot = lib.mkDefault true;
        storageDriver = lib.mkDefault "overlay2";
        daemon = {
          settings = {
            experimental = lib.mkDefault true;
            "log-driver" = lib.mkDefault "journald";
            "registry-mirrors" = lib.mkDefault ["https://mirror.gcr.io"];
          };
        };
      };
      users.users.${username}.extraGroups = lib.mkAfter ["docker"];
      systemd.tmpfiles.rules = lib.mkAfter (
        ["d /opt/stacks 0755 root root -"]
        ++ map (stack: "d ${stack.path} 0755 root root -") stackList
      );
    })
    (lib.mkIf (stackList != []) {
      systemd.services = lib.mapAttrs (_name: unit: unit) stackUnits;
    })
    {
      home-manager.extraSpecialArgs.modulesVirtualisation = modulesVirtualisationArgs;
    }
  ];
}
