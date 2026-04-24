# Disable vendor background launch agents that auto-start at login.
# Targets updater daemons and telemetry — apps still work when launched
# from /Applications; they just don't hold RAM 24/7 for update checks
# that happen at launch anyway.
{ config, ... }:
{
  flake.modules.darwin.disableBackgroundAgents =
    _:
    let
      labels = [
        # Adobe Creative Cloud background helpers
        "com.adobe.AdobeCreativeCloud"
        "com.adobe.ccxprocess"
        "com.adobe.GC.Invoker-1.0"
        "com.adobe.AdobeDesktopService"

        # Vendor updater agents — each app checks at launch anyway
        "us.zoom.updater"
        "us.zoom.updater.login.check"
        "com.microsoft.update.agent"
        "com.google.GoogleUpdater.wake"
        "com.google.keystone.agent"
        "com.google.keystone.xpcservice"

        # Pure telemetry
        "com.solidstatelogic.analytics"
      ];
    in
    {
      system.activationScripts.disableBackgroundAgents.text = ''
        uid=$(id -u "${config.username}")
        for label in ${builtins.concatStringsSep " " labels}; do
          /bin/launchctl disable "gui/$uid/$label" 2>/dev/null || true
          /bin/launchctl bootout "gui/$uid/$label" 2>/dev/null || true
        done
      '';
    };
}
