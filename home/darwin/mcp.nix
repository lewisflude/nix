# Darwin MCP Configuration
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

      time = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@odgrim/mcp-datetime" ];
      };

      sqlite = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "mcp-server-sqlite-npx"
          "${config.home.homeDirectory}/.local/share/mcp/data.db"
        ];
      };

      everything = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-everything" ];
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

      fetch = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "mcp-server-fetch-typescript" ];
      };

      nixos = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-nixos" ];
      };

      puppeteer = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-puppeteer" ];
      };

      # Servers with secrets
      github = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-github" ];
        env = {
          GITHUB_TOKEN = "{env:GITHUB_TOKEN}";
        };
      };

      openai = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@mzxrai/mcp-openai" ];
        env = {
          OPENAI_API_KEY = "{env:OPENAI_API_KEY}";
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

      brave = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
        env = {
          BRAVE_API_KEY = "{env:BRAVE_API_KEY}";
        };
      };

      linear = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "mcp-server-linear" ];
        env = {
          LINEAR_API_KEY = "{env:LINEAR_API_KEY}";
        };
      };

      slack = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-slack" ];
        env = {
          SLACK_BOT_TOKEN = "{env:SLACK_BOT_TOKEN}";
          SLACK_TEAM_ID = "{env:SLACK_TEAM_ID}";
        };
      };

      discord = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@quantgeekdev/discord-mcp" ];
        env = {
          DISCORD_BOT_TOKEN = "{env:DISCORD_BOT_TOKEN}";
        };
      };

      youtube = {
        command = "${pkgs.yutu}/bin/yutu";
        args = [ "mcp" ];
        env = {
          YUTU_CREDENTIAL = "{env:YUTU_CREDENTIAL}";
          YUTU_CACHE_TOKEN = "{env:YUTU_CACHE_TOKEN}";
        };
      };

      postgres = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@modelcontextprotocol/server-postgres" ];
        env = {
          POSTGRES_CONNECTION_STRING = "{env:POSTGRES_CONNECTION_STRING}";
        };
      };

      qdrant = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-qdrant" ];
        env = {
          QDRANT_URL = "{env:QDRANT_URL}";
          QDRANT_API_KEY = "{env:QDRANT_API_KEY}";
        };
      };

      pinecone = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@pinecone-database/mcp" ];
        env = {
          PINECONE_API_KEY = "{env:PINECONE_API_KEY}";
        };
      };

      e2b = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [ "-y" "@e2b/mcp-server" ];
        env = {
          E2B_API_KEY = "{env:E2B_API_KEY}";
        };
      };
    };
  };
}
