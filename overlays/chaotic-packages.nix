_final: prev: {

  pipewire = prev.pipewire_git or prev.pipewire;

  helix = prev.helix_git or prev.helix;
  zed-editor = prev.zed-editor_git or prev.zed-editor;

  ghostty = prev.ghostty_git or prev.ghostty;

  discord = prev.discord-krisp or prev.discord;
  gamescope = prev.gamescope_git or prev.gamescope;
  mangohud = prev.mangohud_git or prev.mangohud;

  inherit (prev) steam;

  gstreamer = prev.gstreamer_git or prev.gstreamer;
  mpv = prev.mpv_git or prev.mpv;
  ffmpeg = prev.ffmpeg_git or prev.ffmpeg;

  git = prev.git_git or prev.git;
  nodejs = prev.nodejs_latest or prev.nodejs;
  llvm = prev.llvm_git or prev.llvm;
  neovim = prev.neovim_git or prev.neovim;

  sway = prev.sway_git or prev.sway;

  swaylock = prev.swaylock-plugin_git or prev.swaylock;
  wayland = prev.wayland_git or prev.wayland;
  wlroots = prev.wlroots_git or prev.wlroots;
  wayland-protocols = prev.wayland-protocols_git or prev.wayland-protocols;

  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr_git or prev.xdg-desktop-portal-wlr;

  obs-studio = prev.obs-studio_git or prev.obs-studio;

  # zfs_cachyos causes kernel module issues, use regular zfs
  inherit (prev) zfs zfsUnstable;
}
