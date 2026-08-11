# GitHub CLI and GitHub Actions runner configuration
{ config, ... }:
let
  # Captured from the top-level scope before the lower-level modules shadow `config`.
  inherit (config) username;

  # Facts shared by the Linux and macOS self-hosted runners.
  runnerUrl = "https://github.com/beigethreat/plugins";
  runnerNodeRuntimes = [ "node24" ];

  # Toolchain both runners need. Each platform appends its own extras below;
  # the divergence is deliberate, so do not merge the two lists.
  commonRunnerPackages = pkgs: [
    pkgs.bashInteractive
    pkgs.cmake
    pkgs.coreutils
    pkgs.curl
    pkgs.git
    pkgs.jq
    pkgs.just
    pkgs.nix
  ];
in
{
  flake.modules.nixos.githubRunners =
    {
      config,
      pkgs,
      ...
    }:
    {
      services.github-runners.tunnels-linux = {
        enable = true;
        package = pkgs.github-runner;
        url = runnerUrl;
        name = "jupiter-tunnels";
        tokenFile = config.sops.secrets.GITHUB_TOKEN.path;
        tokenType = "access";
        replace = true;
        # The module defaults to DynamicUser=true, which makes systemd put the
        # StateDirectory under /var/lib/private and bind-mount it MS_NOEXEC. That
        # stops CI executing binaries it just built (juceaide, plugin .so, etc).
        # Setting user/group is the module's own opt-out: it derives
        # DynamicUser=false from these. The account itself is defined below —
        # the upstream module never creates it.
        user = "github-runner-tunnels";
        group = "github-runner-tunnels";
        # Persist _work across reboots. The default work dir lives under
        # /run (tmpfs) and is wiped on boot, which also wipes the ccache/CPM
        # caches that CI workflows store under ${{ github.workspace }}/.
        # Must be distinct from the StateDirectory: the unconfigure script
        # ends with `find $WORK_DIRECTORY -mindepth 1 -delete`, which would
        # also wipe the runner's tokens if they shared a path.
        workDir = "/var/lib/github-runner-work/tunnels-linux";
        nodeRuntimes = runnerNodeRuntimes;

        extraLabels = [
          "linux"
          "nixos"
          "x64"
          "tunnels-heavy"
        ];

        # Linux-only extras: AWS uploads and plugin validation run on this runner.
        extraPackages = commonRunnerPackages pkgs ++ [
          pkgs.awscli2
          pkgs.pluginval
        ];
      };

      # Static account backing the user/group set on the runner above.
      users.users.github-runner-tunnels = {
        isSystemUser = true;
        group = "github-runner-tunnels";
        home = "/var/lib/github-runner-work/tunnels-linux";
        createHome = false;
      };
      users.groups.github-runner-tunnels = { };

      # Only the work dir needs pre-creating: it is the source of the module's
      # BindPaths= and systemd will not create it. The state and logs dirs are
      # created, chowned and made writable under ProtectSystem=strict by the
      # module's own StateDirectory=/LogsDirectory=.
      systemd.tmpfiles.rules = [
        "d /var/lib/github-runner-work 0755 root root - -"
        "d /var/lib/github-runner-work/tunnels-linux 0750 github-runner-tunnels github-runner-tunnels - -"
      ];
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

      user = username;
      runnerName = "mercury-tunnels";
      runnerLabel = "tunnels-macos";
      tokenFile = config.sops.secrets.GITHUB_TOKEN.path;
      stateDir = "/var/lib/github-runners/${runnerName}";
      logDir = "/var/log/github-runners/${runnerName}";
      workDir = "/private/var/lib/github-runners/_work/${runnerName}";
      runnerPackage = pkgs.github-runner.override {
        nodeRuntimes = runnerNodeRuntimes;
      };
      labels = [
        "macos"
        "arm64"
        runnerLabel
      ];
      # macOS-only extras: the system tar/gzip/find are BSD variants, so the
      # runner needs GNU ones on PATH.
      path = makeBinPath (
        commonRunnerPackages pkgs
        ++ [
          pkgs.findutils
          pkgs.gnutar
          pkgs.gzip
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
