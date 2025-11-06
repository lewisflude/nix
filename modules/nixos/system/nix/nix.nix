{ username, ... }:
{
  # Determinate Nix manages the daemon on NixOS via systemd-nix-daemon
  # Do NOT set nix.enable = true as it conflicts with Determinate Nix's daemon management
  # The determinate.nixosModules.default module handles daemon configuration
  # Explicitly set to false to prevent conflicts (Determinate Nix uses systemd-nix-daemon instead)
  nix.enable = false;

  # Note: Determinate Nix sets 'eval-cores' and 'lazy-trees' in /etc/nix/nix.conf
  # These are experimental Determinate-specific settings that standard Nix doesn't recognize.
  # You may see warnings like:
  #   warning: unknown setting 'eval-cores'
  #   warning: unknown setting 'lazy-trees'
  # These warnings are harmless and can be safely ignored. They occur because Determinate Nix
  # uses experimental features that aren't part of standard Nix yet.

  # Determinate Nix custom settings (if the option exists)
  # Note: The option name may vary depending on Determinate Nix version
  # If this causes errors, check the actual option name in your Determinate Nix version
  # or comment out this section if not needed
  # determinate-nix.customSettings = lib.mkIf (lib.hasAttr "determinate-nix" config) {
  #   # Add any Determinate-specific settings here if needed
  #   # Example: flake-registry = "/etc/nix/flake-registry.json";
  # };

  # When nix.enable = false, NixOS still expects environment.etc."nix/nix.conf" to exist
  # The Determinate Nix module will create this, but we provide a minimal one to satisfy
  # NixOS's expectations during evaluation. The Determinate module will override it.
  environment.etc."nix/nix.conf".text = ''
    # This file is managed by Determinate Nix module
    # User settings are merged from nix.settings below
  '';

  # When nix.enable = false, NixOS doesn't set default Nix environment variables
  # We need to set NIX_PATH for services and scripts that expect it
  # NIX_PATH is a colon-separated list of search path entries
  # Includes nixpkgs channel, nixos-config pointing to config directory, and channels directory
  environment.sessionVariables = {
    NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:nixos-config=/home/${username}/.config/nix:/nix/var/nix/profiles/per-user/root/channels";
  };

  # Binary caches are now configured in flake.nix using extra-substituters and extra-trusted-public-keys
  # This system config only handles core settings and trusts flake configuration
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
