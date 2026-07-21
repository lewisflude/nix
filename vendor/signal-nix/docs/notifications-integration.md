# Notifications Integration

For complete notification styling (colors + padding + spacing + animations), please use **[signal-notifications](https://github.com/lewisflude/signal-notifications)**.

signal-notifications provides a complete, production-ready notification configuration with:
- Signal color palette
- Pre-configured padding, spacing, margins, and border-radius
- Display profiles (compact/relaxed/spacious)
- Animations and transitions
- Urgency-specific styling
- Support for SwayNC, Mako, and Dunst

## Quick Start

```nix
{
  inputs.signal-notifications.url = "github:lewisflude/signal-notifications";

  # ...

  home-manager.users.yourname = {
    imports = [
      signal-nix.homeManagerModules.default
      signal-notifications.homeManagerModules.default
    ];

    theming.signal = {
      enable = true;
      mode = "dark";
    };

    programs.signal-notifications = {
      enable = true;
      profile = "relaxed";  # or "compact" or "spacious"
      swaync.enable = true; # or mako.enable or dunst.enable
    };

    services.swaync.enable = true;
  };
}
```

See [signal-notifications documentation](https://github.com/lewisflude/signal-notifications) for complete setup and configuration options.

---

## Advanced: Colors Only

This module (signal-nix/modules/desktop/notifications) is maintained for advanced users who want **colors only** and prefer to configure all padding, spacing, animations, etc. manually.

If you need full control over your notification configuration:

```nix
theming.signal = {
  enable = true;
  desktop.notifications.swaync.enable = true;  # Provides colors only
};

# Then add your own styling
xdg.configFile."swaync/style.css".text = ''
  @import url("${config.theming.signal.colors.swaync.cssFile}");
  
  /* Your custom CSS using Signal color variables */
  .notification {
    padding: 16px 20px; /* Your custom padding */
  }
'';
```

For most users, [signal-notifications](https://github.com/lewisflude/signal-notifications) is the recommended approach.
