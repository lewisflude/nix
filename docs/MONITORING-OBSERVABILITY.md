# Container Monitoring and Observability

This document outlines strategies for monitoring containerized services and gaining operational visibility.

## Current State

**Basic Monitoring:** systemd journal logs only
- ✅ Service status via `systemctl status`
- ✅ Logs via `journalctl -u podman-*`
- ❌ No metrics collection
- ❌ No alerting
- ❌ No dashboards

## Monitoring Levels

### Level 1: systemd and Journald (Current - Built-in)

**What you get:**
- Service status and restart tracking
- Structured logging via journald
- Basic health via systemd service states

**Usage:**
```bash
# Check service status
systemctl status podman-homarr.service

# View logs
journalctl -u podman-homarr.service -f

# Check all container services
systemctl list-units 'podman-*' --state=running

# View failed services
systemctl --failed 'podman-*'
```

**Pros:**
- ✅ Zero configuration
- ✅ Native NixOS integration
- ✅ Works out of the box

**Cons:**
- ❌ No metrics (CPU, memory, network)
- ❌ No historical data
- ❌ No alerting
- ❌ No visualization

### Level 2: Health Checks (Implemented ✅)

**What you get:**
- Container-level health status
- Automatic restart on health failures
- Application-aware monitoring

**Implementation:**

Already configured in `containers-supplemental/default.nix`:

```nix
extraOptions = [
  "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
  "--health-interval=30s"
  "--health-timeout=10s"
  "--health-retries=3"
];
```

**Usage:**
```bash
# Check container health
podman healthcheck run homarr

# View health status
podman ps --format "{{.Names}}\t{{.Status}}"

# Monitor health in real-time
watch -n5 'podman ps --format "table {{.Names}}\t{{.Status}}"'
```

**Pros:**
- ✅ Application-aware health checks
- ✅ Automatic recovery on failure
- ✅ Already implemented in this config

**Cons:**
- ❌ Still no resource metrics
- ❌ No centralized dashboard
- ❌ No alerting beyond restart

### Level 3: Metrics Collection (Recommended)

Add Prometheus for metrics and Grafana for visualization.

#### Option A: Lightweight - Prometheus + Node Exporter

```nix
{ config, pkgs, ... }: {
  # Enable Prometheus
  services.prometheus = {
    enable = true;
    port = 9090;
    
    exporters = {
      # System metrics
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };
    
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }
      {
        job_name = "cadvisor";
        static_configs = [{
          targets = [ "localhost:8081" ];
        }];
      }
    ];
  };
  
  # Add cAdvisor for container metrics
  virtualisation.oci-containers.containers.cadvisor = {
    image = "gcr.io/cadvisor/cadvisor:v0.47.1";
    
    ports = ["8081:8080"];
    
    volumes = [
      "/:/rootfs:ro"
      "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
      "/sys:/sys:ro"
      "/var/lib/containers:/var/lib/docker:ro"
      "/dev/disk:/dev/disk:ro"
    ];
    
    extraOptions = [
      "--privileged"  # Required for cAdvisor
      "--device=/dev/kmsg"
      
      # Resource limits for monitoring itself
      "--memory=512m"
      "--cpus=0.5"
    ];
  };
  
  # Optional: Grafana for visualization
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3001;
        http_addr = "0.0.0.0";
      };
    };
    
    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        url = "http://localhost:9090";
        isDefault = true;
      }];
    };
  };
  
  # Open firewall ports
  networking.firewall.allowedTCPPorts = [ 9090 3001 8081 ];
}
```

**Access:**
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001` (default login: admin/admin)
- cAdvisor: `http://localhost:8081`

**What you can monitor:**
- Container CPU usage
- Container memory usage
- Container network I/O
- Container disk I/O
- Service restart counts
- Health check status

#### Option B: Full Stack - Add Alerting

