{
  pkgs,
  inputs,
}:
inputs.ghostty.packages.${pkgs.system}.default.override {
  optimize = "ReleaseFast";
  enableX11 = true;
  enableWayland = true;
}
