#!/usr/bin/env bash
#
# XFS Performance Benchmark Suite
#
# Run this before and after applying XFS optimizations to measure impact.
# Results are saved to timestamped files for comparison.
#
# Usage: ./benchmark-xfs-before-after.sh [before|after]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
TEST_DIR="/mnt/storage/xfs-benchmark-test"
RESULTS_DIR="$HOME/.xfs-benchmark-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PHASE="${1:-unknown}"
RESULT_FILE="$RESULTS_DIR/benchmark_${PHASE}_${TIMESTAMP}.txt"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up test files...${NC}"
    rm -rf "$TEST_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  XFS Performance Benchmark Suite                          ║${NC}"
echo -e "${BLUE}║  Phase: ${PHASE^^}                                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Start result file
{
    echo "XFS Benchmark Results - Phase: ${PHASE}"
    echo "Timestamp: $(date)"
    echo "=========================================="
    echo ""
} > "$RESULT_FILE"

# Test 1: Current XFS Mount Options
echo -e "${CYAN}[1/10] Current XFS Mount Options${NC}"
{
    echo "=== XFS Mount Options ==="
    findmnt -t xfs -n -o TARGET,OPTIONS | while read -r mount opts; do
        echo "Mount: $mount"
        echo "Options: $opts"
        echo ""
    done
} | tee -a "$RESULT_FILE"

# Test 2: XFS Filesystem Info
echo -e "${CYAN}[2/10] XFS Filesystem Information${NC}"
{
    echo "=== XFS Filesystem Info ==="
    for mount in /mnt/disk1 /mnt/disk2; do
        if mountpoint -q "$mount"; then
            echo "--- $mount ---"
            xfs_info "$mount" | head -10
            echo ""
        fi
    done
} | tee -a "$RESULT_FILE"

# Test 3: Sysctl Settings
echo -e "${CYAN}[3/10] XFS Sysctl Settings${NC}"
{
    echo "=== XFS Sysctl Settings ==="
    sysctl -a 2>/dev/null | grep xfs || echo "No XFS sysctl settings found"
    echo ""
} | tee -a "$RESULT_FILE"

# Test 4: Check for XFS Scrubbing Timer
echo -e "${CYAN}[4/10] XFS Scrubbing Status${NC}"
{
    echo "=== XFS Scrubbing Timer ==="
    if systemctl list-timers --all 2>/dev/null | grep -q xfs-scrub; then
        systemctl status xfs-scrub-all.timer --no-pager 2>/dev/null || echo "Timer exists but not active"
    else
        echo "XFS scrubbing timer not found (expected before rebuild)"
    fi
    echo ""
} | tee -a "$RESULT_FILE"

# Test 5: Sequential Write Performance
echo -e "${CYAN}[5/10] Sequential Write Performance (1GB file)${NC}"
mkdir -p "$TEST_DIR"
{
    echo "=== Sequential Write Test ==="
    echo "Writing 1GB file with dd..."
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    dd if=/dev/zero of="$TEST_DIR/write-test.dat" bs=1M count=1024 oflag=direct 2>&1 | grep -E "copied|MB/s|GB/s"
    sync
    echo ""
} | tee -a "$RESULT_FILE"

# Test 6: Sequential Read Performance
echo -e "${CYAN}[6/10] Sequential Read Performance (1GB file)${NC}"
{
    echo "=== Sequential Read Test ==="
    echo "Reading 1GB file with dd..."
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    dd if="$TEST_DIR/write-test.dat" of=/dev/null bs=1M iflag=direct 2>&1 | grep -E "copied|MB/s|GB/s"
    echo ""
} | tee -a "$RESULT_FILE"

