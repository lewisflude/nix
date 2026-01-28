{
  lib,
  ...
}:
{
  physicalMemoryLimit = lib.mkOption {
    type = lib.types.int;
    default = 8192;
    description = "Physical memory limit in MiB (8GB default, reduce to 2048 for 16GB systems)";
  };

  ignoreSlowTorrents = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Don't count slow torrents in active limits";
  };
}
