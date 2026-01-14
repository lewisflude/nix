# Shell Environment Configuration
# Environment variables, packages, and related files
{
  config,
  pkgs,
  ...
}:
{
  home = {
    sessionVariables = {
      # Use Nix-provided SSL certificates
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      EDITOR = "hx";
      # NH_FLAKE is set in home/common/nh.nix

      # Direnv performance optimizations
      # Suppress verbose output (already set, kept for clarity)
      DIRENV_LOG_FORMAT = "";
      # Warn if direnv takes longer than 20 seconds (helps identify slow loads)
      DIRENV_WARN_TIMEOUT = "20s";
      # Fail fast if direnv hangs (prevents infinite blocking of shell)
      DIRENV_TIMEOUT = "5s";
    };
    packages = [
      pkgs.zoxide
    ];
  };

  # Declaratively manage p10k configuration
  # This file must exist for p10k to work - if it doesn't, p10k will show the wizard
  home.file.".p10k.zsh" = {
    source = ../../../lib/p10k.zsh;
    # Ensure the file is readable and executable
    executable = false;
  };

  home.file.".config/direnv/lib/layout_zellij.sh".text = ''
    layout_zellij() {

      if [ -n "$ZELLIJ" ]; then
        return 0
      fi


      local session_name="$(basename "$PWD")"

      if [ -f ".zellij.kdl" ]; then

        exec zellij --layout .zellij.kdl attach -c "$session_name"
      else

        exec zellij attach -c "$session_name"
      fi
    }
  '';
}
