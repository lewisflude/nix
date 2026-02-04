# User account configuration
# Uses top-level config.username from modules/meta.nix
{ config, ... }:
let
  inherit (config) username;
in
{
  # NixOS user account
  flake.modules.nixos.users =
    { pkgs, ... }:
    {
      users.users.${username} = {
        isNormalUser = true;
        description = username;
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.zsh;
      };

      programs.zsh.enable = true; # Required for user shell
    };

  # Darwin user configuration
  flake.modules.darwin.users = {
    users.users.${username} = {
      home = "/Users/${username}";
      shell = "/run/current-system/sw/bin/zsh";
    };

    programs.zsh.enable = true;
  };
}
