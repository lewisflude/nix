{
  pkgs,
  inputs,
}:
inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
  optimize = "ReleaseFast";
  enableX11 = true;
  enableWayland = true;
}
