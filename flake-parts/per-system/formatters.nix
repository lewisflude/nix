{
  config,
  ...
}:
{
  perSystem =
    { system, ... }:
    {
      # Formatter for this system
      # Used by `nix fmt` command
      formatter = config._module.args.pkgs.nixfmt-rfc-style;
    };
}
