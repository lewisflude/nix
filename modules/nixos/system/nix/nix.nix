{ username, ... }:
{

  nix.enable = false;

  environment.etc."nix/nix.conf".text = ''


  '';

  # Flakes don't use channels - NIX_PATH is only for legacy compatibility
  # If needed, set to minimal value pointing to flake
  environment.sessionVariables = {
    # NIX_PATH is not needed with pure flakes
    # Uncomment only if you have legacy tools that require it:
    # NIX_PATH = "nixpkgs=flake:nixpkgs:nixos-config=/path/to/config";
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
