# User account configuration
# Uses top-level config.username from modules/meta.nix
#
# The login shell and programs.zsh.enable live in modules/shell/zsh.nix — that
# is the shell feature's concern, and duplicating it here previously meant the
# nixos.shell module was never imported by any host (so its settings were
# silently dead).
{ config, ... }:
let
  inherit (config) username;
in
{
  # NixOS user account
  flake.modules.nixos.users = _: {
    users.users.${username} = {
      isNormalUser = true;
      description = username;
      # Union of admin + desktop group membership. The desktop groups used to
      # live in a separate `desktopUserGroups` module that declared extraGroups
      # for this same user; consolidated here so the account has one owner.
      # No "networkmanager": this fleet runs systemd-networkd (see
      # modules/networking.nix), so the NetworkManager module never creates that
      # group and listing it here would warn on every activation.
      extraGroups = [
        "wheel"
        "audio"
        "video"
        "input"
      ];
    };
  };

  # Darwin user configuration
  flake.modules.darwin.users = _: {
    users.users.${username} = {
      home = "/Users/${username}";
    };
  };
}
