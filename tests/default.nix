{pkgs ? import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") {}}: let
  home-manager = builtins.getFlake "github:nix-community/home-manager/release-24.05";
in
  pkgs.testers.runNixOSTest {
    name = "home-manager-hello";
    nodes.machine = {pkgs, ...}: {
      imports = [home-manager.nixosModules.home-manager];
      users.users.alice = {
        isNormalUser = true;
        initialPassword = "password";
      };
      home-manager.users.alice = {
        home.packages = [pkgs.hello];
        home.stateVersion = "23.11";
      };
    };
    testScript = ''
      start_all()
      machine.wait_for_unit("default.target")
      machine.succeed("su - alice -c 'command -v hello'")
      machine.fail("command -v hello")
    '';
  }
