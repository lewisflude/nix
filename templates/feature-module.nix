{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.FEATURE_NAME;
in
{

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.enable -> (config.host.features.REQUIRED_FEATURE.enable or false);
        message = "FEATURE_NAME requires REQUIRED_FEATURE to be enabled. Set host.features.REQUIRED_FEATURE.enable = true;";
      }

    ];

    environment.systemPackages =
      with pkgs;
      optionals pkgs.stdenv.isLinux [

      ]
      ++ optionals pkgs.stdenv.isDarwin [

      ]
      ++ optionals cfg.OPTIONAL_FLAG [

      ];

    systemd.services = mkIf pkgs.stdenv.isLinux {
      example-service = {
        description = "Example service for FEATURE_NAME";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.example}/bin/example-daemon";
          Restart = "on-failure";

        };
      };
    };

    users.users.${config.host.username}.extraGroups = optional cfg.enable "example-group";

    home-manager.users.${config.host.username} = {

      programs.example = {
        enable = true;

      };

      home.packages = with pkgs; [

      ];
    };

  };
}
