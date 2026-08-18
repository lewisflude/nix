# Home-manager integration into NixOS and Darwin configurations
# Dendritic pattern: Infrastructure provides ONLY the structure
# ALL module imports (external and feature) happen at host level
{ config, ... }:
let
  # Top-level values from dendritic options
  inherit (config) username constants;
in
{
  # NixOS home-manager base configuration (structure only)
  flake.modules.nixos.homeManagerBase =
    { lib, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        # Overwrite a stale .hm-backup instead of aborting activation. Apps
        # that rewrite their own config (e.g. Zed does atomic writes on launch,
        # replacing the store symlink with a real file) otherwise leave a
        # backup that collides on the next rebuild.
        overwriteBackup = true;

        users.${username} =
          { osConfig, ... }:
          {
            # Auto-config: username, homeDirectory, stateVersion
            home.stateVersion = osConfig.system.stateVersion;
            home.username = lib.mkDefault username;
            home.homeDirectory = lib.mkDefault "/home/${username}";
            # We intentionally track unstable for both nixpkgs and home-manager;
            # the branches occasionally drift across a release cut.
            home.enableNixpkgsReleaseCheck = false;
            programs.home-manager.enable = true;

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
        # Overwrite a stale .hm-backup instead of aborting activation. Apps
        # that rewrite their own config (e.g. Zed does atomic writes on launch,
        # replacing the store symlink with a real file) otherwise leave a
        # backup that collides on the next rebuild.
        overwriteBackup = true;

        users.${username} = _: {
          # Auto-config: username, homeDirectory, stateVersion
          home.stateVersion = constants.defaults.stateVersion;
          home.username = lib.mkDefault username;
          home.homeDirectory = lib.mkDefault "/Users/${username}";
          # We intentionally track unstable for both nixpkgs and home-manager;
          # the branches occasionally drift across a release cut.
          home.enableNixpkgsReleaseCheck = false;
          programs.home-manager.enable = true;

          # Disable options.json generation to avoid derivation context warning
          manual.json.enable = false;
        };
      };
    };
}