```nix
{
  services.prometheus = {
    enable = true;
    
    # Add Alertmanager
    alertmanager = {
      enable = true;
      port = 9093;
      
      configuration = {
        route = {
          receiver = "default";
          group_by = ["alertname"];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
        };
        
        receivers = [{
          name = "default";
          # Configure your notification method
          # email_configs = [{ to = "admin@example.com"; }];
          # webhook_configs = [{ url = "https://discord.com/api/webhooks/..."; }];
        }];
      };
    };
    
    # Add alert rules
    rules = [
      ''
        groups:
          - name: containers
            rules:
              # Alert if container is down
              - alert: ContainerDown
                expr: up{job="cadvisor"} == 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Container {{ $labels.instance }} is down"
              
              # Alert on high memory usage
              - alert: ContainerHighMemory
                expr: |
                  (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Container {{ $labels.name }} using >90% memory"
              
              # Alert on high CPU usage
              - alert: ContainerHighCPU
                expr: |
                  rate(container_cpu_usage_seconds_total[5m]) > 0.8
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "Container {{ $labels.name }} using >80% CPU"
              
              # Alert if service restarts frequently
              - alert: ContainerRestartingOften
                expr: |
                  rate(container_start_time_seconds[1h]) > 5
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Container {{ $labels.name }} restarting frequently"
      ''
    ];
  };
}
```

### Level 4: Centralized Logging (Advanced)

For production environments, consider centralized logging:

```nix
{
  # Option: Loki for log aggregation
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;
      
      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };
      
      schema_config = {
        configs = [{
          from = "2024-01-01";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };
      
      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
          cache_location = "/var/lib/loki/cache";
        };
        filesystem.directory = "/var/lib/loki/chunks";
      };
    };
  };
  
  # Promtail to ship logs from journald to Loki
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      
      clients = [{
        url = "http://localhost:3100/loki/api/v1/push";
      }];
      
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = config.networking.hostName;
          };
        };
        relabel_configs = [{
          source_labels = ["__journal__systemd_unit"];
          target_label = "unit";
        }];
      }];
    };
  };
}
```

## Practical Monitoring Setup

### Quick Start: Minimal Monitoring

Add this to your host configuration for basic container monitoring:

```nix
# hosts/jupiter/configuration.nix
{ config, pkgs, ... }: {
  # Import monitoring module
  imports = [ ../../modules/nixos/features/monitoring.nix ];
  
  # Enable basic monitoring
  host.features.monitoring = {
    enable = true;
    
    # Enable what you want
    prometheus.enable = true;
    grafana.enable = true;
    cadvisor.enable = true;
    alerting.enable = false;  # Enable when you configure receivers
  };
}
```

Then create the monitoring module:

```nix
# modules/nixos/features/monitoring.nix
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.host.features.monitoring;
in {
  options.host.features.monitoring = {
    enable = mkEnableOption "container monitoring stack";
    
    prometheus.enable = mkEnableOption "Prometheus metrics" // { default = true; };
    grafana.enable = mkEnableOption "Grafana dashboards" // { default = true; };
    cadvisor.enable = mkEnableOption "cAdvisor container metrics" // { default = true; };
    alerting.enable = mkEnableOption "Alertmanager" // { default = false; };
  };
  
  config = mkIf cfg.enable {
    # Prometheus
    services.prometheus = mkIf cfg.prometheus.enable {
      enable = true;
      port = 9090;
      
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" "processes" ];
        port = 9100;
      };
      
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [{ targets = [ "localhost:9100" ]; }];
        }
      ] ++ optional cfg.cadvisor.enable {
        job_name = "cadvisor";
        static_configs = [{ targets = [ "localhost:8081" ]; }];
      };
    };
    
    # Grafana
    services.grafana = mkIf cfg.grafana.enable {
      enable = true;
      settings.server = {
        http_port = 3001;
        http_addr = "0.0.0.0";
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [{
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }];
      };
    };
    
    # cAdvisor
    virtualisation.oci-containers.containers.cadvisor = mkIf cfg.cadvisor.enable {
      image = "gcr.io/cadvisor/cadvisor:v0.47.1";
      ports = ["8081:8080"];
      volumes = [
        "/:/rootfs:ro"
        "/var/run/podman/podman.sock:/var/run/docker.sock:ro"
        "/sys:/sys:ro"
        "/var/lib/containers:/var/lib/docker:ro"
        "/dev/disk:/dev/disk:ro"
      ];
      extraOptions = [
        "--privileged"
        "--device=/dev/kmsg"
        "--memory=512m"
        "--cpus=0.5"
      ];
    };
    
    # Firewall
    networking.firewall.allowedTCPPorts = 
      optional cfg.prometheus.enable 9090
      ++ optional cfg.grafana.enable 3001
      ++ optional cfg.cadvisor.enable 8081;
  };
}
```

