# Unpackerr Service Module
# Automatic unpacking for *arr stack downloads
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.unpackerr =
    _:
    {
      systemd.services.unpackerr = {
        after = [ "mnt-storage.mount" ];
        requires = [ "mnt-storage.mount" ];
      };

      services.unpackerr = {
        enable = true;
        user = "media";
        group = "media";
        settings = {
          debug = false;
          log_files = 10;
          log_file_mb = 10;
          interval = "2m";
          start_delay = "1m";
          retry_delay = "5m";
          parallel = 1;
          timeout = "10m";
          delete_delay = "5m";
          delete_orig = false;
          radarr = [
            {
              url = "http://127.0.0.1:${toString constants.ports.services.radarr}";
              paths = [ "/mnt/storage/torrents/movies" ];
              protocols = "torrent";
              timeout = "10s";
              delete_orig = false;
              delete_delay = "5m";
            }
          ];
          sonarr = [
            {
              url = "http://127.0.0.1:${toString constants.ports.services.sonarr}";
              paths = [ "/mnt/storage/torrents/tv" ];
              protocols = "torrent";
              timeout = "10s";
              delete_orig = false;
              delete_delay = "5m";
            }
          ];
          lidarr = [
            {
              url = "http://127.0.0.1:${toString constants.ports.services.lidarr}";
              paths = [ "/mnt/storage/torrents/music" ];
              protocols = "torrent";
              timeout = "10s";
              delete_orig = false;
              delete_delay = "5m";
            }
          ];
        };
      };
    };
}
