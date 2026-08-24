# Monero Module - Dendritic Pattern
# Self-hosted Monero node (monerod) plus the Feather desktop wallet.
#
# The whole point of running the node locally is privacy: a remote node sees
# which blocks your wallet asks for and the IP asking, which is enough to
# fingerprint a wallet over time. Feather talks to 127.0.0.1 so nothing about
# your addresses or scan pattern leaves the box.
#
# dataDir stays at the module default /var/lib/monero, which is a dedicated ZFS
# dataset (npool/monero, recordsize=16K) declared in hosts/jupiter/hardware.nix
# -- the LMDB write-amplification note lives there.
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

      # --max-concurrency. Unlimited (0) lets initial sync fan block
      # verification across all 32 threads, which starves the rest of
      # system.slice for the day or two the sync takes. systemd's knobs are
      # the wrong tool for this: Nice only orders tasks within a cgroup under
      # cgroup v2, and IOWeight is inert because ZFS issues writes from the
      # z_wr_iss kernel threads -- monero.service's io.stat reads wbytes=0 on
      # every device. Capping concurrency at the source is what actually
      # works. 8 of 32 leaves the P-cores free; steady state needs one thread
      # for one block every two minutes.
      limits.threads = 8;

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
