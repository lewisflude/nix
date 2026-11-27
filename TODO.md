# TODO

Outstanding maintenance work, highest priority first. Tick items off (`- [x]`)
in the commit that fixes them, then delete ticked items once merged — git
history is the record.

Items marked _(unverified)_ came from review but were not confirmed against the
locked inputs; check before acting.

Source: modernisation audit, 2026-11-27 (nixpkgs `f6840765`, 2026-11-17).

## P0 — Broken or wasting builds

- [x] **Darwin activation scripts never run.** nix-darwin only executes
      `preActivation` / `extraActivation` / `postActivation` (plus built-ins);
      custom names are silently dropped. Move each into
      `system.activationScripts.postActivation.text` with `lib.mkAfter`.
  - `modules/darwin.nix:16` (fixUsrLocalOwnership), `:29` (aaCheckMasAuth),
    `:104` (powerProfiles / pmset)
  - `modules/disable-background-agents.nix:30`
  - `modules/nix.nix:74` (disableSpotlightNixStore)
  - `modules/jupiter-music.nix:77` (jupiterMusicCleanupAutofs)
- [x] **`ntsync` loaded on a kernel without it.** `modules/gaming.nix:56` adds
      it to `boot.kernelModules`, but `modules/zfs.nix:39` pins 6.12 (ntsync
      needs 6.14+). Gate it on kernel version or drop it while pinned.
- [x] **Dead CUDA cache.** Replace `cuda-maintainers.cachix.org` in
      `modules/constants.nix:179,197` with `https://cache.nixos-cuda.org` /
      `cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=`.
- [x] **Stale build workarounds (cause cache misses).** Remove:
  - `doCheck = false` on `cachix` — `modules/cli-apps.nix:10` (also forces
    devenv to rebuild)
  - `doCheck = false` on `pgcli` — `modules/development-tools.nix:38`
  - `boost = pkgs.boost186` on sunshine — `modules/sunshine.nix:62`
  - `cli-helpers-fix` overlay (nixpkgs has 2.15.1) — `modules/overlays.nix:62`
- [x] **Fix evaluation warnings (renamed options).**
  - avahi `publish.*` → `services.avahi.settings.publish.*` —
    `modules/samba.nix:86`, `modules/networking.nix:78`
  - `services.bazarr.listenPort` → `settings.general.port` —
    `modules/arr-stack.nix:57`
  - VPN-Confinement `accessibleFrom` → `allowedIngress` —
    `modules/qbittorrent.nix:196`
