{inputs}: _final: _prev: {
  ghostty = inputs.ghostty.packages.${_final.system}.default.override {
    optimize = "ReleaseFast";
    enableX11 = true;
    enableWayland = true;
  };
}
