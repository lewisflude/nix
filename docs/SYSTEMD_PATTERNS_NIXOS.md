# Systemd Patterns in NixOS

This guide translates common systemd patterns from traditional Linux distributions into NixOS's declarative configuration style.

## Service Types

### Simple Service (Type=simple)

**Traditional systemd:**
```ini
[Unit]
Description=My Simple Service

[Service]
Type=simple
ExecStart=/usr/bin/myapp
Restart=always

[Install]
WantedBy=multi-user.target
```

**NixOS:**
```nix
systemd.services.myapp = {
  description = "My Simple Service";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.myapp}/bin/myapp";
    Restart = "always";
  };
};
```

### Forking Service (Type=forking)

**NixOS:**
```nix
systemd.services.mydaemon = {
  description = "My Forking Daemon";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "forking";
    ExecStart = "${pkgs.mydaemon}/bin/mydaemon";
    PIDFile = "/run/mydaemon.pid";
    Restart = "on-failure";
  };
};
```

### Oneshot Service (Type=oneshot)

**Use case:** Scripts that run once and exit, like mounting or state changes.

**NixOS:**
```nix
systemd.services.setup-something = {
  description = "Setup something at boot";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.writeShellScript "setup" ''
      echo "Setting up..."
      # Your setup commands here
    ''}";
    RemainAfterExit = true;  # Mark as active after exit
  };
};
```

## Handling Dependencies

### Service Requires Another Service

**Pattern:** Service A requires Service B to be running.

**NixOS:**
```nix
systemd.services.service-a = {
  description = "Service A";
  requires = [ "service-b.service" ];
  after = [ "service-b.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.service-a}/bin/service-a";
  };
};
```

### Optional Dependency (Wants)

**Pattern:** Service A wants Service B, but can run without it.

**NixOS:**
```nix
systemd.services.service-a = {
  description = "Service A";
  wants = [ "service-b.service" ];
  after = [ "service-b.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.service-a}/bin/service-a";
  };
};
```

## Network Dependencies

### Wait for Network to be Online

**Pattern:** Service needs network connectivity before starting.

**NixOS:**
```nix
systemd.services.network-dependent = {
  description = "Service that needs network";
  wants = [ "network-online.target" ];
  after = [ "network-online.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
  };
};

# Ensure network-online.target works
systemd.services.NetworkManager-wait-online.enable = true;
# OR for systemd-networkd:
# systemd.services.systemd-networkd-wait-online.enable = true;
```

### Wait for DNS Resolution

**Pattern:** Service needs DNS to work.

**NixOS:**
```nix
systemd.services.dns-dependent = {
  description = "Service that needs DNS";
  wants = [ "network-online.target" ];
  after = [ "network-online.target" "nss-lookup.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
  };
};
```

## Socket Activation

**Pattern:** Start service on-demand when socket is accessed.

**NixOS:**
```nix
systemd.sockets.myapp = {
  description = "MyApp Socket";
  wantedBy = [ "sockets.target" ];
  listenStreams = [ "0.0.0.0:8080" ];
  socketConfig = {
    Accept = false;
  };
};

systemd.services.myapp = {
  description = "MyApp Service";
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    # Service will receive socket from systemd
  };
};
```

## systemd-tmpfiles Configuration

### Create Directories at Boot

**Traditional:**
```ini
# /usr/lib/tmpfiles.d/myapp.conf
d /run/myapp 0755 myuser mygroup -
```

**NixOS:**
```nix
systemd.tmpfiles.rules = [
  "d /run/myapp 0755 myuser mygroup -"
];

# Or more complex example:
systemd.tmpfiles.rules = [
  # Create directory
  "d /var/lib/myapp 0750 myuser mygroup -"
  # Create file with content
  "f /var/lib/myapp/config 0644 myuser mygroup - content here"
  # Clean old files (remove files older than 10 days)
  "d /var/log/myapp 0755 root root 10d"
];
```

### Write to Files at Boot

**Traditional:**
```ini
# /etc/tmpfiles.d/disable-usb-wake.conf
w /proc/acpi/wakeup - - - - USBE
```

**NixOS:**
```nix
systemd.tmpfiles.rules = [
  "w /proc/acpi/wakeup - - - - USBE"
];

# Multiple writes to same file:
systemd.tmpfiles.rules = [
  "w+ /proc/acpi/wakeup - - - - USBE"
  "w+ /proc/acpi/wakeup - - - - LID0"
];
```

## Service Hardening / Sandboxing

### Basic Hardening

