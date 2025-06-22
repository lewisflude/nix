{ ... }: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 30;
        horizontal-pad = 40;
        vertical-pad = 8;
        inner-pad = 0;
        image-size-ratio = 0.5;
        icon-theme = "Papirus";
        dpi-aware = "auto";
        show-actions = true;
        password-character = "*";
        placeholder-text = "Type to search...";
        launch-prefix = "uwsm app --";
      };
      
      colors = {
        background = "24273add";
        text = "cad3f5ff";
        match = "ed8796ff";
        selection = "5b6078ff";
        selection-text = "cad3f5ff";
        selection-match = "ed8796ff";
        border = "b7bdf8ff";
      };
      
      border = {
        width = 1;
        radius = 8;
      };
      
      dmenu = {
        exit-immediately-if-empty = true;
      };
    };
  };
}