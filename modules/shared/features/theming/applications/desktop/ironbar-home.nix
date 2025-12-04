{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme;
in
{
  config = mkIf (cfg.enable && cfg.applications.ironbar.enable && theme != null) {
    programs.ironbar = {
      style =
        let
          inherit (theme) colors;

          # Design System Constants (4px spacing scale)
          spacing = {
            xs = "4px"; # 1x - Tight internal spacing
            sm = "8px"; # 2x - Module container padding
            md = "12px"; # 3x - Standard element padding
            lg = "16px"; # 4x - Wider element padding
            xl = "20px"; # 5x - Extra spacing
            xxl = "24px"; # 6x - Maximum spacing
          };

          radius = {
            sm = "8px"; # Small elements (buttons, chips)
            md = "12px"; # Module pills
          };
        in
        ''
          /* ============================================
             IRONBAR GTK CSS STYLING
             Note: GTK CSS does NOT support :root or CSS variables
             All values are inlined via Nix string interpolation
             ============================================ */

          /* ============================================
             GLOBAL RESET
             ============================================ */
          * {
            font-family: "JetBrainsMono Nerd Font", "Iosevka Nerd Font", sans-serif;
            font-size: 14px;
            font-weight: 600;
            border: none;
            border-radius: 0;
            min-height: 0;
            box-shadow: none;
            text-shadow: none;
          }

          /* ============================================
             WINDOW TRANSPARENCY
             Ensures bar background is fully transparent
             ============================================ */
          window#ironbar,
          #bar,
          .background {
            background-color: rgba(0, 0, 0, 0);
            background-image: none;
          }

          /* ============================================
             MODULE PILLS (Island Design Pattern)
             Shared styling for all floating modules
             ============================================ */
          .workspaces,
          .label,
          .clock,
          .sys-info,
          .brightness,
          .volume,
          .tray,
          .notifications {
            background-color: ${colors."surface-subtle".hex};
            color: ${colors."text-primary".hex};

            /* Pill shape with consistent radius */
            border-radius: ${radius.md};
            border: 1px solid ${colors."divider-primary".hex};

            /* Uniform floating margins (4px scale) */
            margin: ${spacing.xs};

            /* Standard internal padding WITH vertical padding for centering */
            padding: ${spacing.xs} ${spacing.lg};
          }

          /* ============================================
             WORKSPACES MODULE
             ============================================ */
          .workspaces {
            /* Minimal padding - buttons have their own spacing */
            padding: ${spacing.xs} ${spacing.sm};
          }

          .workspaces button {
            background-color: transparent;
            color: ${colors."text-secondary".hex};

            /* Reduced size to fit 40px bar with proper spacing */
            min-height: 24px;
            min-width: 28px;
            padding: ${spacing.xs} ${spacing.md};

            /* Horizontal spacing between buttons */
            margin: 0 ${spacing.xs};

            border-radius: ${radius.sm};
          }

          /* Hover state - only for unfocused buttons */
          .workspaces button:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          /* Focused workspace - highest priority state */
          .workspaces button.focused {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
          }

          /* Focused + Hover - maintain focus appearance */
          .workspaces button.focused:hover {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
          }

          /* Visible but not focused */
          .workspaces button.visible {
            background-color: ${colors."surface-subtle".hex};
          }

          /* Keyboard navigation (accessibility) */
          .workspaces button:focus-visible {
            outline: 2px solid ${colors."accent-primary".hex};
            outline-offset: 2px;
          }

          /* ============================================
             CLOCK MODULE
             Subtle styling - blends with other modules
             ============================================ */
          .clock {
            color: ${colors."text-secondary".hex};
            font-weight: 600; /* Match global weight */
            /* Padding inherited from module pills (4px vertical, 16px horizontal) */
          }

          .clock:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          /* ============================================
             SYSTEM INFO MODULE
             CPU/RAM display with nested elements
             ============================================ */
          .sys-info {
            color: ${colors."accent-info".hex};
            /* Padding inherited from module pills */
          }

          /* Reset nested elements - increased spacing between CPU and RAM */
          .sys-info button,
          .sys-info label {
            background: none;
            border: none;
            padding: 0 ${spacing.sm}; /* Increased from 4px to 8px */
            margin: 0;
            box-shadow: none;
          }

          /* Ensure font icons in sys-info are visually consistent with 16px icons */
          .sys-info {
            font-size: 14px; /* Match global font size for icon consistency */
          }

          /* ============================================
             BRIGHTNESS & VOLUME MODULES
             Semantic colors for quick identification
             Consistent icon sizing with font icons
             ============================================ */
          .brightness {
            color: ${colors."accent-info".hex}; /* Changed from warning */
            /* Font icons should match 16px icon size visually */
            font-size: 14px;
          }

          .volume {
            color: ${colors."accent-primary".hex};
            /* Font icons should match 16px icon size visually */
            font-size: 14px;
          }

          /* ============================================
             TRAY MODULE
             Consistent icon sizing with other modules
             ============================================ */
          .tray {
            /* Vertical padding inherited, horizontal slightly reduced */
            padding: ${spacing.xs} ${spacing.md};
          }

          /* Ensure tray icons are consistently sized */
          .tray image {
            min-width: 16px;
            min-height: 16px;
            /* GTK CSS doesn't support max-width/max-height */
          }

          /* ============================================
             NOTIFICATIONS MODULE
             Consistent styling and icon sizing
             ============================================ */
          .notifications {
            /* Base styling from module pills */
            background-color: ${colors."surface-subtle".hex};
            border-radius: ${radius.md};
            border: 1px solid ${colors."divider-primary".hex};
            margin: ${spacing.xs};

            /* Match other icon-based modules */
            padding: ${spacing.xs} ${spacing.md};
            color: ${colors."text-secondary".hex};
            /* Font icons should match 16px icon size visually */
            font-size: 14px;
          }

          /* Ensure notification icon matches tray icon size */
          .notifications image,
          .notifications button image {
            min-width: 16px;
            min-height: 16px;
            /* GTK CSS doesn't support max-width/max-height */
            /* Apply filter to make outlined icons appear more solid/filled */
            filter: brightness(1.2) contrast(1.1);
          }

          /* Hover state for better interactivity */
          .notifications:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          /* Unread notification indicator */
          .notifications.notification-count {
            color: ${colors."accent-danger".hex};
          }

          /* ============================================
             LABEL MODULE (Window Title / Focused Widget)
             Improved contrast for better visibility
             ============================================ */
          .label {
            /* Use primary text for better contrast */
            color: ${colors."text-primary".hex};
            font-style: italic;
            /* Ensure it's visible even when empty */
            min-width: 0;
          }

          /* Hover state for better interactivity */
          .label:hover {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          /* When label has content, ensure it's always visible */
          .label label {
            color: ${colors."text-primary".hex};
          }

          /* ============================================
             TOOLTIPS
             ============================================ */
          tooltip {
            background-color: ${colors."surface-base".hex};
            border: 1px solid ${colors."divider-primary".hex};
            border-radius: ${radius.md};
            padding: ${spacing.sm} ${spacing.md};
          }

          /* ============================================
             POPUP MENUS
             Note: margin-top removed - handled by popup_gap config
             ============================================ */
          popup {
            background-color: ${colors."surface-base".hex};
            border: 1px solid ${colors."divider-primary".hex};
            border-radius: ${radius.md};
            padding: ${spacing.md};
          }
        '';
    };
  };
}
