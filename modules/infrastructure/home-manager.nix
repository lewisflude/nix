# Home-manager integration into NixOS and Darwin configurations
# Dendritic pattern: Infrastructure provides ONLY the structure
# ALL module imports (external and feature) happen at host level
{ config, ... }:
let
  # Top-level values from dendritic options
  inherit (config) username useremail constants;
in
{
  # NixOS home-manager base configuration (structure only)
  flake.modules.nixos.homeManagerBase =
    { ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";

        users.${username} =
          { osConfig, ... }:
          {
            # Auto-config: username, homeDirectory, stateVersion
            home.stateVersion = osConfig.system.stateVersion;
            home.username = username;
            home.homeDirectory = "/home/${username}";
            programs.home-manager.enable = true;
            programs.git.settings.user.email = useremail;

            # Disable options.json generation to avoid derivation context warning
            manual.json.enable = false;
          };
      };
    };

  # Darwin home-manager base configuration (structure only)
  flake.modules.darwin.homeManagerBase =
    { lib, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";

        users.${username} =
          { ... }:
          {
            # Auto-config: username, homeDirectory, stateVersion
            home.stateVersion = constants.defaults.stateVersion;
            home.username = lib.mkDefault username;
            home.homeDirectory = lib.mkDefault "/Users/${username}";
            programs.home-manager.enable = true;
            programs.git.settings.user.email = useremail;

            # Disable options.json generation to avoid derivation context warning
            manual.json.enable = false;
          };
      };
    };
}
