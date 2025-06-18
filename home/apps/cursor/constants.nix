# Shared constants for Cursor/VSCode configuration
# Provides common file ignore patterns so they stay in one place

{ }:
let
  # Files and directories to ignore globally
  commonIgnores = {
    "**/.DS_Store" = true;
    "**/.direnv" = true;
    "**/.git" = true;
  };
  # File-watcher exclusions – extends commonIgnores
  watcherIgnores = commonIgnores // {
    "**/.git/objects/**" = true;
    "**/.git/subtree-cache/**" = true;
    "**/.git/index.lock" = true;
    "**/node_modules/**" = true;
    "**/.next/**" = true;
    "**/dist/**" = true;
    "**/build/**" = true;
    "**/.cache/**" = true;
  };
in
{
  inherit commonIgnores watcherIgnores;
}
