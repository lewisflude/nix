# Container Stacks

This repository assumes long-lived Compose workloads live under `/opt/stacks`.

- The NixOS `modules.virtualisation` module creates the directory lazily and can enable Docker and/or Podman via the `modules.virtualisation.enableDocker` and `modules.virtualisation.enablePodman` options.
- When Docker is enabled, members of the primary user receive membership in the `docker` group and Home Manager exposes the Docker CLI tools on Linux.
- When Podman is enabled, Home Manager adds the Podman CLI (`podman`, `podman-compose`).
- Hosts that do not need Docker can disable it in their host definition (see `hosts/Lewiss-MacBook-Pro/default.nix` for an example) so the CLI and daemon stay out of the profile.

Set `modules.virtualisation.stacks.<name> = { path = "/opt/stacks/<name>"; };` to have systemd manage a compose project. Each definition creates a `docker-compose-<name>.service` unit that runs `docker compose up -d` during boot and `docker compose down` on stop. Stacks can opt into Podman with `usePodman = true`.

Compose projects under `/opt/stacks/<name>` can be managed with `docker compose` after a rebuild. Add additional automation (e.g. systemd services or timers) near the module when you want to bring stacks up automatically during deployments.
