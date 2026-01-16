{
  lib,
  pkgs,
  cfg,
  constants,
  ...
}:
let
  # Common runtime inputs for all scripts
  commonRuntimeInputs = [
    pkgs.coreutils
    pkgs.systemd
    pkgs.util-linux
    pkgs.findutils
  ];

  # Niri-specific inputs for display management
  niriRuntimeInputs = [
    pkgs.niri
    pkgs.jq
  ];

  # Build environment variables from config
  mkScriptEnv = lib.concatStringsSep "\n" (
    lib.optional (cfg.display.streaming != null) "export STREAMING_DISPLAY=\"${cfg.display.streaming}\""
    ++ lib.optional (cfg.display.primary != null) "export PRIMARY_DISPLAY=\"${cfg.display.primary}\""
    ++ [
      # Export timing constants as JSON for scripts to parse
      "export SUNSHINE_CONSTANTS='${builtins.toJSON constants.timing}'"
    ]
  );

  # Inline common functions (more reliable than sourcing with writeShellApplication)
  commonFunctions = builtins.readFile ./common.sh;

  # Script paths
  steamLauncherScript = ./steam-launcher.sh;
  prepScript = ./prep.sh;
  cleanupScript = ./cleanup.sh;
in
{
  # Steam launcher script with window focusing
  sunshine-steam-launcher = pkgs.writeShellApplication {
    name = "sunshine-steam-launcher";
    runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs ++ [ pkgs.steam ];
    text = commonFunctions + "\n" + builtins.readFile steamLauncherScript;
  };

  # Prep script with environment variable substitution
  sunshine-prep = pkgs.writeShellApplication {
    name = "sunshine-prep";
    runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs;
    text = mkScriptEnv + "\n" + commonFunctions + "\n" + builtins.readFile prepScript;
  };

  # Cleanup script with environment variable substitution
  sunshine-cleanup = pkgs.writeShellApplication {
    name = "sunshine-cleanup";
    runtimeInputs = commonRuntimeInputs ++ niriRuntimeInputs ++ [ pkgs.swaylock-effects ];
    text =
      mkScriptEnv
      + "\nexport LOCK_ON_STREAM_END=\""
      + lib.boolToString cfg.behavior.lockOnStreamEnd
      + "\"\n"
      + commonFunctions
      + "\n"
      + builtins.readFile cleanupScript;
  };
}
