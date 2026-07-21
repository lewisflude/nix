# Signal Semantic Bridge
# Maps UI concepts to Signal palette colors
# Based on signal-palette/semantic-bridge.json v1.1.0
#
# This provides a stable, semantic API for accessing colors across all modules.
# Instead of navigating palette paths directly, modules use semantic names like:
#   semantic.core "background" mode
#   semantic.terminal "ansi-red" mode
#   semantic.syntax "keyword" mode
#
# This abstraction allows the palette structure to change without breaking modules.

{ lib, palette }:

let
  # ============================================================================
  # Semantic Bridge Definitions
  # ============================================================================
  # Maps semantic UI concepts to palette paths
  # Format: { type = "tonal" | "accent" | "categorical"; path = ...; }

  semanticBridge = {
    # Core UI elements - fundamental colors used everywhere
    core = {
      background = {
        type = "tonal";
        path = "surface-base";
      };
      foreground = {
        type = "tonal";
        path = "text-primary";
      };
      cursor = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      selection-bg = {
        type = "tonal";
        path = "divider-strong";
      };
      selection-fg = {
        type = "tonal";
        path = "text-primary";
      };
      focus = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
    };

    # UI components - panels, borders, hover states
    ui = {
      panel-background = {
        type = "tonal";
        path = "surface-subtle";
      };
      panel-border = {
        type = "tonal";
        path = "divider-primary";
      };
      element-hover = {
        type = "tonal";
        path = "surface-hover";
      };
      element-active = {
        type = "tonal";
        path = "divider-strong";
      };
      element-selected = {
        type = "tonal";
        path = "divider-strong";
      };
      element-disabled = {
        type = "tonal";
        path = "surface-subtle";
      };
      status-bar-background = {
        type = "tonal";
        path = "surface-base";
      };
      tab-active-background = {
        type = "tonal";
        path = "surface-subtle";
      };
      tab-inactive-background = {
        type = "tonal";
        path = "surface-base";
      };
      tab-border = {
        type = "tonal";
        path = "divider-primary";
      };
      title-bar-active = {
        type = "tonal";
        path = "surface-base";
      };
      title-bar-inactive = {
        type = "tonal";
        path = "surface-subtle";
      };
    };

    # Text colors - primary, secondary, tertiary, disabled
    text = {
      primary = {
        type = "tonal";
        path = "text-primary";
      };
      secondary = {
        type = "tonal";
        path = "text-secondary";
      };
      tertiary = {
        type = "tonal";
        path = "text-tertiary";
      };
      disabled = {
        type = "tonal";
        path = "text-tertiary";
      };
      placeholder = {
        type = "tonal";
        path = "text-tertiary";
      };
      link = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      link-hover = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
    };

    # Terminal ANSI colors - standard 16-color palette
    terminal = {
      ansi-black = {
        type = "tonal";
        path = "surface-base";
      };
      ansi-red = {
        type = "categorical";
        name = "data-viz-01";
      };
      ansi-green = {
        type = "accent";
        semantic = "primary";
        tier = "Lc75";
      };
      ansi-yellow = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      ansi-blue = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      ansi-magenta = {
        type = "accent";
        semantic = "tertiary";
        tier = "Lc75";
      };
      ansi-cyan = {
        type = "accent";
        semantic = "secondary";
        tier = "Lc75";
      };
      ansi-white = {
        type = "tonal";
        path = "text-primary";
      };
      ansi-bright-black = {
        type = "tonal";
        path = "text-tertiary";
      };
      ansi-bright-red = {
        type = "categorical";
        name = "data-viz-01";
      };
      ansi-bright-green = {
        type = "accent";
        semantic = "primary";
        tier = "Lc75";
      };
      ansi-bright-yellow = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      ansi-bright-blue = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      ansi-bright-magenta = {
        type = "accent";
        semantic = "tertiary";
        tier = "Lc75";
      };
      ansi-bright-cyan = {
        type = "accent";
        semantic = "secondary";
        tier = "Lc75";
      };
      ansi-bright-white = {
        type = "tonal";
        path = "white";
      };
    };

    # Editor-specific UI elements
    editor = {
      background = {
        type = "tonal";
        path = "surface-base";
      };
      foreground = {
        type = "tonal";
        path = "text-primary";
      };
      gutter-background = {
        type = "tonal";
        path = "surface-base";
      };
      active-line-background = {
        type = "tonal";
        path = "surface-subtle";
      };
      line-number = {
        type = "tonal";
        path = "text-tertiary";
      };
      active-line-number = {
        type = "tonal";
        path = "text-secondary";
      };
      indent-guide = {
        type = "tonal";
        path = "divider-primary";
      };
      indent-guide-active = {
        type = "tonal";
        path = "divider-strong";
      };
      invisible = {
        type = "tonal";
        path = "divider-primary";
      };
      bracket-match-background = {
        type = "tonal";
        path = "divider-strong";
      };
      find-match-background = {
        type = "categorical";
        name = "data-viz-04";
      };
      find-match-foreground = {
        type = "tonal";
        path = "surface-base";
      };
      scrollbar-thumb = {
        type = "tonal";
        path = "divider-strong";
      };
      scrollbar-track = {
        type = "tonal";
        path = "surface-base";
      };
    };

    # Syntax highlighting - code editor colors
    syntax = {
      keyword = {
        type = "accent";
        semantic = "tertiary";
        tier = "Lc75";
      };
      function = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      string = {
        type = "categorical";
        name = "data-viz-01";
      };
      number = {
        type = "categorical";
        name = "data-viz-03";
      };
      comment = {
        type = "tonal";
        path = "text-tertiary";
      };
      type = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      variable = {
        type = "tonal";
        path = "text-primary";
      };
      constant = {
        type = "categorical";
        name = "data-viz-06";
      };
      operator = {
        type = "tonal";
        path = "text-secondary";
      };
      tag = {
        type = "accent";
        semantic = "secondary";
        tier = "Lc75";
      };
      attribute = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      preprocessing = {
        type = "accent";
        semantic = "tertiary";
        tier = "Lc75";
      };
      punctuation = {
        type = "tonal";
        path = "text-tertiary";
      };
      escape = {
        type = "categorical";
        name = "data-viz-08";
      };
    };

    # Markup language elements (Markdown, etc.)
    markup = {
      heading = {
        type = "accent";
        semantic = "danger";
        tier = "Lc75";
      };
      bold = {
        type = "tonal";
        path = "text-primary";
      };
      italic = {
        type = "tonal";
        path = "text-primary";
      };
      link = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      link-url = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      code = {
        type = "categorical";
        name = "data-viz-02";
      };
      code-block = {
        type = "tonal";
        path = "surface-subtle";
      };
      quote = {
        type = "tonal";
        path = "text-secondary";
      };
      list-marker = {
        type = "accent";
        semantic = "tertiary";
        tier = "Lc75";
      };
    };

    # Version control status colors
    vcs = {
      added = {
        type = "accent";
        semantic = "primary";
        tier = "Lc75";
      };
      modified = {
        type = "accent";
        semantic = "secondary";
        tier = "Lc75";
      };
      deleted = {
        type = "accent";
        semantic = "danger";
        tier = "Lc75";
      };
      renamed = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      conflict = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      ignored = {
        type = "tonal";
        path = "text-tertiary";
      };
    };

    # Status indicators - error, warning, success, info
    status = {
      error = {
        type = "accent";
        semantic = "danger";
        tier = "Lc75";
      };
      warning = {
        type = "accent";
        semantic = "warning";
        tier = "Lc75";
      };
      success = {
        type = "accent";
        semantic = "primary";
        tier = "Lc75";
      };
      info = {
        type = "accent";
        semantic = "info";
        tier = "Lc75";
      };
      hint = {
        type = "tonal";
        path = "text-secondary";
      };
    };

    # Multiplayer/collaboration colors - distinct per-user colors
    multiplayer = {
      player-1 = {
        type = "categorical";
        name = "data-viz-01";
      };
      player-2 = {
        type = "categorical";
        name = "data-viz-02";
      };
      player-3 = {
        type = "categorical";
        name = "data-viz-03";
      };
      player-4 = {
        type = "categorical";
        name = "data-viz-04";
      };
      player-5 = {
        type = "categorical";
        name = "data-viz-05";
      };
      player-6 = {
        type = "categorical";
        name = "data-viz-06";
      };
      player-7 = {
        type = "categorical";
        name = "data-viz-07";
      };
      player-8 = {
        type = "categorical";
        name = "data-viz-08";
      };
    };
  };

  # ============================================================================
  # Color Resolution Functions
  # ============================================================================

  # Resolve a color specification to the actual color object from palette
  # Returns the full color object with { l, c, h, hex, hexRaw, rgb, description }
  resolveColor =
    spec: mode:
    let
      # Helper to find similar names (simple Levenshtein-like matching)
      findSimilar =
        target: available:
        let
          # Simple similarity check - contains substring or starts with same letter
          similar = builtins.filter (
            name:
            (lib.hasPrefix (builtins.substring 0 1 target) name)
            || (lib.hasInfix (builtins.substring 0 3 target) name)
          ) available;
        in
        if similar != [ ] then
          ''

            Did you mean one of these?
              ${lib.concatMapStringsSep "\n  " (n: "- ${n}") (lib.take 5 similar)}''
        else
          "";

      color =
        if spec.type == "tonal" then
          palette.tonal.${mode}.${spec.path} or (
            let
              available = builtins.attrNames palette.tonal.${mode};
              suggestions = findSimilar spec.path available;
            in
            throw ''
              ❌ Tonal color '${spec.path}' not found for mode '${mode}'

              This is likely a typo in your semantic bridge mapping or module code.
              ${suggestions}

              Available tonal colors for ${mode} mode:
                ${lib.concatMapStringsSep "\n  " (n: "- ${n}") available}

              💡 Tip: Use semantic.core "background" instead of direct palette access.
              📖 See: docs/QUICK_REFERENCE.md for all semantic categories.
            ''
          )
        else if spec.type == "accent" then
          palette.accent.${spec.semantic}.${spec.tier} or (
            let
              availableSemantics = builtins.attrNames palette.accent;
              suggestions = findSimilar spec.semantic availableSemantics;
            in
            throw ''
              ❌ Accent color '${spec.semantic}.${spec.tier}' not found

              This is likely a typo in your semantic bridge mapping.
              ${suggestions}

              Available accent semantics:
                ${lib.concatMapStringsSep "\n  " (n: "- ${n}") availableSemantics}

              Available tiers: Lc75, Lc60

              💡 Tip: Most UI elements use Lc75 tier for better contrast.
              📖 See: docs/signal-palette-integration.md for accent usage.
            ''
          )
        else if spec.type == "categorical" then
          palette.categorical.${mode}.${spec.name} or (
            let
              available = builtins.attrNames palette.categorical.${mode};
              suggestions = findSimilar spec.name available;
            in
            throw ''
              ❌ Categorical color '${spec.name}' not found for mode '${mode}'

              This is likely a typo in your semantic bridge mapping.
              ${suggestions}

              Available categorical colors for ${mode} mode:
                ${lib.concatMapStringsSep "\n  " (n: "- ${n}") available}

              💡 Tip: Categorical colors are for data visualization and distinct UI elements.
              📖 See: docs/QUICK_REFERENCE.md § multiplayer category.
            ''
          )
        else
          throw ''
            ❌ Unknown color type: '${spec.type}'

            Valid color types are:
              - tonal       (for UI surfaces and text)
              - accent      (for semantic colors like primary, danger, info)
              - categorical (for data visualization and multiplayer)

            This is a bug in the semantic bridge definition.
            Please report this at: https://github.com/lewisflude/signal-nix/issues
          '';
    in
    color;

  # Main resolver function - looks up semantic name and resolves to color
  # Returns the full color object
  resolve =
    category: name: mode:
    let
      # Helper to find similar category names
      findSimilarCategory =
        target:
        let
          available = builtins.attrNames semanticBridge;
          similar = builtins.filter (
            cat: (lib.hasPrefix (builtins.substring 0 1 target) cat) || (lib.hasInfix target cat)
          ) available;
        in
        if similar != [ ] then
          ''

            Did you mean one of these categories?
              ${lib.concatMapStringsSep "\n  " (n: "- ${n}") (lib.take 3 similar)}''
        else
          "";

      # Helper to find similar names within a category
      findSimilarName =
        target: categoryNames:
        let
          similar = builtins.filter (
            n: (lib.hasPrefix (builtins.substring 0 1 target) n) || (lib.hasInfix target n)
          ) categoryNames;
        in
        if similar != [ ] then
          ''

            Did you mean one of these?
              ${lib.concatMapStringsSep "\n  " (n: "- ${n}") (lib.take 5 similar)}''
        else
          "";

      spec =
        semanticBridge.${category}.${name} or (
          let
            allCategories = builtins.attrNames semanticBridge;
            categorySuggestions = findSimilarCategory category;
          in
          if !(semanticBridge ? ${category}) then
            throw ''
              ❌ Semantic category '${category}' not found

              You tried to access: semantic.${category} "${name}" ${mode}
              ${categorySuggestions}

              Available categories:
                ${lib.concatMapStringsSep "\n  " (n: "- ${n}") allCategories}

              💡 Example usage:
                semantic.core "background" mode
                semantic.terminal "ansi-red" mode
                semantic.syntax "keyword" mode

              📖 See: docs/QUICK_REFERENCE.md for all categories and their colors.
            ''
          else
            let
              categoryNames = builtins.attrNames semanticBridge.${category};
              nameSuggestions = findSimilarName name categoryNames;
            in
            throw ''
              ❌ Semantic name '${name}' not found in category '${category}'

              You tried to access: semantic.${category} "${name}" ${mode}
              ${nameSuggestions}

              Available names in '${category}':
                ${lib.concatMapStringsSep "\n  " (n: "- ${n}") categoryNames}

              💡 Example usage for this category:
                semantic.${category} "${builtins.head categoryNames}" mode

              📖 See: docs/QUICK_REFERENCE.md § ${category} for all available names.
            ''
        );
    in
    resolveColor spec mode;

  # Convenience function to get just the hex value (most common use case)
  resolveHex =
    category: name: mode:
    (resolve category name mode).hex;

