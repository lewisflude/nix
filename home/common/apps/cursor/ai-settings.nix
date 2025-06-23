# Cursor AI-Specific Configuration
# AI assistant, chat, and Cursor-specific features optimized for performance and stability

{ ... }:
{
  userSettings = {
    # ==== CORE AI PERFORMANCE CONFIGURATION ====

    # AI Response Settings (Conservative for reliability)
    "cursor.general.modelTemperature" = 0.2; # Lower temperature for more consistent code generation
    "cursor.general.requestDelayTime" = 200; # Balanced response time
    "cursor.general.requestTimeoutLength" = 30000; # 30 second timeout
    "cursor.general.maxConcurrentRequests" = 3; # Prevent overwhelming API
    "cursor.general.enableRequestBatching" = true; # Batch requests for efficiency

    # Privacy & Telemetry (Strict Privacy)
    "cursor.privateTelemetryEnabled" = false;
    "cursor.general.enableAnalytics" = false;
    "cursor.general.enableCrashReporting" = false;
    "cursor.general.enableDataCollection" = false;

    # ==== AI MODEL CONFIGURATION ====

    # Primary Models (Updated for 2024/2025 - verify these exist)
    "cursor.ai.defaultModel" = "gpt-4o"; # Primary model for general use
    "cursor.ai.fallbackModel" = "claude-3.5-sonnet"; # Fallback for when primary fails

    # Context & Memory Management (Performance Optimized)
    "cursor.chat.maxConversationLength" = 30; # Reduced to prevent context bloat
    "cursor.general.enableContextMemory" = true;
    "cursor.general.enableSemanticCache" = true;
    "cursor.general.enableBackgroundProcessing" = true;

    # ==== CODE GENERATION SETTINGS ====

    # Context Sources (Selective for Performance)
    "cursor.chat.codeGeneration.useCodebaseContext" = true;
    "cursor.chat.codeGeneration.includeCommentsInCodeGeneration" = true;
    "cursor.chat.codeGeneration.useTerminalContext" = false; # Disabled for privacy
    "cursor.chat.codeGeneration.enableGitContext" = true;
    "cursor.chat.codeGeneration.maxFileCount" = 15; # Reduced for better performance

    # Code Safety & Quality
    "cursor.chat.iterateOnLints" = true;
    "cursor.chat.enableCodeDiffPreview" = true; # Preview changes before applying

    # ==== CHAT INTERFACE SETTINGS ====

    # Chat UX (Productivity Focused)
    "cursor.chat.autoRefresh" = false; # Disabled to prevent distractions
    "cursor.chat.autoScrollToBottom" = true;
    "cursor.chat.suggestFollowUpQuestions" = false; # Disabled to reduce noise
    "cursor.chat.enableSmartSelection" = true;
    "cursor.chat.webSearchTool" = false; # Disabled for privacy and focus

    # Conversation Management
    "cursor.chat.enableConversationHistory" = true; # Useful for context

    # ==== CODE COMPLETION (TAB) SETTINGS ====

    # Tab Completion Performance (Optimized)
    "cursor.cursorTab.enablePartialAccepts" = true;
    "cursor.cursorTab.enableSuggestions" = true;
    "cursor.cursorTab.triggerSuggestions" = true;
    "cursor.cursorTab.multilineAccepts" = true;
    "cursor.cursorTab.suggestionsDelay" = 100; # Slightly slower for stability
    "cursor.cursorTab.maxSuggestions" = 2; # Reduced to minimize noise

    # ==== AGENT & SAFETY SETTINGS ====

    # File System Protection (Enhanced Safety)
    "cursor.agent.dotFilesProtection" = true;
    "cursor.agent.outsideWorkspaceProtection" = true;
    "cursor.agent.requireConfirmation" = true; # Always confirm destructive operations
    "cursor.agent.maxFilesPerOperation" = 5; # Reduced scope for safety

    # Code Review & Validation
    "cursor.agent.enableCodeReview" = true; # AI-powered code review

    # ==== COMPOSER SETTINGS ====

    # Multi-file Editing (Conservative Limits)
    "cursor.composer.enableLargeFileHandling" = false; # Disabled for performance
    "cursor.composer.maxFilesInComposer" = 3; # Reduced complexity
    "cursor.composer.enableFileTree" = true;

    # ==== STABLE FEATURES ONLY ====

    # UI Improvements (Stable Features Only)
    "cursor.general.enableDismissedTerminalNotification" = true;
    "cursor.general.enableTerminalContextAwareCommenting" = true;

    # Platform Optimization (macOS Specific)
    "cursor.general.enableLiveBarsDebugMode" = false; # Disabled for performance
    "cursor.general.enableWindows11SnapAssistGUI" = false; # Not needed on macOS
    "cursor.general.enableWindowsTerminalShell" = false; # Not needed on macOS

    # ==== PERFORMANCE TUNING ====

    # Resource Management
    "cursor.general.enableSmartThrottling" = true; # Enable intelligent request throttling
    "cursor.general.cacheTimeout" = 300000; # 5 minute cache timeout
    "cursor.general.maxCacheSize" = 100; # Limit cache size for memory management

    # ==== REMOVED DEPRECATED/EXPERIMENTAL SETTINGS ====

    # The following settings have been removed as they may not exist or are unstable:
    # - cursor.ai.experimentalModel (may not exist)
    # - cursor.beta.* settings (unstable)
    # - Various experimental features that may cause issues

    # ==== ADDITIONAL PRODUCTIVITY SETTINGS ====

    # Smart Suggestions
    "cursor.general.enableInlineCompletion" = true;
    "cursor.general.enableMultilineCompletion" = true;
    "cursor.general.completionDelay" = 150; # Balanced delay

    # Error Handling
    "cursor.general.enableErrorRecovery" = true;
    "cursor.general.retryFailedRequests" = true;
    "cursor.general.maxRetries" = 2; # Limited retries to prevent delays
  };
}
