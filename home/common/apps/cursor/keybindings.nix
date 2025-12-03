_: {
  # Keybindings for Cursor/VSCode
  # These ensure consistent newline insertion behavior across the editor
  keybindings = [
    # Shift+Enter inserts a new line after the current line
    # This works when editing files and not in suggest widget
    {
      key = "shift+enter";
      command = "editor.action.insertLineAfter";
      when = "editorTextFocus && !editorReadonly && !suggestWidgetVisible && !inSnippetMode";
    }

    # Shift+Enter inserts a line break in text input contexts
    # This covers input boxes, search fields, etc.
    {
      key = "shift+enter";
      command = "editor.action.insertLineBreak";
      when = "textInputFocus && !editorReadonly && !suggestWidgetVisible";
    }

    # When the suggest widget IS visible, Shift+Enter accepts the suggestion
    # This maintains useful autocomplete behavior
    {
      key = "shift+enter";
      command = "acceptSelectedSuggestion";
      when = "suggestWidgetVisible && suggestionMakesTextEdit && textInputFocus";
    }

    # Option+Enter (macOS) / Alt+Enter (Linux) for quick fixes
    # This is a common convention in IDEs
    {
      key = "alt+enter";
      command = "editor.action.quickFix";
      when = "editorHasCodeActionsProvider && textInputFocus && !editorReadonly";
    }
  ];
}
