{ ... }:
{
  # System-wide environment variables
  environment.variables = {
    # GPG
    GPG_TTY = "$(tty)";
  };
}
