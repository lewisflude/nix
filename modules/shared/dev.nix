{
  pkgs,
  lib,
  hostSystem,
  ...
}:
let
  isDarwin = lib.strings.hasSuffix "darwin" hostSystem;
in
{
  environment.variables = {
    RUSTFLAGS = "-L ${pkgs.libiconv}/lib";
  }
  // lib.optionalAttrs isDarwin {
    LIBRARY_PATH = "/usr/lib:/opt/homebrew/lib:${pkgs.libiconv}/lib";
    CPATH = "${pkgs.libiconv}/include";
  };
}
