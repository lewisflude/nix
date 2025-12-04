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
            outline-offset: 0; /* Prevent layout shifts */
            -gtk-icon-effect: none; /* Disable icon effects for performance */
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
             State priority (highest to lowest):
             1. .focused - Always shows accent color, even on hover
             2. :hover - Interactive feedback (only when not focused)
             3. .visible - Subtle background indicator
             4. default - Transparent with secondary text
             ============================================ */
          .workspaces {
            /* Minimal padding - buttons have their own spacing */
            padding: ${spacing.xs} ${spacing.sm};
          }

          /* Default state */
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

          /* Visible but not focused */
          .workspaces button.visible {
            background-color: ${colors."surface-subtle".hex};
          }

          /* Hover state - only for unfocused buttons */
          .workspaces button:hover:not(.focused) {
            background-color: ${colors."surface-emphasis".hex};
            color: ${colors."text-primary".hex};
          }

          /* Focused workspace - highest priority state */
          .workspaces button.focused {
            background-color: ${colors."accent-focus".hex};
            color: ${colors."surface-base".hex};
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

          /* ============================================
             SYSTEM INFO MODULE
             CPU/RAM display with nested elements
             ============================================ */
          .sys-info {
            color: ${colors."accent-info".hex};
            /* Padding inherited from module pills */
          }

          /* Reset nested elements - increased spacing between CPU and RAM */
          .sys-info > * {
            all: unset; /* GTK-idiomatic nuclear reset */
            padding: 0 ${spacing.sm}; /* Increased from 4px to 8px */
          }

          /* ============================================
             ICON-BASED MODULES
             Consistent font sizing for visual alignment with 16px icons
             ============================================ */
          .sys-info,
          .brightness,
          .volume,
          .notifications {
            font-size: 14px; /* Ensures font icons match 16px icon size visually */
          }

          /* ============================================
             BRIGHTNESS & VOLUME MODULES
             Semantic colors for quick identification
             ============================================ */
          .brightness {
            color: ${colors."accent-info".hex}; /* Changed from warning */
          }

          .volume {
            color: ${colors."accent-primary".hex};
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
          }

          /* ============================================
             NOTIFICATIONS MODULE
             Consistent styling and icon sizing
             Note: Notifications uses overlay.widget.notifications with button.text-button inside
             ============================================ */
          .notifications {
            /* Base styling inherited from module pills */
            color: ${colors."text-secondary".hex};
            /* Font size inherited from icon-based modules section */
          }

          /* Button inside notifications inherits parent styling */
          .notifications button {
            all: inherit; /* Inherit all properties from parent */
          }

          /* Ensure notification icons match tray icon size */
          .notifications image {
            min-width: 16px;
            min-height: 16px;
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

          /* When label has content, ensure it's always visible */
          .label label {
            color: ${colors."text-primary".hex};
          }

          /* ============================================
             SHARED INTERACTIVE HOVER STATES
             Common hover behavior for all interactive modules
             ============================================ */
          .clock:hover,
          .label:hover,
          .notifications:hover,
          .notifications button:hover {
            background-color: ${colors."surface-emphasis".hex};
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
