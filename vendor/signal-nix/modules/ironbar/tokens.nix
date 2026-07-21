# Ironbar Color Tokens - Signal Theme
# Only contains color definitions for use in CSS
# Configure ironbar layout, widgets, and behavior in your own config
{
  semantic,
  themeMode,
}:
{
  # Semantic Colors from Signal Theme
  colors = {
    text = {
      primary = (semantic.core "foreground" themeMode).hex;
      secondary = (semantic.text "secondary" themeMode).hex;
      tertiary = (semantic.text "tertiary" themeMode).hex;
    };
    surface = {
      base = (semantic.ui "panel-background" themeMode).hex;
      subtle = (semantic.ui "tab-active-background" themeMode).hex;
      hover = (semantic.ui "element-hover" themeMode).hex;
      emphasis = (semantic.ui "element-active" themeMode).hex;
    };
    divider = {
      primary = (semantic.ui "panel-border" themeMode).hex;
      secondary = (semantic.text "tertiary" themeMode).hex;
    };
    accent = {
      focus = (semantic.core "focus" themeMode).hex;
      primary = (semantic.status "success" themeMode).hex;
      secondary = (semantic.vcs "modified" themeMode).hex;
      success = (semantic.status "success" themeMode).hex;
      warning = (semantic.status "warning" themeMode).hex;
      danger = (semantic.status "error" themeMode).hex;
    };
  };
}
