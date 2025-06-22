{
  imports =
    let
      files = builtins.filter
        (f: f != "default.nix" && f != "hyprland.nix" && f != "window-management.nix")  # hyprland and window-management handled separately in flake
        (builtins.attrNames (builtins.readDir ./.));

      modules = map
        (f: ./. + "/${f}")
        files;
    in
    modules;
}