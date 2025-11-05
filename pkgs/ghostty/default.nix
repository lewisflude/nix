{
  pkgs,
  inputs,
}:
(
  if
    inputs ? ghostty
    && inputs.ghostty ? packages
    && inputs.ghostty.packages ? ${pkgs.stdenv.hostPlatform.system}
    && inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system} ? default
  then inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
  else throw "ghostty input is required with packages.${pkgs.stdenv.hostPlatform.system}.default"
).override
{
  optimize = "ReleaseFast";
  enableX11 = true;
  enableWayland = true;
}
