{ ... }: {
  # System-wide environment variables
  environment.variables = {
    # Development
    EDITOR = "code-cursor";
    VISUAL = "code-cursor";

    # GPG
    GPG_TTY = "$(tty)";
  };
}
