# UI component properties for Zed theme
{
  colors,
  withAlpha,
  ...
}:
{
  "status_bar.background" = colors."surface-emphasis".hex + "ff";
  "title_bar.background" = colors."surface-emphasis".hex + "ff";
  "title_bar.inactive_background" = colors."surface-base".hex + "ff";
  "toolbar.background" = colors."surface-base".hex + "ff";
  "tab_bar.background" = colors."surface-subtle".hex + "ff";
  "tab.inactive_background" = colors."surface-subtle".hex + "ff";
  "tab.active_background" = colors."surface-base".hex + "ff";
  "search.match_background" = withAlpha colors."accent-warning" "66";
  "panel.background" = colors."surface-subtle".hex + "ff";
  "panel.focused_border" = null;
  "panel.indent_guide" = withAlpha colors."divider-primary" "1a";
  "panel.indent_guide_active" = withAlpha colors."divider-primary" "33";
  "panel.indent_guide_hover" = withAlpha colors."divider-primary" "4c";
  "pane.focused_border" = null;
  "pane_group.border" = colors."divider-primary".hex + "ff";
}
