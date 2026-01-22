{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.satty ];

  # Ensure Screenshots directory exists
  home.file."Pictures/Screenshots/.keep".text = "";
}
