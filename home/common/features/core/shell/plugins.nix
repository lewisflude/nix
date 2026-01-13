# ZSH Plugins Configuration
# Plugin loading and configuration
{
  sources,
  ...
}:
{
  programs.zsh.plugins = [
    # ONLY zsh-defer loads synchronously - everything else is deferred manually
    {
      name = "zsh-defer";
      inherit (sources.zsh-defer) src;
      file = "zsh-defer.plugin.zsh";
    }
  ];
}
