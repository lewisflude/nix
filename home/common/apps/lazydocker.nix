{
  programs.lazydocker = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        showCommandLog = false;
        showFileTree = true;
      };
      update = {
        method = "background";
        days = 7;
      };
    };
  };
}
