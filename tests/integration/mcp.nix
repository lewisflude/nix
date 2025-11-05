{
  pkgs,
  lib,
  inputs, # <-- Removed "? null", inputs are now required
  ...
}:
let
  # 1. Use the modern, canonical test runner
  mkTest = pkgs.lib.nixosTest;

  # 2. Get the module directly from inputs. No fallback.
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

          # Import the Home Manager MCP module and enable it minimally
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

      # Keep VM minimal
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
    # 3. Wait for the specific HM service, not the whole system
    machine.wait_for_unit("home-manager-testuser.service")

    # Verify user exists
    machine.succeed("id testuser")

    # Verify Home Manager generated MCP config and copied to target
    machine.succeed("su - testuser -c 'test -f $HOME/.mcp-generated/cursor/mcp.json'")
    machine.succeed("su - testuser -c 'test -f $HOME/.cursor/mcp.json'")
    machine.succeed("su - testuser -c 'grep -q \"\\\"mcpServers\\\"\" $HOME/.cursor/mcp.json'")
  '';
}
