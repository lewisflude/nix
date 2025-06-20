# Cursor AI-Specific Configuration
# AI assistant, chat, and Cursor-specific features

{ ... }:
{
  userSettings = {
    # Core AI Performance Configuration
    "cursor.general.modelTemperature" = 0.2; # Conservative for code generation
    "cursor.general.requestDelayTime" = 200; # Faster AI responses
    "cursor.general.requestTimeoutLength" = 30000;
    "cursor.privateTelemetryEnabled" = false;

    # AI Model Configuration (Optimized for 2024/2025)
    "cursor.ai.defaultModel" = "gpt-4o";
    "cursor.ai.fallbackModel" = "claude-3.5-sonnet";
    "cursor.ai.experimentalModel" = "o3";

    # Context & Memory Management
    "cursor.chat.maxConversationLength" = 50; # Prevent context bloat
    "cursor.general.enableContextMemory" = true;
    "cursor.general.enableSemanticCache" = true;

    # Code Generation Settings (Enhanced Safety)
    "cursor.chat.codeGeneration.useCodebaseContext" = true;
    "cursor.chat.codeGeneration.includeCommentsInCodeGeneration" = true;
    "cursor.chat.codeGeneration.useTerminalContext" = true;
    "cursor.chat.codeGeneration.enableGitContext" = true; # Use git history for better context
    "cursor.chat.codeGeneration.maxFileCount" = 20; # Limit files in context to improve performance

    # Chat Interface & UX Settings
    "cursor.chat.autoRefresh" = true;
    "cursor.chat.autoScrollToBottom" = true;
    "cursor.chat.iterateOnLints" = true;
    "cursor.chat.webSearchTool" = true;
    "cursor.chat.suggestFollowUpQuestions" = true;
    "cursor.chat.enableSmartSelection" = true;
    "cursor.chat.enableCodeDiffPreview" = true; # Show diffs before applying

    # Code Completion (Tab) Settings - Performance Optimized
    "cursor.cursorTab.enablePartialAccepts" = true;
    "cursor.cursorTab.enableSuggestions" = true;
    "cursor.cursorTab.triggerSuggestions" = true;
    "cursor.cursorTab.multilineAccepts" = true; # Accept multi-line suggestions
    "cursor.cursorTab.suggestionsDelay" = 150; # Faster suggestions
    "cursor.cursorTab.maxSuggestions" = 3; # Limit to reduce noise

    # Agent & Safety Settings (Enhanced Protection)
    "cursor.agent.dotFilesProtection" = true;
    "cursor.agent.outsideWorkspaceProtection" = true;
    "cursor.agent.enableCodeReview" = true; # Review changes before applying
    "cursor.agent.requireConfirmation" = true; # Confirm destructive operations
    "cursor.agent.maxFilesPerOperation" = 10; # Limit scope of agent operations

    # Privacy & Security Settings
    "cursor.general.enableAnalytics" = false;
    "cursor.general.enableCrashReporting" = false;
    "cursor.chat.enableConversationHistory" = true; # Keep for context but review periodically
    "cursor.general.enableDataCollection" = false;

    # Composer Settings (Multi-file editing)
    "cursor.composer.enableLargeFileHandling" = true;
    "cursor.composer.maxFilesInComposer" = 5; # Limit complexity
    "cursor.composer.enableFileTree" = true;

    # Beta Features (Curated Selection)
    "cursor.beta.notepads" = true;
    "cursor.beta.useNewChatUI" = true;
    "cursor.beta.useNewComposeUI" = true;
    "cursor.beta.enableAIReview" = true; # AI-powered code review

    # Performance & Resource Management
    "cursor.general.enableBackgroundProcessing" = true;
    "cursor.general.maxConcurrentRequests" = 3; # Prevent overwhelming servers
    "cursor.general.enableRequestBatching" = true; # Batch requests for efficiency

    # Platform-Specific Settings (macOS)
    "cursor.general.enableDismissedTerminalNotification" = true;
    "cursor.general.enableLiveBarsDebugMode" = false;
    "cursor.general.enableTerminalContextAwareCommenting" = true;
    "cursor.general.enableWindows11SnapAssistGUI" = false; # Disable Windows-specific features
    "cursor.general.enableWindowsTerminalShell" = false;
  };
}
