{
  pkgs,
  pog,
  ...
}:
pog.pog {
  name = "calculate-qbittorrent-config";
  version = "1.0.0";
  description = "Calculate optimal qBittorrent settings from speed tests and system resources";

  flags = [
    {
      name = "interface";
      short = "i";
      description = "Network interface to test";
      default = "vlan2";
    }
    {
      name = "vpn_namespace";
      short = "n";
      description = "VPN network namespace (leave empty for direct connection)";
      default = "qbt";
    }
    {
      name = "upload_speed";
      short = "u";
      description = "Manual upload speed in KB/s (skip speed test if provided)";
    }
    {
      name = "priority";
      short = "p";
      description = "Optimization priority: speed, balanced, or hdd-safe";
      default = "speed";
      prompt = ''gum choose "speed" "balanced" "hdd-safe" --header "Select optimization priority:"'';
      completion = ''echo "speed balanced hdd-safe"'';
    }
    {
      name = "output_format";
      short = "o";
      description = "Output format: nix, json, or summary";
      default = "nix";
      completion = ''echo "nix json summary"'';
    }
    {
      name = "skip_test";
      bool = true;
      description = "Skip speed test (requires --upload_speed to be set)";
    }
  ];

  runtimeInputs = [
    pkgs.coreutils
    pkgs.curl
    pkgs.bc
    pkgs.jq
    pkgs.gnused
    pkgs.gum
    pkgs.iproute2
    pkgs.util-linux
  ];

  script =
    helpers: with helpers; ''
            # Speed Test Function
            run_speed_test() {
              local interface="$1"
              local namespace="$2"

              blue "Running speed test..."

              # Create test file (10MB)
              dd if=/dev/zero of=/tmp/qbt-speedtest.tmp bs=1M count=10 2>/dev/null

              # Test upload with httpbin (10MB file)
              local cmd="curl -s --max-time 60 --interface $interface \
                -X POST -H 'Content-Type: application/octet-stream' \
                --data-binary @/tmp/qbt-speedtest.tmp \
                https://httpbin.org/post"

              if [ -n "$namespace" ]; then
                START_TIME=$(date +%s.%N)
                sudo ip netns exec "$namespace" $cmd >/dev/null 2>&1 || die "Speed test failed in VPN namespace"
                END_TIME=$(date +%s.%N)
              else
                START_TIME=$(date +%s.%N)
                eval $cmd >/dev/null 2>&1 || die "Speed test failed"
                END_TIME=$(date +%s.%N)
              fi

              rm -f /tmp/qbt-speedtest.tmp

              # Calculate upload speed
              FILE_SIZE=10485760  # 10MB in bytes
              DURATION=$(echo "$END_TIME - $START_TIME" | bc)
              UPLOAD_MBPS=$(echo "scale=2; ($FILE_SIZE * 8) / ($DURATION * 1000000)" | bc)
              UPLOAD_KBPS=$(echo "scale=0; ($FILE_SIZE) / ($DURATION * 1024)" | bc)

              green "Upload: $UPLOAD_MBPS Mbit/s ($UPLOAD_KBPS KB/s)"

              echo "$UPLOAD_KBPS"
            }

            # System Detection Function
            detect_system_resources() {
              RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
              CPU_CORES=$(nproc)

              # Detect storage type (check if any non-rotational drives exist)
              if lsblk -o NAME,ROTA 2>/dev/null | grep -q " 0$"; then
                STORAGE_TYPE="ssd"
              else
                STORAGE_TYPE="hdd"
              fi

              debug "System: ''${RAM_GB}GB RAM, ''${CPU_CORES} CPU cores, ''${STORAGE_TYPE} storage"
            }

            # Calculator Function - Implements Azureus Calculator Logic
            calculate_settings() {
              local upload_kbps="$1"
              local priority="$2"

              # Core calculation: Upload Slots = Upload Speed ÷ 5 KB/s per slot
              UPLOAD_SLOTS=$((upload_kbps / 5))

              # Base settings
              MAX_CONNECTIONS=600
              MAX_CONNECTIONS_PER_TORRENT=$((upload_kbps / 50))
              [ $MAX_CONNECTIONS_PER_TORRENT -gt 100 ] && MAX_CONNECTIONS_PER_TORRENT=100
              [ $MAX_CONNECTIONS_PER_TORRENT -lt 80 ] && MAX_CONNECTIONS_PER_TORRENT=80

              MAX_UPLOADS=$UPLOAD_SLOTS

              # Priority-based adjustments
              case "$priority" in
                speed)
                  # Speed-optimized: Maximum concurrency
                  MAX_ACTIVE_TORRENTS=$((UPLOAD_SLOTS / 3))
                  MAX_ACTIVE_UPLOADS=$((MAX_ACTIVE_TORRENTS / 2))
                  ;;
                balanced)
                  # Balanced: Current conservative settings
                  MAX_ACTIVE_TORRENTS=150
                  MAX_ACTIVE_UPLOADS=75
                  MAX_UPLOADS=300
                  ;;
                hdd-safe)
                  # HDD-safe: Very conservative for old/slow HDDs
                  MAX_ACTIVE_TORRENTS=100
                  MAX_ACTIVE_UPLOADS=50
                  MAX_UPLOADS=200
                  ;;
              esac

              # Calculate per-torrent upload slots
              MAX_UPLOADS_PER_TORRENT=$((UPLOAD_SLOTS / MAX_ACTIVE_TORRENTS))
              [ $MAX_UPLOADS_PER_TORRENT -lt 10 ] && MAX_UPLOADS_PER_TORRENT=10

              # Upload speed limit (80% rule)
              UPLOAD_SPEED_LIMIT=$((upload_kbps * 80 / 100))

              # System resource settings based on detected RAM
              if [ "$RAM_GB" -ge 32 ]; then
                PHYSICAL_MEMORY_LIMIT=8192
                DISK_CACHE_SIZE=4096
              elif [ "$RAM_GB" -ge 16 ]; then
                PHYSICAL_MEMORY_LIMIT=4096
                DISK_CACHE_SIZE=2048
              else
                PHYSICAL_MEMORY_LIMIT=2048
                DISK_CACHE_SIZE=1024
              fi

              # CPU-based settings
              if [ "$CPU_CORES" -ge 16 ]; then
                ASYNC_IO_THREADS=32
                HASHING_THREADS=8
              elif [ "$CPU_CORES" -ge 8 ]; then
                ASYNC_IO_THREADS=16
                HASHING_THREADS=4
              else
                ASYNC_IO_THREADS=8
                HASHING_THREADS=2
              fi
            }

            # Output Functions
            output_nix() {
              cat << EOF
      # Generated by calculate-qbittorrent-config v1.0.0
      # Upload speed: $UPLOAD_KBPS KB/s ($UPLOAD_MBPS Mbit/s)
      # System: ''${RAM_GB}GB RAM, ''${CPU_CORES} CPU cores, ''${STORAGE_TYPE} storage
      # Priority: $priority

      qbittorrent = {
        # Speed Optimization Settings
        uploadSpeedLimit = $UPLOAD_SPEED_LIMIT;
        maxConnections = $MAX_CONNECTIONS;
        maxConnectionsPerTorrent = $MAX_CONNECTIONS_PER_TORRENT;
        maxUploads = $MAX_UPLOADS;
        maxUploadsPerTorrent = $MAX_UPLOADS_PER_TORRENT;
        maxActiveTorrents = $MAX_ACTIVE_TORRENTS;
        maxActiveUploads = $MAX_ACTIVE_UPLOADS;

        # System Resource Settings
        physicalMemoryLimit = $PHYSICAL_MEMORY_LIMIT;
        asyncIOThreadsCount = $ASYNC_IO_THREADS;
        hashingThreadsCount = $HASHING_THREADS;
        diskCacheSize = $DISK_CACHE_SIZE;
      };
      EOF
            }

            output_json() {
              cat << EOF | jq
      {
        "speed_test": {
          "upload_mbps": $UPLOAD_MBPS,
          "upload_kbps": $UPLOAD_KBPS,
          "interface": "$interface",
          "namespace": "$vpn_namespace"
        },
        "system": {
          "ram_gb": ''${RAM_GB},
          "cpu_cores": ''${CPU_CORES},
          "storage_type": "''${STORAGE_TYPE}"
        },
        "settings": {
          "uploadSpeedLimit": $UPLOAD_SPEED_LIMIT,
          "maxConnections": $MAX_CONNECTIONS,
          "maxConnectionsPerTorrent": $MAX_CONNECTIONS_PER_TORRENT,
          "maxUploads": $MAX_UPLOADS,
          "maxUploadsPerTorrent": $MAX_UPLOADS_PER_TORRENT,
          "maxActiveTorrents": $MAX_ACTIVE_TORRENTS,
          "maxActiveUploads": $MAX_ACTIVE_UPLOADS,
          "physicalMemoryLimit": $PHYSICAL_MEMORY_LIMIT,
          "asyncIOThreadsCount": $ASYNC_IO_THREADS,
          "hashingThreadsCount": $HASHING_THREADS,
          "diskCacheSize": $DISK_CACHE_SIZE
        },
        "priority": "$priority"
      }
      EOF
            }

            output_summary() {
              local storage_upper=$(echo "$STORAGE_TYPE" | tr '[:lower:]' '[:upper:]')
              cat << EOF

      ╔══════════════════════════════════════════════════════════╗
      ║   qBittorrent Speed Optimization Calculator v1.0.0       ║
      ╚══════════════════════════════════════════════════════════╝

      Speed Test Results:
      ─────────────────────────────────────────────────────────
      Interface:        $interface
      Upload Speed:     $UPLOAD_MBPS Mbit/s ($UPLOAD_KBPS KB/s)
      Recommended:      $UPLOAD_SPEED_LIMIT KB/s (80% rule)

      System Resources:
      ─────────────────────────────────────────────────────────
      RAM:              ''${RAM_GB} GB
      CPU Cores:        ''${CPU_CORES}
      Storage:          ''${storage_upper}

      Recommended Settings ($priority Priority):
      ─────────────────────────────────────────────────────────
      uploadSpeedLimit:           $UPLOAD_SPEED_LIMIT KB/s
      maxConnections:             $MAX_CONNECTIONS
      maxConnectionsPerTorrent:   $MAX_CONNECTIONS_PER_TORRENT
      maxUploads:                 $MAX_UPLOADS
      maxUploadsPerTorrent:       $MAX_UPLOADS_PER_TORRENT
      maxActiveTorrents:          $MAX_ACTIVE_TORRENTS
      maxActiveUploads:           $MAX_ACTIVE_UPLOADS

      System Tuning:
      ─────────────────────────────────────────────────────────
      physicalMemoryLimit:        ''${PHYSICAL_MEMORY_LIMIT} MiB
      asyncIOThreadsCount:        ''${ASYNC_IO_THREADS}
      hashingThreadsCount:        ''${HASHING_THREADS}
      diskCacheSize:              ''${DISK_CACHE_SIZE} MiB

      Next Steps:
      ─────────────────────────────────────────────────────────
      1. Run: nix run .#calculate-qbittorrent-config -- -o nix
      2. Copy output to hosts/jupiter/default.nix
      3. Rebuild: nh os switch
      4. Monitor: ./scripts/monitor-hdd-storage.sh

      EOF
            }

            # Main Script
            cyan "🚀 qBittorrent Speed Optimization Calculator"
            echo ""

            # Detect system resources
            detect_system_resources

            # Get upload speed
            if ${var.empty "upload_speed"}; then
              if ${flag "skip_test"}; then
                die "Must provide --upload_speed when using --skip_test"
              fi
              UPLOAD_KBPS=$(run_speed_test "$interface" "$vpn_namespace")
              UPLOAD_MBPS=$(echo "scale=2; $UPLOAD_KBPS * 8 / 1000" | bc)
            else
              UPLOAD_KBPS="$upload_speed"
              UPLOAD_MBPS=$(echo "scale=2; $UPLOAD_KBPS * 8 / 1000" | bc)
              blue "Using manual upload speed: $UPLOAD_MBPS Mbit/s ($UPLOAD_KBPS KB/s)"
            fi

            # Validate priority
            case "$priority" in
              speed|balanced|hdd-safe)
                ;;
              *)
                die "Invalid priority: $priority (must be speed, balanced, or hdd-safe)"
                ;;
            esac

            # Calculate settings
            calculate_settings "$UPLOAD_KBPS" "$priority"

            # Output
            case "$output_format" in
              nix)
                output_nix
                ;;
              json)
                output_json
                ;;
              summary)
                output_summary
                ;;
              *)
                die "Invalid output format: $output_format (must be nix, json, or summary)"
                ;;
            esac

            green "✓ Configuration generated successfully"
    '';
}
