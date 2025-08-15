{
  pkgs,
  cursorInfo,
  cursorVersion,
}:
let
  inherit (pkgs) appimageTools fetchurl lib;

  pname = "cursor";

  # Standard icon sizes for desktop applications
  iconSizes = [
    16
    24
    32
    48
    64
    128
    256
    512
  ];

  # XDG data directories for desktop integration and portal discovery
  xdgDataDirs = lib.concatStringsSep ":" [
    "$prefix/share"
    "@xdp_gtk@/share"
    "@xdp_wlr@/share"
    "@schemas@/share"
    "@mime@/share"
    "@gtk@/share"
    "@xdg_utils@/share"
    "\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  ];

  src = fetchurl {
    url = cursorInfo.linux.url;
    sha256 = cursorInfo.linux.sha256; # SRI
  };

  contents = appimageTools.extract {
    inherit pname src;
    version = cursorVersion;
    postExtract = ''
      # Ensure the extracted AppRun binary has execute permissions
      chmod +x $out/AppRun
    '';
  };

  # Runtime libraries commonly required by Electron apps on NixOS.
  extraLibs = with pkgs; [
    # GL / windowing / input
    libglvnd
    mesa
    vulkan-loader
    libdrm
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXext
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXfixes
    xorg.libXrender
    xorg.libXxf86vm
    xorg.libxcb
    xorg.libxkbfile

    # Audio stacks (PipeWire/Pulse/ALSA)
    alsa-lib
    pipewire
    libpulseaudio

    # Crypto / networking / printing / ids
    nss
    nspr
    libkrb5
    cups
    libuuid

    # Keyring integration
    libsecret

    # Desktop integration & MIME helpers
    glib
    gtk3
    xdg-utils
    gsettings-desktop-schemas
    shared-mime-info

    # Including the portal packages is harmless; they're not dlopen'ed libs,
    # but adding them to XDG_DATA_DIRS helps backend discovery in some setups.
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
  ];
in
appimageTools.wrapType2 {
  inherit pname src;
  version = cursorVersion;

  # Provide runtime deps to the launcher via LD_LIBRARY_PATH.
  extraPkgs = _pkgs: extraLibs;

  extraInstallCommands = ''
    # --- Desktop file: prefer upstream if present; otherwise use fallback
    # This ensures we have a proper .desktop file for application launcher integration
    if [ -f "${contents}/cursor.desktop" ]; then
      install -Dm444 "${contents}/cursor.desktop" "$out/share/applications/cursor.desktop"
    else
      install -Dm444 ${./cursor.desktop} "$out/share/applications/cursor.desktop"
    fi

    # --- Desktop file modifications to use our wrapper
    # Update the Exec line to use our wrapper script (which handles all Wayland configuration)
    # Handle both AppImage format (Exec=AppRun) and our fallback format (Exec=cursor %U)
    substituteInPlace "$out/share/applications/cursor.desktop" \
      --replace-fail "Exec=AppRun" "Exec=cursor %F" \
      --replace-warn "Exec=cursor %U" "Exec=cursor %F"

    # --- Ensure proper window manager integration
    # Add StartupWMClass if not present for consistent dock/taskbar grouping
    if ! grep -q '^StartupWMClass=' "$out/share/applications/cursor.desktop"; then
      printf '%s\n' 'StartupWMClass=cursor' >> "$out/share/applications/cursor.desktop"
    fi

    # --- Icons from AppImage payload if available
    # Extract icons in all standard sizes for better desktop integration
    ${lib.concatMapStringsSep "\n    " (size: ''
      iconPath="${contents}/usr/share/icons/hicolor/${toString size}x${toString size}/apps/cursor.png"
      if [ -f "$iconPath" ]; then
        install -Dm444 "$iconPath" "$out/share/icons/hicolor/${toString size}x${toString size}/apps/cursor.png"
      fi
    '') iconSizes}

    # --- Wrapper to set robust Wayland/portal env and PATH
    # Create a custom wrapper script that properly configures the Electron environment
    # for optimal Wayland support and desktop integration on NixOS
    mkdir -p "$out/bin"
    cat > "$out/bin/cursor" <<'EOF'
    #!@bash@/bin/bash
    set -euo pipefail

    # Compute store prefix from this script's path (avoids using $out in heredoc)
    # /nix/store/...-cursor-*/bin/cursor -> /nix/store/...-cursor-*
    prefix="$(dirname "$(dirname "$(readlink -f "$0")")")"

    # === Wayland Configuration ===
    # Prefer Wayland over X11; allow automatic fallback to X11 when needed
    # These flags enable native Wayland support in the Electron app
    export NIXOS_OZONE_WL=1
    export ELECTRON_OZONE_PLATFORM_HINT="''${ELECTRON_OZONE_PLATFORM_HINT:-auto}"

    # === Portal Integration ===
    # Use portals for open/save dialogs, file pickers, and sandboxed operations
    # This ensures proper desktop integration regardless of the window manager
    export GTK_USE_PORTAL=1

    # === XDG Data Discovery ===
    # Ensure portals, schemas, and MIME data are discoverable by the application
    # NOTE: The dollar-brace syntax is intentionally escaped to preserve shell variables
    export XDG_DATA_DIRS="${xdgDataDirs}"

    # === PATH Configuration ===
    # Make sure xdg-open and other desktop utilities are found
    export PATH="@xdg_utils@/bin:''${PATH}"

    # === Launch Application ===
    # Hand off to the AppImage entry point with Wayland-optimized flags
    # These flags are handled here instead of in the desktop file for better flexibility
    exec "''${APPDIR}/AppRun" \
      --ozone-platform-hint=auto \
      --enable-features=WaylandWindowDecorations,UseOzonePlatform \
      --enable-wayland-ime \
      "$@"
    EOF
    chmod +x "$out/bin/cursor"

    # Fill in tool paths inside the wrapper
    substituteInPlace "$out/bin/cursor" \
      --replace-fail '@bash@' '${pkgs.bash}' \
      --replace-fail '@xdp_gtk@' '${pkgs.xdg-desktop-portal-gtk}' \
      --replace-fail '@xdp_wlr@' '${pkgs.xdg-desktop-portal-wlr}' \
      --replace-fail '@schemas@' '${pkgs.gsettings-desktop-schemas}' \
      --replace-fail '@mime@' '${pkgs.shared-mime-info}' \
      --replace-fail '@gtk@' '${pkgs.gtk3}' \
      --replace-fail '@xdg_utils@' '${pkgs.xdg-utils}'
  '';

  meta = with lib; {
    description = "Cursor — AI-first code editor";
    homepage = "https://www.cursor.com/";
    license = licenses.unfree; # Cursor is not free software
    platforms = platforms.linux;
    mainProgram = "cursor";
  };
}
