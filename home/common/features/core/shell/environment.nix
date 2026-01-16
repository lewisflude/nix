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
      # NH_FLAKE and NH_SEARCH_CHANNEL are set in home/common/features/core/nh.nix

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

  # Note: p10k configuration is now managed by the powerlevel10k Nix module
  # See home/common/apps/powerlevel10k.nix

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
