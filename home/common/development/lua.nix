{ pkgs
, lib
, ...
}: {
  home.packages = with pkgs;
    lib.optionals (!stdenv.isDarwin) [
      love
    ]
    ++ [
      lua
      luarocks
      lua54Packages.busted
    ];
}
