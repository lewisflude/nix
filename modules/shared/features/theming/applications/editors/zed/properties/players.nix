# Players array (8 player color sets) for Zed theme
{
  colors,
  withAlpha,
  cat,
  ...
}:
[
  {
    cursor = colors."accent-focus".hex + "ff";
    background = colors."accent-focus".hex + "ff";
    selection = withAlpha colors."accent-focus" "3d";
  }
  {
    cursor = colors."accent-danger".hex + "ff";
    background = colors."accent-danger".hex + "ff";
    selection = withAlpha colors."accent-danger" "3d";
  }
  {
    cursor = colors."accent-warning".hex + "ff";
    background = colors."accent-warning".hex + "ff";
    selection = withAlpha colors."accent-warning" "3d";
  }
  {
    cursor = (cat "GA03").hex + "ff";
    background = (cat "GA03").hex + "ff";
    selection = withAlpha (cat "GA03") "3d";
  }
  {
    cursor = (cat "GA07").hex + "ff";
    background = (cat "GA07").hex + "ff";
    selection = withAlpha (cat "GA07") "3d";
  }
  {
    cursor = (cat "GA01").hex + "ff";
    background = (cat "GA01").hex + "ff";
    selection = withAlpha (cat "GA01") "3d";
  }
  {
    cursor = (cat "GA04").hex + "ff";
    background = (cat "GA04").hex + "ff";
    selection = withAlpha (cat "GA04") "3d";
  }
  {
    cursor = colors."accent-primary".hex + "ff";
    background = colors."accent-primary".hex + "ff";
    selection = withAlpha colors."accent-primary" "3d";
  }
]
