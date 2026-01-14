# Alternative workspace configurations for ironbar
# Use if name_map icons don't display properly
#
# NOTE: Some CSS techniques below (::before pseudo-elements, content property)
# are NOT supported by GTK CSS. They are included for reference only.
# GTK CSS is a subset of CSS3 - see gtk-css-spec.md for supported properties.

{
  # Option 1: Simple text labels (most reliable)
  workspacesTextLabels = {
    type = "workspaces";
    class = "workspaces";
    name_map = {
      "1" = "Web";
      "2" = "Web2";
      "3" = "Dev";
      "4" = "Dev2";
      "5" = "Chat";
      "6" = "Chat2";
      "7" = "Media";
      "8" = "Media2";
      "9" = "Game";
      "10" = "Misc";
    };
    hide_empty = false;
    hide_lonely = false;
    show_icon = false;
  };

  # Option 2: Numbers only, styled with CSS ::before pseudo-elements
  workspacesNumbered = {
    type = "workspaces";
    class = "workspaces";
    hide_empty = false;
    hide_lonely = false;
    show_icon = false;
  };

  # CSS to add icons via ::before
  # WARNING: This does NOT work in GTK CSS - ::before/::after pseudo-elements
  # and the content property are not supported. Kept for reference only.
  # Consider using name_map with Unicode/emoji icons instead.
  workspacesCssIcons = ''
    /* Add semantic icons before workspace numbers */
    .workspaces button[data-name="1"]::before { content: "󰈹 "; }
    .workspaces button[data-name="2"]::before { content: "󰖟 "; }
    .workspaces button[data-name="3"]::before { content: "󰨞 "; }
    .workspaces button[data-name="4"]::before { content: " "; }
    .workspaces button[data-name="5"]::before { content: "󰭹 "; }
    .workspaces button[data-name="6"]::before { content: "󰙯 "; }
    .workspaces button[data-name="7"]::before { content: "󰝚 "; }
    .workspaces button[data-name="8"]::before { content: "󰎆 "; }
    .workspaces button[data-name="9"]::before { content: "󰊴 "; }
    .workspaces button[data-name="10"]::before { content: "󰋙 "; }

    /* Hide the workspace number itself, show only icon */
    .workspaces button[data-name] { font-size: 0; }
    .workspaces button[data-name]::before { font-size: 16px; }
  '';

  # Option 3: Custom script widget (most control, but more complex)
  workspacesCustomScript = {
    type = "script";
    class = "workspaces-custom";
    mode = "watch";
    cmd = ''
      niri msg --json event-stream | jq -r --unbuffered '
        select(.WorkspacesChanged != null) |
        .WorkspacesChanged.workspaces |
        map(
          (if .idx == 1 then "󰈹"
           elif .idx == 2 then "󰖟"
           elif .idx == 3 then "󰨞"
           elif .idx == 4 then ""
           elif .idx == 5 then "󰭹"
           elif .idx == 6 then "󰙯"
           elif .idx == 7 then "󰝚"
           elif .idx == 8 then "󰎆"
           elif .idx == 9 then "󰊴"
           elif .idx == 10 then "󰋙"
           else .idx end) +
          (if .is_active then "*" else "" end)
        ) |
        join(" ")
      '
    '';
  };
}
