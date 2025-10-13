{lib}: {
  # Create a feature toggle option
  # Usage: mkFeature "myFeature" true "Enable my feature"
  mkFeature = name: default: description:
    lib.mkOption {
      type = lib.types.bool;
      default = default;
      inherit description;
      example = !default;
    };

  # Create multiple feature options at once
  # Usage: mkFeatures { feature1 = true; feature2 = false; }
  mkFeatures = features:
    lib.mapAttrs (name: default:
      lib.mkOption {
        type = lib.types.bool;
        inherit default;
        description = "Enable ${name}";
      })
    features;

  # Create a feature module with options and config
  # Usage: mkFeatureModule "myFeature" { ... }
  mkFeatureModule = {
    name,
    description ? "Enable ${name}",
    default ? false,
    config,
  }: {
    options.features.${name} = {
      enable = lib.mkEnableOption description // {inherit default;};
    };
    config = lib.mkIf config.features.${name}.enable config;
  };

  # Check if a feature is enabled
  # Usage: featureEnabled config "myFeature"
  featureEnabled = config: feature:
    config.features.${feature}.enable or false;

  # Get all enabled features
  # Usage: enabledFeatures config
  enabledFeatures = config:
    lib.filterAttrs (_name: value: value.enable or false) (config.features or {});

  # Conditionally include modules based on features
  # Usage: withFeature config "myFeature" [ ./my-module.nix ]
  withFeature = config: feature: modules:
    lib.optionals (featureEnabled config feature) modules;

  # Platform-specific feature
  # Usage: mkPlatformFeature "linux" "myFeature" true
  mkPlatformFeature = {
    platform, # "linux", "darwin", "all"
    name,
    default ? false,
    description ? "Enable ${name}",
  }: let
    platformCheck =
      if platform == "linux"
      then lib.mkIf (lib.hasInfix "linux" lib.system)
      else if platform == "darwin"
      then lib.mkIf (lib.hasInfix "darwin" lib.system)
      else lib.mkIf true;
  in {
    options.features.${name} = platformCheck (
      lib.mkOption {
        type = lib.types.bool;
        inherit default description;
      }
    );
  };
}
