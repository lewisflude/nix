{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.host.systemDefaults = {
    fileDescriptorLimit = mkOption {
      type = types.int;
      default = 524288;
      example = 1048576;
      description = ''
        Default file descriptor limit applied via systemd's
        DefaultLimitNOFILE. Features can raise this value by overriding
        the option instead of forcing systemd settings directly.
      '';
    };
  };
}
