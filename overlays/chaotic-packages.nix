# Chaotic-Nyx bleeding-edge packages overlay
# Replaces stable packages with bleeding-edge versions from Chaotic-Nyx
# Chaotic packages are added via chaotic.nixosModules.default with _git suffix
# This overlay makes them the default versions instead of requiring _git suffix
_final: prev: {
  # Audio packages
  pipewire = prev.pipewire_git or prev.pipewire;

  # Browser packages
  firefox = prev.firefox_latest or prev.firefox;

  # Editor packages
  helix = prev.helix_git or prev.helix;
  zed-editor = prev.zed-editor_git or prev.zed-editor;

  # Terminal packages
  ghostty = prev.ghostty_git or prev.ghostty;

  # Gaming packages
  discord = prev.discord-krisp or prev.discord;
  gamescope = prev.gamescope_git or prev.gamescope;
  mangohud = prev.mangohud_git or prev.mangohud;
  # Steam from chaotic is available as "steam" (no _git suffix)
  # Chaotic's steam is the bleeding-edge version, so we prefer it if available
  # Note: This assumes chaotic's steam is already in prev.steam if chaotic module is loaded
  inherit (prev) steam;

  # Multimedia packages
  gstreamer = prev.gstreamer_git or prev.gstreamer;
  mpv = prev.mpv_git or prev.mpv;
  ffmpeg = prev.ffmpeg_git or prev.ffmpeg;

  # Development packages
  git = prev.git_git or prev.git;
  nodejs = prev.nodejs_latest or prev.nodejs;
  llvm = prev.llvm_git or prev.llvm;
  neovim = prev.neovim_git or prev.neovim;

  # Wayland/WLroots packages
  sway = prev.sway_git or prev.sway;
  # Note: swaylock-effects is a separate package (not in chaotic), so we keep using stable
  # If you want to use chaotic's swaylock-plugin_git, you can use pkgs.swaylock directly
  swaylock = prev.swaylock-plugin_git or prev.swaylock;
  wayland = prev.wayland_git or prev.wayland;
  wlroots = prev.wlroots_git or prev.wlroots;
  wayland-protocols = prev.wayland-protocols_git or prev.wayland-protocols;

  # XDG desktop portal packages
  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr_git or prev.xdg-desktop-portal-wlr;

  # Streaming/recording packages
  obs-studio = prev.obs-studio_git or prev.obs-studio;

  # ZFS packages (using CachyOS optimized version)
  zfs = prev.zfs_cachyos or prev.zfs;
  zfsUnstable = prev.zfs_cachyos or prev.zfsUnstable;
}
