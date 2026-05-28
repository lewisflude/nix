# Terminal configuration (Ghostty + CLI tools)
# Dendritic pattern: Full implementation as flake.modules.homeManager.terminal
_: {
  flake.modules.homeManager.terminal =
    { lib, pkgs, ... }:
    let
      osc52Copy = pkgs.writeShellApplication {
        name = "osc52-copy";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          if [ "$#" -gt 0 ]; then
            payload=$(printf '%s' "$*" | base64 | tr -d '\r\n')
          else
            payload=$(base64 | tr -d '\r\n')
          fi

          if [ -e /dev/tty ]; then
            printf '\033]52;c;%s\a' "$payload" > /dev/tty
          else
            printf '\033]52;c;%s\a' "$payload"
          fi
        '';
      };

      osc52Test = pkgs.writeShellApplication {
        name = "osc52-test";
        runtimeInputs = [ osc52Copy ];
        text = ''
          osc52-copy "osc52-copy-ok"
          printf 'Sent OSC 52 clipboard test: osc52-copy-ok\n'
        '';
      };
    in
    {
      home.packages = [
        pkgs.clipse
        osc52Copy
        osc52Test
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wtype ];

      # Ghostty configuration
      # Linux: install from nixpkgs
      # macOS: package = null (installed via Homebrew), but config managed by home-manager
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
        enableZshIntegration = true;
        settings = {
          window-decoration = "server";
          font-family = "Iosevka Nerd Font Mono";
          font-feature = "+calt,+liga,+dlig";
          font-size = 14;
          font-synthetic-style = true;
          scrollback-limit = 100000;
          shell-integration-features = "cursor,sudo,title,ssh-env,ssh-terminfo";
          clipboard-read = "allow";
          clipboard-write = "allow";
          image-storage-limit = 320000000;
          keybind = [ ''shift+enter=text:\n'' ];
          window-padding-x = 20;
          window-padding-y = 16;
          window-padding-balance = true;
        };
      };
    };
}
