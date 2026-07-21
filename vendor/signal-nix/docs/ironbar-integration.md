# Ironbar Integration

For ironbar theming, please use **[signal-ironbar](https://github.com/lewisflude/signal-ironbar)**.

signal-ironbar provides a complete, production-ready ironbar configuration with:
- Signal color palette
- Pre-configured widgets (workspaces, clock, tray, notifications, etc.)
- Display profiles (compact/relaxed/spacious)
- Drop-in replacement for manual ironbar config

## Quick Start

```nix
{
  inputs.signal-ironbar.url = "github:lewisflude/signal-ironbar";

  # ...

  home-manager.users.yourname = {
    imports = [ signal-ironbar.homeManagerModules.default ];

    programs.signal-ironbar = {
      enable = true;
      profile = "relaxed";  # or "compact" or "spacious"
    };
  };
}
```

See [signal-ironbar documentation](https://github.com/lewisflude/signal-ironbar) for complete setup and configuration options.

---

## Advanced: Colors Only

This module (signal-nix/modules/ironbar) is maintained for advanced users who want **colors only** and prefer to configure all widgets and layout manually.

If you need full control over your ironbar configuration:

```nix
theming.signal = {
  enable = true;
  ironbar.enable = true;  # Provides colors only
};

# Then import colors in your custom ironbar config
programs.ironbar = {
  enable = true;
  style = ''
    @import url("${config.theming.signal.colors.ironbar.cssFile}");
    /* Your custom CSS using Signal color variables */
  '';
};
```

For most users, [signal-ironbar](https://github.com/lewisflude/signal-ironbar) is the recommended approach.