in
{
  # Export the semantic bridge for inspection/documentation
  inherit semanticBridge;

  # Main resolution functions
  inherit resolve resolveColor;

  # Convenience function for hex-only (most common)
  hex = resolveHex;

  # Category-specific convenience functions
  # These return the full color object
  core = name: mode: resolve "core" name mode;
  ui = name: mode: resolve "ui" name mode;
  text = name: mode: resolve "text" name mode;
  terminal = name: mode: resolve "terminal" name mode;
  editor = name: mode: resolve "editor" name mode;
  syntax = name: mode: resolve "syntax" name mode;
  markup = name: mode: resolve "markup" name mode;
  vcs = name: mode: resolve "vcs" name mode;
  status = name: mode: resolve "status" name mode;
  multiplayer = name: mode: resolve "multiplayer" name mode;

  # Bulk operations - get all colors for a category in a mode
  # Returns attrset of { name = colorObject; ... }
  getAllColors =
    category: mode: lib.mapAttrs (name: spec: resolveColor spec mode) semanticBridge.${category};

  # Get all available semantic names for a category
  # Useful for validation and documentation
  getAvailableNames = category: builtins.attrNames semanticBridge.${category};

  # Get all available categories
  getAvailableCategories = builtins.attrNames semanticBridge;

  # ============================================================================
  # Direct Palette Access Helpers
  # ============================================================================
  # These functions provide controlled access to palette internals for cases
  # where semantic mappings don't apply (e.g., tier-specific requirements,
  # raw categorical colors). Use sparingly and document why semantic bridge
  # doesn't work for your use case.

  # Get a categorical color by name (data-viz-01 through data-viz-08)
  # Use this when you need raw categorical colors outside of semantic mappings
  getCategorical =
    name: mode:
    palette.categorical.${mode}.${name} or (throw ''
      ❌ Categorical color '${name}' not found for mode '${mode}'

      Available categorical colors:
        ${lib.concatMapStringsSep "\n  " (n: "- ${n}") (builtins.attrNames palette.categorical.${mode})}

      💡 Tip: Consider using semantic.multiplayer if this is for distinct UI elements.
      📖 See: docs/QUICK_REFERENCE.md § multiplayer category.
    '');

  # Get an accent color with specific tier (Lc75 or Lc60)
  # Use this only when tier-specific requirements exist (e.g., GTK Adwaita)
  getAccent =
    semantic: tier:
    palette.accent.${semantic}.${tier} or (throw ''
      ❌ Accent color '${semantic}.${tier}' not found

      Available semantics: ${lib.concatStringsSep ", " (builtins.attrNames palette.accent)}
      Available tiers: Lc75, Lc60

      💡 Tip: Most modules should use semantic.status or semantic.core functions.
      📖 See: docs/QUICK_REFERENCE.md for semantic categories.
    '');

  # Get a tonal color by direct path (for special cases like "black", "white")
  # Use this only for extreme contrast colors not in semantic mappings
  getTonal =
    path: mode:
    palette.tonal.${mode}.${path} or (throw ''
      ❌ Tonal color '${path}' not found for mode '${mode}'

      Available tonal colors for ${mode}:
        ${lib.concatMapStringsSep "\n  " (n: "- ${n}") (builtins.attrNames palette.tonal.${mode})}

      💡 Tip: Check semantic.core or semantic.ui categories first.
      📖 See: docs/QUICK_REFERENCE.md § core and ui categories.
    '');
}
