# Obsidian configuration
# Dendritic pattern: Full implementation as flake.modules.homeManager.obsidian
# Cross-platform: home-manager module handles Linux (XDG) and Darwin paths.
_: {
  flake.modules.homeManager.obsidian =
    { pkgs, ... }:
    {
      programs.obsidian = {
        enable = true;
        package = pkgs.obsidian;
        cli.enable = true;

        defaultSettings = {
          app = {
            promptDelete = false;
            alwaysUpdateLinks = true;
            newLinkFormat = "shortest";
            useMarkdownLinks = false;
            attachmentFolderPath = "Attachments";
            spellcheck = true;
            showLineNumber = true;
            livePreview = true;
            readableLineLength = true;
            autoPairBrackets = true;
            autoPairMarkdown = true;
            smartIndentList = true;
            foldHeading = true;
            foldIndent = true;
            strictLineBreaks = false;
            showFrontmatter = true;
          };

          appearance = {
            baseFontSize = 16;
            theme = "obsidian";
            interfaceFontFamily = "Iosevka";
            textFontFamily = "Iosevka";
            monospaceFontFamily = "Iosevka";
            translucency = false;
          };

          corePlugins = [
            "backlink"
            "bases"
            "bookmarks"
            "canvas"
            "command-palette"
            "daily-notes"
            "editor-status"
            "file-explorer"
            "file-recovery"
            "global-search"
            "graph"
            "note-composer"
            "outgoing-link"
            "outline"
            "page-preview"
            "properties"
            "switcher"
            "tag-pane"
            "templates"
            "word-count"
            "workspaces"
          ];
        };

        vaults."Obsidian Vault" = {
          enable = true;
          target = "Obsidian Vault";
        };
      };
    };
}
