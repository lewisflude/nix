{ pkgs, ... }: {
  home.packages = with pkgs; [
    (ffmpeg-full.override { withUnfree = true; withOpengl = true; withCuda = true; })
  ];


  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "text/plain" = "helix.desktop";
      "application/pdf" = "org.gnome.Evince.desktop";
      "image/jpeg" = "org.gnome.eog.desktop";
      "image/png" = "org.gnome.eog.desktop";
      "video/mp4" = "io.mpv.Mpv.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };
  };
}
