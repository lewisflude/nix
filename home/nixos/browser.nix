{ pkgs, lib, ... }:

let
  # Browser constants to avoid repetition and ensure consistency
  desktopFile = "google-chrome.desktop"; # Use Google Chrome as default (with declarative config)

  # Shared MIME types for web content
  webMimeTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];

  addons = pkgs.nur.repos.rycee.firefox-addons;

  # Convert list to defaultApplications format
  mimeDefaults = lib.genAttrs webMimeTypes (type: [ desktopFile ]);
in
{
  home.packages = [
    # Chrome configured via programs.chromium below with declarative extensions
    pkgs.firefox # Auto-detects Wayland/X11 environment
  ];

  # Session variables for optimal Wayland browser support
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1"; # Enable native Wayland for Firefox
    NIXOS_OZONE_WL = "1"; # Enable Ozone Wayland for Chromium-based browsers
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = mimeDefaults;
  };

  # Specialized Chrome launchers for specific use cases
  # Note: Main Chrome is configured via programs.chromium below with optimal flags and declarative extensions
  xdg.desktopEntries = {
    # Removed redundant google-chrome-wayland entry - main Chrome already has optimal Wayland flags

    "chrome-dev" = {
      name = "Chrome (Developer)";
      comment = "Chrome with dev tools and separate profile for development";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --user-data-dir=/tmp/chrome-dev-session --auto-open-devtools-for-tabs --no-default-browser-check --no-first-run";
      icon = "google-chrome";
      type = "Application";
      categories = [
        "Development"
        "WebBrowser"
      ];
      terminal = false;
    };

    "chrome-incognito" = {
      name = "Chrome (Incognito)";
      comment = "Chrome in private browsing mode";
      exec = "${pkgs.google-chrome}/bin/google-chrome-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --incognito";
      icon = "google-chrome";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      terminal = false;
    };
  };

  # Firefox configuration for better privacy and automatic Wayland/X11 detection
  programs.firefox = {
    enable = true;
    package = pkgs.firefox; # Auto-detects Wayland in your Niri session

    profiles.default = {
      id = 0;
      isDefault = true;
      name = "default";

      extensions = {
        force = true;
        packages = with addons; [
          # Privacy & Security
          ublock-origin
          privacy-badger

          # Productivity & Search
          kagi-search
          onepassword-password-manager

          # Development Tools (optional, commented out due to NUR naming)
          # react-developer-tools    # May not be available in NUR
          # vue-js-devtools         # May not be available in NUR

          # Customization
          firefox-color

          # Convenience
          clearurls # Remove tracking parameters
          decentraleyes # Local CDN protection
          # bitwarden                # Alternative to 1Password if needed
        ];
      };
      search = {
        force = true;
        default = "Kagi";
        order = [ "Kagi" ];
        engines.Kagi = {
          urls = [
            {
              template = "https://kagi.com/search";
              params = [
                {
                  name = "q";
                  value = "{searchTerms}";
                }
              ];
            }
          ];
          definedAliases = [ "@k" ];
        };
      };
      settings = {
        # Privacy & Security
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;

        # Wayland support
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "media.ffmpeg.vaapi.enabled" = true;

        # Developer-friendly settings
        "devtools.chrome.enabled" = true;
        "devtools.debugger.remote-enabled" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Performance & Hardware Acceleration
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
      };

      userChrome = ''
        /* Hide tab bar only in fullscreen mode for cleaner experience */
        :root[inFullscreen] #TabsToolbar { visibility: collapse !important; }
      '';
    };
  };

  # Google Chrome with declarative extensions and optimal performance flags
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome; # Using Google Chrome for better compatibility

    # Extensions with IDs from Chrome Web Store URLs
    extensions = [
      # Privacy & Security
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin

      # Productivity
      "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password - Password Manager (aligned with Firefox)

      # Development (optional, comment out if you don't need)
      # "fmkadmapgofadopljbjfkapdkoienihi"  # React Developer Tools
      # "nhdogjmejiglipccpnnnanhbledajbpd"  # Vue.js devtools
    ];

    # Command line arguments for optimal Wayland/NVIDIA performance
    commandLineArgs = [
      # Consolidated feature flags for better maintainability
      "--enable-features=UseOzonePlatform,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,AcceleratedVideoEncoder,VaapiVideoDecoder"
      "--ozone-platform=wayland"

      # NVIDIA-specific optimizations
      "--use-gl=desktop"
      "--ignore-gpu-blocklist"
      "--enable-zero-copy"
      "--enable-gpu-rasterization"
    ];
  };

}