**NixOS:**
```nix
systemd.services.hardened-service = {
  description = "Hardened Service";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    
    # Run as dynamic user (created on-the-fly)
    DynamicUser = true;
    
    # Filesystem protections
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    
    # Network restrictions
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
    
    # Capabilities
    NoNewPrivileges = true;
    CapabilityBoundingSet = "";
    
    # Namespace isolation
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    ProtectKernelModules = true;
  };
};
```

### Service with Specific User and Writable Directories

**NixOS:**
```nix
systemd.services.myapp = {
  description = "MyApp with specific permissions";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    User = "myuser";
    Group = "mygroup";
    
    # Read-only root, but allow writes to specific paths
    ProtectSystem = "strict";
    ReadWritePaths = [ "/var/lib/myapp" "/var/log/myapp" ];
    
    # Create runtime directory
    RuntimeDirectory = "myapp";  # Creates /run/myapp owned by User:Group
    StateDirectory = "myapp";    # Creates /var/lib/myapp
    LogsDirectory = "myapp";     # Creates /var/log/myapp
    CacheDirectory = "myapp";    # Creates /var/cache/myapp
  };
};

# Ensure user exists:
users.users.myuser = {
  isSystemUser = true;
  group = "mygroup";
};

users.groups.mygroup = {};
```

## Service Restart Policies

### Auto-Restart on Failure

**NixOS:**
```nix
systemd.services.resilient-service = {
  description = "Service that auto-restarts";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    Restart = "always";           # always|on-failure|on-abnormal|on-abort|on-watchdog
    RestartSec = "30s";           # Wait 30s before restarting
    StartLimitBurst = 5;          # Allow 5 restarts
    StartLimitIntervalSec = 300;  # Within 5 minutes
  };
};
```

## Environment Variables

### Setting Environment Variables

**NixOS:**
```nix
systemd.services.myapp = {
  description = "Service with environment";
  wantedBy = [ "multi-user.target" ];
  environment = {
    LOG_LEVEL = "debug";
    DATA_DIR = "/var/lib/myapp";
  };
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    # Or use EnvironmentFile for secrets:
    EnvironmentFile = "/run/secrets/myapp-env";
  };
};
```

### Using SOPS Secrets as Environment Variables

**NixOS:**
```nix
{ config, ... }:

{
  sops.secrets."myapp/api-key" = {
    owner = "myuser";
  };

  systemd.services.myapp = {
    description = "Service with secrets";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.myapp}/bin/myapp";
      User = "myuser";
      EnvironmentFile = config.sops.secrets."myapp/api-key".path;
    };
  };
}
```

## Timers (Cron Alternative)

### Run Service Periodically

**NixOS:**
```nix
systemd.timers.backup = {
  description = "Backup Timer";
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "daily";
    # OR: OnCalendar = "Mon,Fri *-*-* 02:00:00";
    # OR: OnCalendar = "*:0/15";  # Every 15 minutes
    Persistent = true;  # Run missed timers on boot
    RandomizedDelaySec = "15min";  # Random delay up to 15min
  };
};

systemd.services.backup = {
  description = "Backup Service";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.writeShellScript "backup" ''
      #!/bin/sh
      echo "Running backup..."
      # Your backup commands
    ''}";
  };
};
```

## Pre/Post Start/Stop Scripts

### Service with Pre-Start and Post-Stop

**NixOS:**
```nix
systemd.services.complex-service = {
  description = "Service with hooks";
  wantedBy = [ "multi-user.target" ];
  
  preStart = ''
    echo "Preparing environment..."
    mkdir -p /var/lib/myapp
    chown myuser:mygroup /var/lib/myapp
  '';
  
  postStart = ''
    echo "Service started, notifying monitoring..."
    curl -X POST http://monitoring.local/notify
  '';
  
  preStop = ''
    echo "About to stop, draining connections..."
    sleep 5
  '';
  
  postStop = ''
    echo "Cleaning up..."
    rm -f /run/myapp/*.pid
  '';
  
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    User = "myuser";
  };
};
```

## Service with OnFailure Notification

### Email Notification on Service Failure

**NixOS:**
```nix
{ pkgs, ... }:

{
  # Notification service template
  systemd.services."notify-failure@" = {
    description = "Notify about failed %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "notify-failure" ''
        #!/bin/sh
        UNIT="$1"
        
        ${pkgs.mailutils}/bin/mail -s "Service $UNIT failed" admin@example.com <<EOF
        Service $UNIT has failed.
        
        Status:
        $(systemctl status "$UNIT")
        
        Journal:
        $(journalctl -u "$UNIT" -n 50 --no-pager)
        EOF
      ''} %i";
    };
  };

  # Use it in your service
  systemd.services.important-service = {
    description = "Important Service";
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      OnFailure = "notify-failure@%n.service";
    };
    serviceConfig = {
      ExecStart = "${pkgs.myapp}/bin/myapp";
    };
  };
}
```

