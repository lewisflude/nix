{
  ...
}:
{
  # Define all supported system architectures
  # This is used by flake-parts to automatically generate perSystem outputs
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
}
