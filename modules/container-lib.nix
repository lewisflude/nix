# Shared OCI container helpers, exposed the dendritic way as `config.containerLib`
# (mirrors `config.mediaLib`). One definition of what a "simple" container looks
# like: an image, a published port, and an optional state directory under
# /var/lib/containers/supplemental/<name>.
{ config, lib, ... }:
let
  media = config.mediaLib;
  inherit (config.constants.defaults) timezone;

  configRoot = "/var/lib/containers/supplemental";

  # Build a single container plus the tmpfiles/firewall facts that go with it.
  # Callers get an attrset, not config, so a module can merge several of them.
  mkContainer =
    {
      name,
      image,
      port,
      internalPort,
      # Mount point of the per-container state dir inside the container.
      configMount ? "/config",
      # false: stateless container — no state dir created and none mounted.
      configDir ? true,
      # true: publish on loopback only (reached through Caddy).
      localhost ? false,
      # Ownership of the state dir. Defaults to the primary interactive user.
      uid ? 1000,
      gid ? 100,
      # true: open `port` on the host firewall (LAN-reachable services).
      openFirewall ? false,
      extraEnv ? { },
      extraVolumes ? [ ],
      extraOptions ? [ ],
    }:
    let
      stateDir = "${configRoot}/${name}";
    in
    {
      container = {
        inherit image extraOptions;
        environment = {
          TZ = timezone;
        }
        // extraEnv;
        volumes = lib.optional configDir "${stateDir}:${configMount}" ++ extraVolumes;
        ports = [
          "${lib.optionalString localhost "127.0.0.1:"}${toString port}:${toString internalPort}"
        ];
      };
      tmpfilesRules = lib.optional configDir (media.mkContainerDir stateDir uid gid);
      firewallPorts = lib.optional openFirewall port;
    };

  # Turn an attrset of specs (keyed by container name) into a NixOS module,
  # deriving containers, their state dirs and their firewall ports from the one
  # source. Adding a container is a single entry.
  mkContainers =
    specs:
    let
      built = lib.mapAttrs (name: spec: mkContainer ({ inherit name; } // spec)) specs;
      entries = lib.attrValues built;
    in
    {
      virtualisation.oci-containers.containers = lib.mapAttrs (_: entry: entry.container) built;
      systemd.tmpfiles.rules = lib.concatMap (entry: entry.tmpfilesRules) entries;
      # Not mkDefault: see the note in jellyfin.nix — mkDefault port lists lose to
      # networking.nix's normal-priority definition instead of merging with it.
      networking.firewall.allowedTCPPorts = lib.concatMap (entry: entry.firewallPorts) entries;
    };

  containerLib = {
    inherit configRoot mkContainer mkContainers;
  };
in
{
  options.containerLib = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    # Repo plumbing; see NIX_PRACTICES.md section 3.5.
    internal = true;
    visible = false;
    default = containerLib;
    description = "Shared OCI container helpers (state dir root, container builder, list-driven module builder).";
  };
}
