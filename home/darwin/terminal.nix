{ ... }:
{
  # Darwin-specific terminal configuration
  # Base configuration is imported from ../common/terminal.nix
  # Ghostty is installed via homebrew on Darwin

  home.sessionVariables = {
    XDG_DATA_DIRS = [
      "/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration"
    ];
  };
}
