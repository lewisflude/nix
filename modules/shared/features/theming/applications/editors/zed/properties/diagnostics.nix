# Diagnostic properties for Zed theme (complete set)
{
  colors,
  withAlpha,
  ...
}:
{
  conflict = colors."accent-warning".hex + "ff";
  "conflict.background" = withAlpha colors."accent-warning" "1a";
  "conflict.border" = colors."accent-warning".hex + "ff";
  created = colors."accent-primary".hex + "ff";
  "created.background" = withAlpha colors."accent-primary" "1a";
  "created.border" = colors."accent-primary".hex + "ff";
  deleted = colors."accent-danger".hex + "ff";
  "deleted.background" = withAlpha colors."accent-danger" "1a";
  "deleted.border" = colors."accent-danger".hex + "ff";
  error = colors."accent-danger".hex + "ff";
  "error.background" = withAlpha colors."accent-danger" "1a";
  "error.border" = colors."accent-danger".hex + "ff";
  hidden = colors."text-tertiary".hex + "ff";
  "hidden.background" = withAlpha colors."text-tertiary" "1a";
  "hidden.border" = colors."divider-primary".hex + "ff";
  hint = colors."accent-info".hex + "ff";
  "hint.background" = withAlpha colors."accent-info" "1a";
  "hint.border" = colors."accent-focus".hex + "ff";
  ignored = colors."text-tertiary".hex + "ff";
  "ignored.background" = withAlpha colors."text-tertiary" "1a";
  "ignored.border" = colors."divider-primary".hex + "ff";
  info = colors."accent-focus".hex + "ff";
  "info.background" = withAlpha colors."accent-focus" "1a";
  "info.border" = colors."accent-focus".hex + "ff";
  modified = colors."accent-warning".hex + "ff";
  "modified.background" = withAlpha colors."accent-warning" "1a";
  "modified.border" = colors."accent-warning".hex + "ff";
  predictive = colors."text-secondary".hex + "ff";
  "predictive.background" = withAlpha colors."text-secondary" "1a";
  "predictive.border" = colors."accent-primary".hex + "ff";
  renamed = colors."accent-focus".hex + "ff";
  "renamed.background" = withAlpha colors."accent-focus" "1a";
  "renamed.border" = colors."accent-focus".hex + "ff";
  success = colors."accent-primary".hex + "ff";
  "success.background" = withAlpha colors."accent-primary" "1a";
  "success.border" = colors."accent-primary".hex + "ff";
  unreachable = colors."text-secondary".hex + "ff";
  "unreachable.background" = withAlpha colors."text-secondary" "1a";
  "unreachable.border" = colors."divider-primary".hex + "ff";
  warning = colors."accent-warning".hex + "ff";
  "warning.background" = withAlpha colors."accent-warning" "1a";
  "warning.border" = colors."accent-warning".hex + "ff";
}
