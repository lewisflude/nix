#!/usr/bin/env bash
# Scan NixOS system for known CVE vulnerabilities using vulnix
# Usage: ./scan-vulnerabilities.sh [--critical] [--output file.txt]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
SHOW_CRITICAL_ONLY=false
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --critical)
      SHOW_CRITICAL_ONLY=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--critical] [--output file.txt]"
      echo "  --critical    Show only critical vulnerabilities (CVSS >= 9.0)"
      echo "  --output FILE Write results to file"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=== NixOS Vulnerability Scanner ===${NC}"
echo -e "${BLUE}Scanning system for known CVE vulnerabilities...${NC}\n"

# Check if vulnix is available, if not use nix-shell
if ! command -v vulnix &> /dev/null; then
  echo -e "${YELLOW}Note: Running vulnix via nix-shell (this may take a moment)...${NC}\n"
  VULNIX_CMD="nix-shell -p vulnix --run 'vulnix --system 2>&1'"
else
  VULNIX_CMD="vulnix --system 2>&1"
fi

# Run vulnix
if [[ -n "$OUTPUT_FILE" ]]; then
  eval "$VULNIX_CMD" | tee "$OUTPUT_FILE"
  SCAN_OUTPUT=$(cat "$OUTPUT_FILE")
else
  SCAN_OUTPUT=$(eval "$VULNIX_CMD")
  echo "$SCAN_OUTPUT"
fi

echo -e "\n${BLUE}=== Vulnerability Summary ===${NC}"

# Count vulnerabilities by severity
CRITICAL=$(echo "$SCAN_OUTPUT" | grep -oP 'CVSSv3\s+\K[0-9.]+' | awk '$1 >= 9.0' | wc -l || true)
HIGH=$(echo "$SCAN_OUTPUT" | grep -oP 'CVSSv3\s+\K[0-9.]+' | awk '$1 >= 7.0 && $1 < 9.0' | wc -l || true)
MEDIUM=$(echo "$SCAN_OUTPUT" | grep -oP 'CVSSv3\s+\K[0-9.]+' | awk '$1 >= 4.0 && $1 < 7.0' | wc -l || true)
LOW=$(echo "$SCAN_OUTPUT" | grep -oP 'CVSSv3\s+\K[0-9.]+' | awk '$1 < 4.0' | wc -l || true)
TOTAL=$(echo "$SCAN_OUTPUT" | grep -oP 'CVSSv3\s+\K[0-9.]+' | wc -l || true)

echo -e "${RED}Critical (>= 9.0):${NC} $CRITICAL"
echo -e "${YELLOW}High (7.0-8.9):${NC}    $HIGH"
echo -e "${GREEN}Medium (4.0-6.9):${NC}  $MEDIUM"
echo -e "${GREEN}Low (< 4.0):${NC}       $LOW"
echo -e "${BLUE}Total:${NC}             $TOTAL"

if [[ $SHOW_CRITICAL_ONLY == true ]]; then
  echo -e "\n${RED}=== Critical Vulnerabilities (CVSS >= 9.0) ===${NC}"
  echo "$SCAN_OUTPUT" | awk '
    BEGIN { in_package=0; package_name=""; cvss="" }
    /^[a-zA-Z]/ && !/^CVE/ && !/^https/ { 
      package_name=$0
      in_package=1
      next
    }
    /CVSSv3/ {
      cvss=$NF
      if (cvss >= 9.0 && package_name != "") {
        print "\n" package_name
      }
    }
    /https:.*CVE/ {
      if (cvss >= 9.0 && package_name != "") {
        print $0
      }
    }
  '
fi

# Recommendations
echo -e "\n${BLUE}=== Recommendations ===${NC}"
if [[ $CRITICAL -gt 0 ]]; then
  echo -e "${RED}⚠️  URGENT: $CRITICAL critical vulnerabilities found!${NC}"
  echo "   Run: nix flake update"
  echo "   Then: nh os switch"
fi

if [[ $HIGH -gt 0 ]]; then
  echo -e "${YELLOW}⚠️  $HIGH high-severity vulnerabilities found${NC}"
  echo "   Consider updating affected packages"
fi

echo -e "\n${BLUE}Next steps:${NC}"
echo "1. Update flake: nix flake update"
echo "2. Review changes: git diff flake.lock"
echo "3. Rebuild system: nh os switch"
echo "4. Re-scan to verify: ./scripts/validation/scan-vulnerabilities.sh"

# Exit with error if critical vulns found
if [[ $CRITICAL -gt 0 ]]; then
  exit 1
fi
