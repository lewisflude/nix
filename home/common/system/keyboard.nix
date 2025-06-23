{ pkgs, lib, system, ... }: {
  home.packages = lib.optionals (lib.hasInfix "linux" system) (with pkgs; [
    vial
    via
  ]);
}
