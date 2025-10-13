# Development profile
# For development environments with language tooling and terminal enhancements
# This is a middle ground between minimal and full profiles
{...}: {
  imports = [
    ./base.nix

    # Development tools (but not IDEs)
    ../development
  ];
}
