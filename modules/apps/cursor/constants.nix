# Shared constants for Cursor/VSCode configuration

{ }:

let
  commonIgnores = {
    "**/.DS_Store" = true;
    "**/.direnv" = true;
    "**/.git" = true;
  };

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
