{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "visualize-modules";
  version = "1.0.0";
  description = "Generate dependency graph of all modules in the configuration";

  flags = [
    {
      name = "output_dir";
      short = "o";
      description = "Output directory for generated files";
      default = "docs/generated";
    }
    {
      name = "format";
      short = "f";
      description = "Output format (svg, png, dot, all)";
      default = "all";
      completion = ''echo "svg png dot all"'';
    }
  ];

  runtimeInputs = with pkgs; [
    coreutils
    graphviz
    findutils
  ];

  script =
    helpers: with helpers; ''
      REPO_ROOT="${config-root}"
      OUTPUT_DIR="$output_dir"
      FORMAT="$format"


      mkdir -p "$OUTPUT_DIR"

      GRAPH_FILE="$OUTPUT_DIR/module-dependencies.dot"
      SVG_FILE="$OUTPUT_DIR/module-dependencies.svg"
      PNG_FILE="$OUTPUT_DIR/module-dependencies.png"

      blue "Module Dependency Visualization Tool"
      echo "======================================"
      echo ""


      generate_dot() {
          cyan "Generating dependency graph..."

          cat > "$GRAPH_FILE" <<'EOF'
      digraph ModuleDependencies {
          // Graph settings
          rankdir=LR;
          node [shape=box, style=rounded, fontname="Arial"];
          edge [fontname="Arial", fontsize=10];

          // Styling
          graph [bgcolor="
          node [fillcolor="
          edge [color="

          // Subgraphs for organization
          subgraph cluster_shared {
              label="Shared Modules";
              style=filled;
              color="
              fillcolor="
      EOF


          find "$REPO_ROOT/modules/shared" -name "default.nix" 2>/dev/null | while read -r file; do
              local module_name=$(basename "$(dirname "$file")")
              if [[ "$module_name" == "shared" ]]; then
                  module_name="shared_root"
              fi
              echo "          \"shared_$module_name\" [label=\"$module_name\"];" >> "$GRAPH_FILE"
          done

          echo "      }" >> "$GRAPH_FILE"


          cat >> "$GRAPH_FILE" <<'EOF'

          subgraph cluster_darwin {
              label="Darwin Modules";
              style=filled;
              color="
              fillcolor="
      EOF

          find "$REPO_ROOT/modules/darwin" -name "default.nix" 2>/dev/null | while read -r file; do
              local module_name=$(basename "$(dirname "$file")")
              if [[ "$module_name" == "darwin" ]]; then
                  module_name="darwin_root"
              fi
              echo "          \"darwin_$module_name\" [label=\"$module_name\"];" >> "$GRAPH_FILE"
          done

          echo "      }" >> "$GRAPH_FILE"


          cat >> "$GRAPH_FILE" <<'EOF'

          subgraph cluster_nixos {
              label="NixOS Modules";
              style=filled;
              color="
              fillcolor="
      EOF

          find "$REPO_ROOT/modules/nixos" -name "default.nix" 2>/dev/null | while read -r file; do
              local module_name=$(basename "$(dirname "$file")")
              if [[ "$module_name" == "nixos" ]]; then
                  module_name="nixos_root"
              fi
              echo "          \"nixos_$module_name\" [label=\"$module_name\"];" >> "$GRAPH_FILE"
          done

          echo "      }" >> "$GRAPH_FILE"


          echo "}" >> "$GRAPH_FILE"

          green "✓ DOT file created: $GRAPH_FILE"
      }


      render_graph() {
          if command -v dot &> /dev/null; then
              case "$FORMAT" in
                  svg|all)
                      cyan "Rendering graph to SVG..."
                      dot -Tsvg "$GRAPH_FILE" -o "$SVG_FILE"
                      green "✓ SVG created: $SVG_FILE"
                      ;;
              esac

              case "$FORMAT" in
                  png|all)
                      cyan "Rendering graph to PNG..."
                      dot -Tpng "$GRAPH_FILE" -o "$PNG_FILE"
                      green "✓ PNG created: $PNG_FILE"
                      ;;
              esac
          else
              yellow "⚠ Graphviz not installed. Install with:"
              echo "  nix-shell -p graphviz"
              echo "  Or: brew install graphviz (on macOS)"
              echo ""
              echo "DOT file created: $GRAPH_FILE"
              echo "You can render it online at: https://dreampuf.github.io/GraphvizOnline/"
          fi
      }


      generate_summary() {
          cyan "Generating module summary..."

          local summary_file="$OUTPUT_DIR/module-summary.txt"

          cat > "$summary_file" <<EOF
      Module Dependency Summary
      Generated: $(date)
      ================================================================================

      EOF

          echo "Shared Modules:" >> "$summary_file"
          find "$REPO_ROOT/modules/shared" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "$summary_file"
          find "$REPO_ROOT/modules/shared" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "$summary_file"
          echo "" >> "$summary_file"

          echo "Darwin Modules:" >> "$summary_file"
          find "$REPO_ROOT/modules/darwin" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "$summary_file"
          find "$REPO_ROOT/modules/darwin" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "$summary_file"
          echo "" >> "$summary_file"

          echo "NixOS Modules:" >> "$summary_file"
          find "$REPO_ROOT/modules/nixos" -name "*.nix" -not -name "default.nix" | wc -l | xargs echo "  Files:" >> "$summary_file"
          find "$REPO_ROOT/modules/nixos" -type d -name "*" | wc -l | xargs echo "  Directories:" >> "$summary_file"
          echo "" >> "$summary_file"

          green "✓ Summary created: $summary_file"
          cat "$summary_file"
      }


      cyan "Starting module analysis..."
      echo ""

      generate_dot
      generate_summary
      render_graph

      echo ""
      green "✓ Module visualization complete!"
      echo ""
      echo "Output files:"
      echo "  - $GRAPH_FILE"
      [[ "$FORMAT" == "svg" || "$FORMAT" == "all" ]] && [[ -f "$SVG_FILE" ]] && echo "  - $SVG_FILE"
      [[ "$FORMAT" == "png" || "$FORMAT" == "all" ]] && [[ -f "$PNG_FILE" ]] && echo "  - $PNG_FILE"
      echo "  - $OUTPUT_DIR/module-summary.txt"
    '';
}
