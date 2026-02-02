# NixOS MCP Configuration
{ config, pkgs, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      # Core servers (no secrets required)
      memory = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-memory" ];
      };

      git = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@cyanheads/git-mcp-server" ];
      };

      # Optional servers (no secrets required)
      filesystem = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          config.home.homeDirectory
        ];
      };

      sequentialthinking = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
      };

      nixos = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-nixos" ];
      };

      wayland = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "mcp-server-wayland" ];
      };

      # Servers with secrets (secrets injected via env)
      github = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-github" ];
        env = {
          GITHUB_TOKEN = "{env:GITHUB_TOKEN}";
        };
      };

      docs = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@arabold/docs-mcp-server" ];
        env = {
          OPENAI_API_KEY = "{env:OPENAI_API_KEY}";
        };
      };

      kagi = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-kagi" ];
        env = {
          KAGI_API_KEY = "{env:KAGI_API_KEY}";
        };
      };

      homeassistant = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "homeassistant-mcp" ];
        env = {
          HASS_URL = "{env:HOME_ASSISTANT_BASE_URL}";
          HASS_TOKEN = "{env:HOME_ASSISTANT_TOKEN}";
        };
      };
    };
  };
}
