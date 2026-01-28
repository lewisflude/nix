# Productivity Tools Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  productivity = {
    enable = mkEnableOption "productivity and office tools";
    office = mkEnableOption "office suite (LibreOffice)";
    notes = mkEnableOption "note-taking (Obsidian)";
    email = mkEnableOption "email clients";
    calendar = mkEnableOption "calendar applications";
    resume = mkEnableOption "resume generation and management";
  };
}
