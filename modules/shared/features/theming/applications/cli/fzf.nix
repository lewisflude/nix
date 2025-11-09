{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkAfter;
  cfg = config.theming.signal;
  inherit (themeContext) theme;
  inherit (theme) colors;

  # fzf requires hex colors WITH # prefix in --color options
  # Home Manager's programs.fzf.colors strips the # prefix, which causes errors
  # Solution: Use defaultOptions to set colors directly with # prefix
  # This bypasses Home Manager's color formatting and ensures correct format
  fzfColorOptions = [
    "--color=fg:${colors."text-primary".hex}"
    "--color=bg:${colors."surface-base".hex}"
    "--color=hl:${colors."accent-primary".hex}"
    "--color=fg+:${colors."text-primary".hex}"
    "--color=bg+:${colors."surface-subtle".hex}"
    "--color=hl+:${colors."accent-focus".hex}"
    "--color=info:${colors."accent-info".hex}"
    "--color=prompt:${colors."accent-primary".hex}"
    "--color=pointer:${colors."accent-focus".hex}"
    "--color=marker:${colors."accent-primary".hex}"
    "--color=spinner:${colors."accent-info".hex}"
    "--color=header:${colors."text-secondary".hex}"
  ];
in
{
  config = mkIf (cfg.enable && cfg.applications.fzf.enable && theme != null) (mkMerge [
    {
      # Set colors via defaultOptions to ensure # prefix is preserved
      # Home Manager's programs.fzf.colors strips the # prefix, which breaks fzf
      # Use mkAfter to append color options after any existing defaultOptions
      programs.fzf.defaultOptions = mkAfter fzfColorOptions;
    }
    # Also set programs.fzf.colors for Home Manager integration
    # (even though we override via defaultOptions, this keeps the config consistent)
    {
      programs.fzf.colors = {
        fg = colors."text-primary".hex;
        bg = colors."surface-base".hex;
        hl = colors."accent-primary".hex;
        "fg+" = colors."text-primary".hex;
        "bg+" = colors."surface-subtle".hex;
        "hl+" = colors."accent-focus".hex;
        info = colors."accent-info".hex;
        prompt = colors."accent-primary".hex;
        pointer = colors."accent-focus".hex;
        marker = colors."accent-primary".hex;
        spinner = colors."accent-info".hex;
        header = colors."text-secondary".hex;
      };
    }
  ]);
}
