{
  imports =
    let
      files = builtins.filter
        (f: f != "default.nix")
        (builtins.attrNames (builtins.readDir ./.));

      modules = map
        (f: ./. + "/${f}")
        files;
    in
    modules;
}

