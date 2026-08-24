# Monero Module - Dendritic Pattern
# Self-hosted Monero node (monerod) plus the Feather desktop wallet.
#
# The whole point of running the node locally is privacy: a remote node sees
# which blocks your wallet asks for and the IP asking, which is enough to
# fingerprint a wallet over time. Feather talks to 127.0.0.1 so nothing about
# your addresses or scan pattern leaves the box.
{ config, ... }:
let
  inherit (config) constants;
  monero = constants.ports.services.monero;
in
{
  flake.modules.nixos.monero = _: {
    services.monero = {
      enable = true;

      # Pruned: keeps the ~1/8 of ring-signature data a wallet actually needs to
      # verify and scan, ~60-70GB instead of ~250GB and growing. A pruned node
      # is fully validating and fully private for your own wallet -- the only
      # thing it can't do is serve historical blocks to other people's syncs.
      prune = true;

      rpc = {
        # Loopback only. Not in the firewall, not reachable over Tailscale.
        address = "127.0.0.1";
        port = monero.rpc;
        # Unrestricted is correct for a loopback-only RPC: `restricted` is the
        # mode public nodes run to protect themselves from their users, and it
        # withholds commands (ban management, full block data) that are useful
        # when the caller is you.
        restricted = false;
      };
    };

    # Deliberately no firewall openings. monerod dials out to peers on
    # ${toString monero.p2p}; inbound is only needed to serve other people's
    # nodes, and accepting it advertises "Monero user here" to anyone scanning.
  };

  flake.modules.homeManager.monero =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Feather rather than monero-gui: same wallet2 core, far lighter, and it
      # doesn't try to manage its own bundled monerod alongside the system one.
      # Wallet files and the seed are user data -- they live in ~/.feather and
      # are deliberately not Nix-managed. Back them up out of band.
      home.packages = [ pkgs.feather ];
    };
}
