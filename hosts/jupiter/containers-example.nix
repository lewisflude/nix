# Example container configuration for Jupiter
# To use this configuration:
# 1. Review and adjust paths as needed
# 2. Uncomment the containers section in your default.nix
# 3. Run: sudo nixos-rebuild switch --flake .#jupiter
{
  # This is an example of how to enable containers in your Jupiter host
  # Add this to your hosts/jupiter/default.nix features section:

  /*
  containers = {
    enable = true;

    mediaManagement = {
      enable = true;
      # Path where your movies, tv shows, music, etc. are stored
      dataPath = "/mnt/storage";
      # Path where container configurations will be stored
      configPath = "/var/lib/containers/media-management";
    };

    productivity = {
      enable = true;
      # Path where AI tool configurations will be stored
      configPath = "/var/lib/containers/productivity";
    };
  };
  */

  # The configuration above will:
  # 1. Enable Podman with Docker compatibility
  # 2. Create systemd services for all containers
  # 3. Set up Podman networks (media, frontend)
  # 4. Configure GPU passthrough for AI containers
  # 5. Manage container lifecycle with systemd

  # After enabling, your containers will be accessible at:
  # - Radarr: http://jupiter:7878
  # - Sonarr: http://jupiter:8989
  # - Prowlarr: http://jupiter:9696
  # - Jellyfin: http://jupiter:8096
  # - Open WebUI: http://jupiter:7000
  # - ComfyUI: http://jupiter:8188
  # - And more... (see README.md for full list)
}
