# Cursor AI-Specific Configuration
# Since most cursor.* settings are invalid/undocumented, this file now contains
# only standard VS Code settings that work reliably with Cursor
_: {
  userSettings = {
    # ==== PRIVACY & TELEMETRY ====
    "telemetry.telemetryLevel" = "off";

    # ==== SECURITY ====
    "security.workspace.trust.enabled" = false;

    "nxConsole" = {
      "generateAiAgentRules" = true;
    };
  };
}
