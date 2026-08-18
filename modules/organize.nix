_: {
  flake.modules.darwin.organize = _: {
    homebrew.brews = [ "organize-tool" ];
  };

  flake.modules.homeManager.organize =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin;
      configPath = "${config.home.homeDirectory}/.config/organize/config.yaml";
    in
    lib.mkIf isDarwin {
      xdg.configFile."organize/config.yaml".source = ./organize/config.yaml;

      launchd.agents.organize = {
        enable = true;
        config = {
          LowPriorityIO = true;
          ProcessType = "Background";
          ProgramArguments = [
            "/opt/homebrew/bin/organize"
            "run"
            configPath
          ];
          StartCalendarInterval = [
            {
              Hour = 9;
              Minute = 0;
            }
          ];
          RunAtLoad = false;
          StandardOutPath = "/tmp/organize.log";
          StandardErrorPath = "/tmp/organize.err";
        };
      };
    };
}
