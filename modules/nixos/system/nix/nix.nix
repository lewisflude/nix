{ username, ... }:
{
  # Determinate Nix manages the daemon on NixOS via systemd-nix-daemon
  # Do NOT set nix.enable = true as it conflicts with Determinate Nix's daemon management
  # The determinate.nixosModules.default module handles daemon configuration

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

  # You can still configure Nix settings - Determinate will merge these
  nix.settings = {
    sandbox = true;
    trusted-users = [
      "root"
      "@wheel"
      username
    ];
    use-xdg-base-directories = true;
    # Accept flake configuration settings globally to avoid warnings
    # This allows nixConfig in flake.nix to be trusted automatically
    accept-flake-config = true;
  };
}
