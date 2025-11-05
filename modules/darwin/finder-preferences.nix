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
        # File and folder display
        AppleShowAllFiles = false; # Don't show hidden files by default
        AppleShowAllExtensions = true; # Always show file extensions
        ShowStatusBar = true; # Show status bar with item/disk info
        ShowPathbar = true; # Show path breadcrumbs
        _FXShowPosixPathInTitle = true; # Show full POSIX path in title bar

        # Sorting and organization
        _FXSortFoldersFirst = true; # Keep folders on top when sorting by name
        _FXSortFoldersFirstOnDesktop = true; # Same for desktop

        # Search behavior
        FXDefaultSearchScope = "SCcf"; # Search current folder by default (not "This Mac")

        # Trash management
        FXRemoveOldTrashItems = true; # Auto-empty trash after 30 days

        # View preferences
        FXPreferredViewStyle = "Nlsv"; # List view by default
        # Options: "icnv"=Icon, "Nlsv"=List, "clmv"=Column, "Flwv"=Gallery

        # Desktop items
        CreateDesktop = true; # Show desktop icons
        ShowExternalHardDrivesOnDesktop = true; # Show external drives
        ShowHardDrivesOnDesktop = true; # Show internal drives
        ShowMountedServersOnDesktop = true; # Show network drives
        ShowRemovableMediaOnDesktop = true; # Show CDs, DVDs, iPods

        # Behavior
        QuitMenuItem = true; # Allow quitting Finder with ⌘Q
        FXEnableExtensionChangeWarning = false; # Don't warn when changing extensions

        # Default folder for new Finder windows
        NewWindowTarget = "Home"; # Open home folder
        # Options: "Computer", "OS volume", "Home", "Desktop", "Documents", "Recents", "iCloud Drive", "Other"
        # NewWindowTargetPath = "file:///Users/"; # Used when NewWindowTarget = "Other"
      };

      # Additional Finder-related preferences via CustomUserPreferences
      CustomUserPreferences."com.apple.finder" = {
        # These override/supplement the ones in your existing system.nix
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false; # Can be toggled with Cmd+Shift+.
        ShowPathbar = true;
        ShowStatusBar = true;
        FXPreferredViewStyle = "Nlsv";
        ShowTabView = true;
        ShowSidebar = true;

        # Additional settings not available as direct options
        WarnOnEmptyTrash = false; # Don't warn when emptying trash
        DisableAllAnimations = false; # Keep animations enabled
        ShowRecentTags = false; # Don't show recent tags in sidebar

        # Default column widths for list view
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

      # Spotlight preferences
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
