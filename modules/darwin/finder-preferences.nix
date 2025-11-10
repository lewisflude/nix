{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.finderPreferences;
in
{
  options.host.features.finderPreferences = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable enhanced Finder preferences";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults = {
      finder = {

        AppleShowAllFiles = false;
        AppleShowAllExtensions = true;
        ShowStatusBar = true;
        ShowPathbar = true;
        _FXShowPosixPathInTitle = true;

        _FXSortFoldersFirst = true;
        _FXSortFoldersFirstOnDesktop = true;

        FXDefaultSearchScope = "SCcf";

        FXRemoveOldTrashItems = true;

        FXPreferredViewStyle = "Nlsv";

        CreateDesktop = true;
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;

        QuitMenuItem = true;
        FXEnableExtensionChangeWarning = false;

        # Use "Home" instead of "Other" - more reliable
        NewWindowTarget = "Home";

      };
    };
  };
}
