{ inputs, ... }:
{
  perSystem = _: {
    # Development services - run with: nix run .#dev
    process-compose."dev" = {
      imports = [
        inputs.services-flake.processComposeModules.default
      ];

      services = {
        postgres."pg1" = {
          enable = true;
          initialDatabases = [
            { name = "dev"; }
            { name = "test"; }
          ];
          dataDir = "$HOME/.services-flake/postgres";
        };

        redis."redis1" = {
          enable = true;
          dataDir = "$HOME/.services-flake/redis";
        };

        ollama."ollama-dev" = {
          enable = true;
          dataDir = "$HOME/.services-flake/ollama";
          models = [
            "llama3.2"
            "qwen2.5-coder:7b"
          ];
        };

        open-webui."webui-dev" = {
          enable = true;
          environment = {
            OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
            WEBUI_AUTH = "False"; # Disable auth for local dev
          };
        };

        # Additional services available (uncomment to enable):
        # - minio."minio1" - S3-compatible storage
        # - nginx."nginx1" - Local reverse proxy
        # - prometheus."prom1" + grafana."grafana1" - Monitoring stack
      };
    };
  };
}
