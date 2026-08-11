# Restic Backup Service Module - Dendritic Pattern
# Backup solution with REST server
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.restic =
    # `config` here is the NixOS-scope config (for sops secret paths); the
    # flake-parts `constants` above is captured before this shadows it.
    { pkgs, config, ... }:
    {
      environment.systemPackages = [ pkgs.restic ];

      # REST server for backup storage
      services.restic.server = {
        enable = true;
        listenAddress = "127.0.0.1:${toString constants.ports.services.restic}";
        extraFlags = [ "--no-auth" ];
      };

      # =======================================================================
      # Backup jobs
      # =======================================================================
      # Until 2026-08-11 this module started a REST server and defined no
      # backups whatsoever, so npool — a four-device stripe with no redundancy,
      # holding / and /home — had neither replication nor backup. Any one of
      # the four devices failing meant total loss.
      #
      # The repository deliberately lives on /mnt/disk1, which is XFS and
      # outside npool entirely, so it survives the pool failing. That makes it
      # a genuine second copy but NOT an offsite one: it does not survive
      # theft, fire, or a PSU that takes the whole machine with it. Adding a
      # second `services.restic.backups.<name>` pointed at a remote repository
      # is the intended next step.
      services.restic.backups.system = {
        initialize = true;
        repository = "/mnt/disk1/backups/restic";
        passwordFile = config.sops.secrets.restic-password.path;

        paths = [
          "/home"
          "/etc"
          "/var/lib"
        ];

        # Caches, build artefacts and reconstructible container/service state.
        # Anything excluded here must be recreatable from the flake.
        exclude = [
          "/home/*/.cache"
          "/home/*/.local/share/Steam"
          "/home/*/.local/share/Trash"
          "/home/*/.var/app/*/cache"
          "/var/lib/containers"
          "/var/lib/docker"
          "/var/lib/systemd/coredump"
          "**/node_modules"
          "**/.direnv"
        ];

        timerConfig = {
          OnCalendar = "daily";
          # Spread against the 02:00/04:00 SMART self-tests so a long test on a
          # 14 TB spinner is not competing with backup reads for the same disk.
          RandomizedDelaySec = "1h";
          Persistent = true;
        };

        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
      };

      # A backup that fails quietly is worse than no backup: it looks like
      # protection right up until the restore. Route failures to the same
      # alert fan-out that disk and pool errors use.
      systemd.services.restic-backups-system.onFailure = [ "alert@%n.service" ];

      users.users.restic = {
        isSystemUser = true;
        group = "restic";
      };

      users.groups.restic = { };

      security.wrappers.restic = {
        source = "${pkgs.restic.out}/bin/restic";
        owner = "restic";
        group = "users";
        permissions = "u=rwx,g=,o=";
        capabilities = "cap_dac_read_search=+ep";
      };
    };
}
