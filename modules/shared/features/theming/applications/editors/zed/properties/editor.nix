# Editor properties for Zed theme
{
  colors,
  withAlpha,
  ...
}:
{
  "editor.foreground" = colors."text-primary".hex + "ff";
  "editor.background" = colors."surface-base".hex + "ff";
  "editor.gutter.background" = colors."surface-base".hex + "ff";
  "editor.subheader.background" = colors."surface-subtle".hex + "ff";
  "editor.active_line.background" = withAlpha colors."surface-subtle" "bf";
  "editor.highlighted_line.background" = colors."surface-subtle".hex + "ff";
  "editor.line_number" = colors."text-tertiary".hex;
  "editor.active_line_number" = colors."text-primary".hex;
  "editor.invisible" = colors."text-tertiary".hex + "ff";
  "editor.indent_guide" = withAlpha colors."divider-primary" "1a";
  "editor.indent_guide_active" = withAlpha colors."divider-primary" "33";
  "editor.wrap_guide" = withAlpha colors."divider-primary" "0d";
  "editor.active_wrap_guide" = withAlpha colors."divider-primary" "1a";
  "editor.document_highlight.bracket_background" = withAlpha colors."accent-focus" "1a";
  "editor.document_highlight.read_background" = withAlpha colors."accent-focus" "1a";
  "editor.document_highlight.write_background" = withAlpha colors."text-tertiary" "66";
}
