{
  pkgs,
  config,
  lib,
  username,
  ...
}:

let
  yk = pkgs.fetchFromGitHub {
    owner = "noperator";
    repo = "yknotify";
    rev = "6a78d2d95a0fc8f3c3cb9065824380fa6213c274";
    sha256 = "sha256-3ScQS0b4GT42ey/+EYYHR62ovcfziiT/Q9MXF+th9uk=";
  };
in
{
  home.packages = [ pkgs.terminal-notifier ];

  home.file."yknotify.sh" = {
    source = pkgs.writeShellScript "yknotify" (
      lib.replaceStrings [ "<USER>" ] [ username ] (builtins.readFile "${yk}/yknotify.sh")
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
