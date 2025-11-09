{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.theming.signal = {
    enable = mkEnableOption "Signal OKLCH color palette theme";

    mode = mkOption {
      type = types.enum [
        "light"
        "dark"
        "auto"
      ];
      default = "dark";
      description = ''
        Color theme mode:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)
      '';
    };

    # Note: Applications are defined per-platform (NixOS vs Home Manager)
    # Each platform module should define its own applications option structure
    # This allows platform-specific applications without conflicts

    # Brand governance policy for handling conflicts between functional and brand colors
    brandGovernance = {
      policy = mkOption {
        type = types.enum [
          "functional-override"
          "separate-layer"
          "integrated"
        ];
        default = "functional-override";
        description = ''
          Brand governance policy:
          - functional-override: Functional colors (e.g., accent-danger) override brand colors. Brand colors are decorative only.
          - separate-layer: Brand colors exist as a separate decorative layer alongside functional colors.
          - integrated: Brand colors can replace functional colors, but must maintain accessibility compliance.
        '';
      };

      decorativeBrandColors = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Brand colors used only for decorative elements (logos, headers, etc.).
          These do not override functional semantic colors.
          Example: { "brand-primary" = "#ff6b35"; "brand-secondary" = "#004e89"; }
        '';
      };

      brandColors = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              l = mkOption {
                type = types.float;
                description = "Lightness (0.0-1.0)";
              };
              c = mkOption {
                type = types.float;
                description = "Chroma (0.0-0.4+)";
              };
              h = mkOption {
                type = types.float;
                description = "Hue (0-360 degrees)";
              };
              hex = mkOption {
                type = types.str;
                description = "Hex color code";
              };
            };
          }
        );
        default = { };
        description = ''
          Brand colors that replace functional colors (only used with policy = "integrated").
          Must meet WCAG AA contrast requirements.
          Example: { "accent-primary" = { l = 0.7; c = 0.2; h = 130; hex = "#4db368"; }; }
        '';
      };

      # Multiple brand layers support
      # Allows defining primary, secondary, and additional brand color sets
      brandLayers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              # Layer priority (higher priority layers override lower priority ones)
              priority = mkOption {
                type = types.int;
                default = 0;
                description = "Layer priority (higher = applied later, can override previous layers)";
              };

              # Decorative colors for this layer
              decorative = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Decorative brand colors for this layer";
              };

              # Functional colors for this layer (only used with integrated policy)
              functional = mkOption {
                type = types.attrsOf (
                  types.submodule {
                    options = {
                      l = mkOption {
                        type = types.float;
                        description = "Lightness (0.0-1.0)";
                      };
                      c = mkOption {
                        type = types.float;
                        description = "Chroma (0.0-0.4+)";
                      };
                      h = mkOption {
                        type = types.float;
                        description = "Hue (0-360 degrees)";
                      };
                      hex = mkOption {
                        type = types.str;
                        description = "Hex color code";
                      };
                    };
                  }
                );
                default = { };
                description = "Functional brand colors for this layer (must meet accessibility requirements)";
              };
            };
          }
        );
        default = { };
        description = ''
          Multiple brand layers for complex branding scenarios.
          Each layer can have its own decorative and functional colors.
          Layers are applied in priority order (higher priority = applied later).
          Example:
            brandLayers = {
              primary = {
                priority = 1;
                decorative = { "brand-primary" = "#ff6b35"; };
              };
              secondary = {
                priority = 0;
                decorative = { "brand-secondary" = "#004e89"; };
              };
            };
        '';
      };
    };

    # Allow users to override specific colors (advanced usage)
    # DEPRECATED: Use brandGovernance.brandColors instead for brand integration
    overrides = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            l = mkOption {
              type = types.float;
              description = "Lightness (0.0-1.0)";
            };
            c = mkOption {
              type = types.float;
              description = "Chroma (0.0-0.4+)";
            };
            h = mkOption {
              type = types.float;
              description = "Hue (0-360 degrees)";
            };
            hex = mkOption {
              type = types.str;
              description = "Hex color code";
            };
          };
        }
      );
      default = { };
      description = ''
        Override specific palette colors. Use with caution.
        ?? DEPRECATED: For brand colors, use brandGovernance.brandColors instead.
        Example: { "accent-primary" = { l = 0.7; c = 0.2; h = 130; hex = "#4db368"; }; }
      '';
    };

    # Theme validation options
    validation = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable automatic theme validation during generation.
          When enabled, the theme will be validated for completeness and accessibility.
        '';
      };

      strictMode = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable strict validation mode.
          When enabled, theme generation will fail if validation errors are found.
          When disabled, validation errors are reported as warnings.
        '';
      };

      level = mkOption {
        type = types.enum [
          "AA"
          "AAA"
        ];
        default = "AA";
        description = ''
          WCAG contrast level to validate against:
          - AA: Minimum contrast for normal use (4.5:1 for normal text, 3:1 for large text)
          - AAA: Enhanced contrast for better accessibility (7:1 for normal text, 4.5:1 for large text)
        '';
      };

      validationLevel = mkOption {
        type = types.enum [
          "basic"
          "standard"
          "strict"
        ];
        default = "standard";
        description = ''
          Validation thoroughness level:
          - basic: Only check theme completeness (required tokens exist)
          - standard: Check completeness and critical accessibility pairs (default)
          - strict: Full validation including all color pairs and structure checks
        '';
      };

      useAPCA = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Also validate using APCA (Advanced Perceptual Contrast Algorithm).
          APCA provides more perceptually accurate contrast measurements than WCAG.
          When enabled, both WCAG and APCA validations are performed.
        '';
      };
    };

    # Theme variant support
    # Variants modify the base theme for accessibility or user preferences
    variant = mkOption {
      type = types.nullOr (
        types.enum [
          "default"
          "high-contrast"
          "reduced-motion"
          "color-blind-friendly"
        ]
      );
      default = null;
      description = ''
        Theme variant to apply:
        - default: Standard theme (no modifications)
        - high-contrast: Increased contrast for better visibility
        - reduced-motion: Reduced saturation for less visual motion
        - color-blind-friendly: Adjusted hues for better color-blind accessibility
      '';
    };
  };
}
