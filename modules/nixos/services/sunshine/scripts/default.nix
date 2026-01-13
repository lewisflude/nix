{
  # config,
  lib,
  pkgs,
  cfg,
  ...
}:
with lib;
let
  # Helper to create shell application from script file
  mkScriptApp =
    name: scriptPath: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile scriptPath;
    };

  # Script paths
  steamLauncherScript = ./steam-launcher.sh;
  prepScript = ./prep.sh;
  cleanupScript = ./cleanup.sh;
in
{
  # Steam launcher script
  sunshine-steam-launcher = mkScriptApp "sunshine-steam-launcher" steamLauncherScript [
    pkgs.steam
    pkgs.niri
    pkgs.jq
    pkgs.coreutils
    pkgs.procps
    pkgs.systemd
    pkgs.findutils
    pkgs.util-linux
  ];

  # Prep script with environment variable substitution
  sunshine-prep = pkgs.writeShellApplication {
    name = "sunshine-prep";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
      pkgs.systemd
      pkgs.coreutils
      pkgs.util-linux
      pkgs.findutils
    ];
    text = ''
      ${lib.optionalString (cfg.streamingDisplay != null) ''
        export STREAMING_DISPLAY="${cfg.streamingDisplay}"
      ''}
      ${lib.optionalString (cfg.primaryDisplay != null) ''
        export PRIMARY_DISPLAY="${cfg.primaryDisplay}"
      ''}
      ${builtins.readFile prepScript}
    '';
  };

  # Cleanup script with environment variable substitution
  sunshine-cleanup = pkgs.writeShellApplication {
    name = "sunshine-cleanup";
    runtimeInputs = [
      pkgs.niri
      pkgs.systemd
      pkgs.coreutils
      pkgs.swaylock-effects
      pkgs.util-linux
      pkgs.findutils
    ];
    text = ''
      ${lib.optionalString (cfg.streamingDisplay != null) ''
        export STREAMING_DISPLAY="${cfg.streamingDisplay}"
      ''}
      ${lib.optionalString (cfg.primaryDisplay != null) ''
        export PRIMARY_DISPLAY="${cfg.primaryDisplay}"
      ''}
      export LOCK_ON_STREAM_END="${lib.boolToString cfg.lockOnStreamEnd}"
      ${builtins.readFile cleanupScript}
    '';
  };
}