## Useful Prometheus Queries

### Container Resource Usage

```promql
# Memory usage per container
container_memory_usage_bytes{name!=""}

# CPU usage per container (%)
rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100

# Network I/O per container
rate(container_network_transmit_bytes_total{name!=""}[5m])

# Disk I/O per container
rate(container_fs_writes_bytes_total{name!=""}[5m])
```

### Service Health

```promql
# Container restart count
changes(container_start_time_seconds{name!=""}[1h])

# Containers by state
container_last_seen{name!=""} == 1

# Health check failures
up{job="cadvisor"} == 0
```

### System Overview

```promql
# Total container count
count(container_last_seen{name!=""})

# Total memory used by containers
sum(container_memory_usage_bytes{name!=""})

# Total CPU used by containers
sum(rate(container_cpu_usage_seconds_total{name!=""}[5m]))
```

## Grafana Dashboards

### Import Pre-built Dashboards

1. Go to Grafana (http://localhost:3001)
2. Navigate to Dashboards → Import
3. Import these dashboard IDs:
   - **893** - Docker container & host metrics
   - **11600** - Container metrics (detailed)
   - **1860** - Node Exporter Full (system metrics)

### Custom Dashboard Example

Create a simple dashboard showing:
- Container status (up/down)
- Memory usage per container
- CPU usage per container
- Network traffic
- Recent restarts

## Alerting Examples

### Discord Webhook

```nix
services.prometheus.alertmanager.configuration = {
  receivers = [{
    name = "discord";
    webhook_configs = [{
      url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID";
      send_resolved = true;
    }];
  }];
};
```

### Email Alerts

```nix
services.prometheus.alertmanager.configuration = {
  receivers = [{
    name = "email";
    email_configs = [{
      to = "admin@example.com";
      from = "alertmanager@jupiter";
      smarthost = "smtp.gmail.com:587";
      auth_username = "your-email@gmail.com";
      auth_password = "your-app-password";
    }];
  }];
};
```

## Best Practices

### ✅ DO

1. **Start simple** - Level 1 & 2 first, then add metrics
2. **Monitor what matters** - Focus on critical services
3. **Set sensible thresholds** - Avoid alert fatigue
4. **Test your alerts** - Verify they work before production
5. **Document runbooks** - What to do when alerts fire
6. **Regular review** - Check dashboards weekly

### ❌ DON'T

1. **Don't over-monitor** - Too many metrics = noise
2. **Don't ignore alerts** - Or disable them if they're noisy
3. **Don't forget backups** - Monitor backup success too
4. **Don't expose metrics publicly** - Use firewall or reverse proxy
5. **Don't set unrealistic SLOs** - 100% uptime is impossible

## Resource Impact

### Monitoring Overhead

| Component | CPU | Memory | Disk |
|-----------|-----|--------|------|
| Health checks | Negligible | None | None |
| Prometheus | ~100MB | ~500MB | ~10GB/year |
| Grafana | ~50MB | ~200MB | ~1GB |
| cAdvisor | ~50MB | ~200MB | None |
| Alertmanager | ~20MB | ~100MB | Negligible |

Total overhead: ~200MB CPU, ~1GB RAM, ~11GB disk/year

## Next Steps

1. **Phase 1:** Rely on systemd status and health checks (current)
2. **Phase 2:** Add Prometheus + cAdvisor for metrics
3. **Phase 3:** Add Grafana for visualization
4. **Phase 4:** Configure alerting for critical issues
5. **Phase 5:** Consider centralized logging (Loki)

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [cAdvisor Documentation](https://github.com/google/cadvisor)
- [Container Monitoring Best Practices](https://www.cncf.io/blog/2022/05/11/best-practices-for-monitoring-cloud-native-applications/)
