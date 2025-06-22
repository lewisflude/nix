{
  imports =
    let
      files = builtins.filter
        (f: f != "default.nix" && f != "hyprland.nix" && f != "overlays.nix" && f != "window-management.nix" && f != "graphics.nix")  # temporarily disable problematic modules
        (builtins.attrNames (builtins.readDir ./.));

      modules = map
        (f: ./. + "/${f}")
        files;
    in
    modules;
}