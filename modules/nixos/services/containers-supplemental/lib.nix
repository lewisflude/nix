{lib}: let
  inherit (lib) mkOption types optional;
in {
  # Generate resource limit options for a container
  mkResourceOptions = defaults: {
    memory = mkOption {
      type = types.str;
      default = defaults.memory or "512m";
      description = "Memory limit for the container (e.g., '512m', '1g').";
      example = "1g";
    };

    cpus = mkOption {
      type = types.str;
      default = defaults.cpus or "1";
      description = "CPU limit for the container (number of CPUs or fraction).";
      example = "2";
    };

    memorySwap = mkOption {
      type = types.nullOr types.str;
      default = defaults.memorySwap or null;
      description = "Memory + swap limit (null means no limit).";
      example = "2g";
    };
  };

  # Produce resource flags for podman/docker extraOptions
  mkResourceFlags = resources:
    [
      "--memory=${resources.memory}"
      "--cpus=${resources.cpus}"
    ]
    ++ optional (resources.memorySwap != null) "--memory-swap=${resources.memorySwap}";

  # Standard health-check flags helper
  mkHealthFlags = {
    cmd,
    interval ? "30s",
    timeout ? "10s",
    retries ? "3",
    startPeriod ? null,
  }:
    [
      "--health-cmd=${cmd}"
      "--health-interval=${interval}"
      "--health-timeout=${timeout}"
      "--health-retries=${retries}"
    ]
    ++ optional (startPeriod != null) "--health-start-period=${startPeriod}";
}
