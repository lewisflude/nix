# Shell Environment Configuration
# Environment variables, packages, and related files
{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.zsh = {
    # Variables for .zshenv (sourced by ALL shells - interactive, non-interactive, login)
    # These should not produce output or assume TTY attachment
    envExtra = ''
      # Word characters for word-based navigation (Ctrl+W, Alt+B, etc.)
      # Excludes '/' so path components are treated as separate words
      export WORDCHARS='*?_-.[]~=&;!'

      # SOPS (secrets management) configuration
      export SOPS_GPG_EXEC="${lib.getExe pkgs.gnupg}"
      export SOPS_GPG_ARGS="--pinentry-mode=loopback"

      # Nix flake location
      export NIX_FLAKE="${config.home.homeDirectory}/.config/nix"
    '';
  };

  home = {
    sessionVariables = {
      # Use Nix-provided SSL certificates
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      EDITOR = "hx";
      # Terminal color support (follows CLICOLOR standard)
      COLORTERM = "truecolor"; # Indicate 24-bit color support
      CLICOLOR = "1"; # Enable colors in CLI tools

      # Direnv performance optimizations
      DIRENV_LOG_FORMAT = "";
      DIRENV_WARN_TIMEOUT = "20s";
      DIRENV_TIMEOUT = "5s";
    };
    packages = [
      pkgs.zoxide
      # Note: vivid should be provided by signal-nix theming module
    ];
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
