# Signal Neovim Theme Module
#
# This module ONLY applies Signal colorscheme to neovim.
# It assumes you have already enabled neovim with:
#   programs.neovim.enable = true;
#
# The module will not install neovim, plugins, or configure LSP/Treesitter.
# You are responsible for installing:
#   - nvim-treesitter (optional, for better syntax highlighting)
#   - nvim-lspconfig (optional, for LSP semantic tokens)
#   - gitsigns.nvim (optional, for git integration)
{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.neovim.extraLuaConfig
# UPSTREAM SCHEMA: https://neovim.io/doc/user/syntax.html
# SCHEMA VERSION: 0.9.0
# LAST VALIDATED: 2026-01-20
# NOTES: Neovim requires Lua code for colorscheme definition. Home-Manager provides
#        extraLuaConfig for custom Lua. We generate complete colorscheme using
#        vim.api.nvim_set_hl. No structured options exist for custom themes.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Generate Neovim colorscheme in Lua format
  generateColorscheme =
    mode:
    let
      # Define colors using semantic bridge for the given mode
      colors = {
        # Editor UI
        bg = semantic.editor "background" mode;
        bg_alt = semantic.editor "active-line-background" mode;
        bg_highlight = semantic.core "selection-bg" mode;
        fg = semantic.editor "foreground" mode;
        fg_alt = semantic.editor "line-number" mode;
        fg_dim = semantic.syntax "comment" mode;

        # Syntax colors
        keyword = semantic.syntax "keyword" mode;
        function = semantic.syntax "function" mode;
        string = semantic.syntax "string" mode;
        number = semantic.syntax "number" mode;
        type = semantic.syntax "type" mode;
        constant = semantic.syntax "constant" mode;
        operator = semantic.syntax "operator" mode;
        tag = semantic.syntax "tag" mode;
        preprocessing = semantic.syntax "preprocessing" mode;

        # Status colors
        error = semantic.status "error" mode;
        warning = semantic.status "warning" mode;
        success = semantic.status "success" mode;
        info = semantic.status "info" mode;

        # UI colors
        border = semantic.ui "panel-border" mode;
        cursor_line = semantic.editor "active-line-background" mode;
        cursor = semantic.core "cursor" mode;
        selection = semantic.core "selection-bg" mode;
        visual = semantic.core "selection-bg" mode;

        # Git/VCS colors
        git_add = semantic.vcs "added" mode;
        git_change = semantic.vcs "modified" mode;
        git_delete = semantic.vcs "deleted" mode;

        # Diff colors (use editor backgrounds)
        diff_add = semantic.editor "active-line-background" mode;
        diff_delete = semantic.editor "active-line-background" mode;
        diff_change = semantic.editor "active-line-background" mode;
        diff_text = semantic.core "selection-bg" mode;

        # Multiplayer colors for diverse syntax
        player-1 = semantic.multiplayer "player-1" mode;
        player-2 = semantic.multiplayer "player-2" mode;
        player-3 = semantic.multiplayer "player-3" mode;
      };
    in
    pkgs.writeText "signal-${mode}.lua" ''
      -- Signal ${lib.toUpper (builtins.substring 0 1 mode)}${builtins.substring 1 (-1) mode} colorscheme
      -- Generated from Signal design system

      local colors = {
        bg = "${colors.bg.hex}",
        bg_alt = "${colors.bg_alt.hex}",
        bg_highlight = "${colors.bg_highlight.hex}",
        fg = "${colors.fg.hex}",
        fg_alt = "${colors.fg_alt.hex}",
        fg_dim = "${colors.fg_dim.hex}",

        -- Syntax colors
        keyword = "${colors.keyword.hex}",
        func = "${colors.function.hex}",
        string = "${colors.string.hex}",
        number = "${colors.number.hex}",
        type = "${colors.type.hex}",
        constant = "${colors.constant.hex}",
        operator = "${colors.operator.hex}",
        tag = "${colors.tag.hex}",
        preprocessing = "${colors.preprocessing.hex}",

        -- Status colors
        error = "${colors.error.hex}",
        warning = "${colors.warning.hex}",
        success = "${colors.success.hex}",
        info = "${colors.info.hex}",

        -- UI colors
        border = "${colors.border.hex}",
        cursor_line = "${colors.cursor_line.hex}",
        cursor = "${colors.cursor.hex}",
        selection = "${colors.selection.hex}",
        visual = "${colors.visual.hex}",

        -- Git colors
        git_add = "${colors.git_add.hex}",
        git_change = "${colors.git_change.hex}",
        git_delete = "${colors.git_delete.hex}",

        -- Diff colors
        diff_add = "${colors.diff_add.hex}",
        diff_delete = "${colors.diff_delete.hex}",
        diff_change = "${colors.diff_change.hex}",
        diff_text = "${colors.diff_text.hex}",

        -- Diverse syntax colors
        magenta = "${colors.player-1.hex}",
        teal = "${colors.player-2.hex}",
        cyan = "${colors.info.hex}",
      }

      -- Clear existing highlights
      vim.cmd("highlight clear")
      if vim.fn.exists("syntax_on") then
        vim.cmd("syntax reset")
      end

      vim.o.termguicolors = true
      vim.g.colors_name = "signal-${mode}"

      local hi = vim.api.nvim_set_hl

      -- Editor highlights
      hi(0, "Normal", { fg = colors.fg, bg = colors.bg })
      hi(0, "NormalFloat", { fg = colors.fg, bg = colors.bg_alt })
      hi(0, "NormalNC", { fg = colors.fg, bg = colors.bg })
      hi(0, "CursorLine", { bg = colors.cursor_line })
      hi(0, "CursorColumn", { bg = colors.cursor_line })
      hi(0, "LineNr", { fg = colors.fg_dim })
      hi(0, "CursorLineNr", { fg = colors.fg, bold = true })
      hi(0, "Visual", { bg = colors.visual })
      hi(0, "VisualNOS", { bg = colors.visual })
      hi(0, "Search", { fg = colors.bg, bg = colors.warning })
      hi(0, "IncSearch", { fg = colors.bg, bg = colors.success })
      hi(0, "Cursor", { fg = colors.bg, bg = colors.cursor })
      hi(0, "ColorColumn", { bg = colors.bg_alt })

      -- Window/Buffer
      hi(0, "VertSplit", { fg = colors.border })
      hi(0, "WinSeparator", { fg = colors.border })
      hi(0, "StatusLine", { fg = colors.fg, bg = colors.bg_alt })
      hi(0, "StatusLineNC", { fg = colors.fg_dim, bg = colors.bg_alt })
      hi(0, "TabLine", { fg = colors.fg_alt, bg = colors.bg_alt })
      hi(0, "TabLineFill", { bg = colors.bg_alt })
      hi(0, "TabLineSel", { fg = colors.fg, bg = colors.bg, bold = true })

      -- Popups/Menus
      hi(0, "Pmenu", { fg = colors.fg, bg = colors.bg_alt })
      hi(0, "PmenuSel", { fg = colors.bg, bg = colors.cursor })
      hi(0, "PmenuSbar", { bg = colors.bg_highlight })
      hi(0, "PmenuThumb", { bg = colors.border })

      -- Syntax
      hi(0, "Comment", { fg = colors.fg_dim, italic = true })
      hi(0, "Constant", { fg = colors.constant })
      hi(0, "String", { fg = colors.string })
      hi(0, "Character", { fg = colors.string })
      hi(0, "Number", { fg = colors.number })
      hi(0, "Boolean", { fg = colors.constant })
      hi(0, "Float", { fg = colors.number })

      hi(0, "Identifier", { fg = colors.fg })
      hi(0, "Function", { fg = colors.func })

      hi(0, "Statement", { fg = colors.keyword })
      hi(0, "Conditional", { fg = colors.keyword })
      hi(0, "Repeat", { fg = colors.keyword })
      hi(0, "Label", { fg = colors.keyword })
      hi(0, "Operator", { fg = colors.operator })
      hi(0, "Keyword", { fg = colors.keyword })
      hi(0, "Exception", { fg = colors.error })

      hi(0, "PreProc", { fg = colors.preprocessing })
      hi(0, "Include", { fg = colors.preprocessing })
      hi(0, "Define", { fg = colors.preprocessing })
      hi(0, "Macro", { fg = colors.preprocessing })
      hi(0, "PreCondit", { fg = colors.preprocessing })

      hi(0, "Type", { fg = colors.type })
      hi(0, "StorageClass", { fg = colors.keyword })
      hi(0, "Structure", { fg = colors.type })
      hi(0, "Typedef", { fg = colors.type })

      hi(0, "Special", { fg = colors.magenta })
      hi(0, "SpecialChar", { fg = colors.magenta })
      hi(0, "Tag", { fg = colors.tag })
      hi(0, "Delimiter", { fg = colors.fg_alt })
      hi(0, "SpecialComment", { fg = colors.info, italic = true })
      hi(0, "Debug", { fg = colors.error })

      hi(0, "Underlined", { underline = true })
      hi(0, "Bold", { bold = true })
      hi(0, "Italic", { italic = true })

      hi(0, "Error", { fg = colors.error })
      hi(0, "ErrorMsg", { fg = colors.error, bold = true })
      hi(0, "WarningMsg", { fg = colors.warning })
      hi(0, "Todo", { fg = colors.keyword, bold = true })

      -- Treesitter
      hi(0, "@variable", { fg = colors.fg })
      hi(0, "@variable.builtin", { fg = colors.error })
      hi(0, "@variable.parameter", { fg = colors.constant })
      hi(0, "@variable.member", { fg = colors.teal })

      hi(0, "@constant", { fg = colors.constant })
      hi(0, "@constant.builtin", { fg = colors.constant })
      hi(0, "@constant.macro", { fg = colors.preprocessing })

      hi(0, "@string", { fg = colors.string })
      hi(0, "@string.regexp", { fg = colors.teal })
      hi(0, "@string.escape", { fg = colors.magenta })

      hi(0, "@character", { fg = colors.string })
      hi(0, "@number", { fg = colors.number })
      hi(0, "@boolean", { fg = colors.constant })
      hi(0, "@float", { fg = colors.number })

      hi(0, "@function", { fg = colors.func })
      hi(0, "@function.builtin", { fg = colors.info })
      hi(0, "@function.macro", { fg = colors.preprocessing })
      hi(0, "@function.call", { fg = colors.func })
      hi(0, "@method", { fg = colors.func })
      hi(0, "@method.call", { fg = colors.func })

      hi(0, "@constructor", { fg = colors.type })
      hi(0, "@parameter", { fg = colors.constant })

      hi(0, "@keyword", { fg = colors.keyword })
      hi(0, "@keyword.function", { fg = colors.keyword })
      hi(0, "@keyword.operator", { fg = colors.keyword })
      hi(0, "@keyword.return", { fg = colors.keyword })

      hi(0, "@conditional", { fg = colors.keyword })
      hi(0, "@repeat", { fg = colors.keyword })
      hi(0, "@label", { fg = colors.keyword })

      hi(0, "@operator", { fg = colors.operator })
      hi(0, "@exception", { fg = colors.error })

      hi(0, "@type", { fg = colors.type })
      hi(0, "@type.builtin", { fg = colors.type })
      hi(0, "@type.qualifier", { fg = colors.keyword })

      hi(0, "@property", { fg = colors.teal })
      hi(0, "@field", { fg = colors.teal })

      hi(0, "@punctuation.delimiter", { fg = colors.fg_alt })
      hi(0, "@punctuation.bracket", { fg = colors.fg_alt })
      hi(0, "@punctuation.special", { fg = colors.magenta })

      hi(0, "@comment", { link = "Comment" })

      hi(0, "@tag", { fg = colors.tag })
      hi(0, "@tag.attribute", { fg = colors.type })
      hi(0, "@tag.delimiter", { fg = colors.fg_alt })

      -- LSP Semantic Tokens
      hi(0, "@lsp.type.namespace", { fg = colors.yellow })
      hi(0, "@lsp.type.type", { link = "@type" })
      hi(0, "@lsp.type.class", { link = "@type" })
      hi(0, "@lsp.type.enum", { link = "@type" })
      hi(0, "@lsp.type.interface", { link = "@type" })
      hi(0, "@lsp.type.struct", { link = "@type" })
      hi(0, "@lsp.type.parameter", { link = "@parameter" })
      hi(0, "@lsp.type.variable", { link = "@variable" })
      hi(0, "@lsp.type.property", { link = "@property" })
      hi(0, "@lsp.type.enumMember", { link = "@constant" })
      hi(0, "@lsp.type.function", { link = "@function" })
      hi(0, "@lsp.type.method", { link = "@method" })
      hi(0, "@lsp.type.macro", { link = "@constant.macro" })
      hi(0, "@lsp.type.decorator", { fg = colors.preprocessing })

      -- Git
      hi(0, "GitSignsAdd", { fg = colors.git_add })
      hi(0, "GitSignsChange", { fg = colors.git_change })
      hi(0, "GitSignsDelete", { fg = colors.git_delete })

      hi(0, "DiffAdd", { bg = colors.diff_add })
      hi(0, "DiffDelete", { bg = colors.diff_delete })
      hi(0, "DiffChange", { bg = colors.diff_change })
      hi(0, "DiffText", { bg = colors.diff_text })

      -- Diagnostics
      hi(0, "DiagnosticError", { fg = colors.error })
      hi(0, "DiagnosticWarn", { fg = colors.warning })
      hi(0, "DiagnosticInfo", { fg = colors.info })
      hi(0, "DiagnosticHint", { fg = colors.teal })

      hi(0, "DiagnosticUnderlineError", { sp = colors.error, undercurl = true })
      hi(0, "DiagnosticUnderlineWarn", { sp = colors.warning, undercurl = true })
      hi(0, "DiagnosticUnderlineInfo", { sp = colors.info, undercurl = true })
      hi(0, "DiagnosticUnderlineHint", { sp = colors.teal, undercurl = true })
    '';

  # Generate both dark and light colorschemes
  darkColorscheme = generateColorscheme "dark";
  lightColorscheme = generateColorscheme "light";

  # Resolved mode for static theme selection
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if neovim should be themed
  # Check if neovim should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "neovim" [
    "editors"
    "neovim"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Assumes user has already set programs.neovim.enable = true
    # Only apply the color theme via extraLuaConfig
    programs.neovim.extraLuaConfig = ''
      -- Load Signal colorscheme
      ${
        if cfg.mode != "auto" then
          ''
            dofile("${if themeMode == "dark" then darkColorscheme else lightColorscheme}")
          ''
        else
          ''
            -- Auto mode: try to detect system theme
            -- Default to dark if detection fails
            dofile("${darkColorscheme}")
          ''
      }
    '';
  };
}
