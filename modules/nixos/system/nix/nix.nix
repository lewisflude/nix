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

  # Binary caches from flake.nix nixConfig
  # These must be explicitly set here because system builds use system-level config,
  # not flake nixConfig. The flake.nix nixConfig only applies during flake evaluation.
  # The Determinate Nix module should merge nix.settings into /etc/nix/nix.conf
  # even when nix.enable = false. Synchronized with flake.nix nixConfig.extra-substituters
  nix.settings = {
    sandbox = true;
    trusted-users = [
      "root"
      "@wheel"
      username
    ];
    use-xdg-base-directories = true;
    accept-flake-config = true;

    # Binary caches from flake.nix nixConfig
    # Synchronized with flake.nix nixConfig.extra-substituters
    substituters = [
      "https://nix-community.cachix.org?priority=1"
      "https://lewisflude.cachix.org?priority=2"
      "https://nixpkgs-wayland.cachix.org?priority=3"
      "https://numtide.cachix.org?priority=4"
      "https://chaotic-nyx.cachix.org?priority=5"
      "https://nixpkgs-python.cachix.org?priority=6"
      "https://niri.cachix.org?priority=7"
      "https://helix.cachix.org?priority=8"
      "https://ghostty.cachix.org?priority=9"
      "https://yazi.cachix.org?priority=10"
      "https://ags.cachix.org?priority=11"
      "https://zed.cachix.org?priority=12"
      "https://catppuccin.cachix.org?priority=13"
      "https://devenv.cachix.org?priority=14"
      "https://viperml.cachix.org?priority=15"
      "https://cuda-maintainers.cachix.org?priority=16"
    ];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
