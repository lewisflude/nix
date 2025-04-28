{ config, lib, pkgs, ... }: {
  # System-wide environment variables
  environment.variables = {
    # Development
    EDITOR = "code";
    VISUAL = "code";

    # GPG
    GPG_TTY = "$(tty)";
  };
}
