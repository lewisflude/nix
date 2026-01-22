{
  inputs,
  withSystem,
  hostsConfig,
  systemBuilders,
  ...
}:
{
  # Darwin system configurations
  flake.darwinConfigurations = builtins.mapAttrs (
    hostName: hostConfig:
    withSystem hostConfig.system (
      _:
      systemBuilders.mkDarwinSystem hostName hostConfig {
        inherit (inputs) homebrew-j178;
      }
    )
  ) (hostsConfig.getDarwinHosts hostsConfig.hosts);
}
