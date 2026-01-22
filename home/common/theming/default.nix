{ ... }:
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";

    # Explicitly enable ironbar colors (required when using colors.ironbar in config)
    ironbar.enable = true;
  };
}