- [x] **lazygit `git.paging` is superseded** by `git.diffRenderers` (store
      symlink blocks lazygit's auto-migration) — `modules/cli-apps.nix:63`
- [ ] **Homarr image is archived.** `ghcr.io/ajnart/homarr:0.15.3` →
      `ghcr.io/homarr-labs/homarr` (v2; major migration) —
      `modules/podman-containers.nix:87`
- [ ] **Rotate the GitHub token** in the untracked `~/.config/nix/nix.conf`
      (exposed in a session transcript); source it from sops via `!include`
      instead (see P1 nix-user item).
- [ ] **Log in to FlakeHub cache** (`determinate-nixd login`) — currently 401.

## P1 — Replace hand-rolled config with upstream modules

- [x] **NVIDIA** — `modules/graphics.nix`,
      `modules/hosts/jupiter/hardware.nix:156`
  - `package = …production` → `hardware.nvidia.branch = "production"`
  - `extraModprobeConfig` NVreg strings → `hardware.nvidia.moduleParams.nvidia`
  - drop `nvidia-vaapi-driver` (added by `videoAcceleration`),
    `libva-vdpau-driver`, and `nvidia-drm.modeset/fbdev` kernel params
  - drop `WLR_DRM_DEVICES` (wlroots-only; niri uses `debug.render-drm-device`)
- [x] **fail2ban** filters via `environment.etc` →
      `services.fail2ban.jails.<name>.filter` — `modules/fail2ban.nix:83`
- [x] **Home Assistant secrets** — drop `hass-secrets-link` oneshot; set
      `sops.templates."hass-secrets.yaml".path` directly —
      `modules/home-assistant.nix:344`
- [ ] **Home Assistant `config.http`** — moved to UI in HA 2026.8; migrate and
      remove — `modules/home-assistant.nix:148`
- [x] **Caddy** — use `services.caddy.openFirewall` (`modules/caddy.nix:117`);
      drop v1-era `header_up X-Forwarded-*` (`modules/caddy.nix:9`)
- [ ] **Wake-on-LAN** — replace ethtool unit with `systemd.network.links`
      `WakeOnLan = "magic"` (UDP 9 rule already dropped; a custom `.link`
      replaces `99-default.link`, so carry its `NamePolicy` etc.) —
      `modules/wake-on-lan.nix:8`
- [ ] **Greeter** — launch `niri-uwsm.desktop` instead of wrapping
      `niri-session` in uwsm; then drop the polkit `mkForce` hack —
      `modules/greeter.nix:21`
- [ ] **GitHub runner** → nix-darwin `services.github-runners.<name>` —
      `modules/gh.nix:161`
- [x] **Node tooling** → HM `programs.npm` / `programs.pnpm` (keep the
      `sessionPath` entry) — `modules/javascript.nix:9`
- [ ] **Homebrew cleanup** — `modules/darwin.nix:139-156`
  - consider dropping `gpg-suite` (duplicates HM gpg + `pinentry_mac`)
  - consider `ghostty` cask → `pkgs.ghostty-bin`
- [x] **`$DRY_RUN_CMD` → `run`** in HM activation — `modules/nix-user.nix:39`,
      `modules/claude-code.nix:311`, `modules/codex.nix:164`,
      `modules/ai-cli-lib.nix:233`
- [ ] **nix-user token plumbing** — replace activation script rewriting
      `nix.conf` with HM `nix.extraOptions` + `!include <sops path>` —
      `modules/nix-user.nix:13`

## P2 — Remove dead weight

- [x] Unused overlays + inputs: `nur` (`modules/overlays.nix:47`), `fenix`
      (`modules/development-tools.nix:5`); remove matching dependabot entries
- [x] nvfetcher plumbing: `overlays/sources.toml`, `overlays/_sources/`,
      nvfetcher step in `pkgs/pog-scripts/update-all.nix:90`, treefmt exclude in
      `modules/per-system/treefmt.nix:20`
- [x] Orphaned `pkgs/home-assistant/custom-components/home-llm.nix`
- [x] Unused `chaotic-nyx.cachix.org` substituter —
      `modules/constants.nix:177,195`
- [x] Redundant `experimental-features` under Determinate; fix stale "3.18.1"
      comment — `modules/nix.nix:3,41`
- [x] CI: drop `platformLib` warning mask (`.github/workflows/ci.yml:36`); stop
      swallowing cachix push failures with `|| true` (`:115`, `:154`)
- [x] Stray `.alejandra.toml`, `.deadnix.toml` (treefmt is authoritative)
- [ ] Karabiner config for an uninstalled app — `modules/karabiner.nix` (re-add
      cask or drop module)
- [ ] `hyprcursor-phinger` input likely unused under niri _(unverified)_ —
      `modules/niri/session.nix:33`
- [x] Garnix `packages.x86_64-linux.*` only matches `dev`; expose real packages
      or drop the line — `garnix.yaml:12`
- [x] `nix-shell -p` hints → `nix run nixpkgs#…` —
      `scripts/validation/scan-vulnerabilities.sh:44`,
      `pkgs/pog-scripts/visualize-modules.nix:155` (dead branch)
- [x] Unused dependabot entries `solaar`, `nix-openclaw` —
      `.github/dependabot.yml:53,64`

## P3 — Larger decisions

- [ ] **powerlevel10k → starship** (`programs.starship`); removes vendored
      `modules/shell/p10k/` and instant-prompt hack
- [ ] **niri-flake stalled** (last commit 2026-08-04) → nixpkgs `programs.niri`;
      requires replacing the `programs.niri.settings` DSL and removes the
      `nixpkgs-niri` pin
- [ ] **claude-code-nix → llm-agents** `claude-code`; first add
      `cache.numtide.com` /
      `niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=` to
      `modules/constants.nix`
- [ ] **ZFS** — `zfs_2_3` is now 2.3.9: revisit `zfs_bclone_enabled=0` pin
      (`modules/zfs.nix:63`); consider `services.sanoid` over
      `services.zfs.autoSnapshot` (`:79`)
- [ ] **Tooling overlap** — pick one of: dependabot nix vs
      `update-flake-lock.yml`; commitizen hook vs cocogitto; `devour-flake` vs
      `nix-fast-build`
- [ ] **devShell** — use git-hooks `inputsFrom = [ config.pre-commit.devShell ]`
      instead of hand-merging `enabledPackages` _(unverified)_ —
      `modules/per-system/devShells.nix:10`
- [ ] **flake-parts `partitions`** for dev-only inputs (low value for a
      non-consumed config)
- [ ] **claude-desktop-linux** upstream stale (last push 2025-11); watch for a
      maintained replacement — `modules/claude-code.nix:21`
