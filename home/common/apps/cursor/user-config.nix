# User-Specific Configuration
# Machine/user-specific settings that may vary between setups
# Copy this file and customize for your environment

{ ... }:
{
  userSettings = {
    # Git Signing (customize these for your setup)
    # Uncomment and set your signing key ID:
    # "git.signingKeyId" = "YOUR_GPG_KEY_ID_HERE";

    # SSH Agent Configuration (macOS-specific)
    # Uncomment and customize if you use GPG for SSH:
    # "terminal.integrated.env.osx" = {
    #   "SSH_AUTH_SOCK" = "/Users/YOUR_USERNAME/.gnupg/S.gpg-agent.ssh";
    # };
  };
}
