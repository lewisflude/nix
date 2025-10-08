{
  pkgs,
  lib,
  fetchurl,
  stdenvNoCC,
  cursorInfo,
}: let
  cursorCliInfo = cursorInfo.cursorCli;
  version = cursorCliInfo.version;
  pname = "cursor-cli";
in
  stdenvNoCC.mkDerivation rec {
    inherit pname version;

    src =
      if pkgs.stdenv.isDarwin
      then
        if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
        then
          fetchurl
          {
            url = cursorCliInfo.darwin.aarch64.url;
            sha256 = cursorCliInfo.darwin.aarch64.sha256;
          }
        else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin"
        then
          fetchurl
          {
            url = cursorCliInfo.darwin.x86_64.url;
            sha256 = cursorCliInfo.darwin.x86_64.sha256;
          }
        else throw "Unsupported Darwin architecture for cursor-cli"
      else if pkgs.stdenv.isLinux
      then
        if pkgs.stdenv.hostPlatform.system == "aarch64-linux"
        then
          fetchurl
          {
            url = cursorCliInfo.linux.aarch64.url;
            sha256 = cursorCliInfo.linux.aarch64.sha256;
          }
        else if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
        then
          fetchurl
          {
            url = cursorCliInfo.linux.x86_64.url;
            sha256 = cursorCliInfo.linux.x86_64.sha256;
          }
        else throw "Unsupported Linux architecture for cursor-cli"
      else throw "Unsupported OS for cursor-cli";

    dontUnpack = false;

    installPhase = ''
      mkdir -p $out/bin
      tar -xzf $src --strip-components=1
      mv cursor-agent $out/bin/cursor-agent
    '';

    meta = with lib; {
      description = "Cursor CLI - AI-first code editor command line interface";
      homepage = "https://www.cursor.com/";
      license = licenses.unfree;
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "cursor-agent";
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
