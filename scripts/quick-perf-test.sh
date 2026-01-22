#!/usr/bin/env bash
# Save as: ~/quick-perf-test.sh

RESULTS_FILE="perf-test-$(date +%Y%m%d-%H%M%S).txt"

echo "=== Quick Performance Test ===" | tee "$RESULTS_FILE"
date | tee -a "$RESULTS_FILE"

# 1. Config check
echo -e "\n### Configuration ###" | tee -a "$RESULTS_FILE"
echo "I/O Schedulers:" | tee -a "$RESULTS_FILE"
grep "" /sys/block/{nvme0n1,sda,sdb}/queue/scheduler 2>/dev/null | tee -a "$RESULTS_FILE"

echo -e "\nKey sysctls:" | tee -a "$RESULTS_FILE"
sysctl vm.swappiness net.ipv4.tcp_congestion_control | tee -a "$RESULTS_FILE"

echo -e "\nCPU Governor:" | tee -a "$RESULTS_FILE"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor | tee -a "$RESULTS_FILE"

echo -e "\nOOM Protection:" | tee -a "$RESULTS_FILE"
systemctl is-active systemd-oomd | tee -a "$RESULTS_FILE"

# 2. Quick disk test
echo -e "\n### Disk Performance ###" | tee -a "$RESULTS_FILE"
sudo hdparm -t /dev/nvme0n1 | grep "Timing" | tee -a "$RESULTS_FILE"

# 3. Memory pressure
echo -e "\n### Memory Responsiveness ###" | tee -a "$RESULTS_FILE"
echo "Testing command latency under memory pressure..." | tee -a "$RESULTS_FILE"
nix-shell -p stress-ng --run "stress-ng --vm 2 --vm-bytes 60% --timeout 10s" &
sleep 2
time ls -la /tmp > /dev/null 2>&1
wait

echo -e "\nResults saved to: $RESULTS_FILE"
