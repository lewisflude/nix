# GPU Passthrough
# Dynamic VFIO GPU passthrough for Windows VM with NVIDIA RTX 4090
# Uses iGPU for host display when VM is running, rebinds nvidia when stopped
_: {
  flake.modules.nixos.gpuPassthrough =
    { pkgs, config, ... }:
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
        "vfio_virqfd"
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

            # Refuse if GPU-dependent services are running
            for svc in wivrn sunshine; do
              if systemctl --user is-active "$svc.service" 2>/dev/null; then
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
        "f /dev/shm/looking-glass 0660 ${config.host.username} libvirtd -"
        "d /home/${config.host.username}/vm-shared 0755 ${config.host.username} users -"
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
