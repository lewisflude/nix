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
    enable = mkEnableOption "productivity and office tools" // {
      example = true;
    };
    office = mkEnableOption "office suite (LibreOffice)" // {
      example = true;
    };
    notes = mkEnableOption "note-taking (Obsidian)" // {
      example = true;
    };
    email = mkEnableOption "email clients" // {
      example = true;
    };
    calendar = mkEnableOption "calendar applications" // {
      example = true;
    };
    resume = mkEnableOption "resume generation and management" // {
      example = true;
    };
  };
}
