# Boot configuration module
# Provides systemd-boot and ZFS support
_: {
  flake.modules.nixos.boot =
    { lib, ... }:
    {
      boot = {
        loader.systemd-boot = {
          enable = lib.mkDefault true;
          editor = false;
          configurationLimit = lib.mkDefault 10;
        };

        supportedFilesystems.zfs = true;

        # Deliberate deviation from the option docs, which say "highly
        # recommended to keep this option disabled as it bypasses ZFS
        # safeguard that protect your pools". That safeguard exists for
        # shared/multi-host storage; npool is a single-host local pool, and
        # this box panics and reboots by design (see crash-recovery.nix), so
        # unclean shutdowns are routine rather than exceptional. With this
        # false, one of those reboots leaves it sitting at an unbootable
        # initrd needing zfs_force=1 typed at the console -- and it is
        # usually reached over Tailscale/mosh, not in person.
        #
        # Currently also the default (the default is
        # `versionOlder stateVersion "26.11"`, and ours is 25.05), but stated
        # explicitly so the value survives a stateVersion bump.
        zfs.forceImportRoot = true;
      };

      services.fstrim.enable = true;
    };
}
