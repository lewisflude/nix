# Cursor AI-Specific Configuration
# AI assistant, chat, and Cursor-specific features

{ ... }:
{
  userSettings = {
    # Cursor AI Configuration
    "cursor.chat.codeGeneration.useCodebaseContext" = true;
    "cursor.chat.codeGeneration.includeCommentsInCodeGeneration" = true;
    "cursor.chat.codeGeneration.useTerminalContext" = true;
    "cursor.general.enableDismissedTerminalNotification" = true;
    "cursor.general.enableLiveBarsDebugMode" = false;
    "cursor.general.enableTerminalContextAwareCommenting" = true;
    "cursor.general.enableWindows11SnapAssistGUI" = false;
    "cursor.general.enableWindowsTerminalShell" = false;
    "cursor.general.modelTemperature" = 0.2;
    "cursor.general.requestDelayTime" = 200; # Faster AI responses
    "cursor.general.requestTimeoutLength" = 30000;
    "cursor.privateTelemetryEnabled" = false;

    # Cursor Chat Settings
    "cursor.chat.autoAcceptDiffs" = true;
    "cursor.chat.autoApplyToFilesOutsideContextInManualMode" = true;
    "cursor.chat.autoRefresh" = true;
    "cursor.chat.autoScrollToBottom" = true;
    "cursor.chat.iterateOnLints" = true;
    "cursor.chat.webSearchTool" = true;

    # Enhanced AI Features
    "cursor.chat.suggestFollowUpQuestions" = true;
    "cursor.chat.enableSmartSelection" = true;

    # Cursor Beta Features
    "cursor.beta.notepads" = true;
    "cursor.beta.useNewChatUI" = true;
    "cursor.beta.useNewComposeUI" = true;

    # Cursor Tab Settings
    "cursor.cursorTab.enablePartialAccepts" = true;
    "cursor.cursorTab.enableSuggestions" = true;
    "cursor.cursorTab.triggerSuggestions" = true;

    # AI Agent Settings
    "cursor.agent.dotFilesProtection" = true;
    "cursor.agent.outsideWorkspaceProtection" = true;

    # AI Model Configuration
    "cursor.ai.defaultModel" = "gpt-4o";
    "cursor.ai.fallbackModel" = "claude-3.5-sonnet";
    "cursor.ai.experimentalModel" = "o3";
  };
}
