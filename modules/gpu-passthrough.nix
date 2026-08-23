# GPU Passthrough
# Dynamic VFIO GPU passthrough for Windows VM with NVIDIA RTX 4090
# Uses iGPU for host display when VM is running, rebinds nvidia when stopped
{ config, ... }:
let
  inherit (config) username;
in
{
  flake.modules.nixos.gpuPassthrough =
    { pkgs, ... }:
    {
      # IOMMU support
      boot.kernelParams = [
        "intel_iommu=on"
        "iommu=pt"
      ];

      boot.kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
      ];

      # Virtualization stack
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          swtpm.enable = true; # TPM 2.0 emulation (Windows 11)
          runAsRoot = true; # Required for VFIO device access
          vhostUserPackages = [ pkgs.virtiofsd ];
        };
      };

      # Networking for VM
      networking.firewall.trustedInterfaces = [ "virbr0" ];

      # Auto-start libvirt default NAT network
      systemd.services.libvirtd-default-network = {
        description = "Start libvirt default network";
        after = [ "libvirtd.service" ];
        requires = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
          ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
        '';
      };

      programs.virt-manager.enable = true;

      environment.systemPackages = [
        pkgs.looking-glass-client
        pkgs.virtiofsd
        (pkgs.writeShellApplication {
          name = "vm-gpu-bind";
          runtimeInputs = [
            pkgs.pciutils
            pkgs.kmod
          ];
          text = ''
            # Bind GPU to vfio-pci for passthrough
            # Run: lspci -nn | grep NVIDIA to find your PCI IDs
            # Then set these in the script or pass as args

            # Refuse if GPU-dependent services are running.
            #
            # This script writes to /sys/bus/pci/drivers/*/{bind,unbind}, so it
            # runs as root -- but the services are in the *desktop user's*
            # session. A bare `systemctl --user` under sudo queries root's user
            # bus, which has neither unit, so the guard would silently always
            # pass and let us pull the GPU out from under a live VR session.
            # Resolve the invoking user's bus explicitly.
            guard_uid="''${SUDO_UID:-$(id -u)}"
            for svc in wivrn sunshine; do
              if XDG_RUNTIME_DIR="/run/user/$guard_uid" \
                 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$guard_uid/bus" \
                 systemctl --user --machine="$guard_uid@.host" is-active "$svc.service" >/dev/null 2>&1; then
                echo "ERROR: $svc is running. Stop it first: systemctl --user stop $svc" >&2
                exit 1
              fi
            done

            GPU_PCI=''${1:-"01:00.0"}
            GPU_AUDIO=''${2:-"01:00.1"}

            echo "Unbinding NVIDIA GPU ($GPU_PCI) from nvidia driver..."
            echo "$GPU_PCI" > /sys/bus/pci/drivers/nvidia/unbind 2>/dev/null || true
            echo "$GPU_AUDIO" > /sys/bus/pci/drivers/snd_hda_intel/unbind 2>/dev/null || true

            echo "Binding to vfio-pci..."
            echo "vfio-pci" > "/sys/bus/pci/devices/0000:$GPU_PCI/driver_override"
            echo "vfio-pci" > "/sys/bus/pci/devices/0000:$GPU_AUDIO/driver_override"
            echo "0000:$GPU_PCI" > /sys/bus/pci/drivers/vfio-pci/bind
            echo "0000:$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/bind

            echo "GPU bound to vfio-pci, ready for passthrough"
          '';
        })
        (pkgs.writeShellApplication {
          name = "vm-gpu-unbind";
          runtimeInputs = [
            pkgs.pciutils
            pkgs.kmod
          ];
          text = ''
            # Return GPU to nvidia driver after VM shutdown
            GPU_PCI=''${1:-"01:00.0"}
            GPU_AUDIO=''${2:-"01:00.1"}

            echo "Unbinding from vfio-pci..."
            echo "0000:$GPU_PCI" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true
            echo "0000:$GPU_AUDIO" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || true

            echo "" > "/sys/bus/pci/devices/0000:$GPU_PCI/driver_override"
            echo "" > "/sys/bus/pci/devices/0000:$GPU_AUDIO/driver_override"

            echo "Rebinding to nvidia..."
            echo "0000:$GPU_PCI" > /sys/bus/pci/drivers_probe
            echo "0000:$GPU_AUDIO" > /sys/bus/pci/drivers_probe

            echo "GPU returned to nvidia driver"
          '';
        })
      ];

      # Shared folder for VM file transfers via virtiofs
      systemd.tmpfiles.rules = [
        "f /dev/shm/looking-glass 0660 ${username} libvirtd -"
        "d /home/${username}/vm-shared 0755 ${username} users -"
      ];
    };

  flake.modules.homeManager.gpuPassthrough =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.virt-viewer
      ];
    };
}
