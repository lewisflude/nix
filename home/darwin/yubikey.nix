{
  pkgs,
  config,
  lib,
  username,
  ...
}:

let
  yknotify = pkgs.buildGoModule {
    pname = "yknotify";
    version = "unstable-2025-02-12";
    src = pkgs.fetchFromGitHub {
      owner = "noperator";
      repo = "yknotify";
      rev = "6a78d2d95a0fc8f3c3cb9065824380fa6213c274";
      sha256 = "sha256-3ScQS0b4GT42ey/+EYYHR62ovcfziiT/Q9MXF+th9uk=";
    };
    vendorHash = null;
  };
in
{
  home.packages = [ pkgs.terminal-notifier yknotify ];

  home.file."yknotify.sh" = {
    source = pkgs.writeShellScript "yknotify" (
      lib.replaceStrings 
        [ "<USER>" "/Users/<USER>/go/bin/yknotify" ] 
        [ username "${yknotify}/bin/yknotify" ]
        (builtins.readFile "${yknotify.src}/yknotify.sh")
    );
    executable = true;
    force = true;
  };

  launchd.agents.yknotify = {
    enable = true;
    config = {
      Label = "com.user.yknotify";
      ProgramArguments = [ "${config.home.homeDirectory}/yknotify.sh" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  home.activation.debugYknotify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "✅ yknotify is being evaluated for ${config.home.username}" >&2
  '';
}