## Masking Services

### Prevent Service from Ever Starting

**NixOS:**
```nix
# Completely disable a service
systemd.services.unwanted-service.enable = false;

# OR mask it (makes it impossible to start even manually)
systemd.services.unwanted-service = {
  enable = false;
  unitConfig.ConditionPathExists = "/this/path/does/not/exist";
};

# OR for system services, use:
systemd.services."unwanted-service".enable = lib.mkForce false;
```

## Path-Based Activation

### Start Service When File/Directory Changes

**NixOS:**
```nix
systemd.paths.watch-config = {
  description = "Watch for config changes";
  wantedBy = [ "multi-user.target" ];
  pathConfig = {
    PathModified = "/etc/myapp/config.yaml";
    Unit = "reload-myapp.service";
  };
};

systemd.services.reload-myapp = {
  description = "Reload MyApp Configuration";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.systemd}/bin/systemctl reload myapp.service";
  };
};
```

## Logging Configuration

### Control Service Log Level

**NixOS:**
```nix
systemd.services.verbose-service = {
  description = "Service with debug logging";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    LogLevelMax = 7;  # 0=emerg, 7=debug
    StandardOutput = "journal";
    StandardError = "journal";
    SyslogIdentifier = "myapp";
  };
};
```

### Suppress Service Output

**NixOS:**
```nix
systemd.services.quiet-service = {
  description = "Service without logs";
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    StandardOutput = "null";
    StandardError = "null";
  };
};
```

## Complete Real-World Example

### qBittorrent with VPN Binding

**NixOS Module:**
```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.qbittorrent-vpn;
  constants = import ../lib/constants.nix;
in
{
  options.services.qbittorrent-vpn = {
    enable = lib.mkEnableOption "qBittorrent with VPN binding";
    
    interface = lib.mkOption {
      type = lib.types.str;
      default = "proton0";
      description = "VPN interface to bind to";
    };
  };

  config = lib.mkIf cfg.enable {
    # Create user
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "qbittorrent";
    };
    users.groups.qbittorrent = {};

    # Service configuration
    systemd.services.qbittorrent = {
      description = "qBittorrent with VPN binding";
      after = [ "network-online.target" "${cfg.interface}.service" ];
      wants = [ "network-online.target" ];
      requires = [ "${cfg.interface}.service" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        # Wait for VPN interface
        for i in {1..30}; do
          if ip addr show ${cfg.interface} &>/dev/null; then
            echo "VPN interface ${cfg.interface} is up"
            break
          fi
          echo "Waiting for VPN interface... ($i/30)"
          sleep 1
        done
      '';

      serviceConfig = {
        Type = "simple";
        User = "qbittorrent";
        Group = "qbittorrent";
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox";
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = "30s";
        
        # Hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        
        # Directories
        StateDirectory = "qbittorrent";
        RuntimeDirectory = "qbittorrent";
        ReadWritePaths = [ "/mnt/storage/torrents" ];
        
        # Network binding
        Environment = "QBT_PROFILE=/var/lib/qbittorrent";
      };

      # Notify on failure
      unitConfig.OnFailure = "notify-failure@%n.service";
    };

    # Monitoring timer
    systemd.timers.qbittorrent-health = {
      description = "qBittorrent Health Check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5";  # Every 5 minutes
        Persistent = true;
      };
    };

    systemd.services.qbittorrent-health = {
      description = "Check qBittorrent VPN binding";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "check-qbt" ''
          #!/bin/sh
          # Check if process is bound to VPN interface
          if ! ip addr show ${cfg.interface} | grep -q "state UP"; then
            echo "VPN interface down, restarting qBittorrent"
            systemctl restart qbittorrent.service
          fi
        ''}";
      };
    };
  };
}
```

## Tips for Converting systemd Unit Files

1. **Unit section** → `unitConfig = { ... }`
2. **Service section** → `serviceConfig = { ... }`
3. **Install section** → `wantedBy`, `requiredBy`, `before`, `after`
4. **ExecStart with shell scripts** → Use `pkgs.writeShellScript`
5. **Drop-in overrides** → Merge directly into service definition
6. **Unit file paths** → Reference packages with `${pkgs.name}/bin/command`

## Debugging Services in NixOS

```bash
# Same commands work as on any systemd system:
systemctl status myservice
journalctl -u myservice -f
systemctl list-dependencies myservice
systemd-analyze verify /etc/systemd/system/myservice.service

# Check generated unit file:
systemctl cat myservice

# See what NixOS generated:
cat /etc/systemd/system/myservice.service
```

## References

- [NixOS Manual - systemd Services](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [systemd.exec(5)](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
- Arch Wiki systemd article (source of these patterns)
