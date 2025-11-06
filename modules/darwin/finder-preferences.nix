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

        NewWindowTarget = "Home";

      };

      CustomUserPreferences."com.apple.finder" = {

        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXPreferredViewStyle = "Nlsv";
        ShowTabView = true;
        ShowSidebar = true;

        WarnOnEmptyTrash = false;
        DisableAllAnimations = false;
        ShowRecentTags = false;

        StandardViewSettings = {
          ListViewSettings = {
            columns = {
              name = {
                width = 300;
              };
              size = {
                width = 100;
              };
              kind = {
                width = 150;
              };
              dateModified = {
                width = 180;
              };
            };
          };
        };
      };

      CustomUserPreferences."com.apple.Spotlight" = {
        orderedItems = [
          {
            enabled = true;
            name = "APPLICATIONS";
          }
          {
            enabled = true;
            name = "SYSTEM_PREFS";
          }
          {
            enabled = true;
            name = "DIRECTORIES";
          }
          {
            enabled = true;
            name = "PDF";
          }
          {
            enabled = true;
            name = "DOCUMENTS";
          }
          {
            enabled = false;
            name = "MESSAGES";
          }
          {
            enabled = false;
            name = "CONTACT";
          }
          {
            enabled = false;
            name = "EVENT_TODO";
          }
          {
            enabled = false;
            name = "IMAGES";
          }
          {
            enabled = false;
            name = "BOOKMARKS";
          }
          {
            enabled = false;
            name = "MUSIC";
          }
          {
            enabled = false;
            name = "MOVIES";
          }
        ];
      };
    };
  };
}
