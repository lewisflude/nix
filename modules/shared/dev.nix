{pkgs, ...}: {
  environment.variables = {
    LIBRARY_PATH = "/usr/lib:/opt/homebrew/lib:${pkgs.libiconv}/lib";
    CPATH = "${pkgs.libiconv}/include";
    RUSTFLAGS = "-L ${pkgs.libiconv}/lib";
  };
}
