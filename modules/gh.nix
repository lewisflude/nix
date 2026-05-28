# GitHub CLI and GitHub Actions runner configuration
_: {
  flake.modules.nixos.githubRunners =
    { config, lib, pkgs, ... }:
    {
      services.github-runners.tunnels-linux = {
        enable = true;
        url = "https://github.com/beigethreat/tunnels";
        name = "jupiter-tunnels";
        tokenFile = config.sops.secrets.GITHUB_TOKEN.path;
        tokenType = "access";
        replace = true;
        # Persist _work across reboots. The default work dir lives under
        # /run (tmpfs) and is wiped on boot, which also wipes the ccache/CPM
        # caches that CI workflows store under ${{ github.workspace }}/.
        # Must be distinct from the StateDirectory: the unconfigure script
        # ends with `find $WORK_DIRECTORY -mindepth 1 -delete`, which would
        # also wipe the runner's tokens if they shared a path.
        workDir = "/var/lib/github-runner-work/tunnels-linux";
        nodeRuntimes = [
          "node24"
        ];

        extraLabels = [
          "linux"
          "nixos"
          "x64"
          "tunnels-heavy"
        ];

        extraPackages = with pkgs; [
          awscli2
          bashInteractive
          cmake
          coreutils
          curl
          git
          jq
          just
          nix
          pluginval
        ];
      };

      # The github-runners module BindPaths the workDir into the service's
      # mount namespace but does not create it. Add a second StateDirectory
      # entry so systemd creates and chowns it for the DynamicUser the
      # runner runs as, and clear BindPaths — the StateDirectory mechanism
      # already exposes the path to the namespace, and an additional
      # BindPaths over the same symlink path makes the CHDIR step fail
      # with EACCES when the working directory resolves through the
      # bind mount.
      systemd.services.github-runner-tunnels-linux.serviceConfig = {
        StateDirectory = lib.mkForce [
          "github-runner/tunnels-linux"
          "github-runner-work/tunnels-linux"
        ];
        BindPaths = lib.mkForce [ ];
      };
    };

  flake.modules.darwin.githubRunners =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        escapeShellArg
        makeBinPath
        mkBefore
        ;

      user = config.host.username;
      runnerName = "mercury-tunnels";
      runnerLabel = "tunnels-macos";
      runnerUrl = "https://github.com/beigethreat/tunnels";
      tokenFile = config.sops.secrets.GITHUB_TOKEN.path;
      stateDir = "/var/lib/github-runners/${runnerName}";
      logDir = "/var/log/github-runners/${runnerName}";
      workDir = "/private/var/lib/github-runners/_work/${runnerName}";
      runnerPackage = pkgs.github-runner.override {
        nodeRuntimes = [
          "node24"
        ];
      };
      labels = [
        "macos"
        "arm64"
        runnerLabel
      ];
      path = makeBinPath (
        with pkgs;
        [
          bashInteractive
          cmake
          coreutils
          curl
          findutils
          git
          gnutar
          gzip
          jq
          just
          nix
        ]
      );
      configureRunner = pkgs.writeShellApplication {
        name = "configure-github-runner-${runnerLabel}";
        runtimeInputs = [
          runnerPackage
        ];
        text = ''
          set -euo pipefail

          token="$(<"${tokenFile}")"
          # shellcheck disable=SC2054
          args=(
            --unattended
            --disableupdate
            --work ${escapeShellArg workDir}
            --url ${escapeShellArg runnerUrl}
            --labels ${escapeShellArg (concatStringsSep "," labels)}
            --name ${escapeShellArg runnerName}
            --replace
          )

          if [[ "$token" == ghp_* || "$token" == github_pat_* ]]; then
            args+=(--pat "$token")
          else
            args+=(--token "$token")
          fi

          config.sh "''${args[@]}"
        '';
      };
    in
    {
      launchd.daemons.github-runner-tunnels-macos = {
        serviceConfig = {
          Label = "github-runner-${runnerLabel}";
          KeepAlive = {
            Crashed = false;
          };
          ProcessType = "Standard";
          RunAtLoad = true;
          StandardErrorPath = "${logDir}/launchd-stderr.log";
          StandardOutPath = "${logDir}/launchd-stdout.log";
          ThrottleInterval = 30;
          UserName = user;
          WatchPaths = [
            "/etc/resolv.conf"
            "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
            tokenFile
          ];
          WorkingDirectory = stateDir;
        };

        script = ''
          set -euo pipefail

          export HOME=${escapeShellArg stateDir}
          export RUNNER_ROOT=${escapeShellArg stateDir}
          export PATH=${escapeShellArg path}:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin

          echo "Configuring GitHub Actions Runner"
          ${pkgs.findutils}/bin/find ${escapeShellArg workDir} -mindepth 1 -delete

          if [[ ! -f "$RUNNER_ROOT/.runner" ]]; then
            ${configureRunner}/bin/configure-github-runner-${runnerLabel}
          fi

          exec ${runnerPackage}/bin/Runner.Listener run --startuptype service
        '';
      };

      system.activationScripts.launchd.text = mkBefore ''
        set -euo pipefail

        old_label="actions.runner.beigethreat-tunnels.mercury-tunnels"
        old_plist="/Users/${config.host.username}/Library/LaunchAgents/$old_label.plist"
        old_dir="/Users/${config.host.username}/actions-runner-tunnels-macos"
        uid="$(id -u ${config.host.username})"

        if [ -e "$old_plist" ]; then
          /bin/launchctl bootout "gui/$uid/$old_label" 2>/dev/null || true
          /bin/rm -f "$old_plist"
        fi

        if [ -d "$old_dir" ] && [ -z "$(/bin/ls -A "$old_dir")" ]; then
          /bin/rmdir "$old_dir" 2>/dev/null || true
        fi

        echo >&2 "setting up GitHub Runner '${runnerName}'..."
        # shellcheck disable=SC2174
        ${pkgs.coreutils}/bin/mkdir -p -m u=rwx,g=rx,o= ${escapeShellArg stateDir}
        ${pkgs.coreutils}/bin/chown ${escapeShellArg user} ${escapeShellArg stateDir}
        # shellcheck disable=SC2174
        ${pkgs.coreutils}/bin/mkdir -p -m u=rwx,g=rx,o= ${escapeShellArg logDir}
        ${pkgs.coreutils}/bin/chown ${escapeShellArg user} ${escapeShellArg logDir}
        # shellcheck disable=SC2174
        ${pkgs.coreutils}/bin/mkdir -p -m u=rwx,g=rx,o= ${escapeShellArg workDir}
        ${pkgs.coreutils}/bin/chown ${escapeShellArg user} ${escapeShellArg workDir}

        if /bin/launchctl print system/github-runner-${runnerLabel} >/dev/null 2>&1; then
          /bin/launchctl kickstart -k system/github-runner-${runnerLabel} >/dev/null 2>&1 || true
        fi
      '';
    };

  flake.modules.homeManager.gh =
    { pkgs, ... }:
    {
      programs.gh = {
        enable = true;
        extensions = [
          pkgs.gh-poi # Safely clean up merged branches
          pkgs.gh-notify # View notifications with fzf support
          pkgs.gh-markdown-preview # Terminal markdown rendering
        ];

        settings = {
          editor = "hx";
          git_protocol = "ssh";
          prompt = "enabled";
          aliases = {
            co = "pr checkout";
            pv = "pr view";
            clean = "poi";
            notifications = "notify";
          };
        };
      };

      programs.gh-dash = {
        enable = true;
        settings = {
          prSections = [
            {
              title = "My Pull Requests";
              filters = "is:open author:@me";
            }
            {
              title = "Needs My Review";
              filters = "is:open review-requested:@me";
            }
          ];
        };
      };
    };
}
