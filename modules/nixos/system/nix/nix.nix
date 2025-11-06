{ username, ... }:
{

  nix.enable = false;

  environment.etc."nix/nix.conf".text = ''


  '';

  environment.sessionVariables = {
    NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:nixos-config=/home/${username}/.config/nix:/nix/var/nix/profiles/per-user/root/channels";
  };

  nix.settings = {
    sandbox = true;
    trusted-users = [
      "root"
      "@wheel"
      username
    ];
    use-xdg-base-directories = true;
    accept-flake-config = true;
  };
}
