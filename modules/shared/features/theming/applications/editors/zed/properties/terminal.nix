# Terminal properties for Zed theme (complete ANSI set)
{
  colors,
  withAlpha,
  ...
}:
{
  "terminal.background" = colors."surface-base".hex + "ff";
  "terminal.foreground" = colors."text-primary".hex + "ff";
  "terminal.bright_foreground" = colors."text-primary".hex + "ff";
  "terminal.dim_foreground" = colors."surface-base".hex + "ff";
  "terminal.ansi.background" = colors."surface-base".hex + "ff";
  "terminal.ansi.black" = colors."ansi-black".hex + "ff";
  "terminal.ansi.bright_black" = colors."ansi-bright-black".hex + "ff";
  "terminal.ansi.dim_black" = colors."text-primary".hex + "ff";
  "terminal.ansi.red" = colors."ansi-red".hex + "ff";
  "terminal.ansi.bright_red" = colors."ansi-red".hex + "ff";
  "terminal.ansi.dim_red" = withAlpha colors."ansi-red" "cc";
  "terminal.ansi.green" = colors."ansi-green".hex + "ff";
  "terminal.ansi.bright_green" = colors."ansi-green".hex + "ff";
  "terminal.ansi.dim_green" = withAlpha colors."ansi-green" "cc";
  "terminal.ansi.yellow" = colors."ansi-yellow".hex + "ff";
  "terminal.ansi.bright_yellow" = colors."ansi-yellow".hex + "ff";
  "terminal.ansi.dim_yellow" = withAlpha colors."ansi-yellow" "cc";
  "terminal.ansi.blue" = colors."ansi-blue".hex + "ff";
  "terminal.ansi.bright_blue" = colors."ansi-blue".hex + "ff";
  "terminal.ansi.dim_blue" = withAlpha colors."ansi-blue" "cc";
  "terminal.ansi.magenta" = colors."ansi-magenta".hex + "ff";
  "terminal.ansi.bright_magenta" = colors."ansi-magenta".hex + "ff";
  "terminal.ansi.dim_magenta" = withAlpha colors."ansi-magenta" "cc";
  "terminal.ansi.cyan" = colors."ansi-cyan".hex + "ff";
  "terminal.ansi.bright_cyan" = colors."ansi-cyan".hex + "ff";
  "terminal.ansi.dim_cyan" = withAlpha colors."ansi-cyan" "cc";
  "terminal.ansi.white" = colors."ansi-white".hex + "ff";
  "terminal.ansi.bright_white" = colors."ansi-bright-white".hex + "ff";
  "terminal.ansi.dim_white" = colors."text-tertiary".hex + "ff";
}
