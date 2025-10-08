{ pkgs
, cursorInfo ? builtins.fromJSON (builtins.readFile ../../cursor-info.json)
, cursorVersion ? cursorInfo.version
,
}:
let
  inherit (pkgs) lib fetchurl stdenvNoCC;
  cursorApp =
    if pkgs.stdenv.isLinux
    then
      (import ./linux.nix {
        inherit pkgs cursorInfo cursorVersion;
        inherit (pkgs) lib;
      })
    else if pkgs.stdenv.isDarwin
    then (import ./darwin.nix { inherit pkgs cursorInfo cursorVersion; })
    else throw "Cursor is only packaged for Linux and Darwin.";

  cursorCli = import ./cursor-cli.nix {
    inherit pkgs lib fetchurl stdenvNoCC cursorInfo; # Pass cursorInfo
  };
in
{
  cursor = cursorApp;
  cursor-cli = cursorCli;
}
