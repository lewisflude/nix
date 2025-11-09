{ lib }:
rec {
  # Create theme context from configuration
  # This is the main function that modules should use to create context
  # Returns a structured context object that can be passed to application modules
  createContext =
    {
      themeLib,
      palette,
      mode,
    }:
    let
      # Validate inputs (evaluated for side effects)

      # Generate theme for the resolved mode
      # Pass empty set {} to disable validation (can be enhanced later to use config)
      theme = themeLib.generateTheme mode { };
    in
    {
      inherit theme mode palette;
      lib = themeLib;
    };

  # Validate theme context
  # Ensures all required fields are present and valid
  validateContext =
    context:
    let
      requiredFields = [
        "theme"
        "mode"
        "palette"
        "lib"
      ];
      missingFields = lib.filter (field: !(context ? ${field})) requiredFields;
    in
    if missingFields != [ ] then
      throw "Theme context is missing required fields: ${lib.concatStringsSep ", " missingFields}"
    else if
      !builtins.elem context.mode [
        "light"
        "dark"
      ]
    then
      throw "Theme context has invalid mode: ${context.mode}. Must be 'light' or 'dark'"
    else if context.theme == null then
      throw "Theme context has null theme"
    else
      context;

  # Get theme from context (convenience function)
  getTheme = context: context.theme;

  # Get mode from context (convenience function)
  getMode = context: context.mode;

  # Check if context is valid (non-throwing validation)
  isValidContext =
    context:
    let
      result = builtins.tryEval (validateContext context);
    in
    result.success;
}
