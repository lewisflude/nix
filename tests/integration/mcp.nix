{
  pkgs,
  lib,
  inputs,
  ...
}:
let

  mkTest = pkgs.lib.nixosTest;

  hmModule = inputs.home-manager.nixosModules.home-manager;
in
mkTest {
  name = "mcp-service-test";

  nodes.machine =
    { ... }:
    {
      imports = [ hmModule ];

      users.users.testuser = {
        isNormalUser = true;
        home = "/home/testuser";
        extraGroups = [ "wheel" ];
      };

      home-manager = {
        useUserPackages = true;
        users.testuser = {
          home.stateVersion = "24.11";

          imports = [ ../../home/common/modules/mcp.nix ];

          services.mcp = {
            enable = true;
            targets.cursor = {
              directory = "/home/testuser/.cursor";
              fileName = "mcp.json";
            };
            servers = { };
          };
        };
      };

      boot.loader.grub.enable = false;
      boot.loader.systemd-boot.enable = lib.mkForce false;
      fileSystems."/" = {
        device = "/dev/vda";
        fsType = "ext4";
      };
      virtualisation.graphics = false;
    };

  testScript = ''
    machine.start()

    machine.wait_for_unit("home-manager-testuser.service")


    machine.succeed("id testuser")


    machine.succeed("su - testuser -c 'test -f $HOME/.mcp-generated/cursor/mcp.json'")
    machine.succeed("su - testuser -c 'test -f $HOME/.cursor/mcp.json'")
    machine.succeed("su - testuser -c 'grep -q \"\\\"mcpServers\\\"\" $HOME/.cursor/mcp.json'")
  '';
}
