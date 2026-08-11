# Mosh Service Module - Dendritic Pattern
# Mobile shell with UDP-based SSH alternative for better roaming
# Usage: Import flake.modules.nixos.mosh in host definition
{ config, ... }:
let
  inherit (config.constants.ports.services) mosh;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.mosh =
    { pkgs, ... }:
    {
      # Mosh (mobile shell) - UDP-based SSH alternative for better roaming
      # More resilient to network changes, intermittent connectivity, and roaming
      programs.mosh = {
        enable = true;

        # Firewall is opened explicitly below from the shared constant rather
        # than by the module's hardcoded 60000-61000, so the port range has a
        # single source of truth in modules/constants.nix.
        openFirewall = false;

        # Enable libutempter for proper utmp/wtmp logging
        # This allows 'who' and 'last' commands to work with mosh sessions
        withUtempter = true;
      };

      # Mosh allocates one UDP port per session from this range.
      networking.firewall.allowedUDPPortRanges = [ mosh ];

      # Workaround for termix mobile app bug - it calls 'cmosh-server' instead of 'mosh-server'
      environment.systemPackages = [
        (pkgs.runCommand "cmosh-server-symlink" { } ''
          mkdir -p $out/bin
          ln -s ${pkgs.mosh}/bin/mosh-server $out/bin/cmosh-server
        '')
      ];
    };

  # ==========================================================================
  # Darwin System Configuration
  # ==========================================================================
  # macOS doesn't need a daemon — mosh-server is exec'd over SSH on demand.
  # Just put the binary on PATH (and provide the cmosh-server symlink that
  # the Termix iOS app expects).
  flake.modules.darwin.mosh =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.mosh
        (pkgs.runCommand "cmosh-server-symlink" { } ''
          mkdir -p $out/bin
          ln -s ${pkgs.mosh}/bin/mosh-server $out/bin/cmosh-server
        '')
      ];
    };
}
