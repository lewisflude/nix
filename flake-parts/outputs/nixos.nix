{
  inputs,
  self,
  withSystem,
  hostsConfig,
  systemBuilders,
  ...
}:
{
  # NixOS system configurations
  flake.nixosConfigurations = builtins.mapAttrs (
    hostName: hostConfig:
    withSystem hostConfig.system (
      _:
      systemBuilders.mkNixosSystem hostName hostConfig {
        inherit self;
      }
    )
  ) (hostsConfig.getNixosHosts hostsConfig.hosts);
}
