# Top-level options for shared configuration
# Following dendritic pattern: these options are accessible via config.username
# in all modules (both flake-parts level and within NixOS/Darwin/home-manager modules)
{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis";
      description = "Primary user's username";
    };

    useremail = lib.mkOption {
      type = lib.types.singleLineStr;
      readOnly = true;
      default = "lewis@lewisflude.com";
      description = "Primary user's email address";
    };
  };
}
