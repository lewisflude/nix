#!/usr/bin/env bash
# Module Dependency Visualization Tool
# Generates a dependency graph of all modules in the configuration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/docs/generated"
GRAPH_FILE="${OUTPUT_DIR}/module-dependencies.dot"
SVG_FILE="${OUTPUT_DIR}/module-dependencies.svg"
PNG_FILE="${OUTPUT_DIR}/module-dependencies.png"

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

echo -e "${BLUE}Module Dependency Visualization Tool${NC}"
echo "======================================"
echo ""

# Function to find all default.nix files
find_modules() {
    echo -e "${GREEN}Finding all modules...${NC}"
    find "${REPO_ROOT}" \
        -name "default.nix" \
        -not -path "*/.*" \
        -not -path "*/result/*" \
        -not -path "*/node_modules/*" \
        | sort
}

# Function to extract imports from a file
extract_imports() {
    local file="$1"
    grep -oP '(?<=imports = \[)[^\]]*' "$file" 2>/dev/null || true
}

# Function to generate DOT graph
generate_dot() {
    echo -e "${GREEN}Generating dependency graph...${NC}"

    cat > "${GRAPH_FILE}" <<'EOF'
digraph ModuleDependencies {
    // Graph settings
    rankdir=LR;
    node [shape=box, style=rounded, fontname="Arial"];
    edge [fontname="Arial", fontsize=10];

    // Styling
    graph [bgcolor="#f8f9fa", pad="0.5", ranksep="1.0", nodesep="0.5"];
    node [fillcolor="#e3f2fd", style="rounded,filled", color="#1976d2"];
    edge [color="#757575"];

    // Subgraphs for organization
    subgraph cluster_shared {
        label="Shared Modules";
        style=filled;
        color="#c5e1a5";
        fillcolor="#f1f8e9";
EOF

    # Add shared modules
    find "${REPO_ROOT}/modules/shared" -name "default.nix" 2>/dev/null | while read -r file; do
        local module_name=$(basename "$(dirname "$file")")
        if [[ "$module_name" == "shared" ]]; then
            module_name="shared_root"
        fi
        echo "        \"shared_${module_name}\" [label=\"${module_name}\"];" >> "${GRAPH_FILE}"
    done

    echo "    }" >> "${GRAPH_FILE}"

    # Add darwin modules
    cat >> "${GRAPH_FILE}" <<'EOF'

    subgraph cluster_darwin {
        label="Darwin Modules";
        style=filled;
        color="#b39ddb";
        fillcolor="#ede7f6";
EOF

    find "${REPO_ROOT}/modules/darwin" -name "default.nix" 2>/dev/null | while read -r file; do
        local module_name=$(basename "$(dirname "$file")")
        if [[ "$module_name" == "darwin" ]]; then
            module_name="darwin_root"
        fi
        echo "        \"darwin_${module_name}\" [label=\"${module_name}\"];" >> "${GRAPH_FILE}"
    done

    echo "    }" >> "${GRAPH_FILE}"

    # Add nixos modules
    cat >> "${GRAPH_FILE}" <<'EOF'

    subgraph cluster_nixos {
        label="NixOS Modules";
        style=filled;
        color="#90caf9";
        fillcolor="#e3f2fd";
EOF

    find "${REPO_ROOT}/modules/nixos" -name "default.nix" 2>/dev/null | while read -r file; do
        local module_name=$(basename "$(dirname "$file")")
        if [[ "$module_name" == "nixos" ]]; then
            module_name="nixos_root"
        fi
        echo "        \"nixos_${module_name}\" [label=\"${module_name}\"];" >> "${GRAPH_FILE}"
    done

    echo "    }" >> "${GRAPH_FILE}"

    # Close graph
    echo "}" >> "${GRAPH_FILE}"
}

# Function to render graph
render_graph() {
    if command -v dot &> /dev/null; then
        echo -e "${GREEN}Rendering graph to SVG...${NC}"
        dot -Tsvg "${GRAPH_FILE}" -o "${SVG_FILE}"
        echo -e "${GREEN}✓ SVG created: ${SVG_FILE}${NC}"

        echo -e "${GREEN}Rendering graph to PNG...${NC}"
        dot -Tpng "${GRAPH_FILE}" -o "${PNG_FILE}"
        echo -e "${GREEN}✓ PNG created: ${PNG_FILE}${NC}"
    else
        echo -e "${YELLOW}⚠ Graphviz not installed. Install with:${NC}"
        echo "  nix-shell -p graphviz"
        echo "  Or: brew install graphviz (on macOS)"
        echo ""
        echo -e "${GREEN}✓ DOT file created: ${GRAPH_FILE}${NC}"
        echo "  You can render it online at: https://dreampuf.github.io/GraphvizOnline/"
    fi
}

# Function to generate text summary
generate_summary() {
    echo -e "${GREEN}Generating module summary...${NC}"

    local summary_file="${OUTPUT_DIR}/module-summary.txt"

    cat > "${summary_file}" <<EOF
Module Dependency Summary
Generated: $(date)
================================================================================

EOF

    echo "Shared Modules:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/shared" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/shared" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "${summary_file}"
    echo "" >> "${summary_file}"

    echo "Darwin Modules:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/darwin" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/darwin" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "${summary_file}"
    echo "" >> "${summary_file}"

    echo "NixOS Modules:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/nixos" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "${summary_file}"
    find "${REPO_ROOT}/modules/nixos" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "${summary_file}"
    echo "" >> "${summary_file}"

    echo -e "${GREEN}✓ Summary created: ${summary_file}${NC}"
    cat "${summary_file}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting module analysis...${NC}"
    echo ""

    generate_dot
    generate_summary
    render_graph

    echo ""
    echo -e "${GREEN}✓ Module visualization complete!${NC}"
    echo ""
    echo "Output files:"
    echo "  - ${GRAPH_FILE}"
    [[ -f "${SVG_FILE}" ]] && echo "  - ${SVG_FILE}"
    [[ -f "${PNG_FILE}" ]] && echo "  - ${PNG_FILE}"
    echo "  - ${OUTPUT_DIR}/module-summary.txt"
}

main "$@"
