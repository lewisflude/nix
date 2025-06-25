# Cursor AI-Specific Configuration
# Since most cursor.* settings are invalid/undocumented, this file now contains
# only standard VS Code settings that work reliably with Cursor

{ ... }:
{
  userSettings = {
    # ==== PRIVACY & TELEMETRY ====
    "telemetry.telemetryLevel" = "off";
    
    # ==== SECURITY ====
    "security.workspace.trust.enabled" = false;
    
    # Note: All cursor.* settings have been removed as they are either:
    # - Invalid/undocumented in official Cursor documentation
    # - Better configured through Cursor's UI (Settings → Features/Models/Rules)
    # - Replaced by .cursorrules files for AI behavior
    #
    # For Cursor-specific configuration:
    # 1. Use Settings → Features → Chat for chat preferences
    # 2. Use Settings → Models for AI model selection
    # 3. Use Settings → Rules for global AI behavior rules
    # 4. Use .cursorrules files in project root for project-specific rules
  };
}