{
  pkgs,
  pog,
  config-root,
}:
pog.pog {
  name = "new-module";
  version = "2.0.0";
  description = "Create a new Nix module from template";

  flags = [
    {
      name = "type";
      short = "t";
      description = "Module type";
      required = true;
      prompt = ''
        gum choose "feature" "service" "overlay" "test" --header "Select module type:"
      '';
      promptError = "Failed to get module type";
      completion = ''echo "feature service overlay test"'';
    }
    {
      name = "name";
      short = "n";
      description = "Module name (e.g., 'kubernetes', 'grafana')";
      required = true;
      prompt = ''
        gum input --placeholder "my-module" --header "Enter module name:"
      '';
      promptError = "Failed to get module name";
    }
    {
      name = "force";
      short = "f";
      bool = true;
      description = "Overwrite existing module";
    }
    {
      name = "dry_run";
      bool = true;
      description = "Show what would be created without creating";
    }
  ];

  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gum
  ];

  script =
    helpers: with helpers; ''
      REPO_ROOT="${config-root}"
      MODULE_TYPE="$type"
      MODULE_NAME="$name"


      NAME_UPPER=$(echo "$MODULE_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
      NAME_CAMEL=$(echo "$MODULE_NAME" | sed -r 's/(^|-)([a-z])/\U\2/g')
      NAME_SNAKE=$(echo "$MODULE_NAME" | tr '-' '_')

      debug "Module type: $MODULE_TYPE"
      debug "Module name: $MODULE_NAME"
      debug "Name formats: upper=$NAME_UPPER, camel=$NAME_CAMEL, snake=$NAME_SNAKE"


      case "$MODULE_TYPE" in
        feature)
          TEMPLATE="$REPO_ROOT/templates/feature-module.nix"
          OUTPUT_DIR="$REPO_ROOT/modules/nixos/features"
          OUTPUT_FILE="$OUTPUT_DIR/$MODULE_NAME.nix"
          ;;
        service)
          TEMPLATE="$REPO_ROOT/templates/service-module.nix"
          OUTPUT_DIR="$REPO_ROOT/modules/nixos/services"
          OUTPUT_FILE="$OUTPUT_DIR/$MODULE_NAME.nix"
          ;;
        overlay)
          TEMPLATE="$REPO_ROOT/templates/overlay-template.nix"
          OUTPUT_DIR="$REPO_ROOT/overlays"
          OUTPUT_FILE="$OUTPUT_DIR/$MODULE_NAME.nix"
          ;;
        test)
          TEMPLATE="$REPO_ROOT/templates/test-module.nix"
          OUTPUT_DIR="$REPO_ROOT/tests"
          OUTPUT_FILE="$OUTPUT_DIR/$MODULE_NAME.nix"
          ;;
        *)
          die "Invalid module type: $MODULE_TYPE"
          ;;
      esac

      debug "Template: $TEMPLATE"
      debug "Output: $OUTPUT_FILE"


      ${file.notExists "TEMPLATE"} && die "Template not found: $TEMPLATE"


      if ${file.exists "OUTPUT_FILE"}; then
        if ${flag "force"}; then
          yellow "⚠️  File exists, but --force flag provided"
        else
          die "File already exists: $OUTPUT_FILE (use --force to overwrite)"
        fi
      fi


      if ${flag "dry_run"}; then
        cyan "🔍 Dry run mode - would create:"
        echo "  Type:     $MODULE_TYPE"
        echo "  Name:     $MODULE_NAME"
        echo "  Output:   $OUTPUT_FILE"
        echo "  Template: $TEMPLATE"
        exit 0
      fi


      blue "🚀 Creating new $MODULE_TYPE module: $MODULE_NAME"


      mkdir -p "$OUTPUT_DIR"


      sed -e "s/FEATURE_NAME/$NAME_SNAKE/g" \
          -e "s/SERVICE_NAME/$NAME_SNAKE/g" \
          -e "s/SERVICE_PACKAGE/$MODULE_NAME/g" \
          -e "s/DESCRIPTION/Description for $MODULE_NAME/g" \
          "$TEMPLATE" > "$OUTPUT_FILE"

      green "✓ Created: $OUTPUT_FILE"


      echo ""
      cyan "📋 Next steps:"

      case "$MODULE_TYPE" in
        feature)
          echo "  1. Add feature options to modules/shared/host-options.nix"
          echo "  2. Implement the feature in $OUTPUT_FILE"
          echo "  3. Enable in a host: host.features.$NAME_SNAKE.enable = true"
          echo "  4. Test the configuration"
          echo ""
          yellow "💡 Add this to modules/shared/host-options.nix:"
          echo ""
          echo "    $NAME_SNAKE = {"
          echo "      enable = mkEnableOption \"$MODULE_NAME feature\";"
          echo "    };"
          ;;
        service)
          echo "  1. Customize the service in $OUTPUT_FILE"
          echo "  2. Add to host configuration: services.$NAME_SNAKE.enable = true"
          echo "  3. Test the service"
          ;;
        overlay)
          echo "  1. Implement package overrides in $OUTPUT_FILE"
          echo "  2. Import in overlays/default.nix"
          echo "  3. Rebuild to apply changes"
          ;;
        test)
          echo "  1. Implement tests in $OUTPUT_FILE"
          echo "  2. Run with: nix build .#checks.x86_64-linux.test-name"
          ;;
      esac

      echo ""
      blue "📖 Template reference: $TEMPLATE"
      green "🎉 Happy hacking!"
    '';
}