# Test 7: Metadata Operations (File Creation)
echo -e "${CYAN}[7/10] Metadata Performance (Create 10000 files)${NC}"
{
    echo "=== Metadata Test: File Creation ==="
    TEST_SUBDIR="$TEST_DIR/metadata-test"
    mkdir -p "$TEST_SUBDIR"
    START=$(date +%s.%N)
    for i in {1..10000}; do
        touch "$TEST_SUBDIR/file_$i" 2>/dev/null
    done
    END=$(date +%s.%N)
    DURATION=$(echo "$END - $START" | bc)
    RATE=$(echo "10000 / $DURATION" | bc)
    echo "Created 10000 files in ${DURATION}s (${RATE} files/sec)"
    echo ""
} | tee -a "$RESULT_FILE"

# Test 8: Metadata Operations (Directory Listing)
echo -e "${CYAN}[8/10] Metadata Performance (List 10000 files)${NC}"
{
    echo "=== Metadata Test: Directory Listing ==="
    START=$(date +%s.%N)
    ls "$TEST_SUBDIR" > /dev/null
    END=$(date +%s.%N)
    DURATION=$(echo "$END - $START" | bc)
    echo "Listed 10000 files in ${DURATION}s"
    echo ""
} | tee -a "$RESULT_FILE"

# Test 9: Metadata Operations (File Deletion)
echo -e "${CYAN}[9/10] Metadata Performance (Delete 10000 files)${NC}"
{
    echo "=== Metadata Test: File Deletion ==="
    START=$(date +%s.%N)
    rm -rf "$TEST_SUBDIR"
    END=$(date +%s.%N)
    DURATION=$(echo "$END - $START" | bc)
    RATE=$(echo "10000 / $DURATION" | bc)
    echo "Deleted 10000 files in ${DURATION}s (${RATE} files/sec)"
    echo ""
} | tee -a "$RESULT_FILE"

# Test 10: Large File Allocation Pattern
echo -e "${CYAN}[10/10] Large File Allocation Test (5GB)${NC}"
{
    echo "=== Large File Allocation ==="
    echo "Creating sparse 5GB file..."
    START=$(date +%s.%N)
    truncate -s 5G "$TEST_DIR/large-file.dat"
    dd if=/dev/zero of="$TEST_DIR/large-file.dat" bs=1M count=5120 conv=notrunc oflag=direct 2>&1 | grep -E "copied|MB/s|GB/s"
    END=$(date +%s.%N)
    DURATION=$(echo "$END - $START" | bc)
    echo "Total time: ${DURATION}s"
    
    # Check fragmentation
    if command -v xfs_bmap &> /dev/null; then
        EXTENTS=$(xfs_bmap "$TEST_DIR/large-file.dat" | wc -l)
        echo "File extents: $EXTENTS (lower is better, 1 = perfectly contiguous)"
    fi
    echo ""
} | tee -a "$RESULT_FILE"

# Summary
echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Benchmark Complete!                                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Results saved to:${NC} $RESULT_FILE"
echo ""

# If both before and after exist, show comparison
BEFORE_FILE=$(ls -t "$RESULTS_DIR"/benchmark_before_*.txt 2>/dev/null | head -1)
AFTER_FILE=$(ls -t "$RESULTS_DIR"/benchmark_after_*.txt 2>/dev/null | head -1)

if [[ -f "$BEFORE_FILE" ]] && [[ -f "$AFTER_FILE" ]]; then
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Performance Comparison Available                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "Run this to compare results:"
    echo -e "${GREEN}  diff -y $BEFORE_FILE $AFTER_FILE | less${NC}"
    echo ""
    echo -e "Or extract specific metrics:"
    echo -e "${GREEN}  grep -E 'MB/s|files/sec|File extents' $BEFORE_FILE $AFTER_FILE${NC}"
fi

echo -e "\n${BLUE}Next steps:${NC}"
if [[ "$PHASE" == "before" ]]; then
    echo -e "  1. Run: ${GREEN}nh os switch${NC}"
    echo -e "  2. Run: ${GREEN}$0 after${NC}"
else
    echo -e "  1. Compare results with before benchmarks"
    echo -e "  2. Check XFS features: ${GREEN}./scripts/diagnostics/check-xfs-features.sh${NC}"
    echo -e "  3. Monitor scrubbing: ${GREEN}systemctl status xfs-scrub-all.timer${NC}"
fi
echo ""
