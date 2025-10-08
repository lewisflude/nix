{lib, ...}: {
  programs.micro = {
    enable = true;
    settings = {
      autoindent = true;
      tabmovement = true;
      tabsize = 2;
      ruler = true;
      scrollmargin = 3;
      ignorecase = true;
      smartcase = true;
      syntax = true;
      colorscheme = lib.mkForce "default";
    };
  };
}
