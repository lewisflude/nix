# GTK & Qt Theming Example

This example shows how to enable both GTK and Qt theming with Signal.

```nix
{
  # Import signal-nix in your flake inputs
  inputs.signal-nix.url = "github:lewisflude/signal-nix";

  # In your home-manager configuration:
  imports = [ inputs.signal-nix.homeManagerModules.default ];

  # Enable GTK (required for GTK theming)
  gtk.enable = true;

  # Enable Qt (required for Qt theming)
  qt.enable = true;

  # Enable Signal theming
  theming.signal = {
    enable = true;
    mode = "dark"; # or "light"

    # Enable GTK theming
    gtk.enable = true;

    # Enable Qt/KDE theming
    qt.enable = true;
  };
}
```

## What This Configures

### GTK (gtk.enable = true)
- Sets Adwaita or Adwaita-dark theme
- Applies Signal colors via CSS variables
- Configures GTK3 and GTK4 applications

### Qt/KDE (qt.enable = true)
- Sets Adwaita-qt style to match GTK
- Configures comprehensive KDE color scheme
- Applies to Qt5 and Qt6 applications
- Colors match Signal design system

## Auto-Enable

You can also use `autoEnable` to automatically theme both GTK and Qt when they're enabled:

```nix
{
  gtk.enable = true;
  qt.enable = true;

  theming.signal = {
    enable = true;
    autoEnable = true; # Automatically themes all enabled programs
    mode = "dark";
  };
}
```

With `autoEnable`, you don't need to explicitly set `gtk.enable` or `qt.enable` under `theming.signal`.
