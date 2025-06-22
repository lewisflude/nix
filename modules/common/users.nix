{ username, system, lib, pkgs, ... }:
{
  users.users.${username} = {
    name = username;
    home = if lib.hasInfix "darwin" system 
      then "/Users/${username}"
      else "/home/${username}";
  } // lib.optionalAttrs (lib.hasInfix "linux" system) {
    # NixOS-specific user configuration
    isNormalUser = true;
    group = username;
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
    initialPassword = "changeMe";
  };

  # Create user group on Linux
  users.groups = lib.mkIf (lib.hasInfix "linux" system) {
    ${username} = {};
  };
}
