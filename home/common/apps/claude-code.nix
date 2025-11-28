{ pkgs, inputs, ... }:
{
  # Claude Code CLI - agentic coding assistant
  # Uses claude-code-overlay for pre-built binaries from Anthropic
  # MCP servers configured in home/{nixos,darwin}/mcp.nix

  programs.claude-code = {
    enable = true;

    # Override package to use the pre-built binary from claude-code-overlay
    # Access directly from the flake input's packages
    package = inputs.claude-code-overlay.packages.${pkgs.system}.claude;

    # Custom commands for Claude Code
    # Usage: Type /command-name in claude-code prompt
    commands = {
      # Code review command
      review = ''
        # Code Review

        Perform a comprehensive code review of the selected code or files.

        ## What to analyze:
        1. **Bugs and Issues**: Identify potential bugs, logic errors, or edge cases
        2. **Best Practices**: Check adherence to language and framework conventions
        3. **Performance**: Look for performance bottlenecks or inefficiencies
        4. **Security**: Identify security vulnerabilities or concerns
        5. **Maintainability**: Assess code clarity, documentation, and structure
        6. **Testing**: Suggest areas that need better test coverage

        ## For Nix code specifically:
        - Check for 'with pkgs;' antipattern (should use explicit references)
        - Verify correct module placement (system vs home-manager)
        - Ensure constants are used instead of hardcoded values
        - Validate conventional commit message format

        Provide actionable feedback with specific suggestions for improvement.
      '';

      # Conventional commit message generator
      commit = ''
        # Generate Conventional Commit Message

        Generate a conventional commit message for the staged changes.

        ## Format:
        ```
        <type>(<scope>): <description>

        [optional body]

        [optional footer(s)]
        ```

        ## Types:
        - **feat**: New feature
        - **fix**: Bug fix
        - **refactor**: Code refactoring
        - **docs**: Documentation changes
        - **test**: Test additions or changes
        - **chore**: Build/tooling changes
        - **style**: Code style changes (formatting)
        - **perf**: Performance improvements

        ## Rules:
        1. Keep description concise (50 chars or less)
        2. Use imperative mood ("add" not "added" or "adds")
        3. Focus on the "why" not the "what"
        4. Reference issue numbers if applicable

        Run `git diff --staged` to see the changes, then generate an appropriate commit message.
      '';

      # Nix expression helper
      nix = ''
        # Nix Expression Helper

        Help with Nix expressions and configuration following this repository's conventions.

        ## Module Placement Guidelines:
        ### System-Level (modules/nixos/ or modules/darwin/):
        - System services (systemd, launchd)
        - Hardware configuration
        - Container runtimes
        - Graphics drivers

        ### Home-Manager (home/common/apps/):
        - User applications
        - Dotfiles
        - Development tools
        - Desktop applications

        ## Code Style Requirements:
        1. ❌ Never use 'with pkgs;' - use explicit references
        2. ✅ Use constants from lib/constants.nix
        3. ✅ Follow conventional commits
        4. ✅ Format with 'nix fmt' or 'treefmt'

        ## Available Tools:
        - `nix run .#new-module` - Create new modules
        - `nix run .#update-all` - Update dependencies
        - `nix fmt` - Format code

        Provide clear explanations and suggest improvements following these patterns.
      '';

      # Debug helper
      debug = ''
        # Debug Helper

        Help debug the issue step-by-step.

        ## Debugging Process:
        1. **Understand the Problem**: Clarify what's broken and expected behavior
        2. **Gather Information**: Review error messages, logs, and relevant code
        3. **Identify Root Cause**: Analyze potential causes based on evidence
        4. **Suggest Solutions**: Provide concrete fixes with explanations
        5. **Prevent Recurrence**: Suggest how to prevent similar issues

        ## For Nix Issues:
        - Run `nix flake check` to validate configuration
        - Check build logs: `nix log /nix/store/<path>`
        - Trace evaluation: `nix eval --show-trace`
        - Test builds: `nix build --dry-run`

        ## For System Issues:
        - Check systemd logs: `journalctl -xe`
        - Review home-manager logs
        - Use diagnostic scripts in `scripts/` directory

        Work through the problem methodically.
      '';

      # Refactor command
      refactor = ''
        # Refactoring Assistant

        Suggest refactoring improvements for the selected code.

        ## Focus Areas:
        1. **Code Clarity**: Improve readability and understandability
        2. **Maintainability**: Make code easier to modify and extend
        3. **Performance**: Optimize bottlenecks
        4. **Best Practices**: Apply language/framework patterns
        5. **Simplification**: Reduce complexity where possible

        ## Refactoring Guidelines:
        - Keep changes focused and atomic
        - Maintain backward compatibility when possible
        - Add tests for new behavior
        - Document breaking changes clearly

        ## For Nix Code:
        - Extract common patterns into functions
        - Use feature flags for optional functionality
        - Consolidate duplicated configuration
        - Improve module structure and organization

        Provide before/after examples with clear explanations.
      '';

      # Documentation generator
      doc = ''
        # Documentation Generator

        Generate comprehensive documentation for the selected code.

        ## Documentation Structure:
        1. **Overview**: What the code does at a high level
        2. **Purpose**: Why this code exists
        3. **Usage**: How to use it with examples
        4. **Parameters/Options**: Detailed parameter descriptions
        5. **Return Values**: What the code returns
        6. **Examples**: Real-world usage examples
        7. **Notes**: Important caveats, warnings, or tips

        ## For Nix Modules:
        Example module option documentation:
        - Use lib.mkOption with clear descriptions
        - Include type, default, and example values
        - Provide usage examples and important notes

        ## Documentation Best Practices:
        - Write for someone unfamiliar with the code
        - Include practical examples
        - Document edge cases and limitations
        - Keep it up-to-date with code changes

        Generate clear, comprehensive documentation.
      '';

      # Test generation
      test = ''
        # Test Case Generator

        Generate comprehensive test cases for the selected code.

        ## Test Categories:
        1. **Happy Path**: Normal, expected usage
        2. **Edge Cases**: Boundary conditions and limits
        3. **Error Handling**: Invalid inputs and error conditions
        4. **Integration**: Interactions with other components
        5. **Performance**: Speed and resource usage
        6. **Security**: Authentication, authorization, input validation

        ## For Nix Code:
        - Test module evaluation: `nix eval .#<output>`
        - Test builds: `nix build .#<package>`
        - Integration tests in `tests/` directory
        - Use NixOS VM tests for system config

        ## Test Structure:
        Tests should include:
        - Test name and clear description
        - Test script or implementation
        - Expected results for validation

        Generate a complete test suite with clear descriptions.
      '';

      # Explain code
      explain = ''
        # Code Explanation

        Explain the selected code in clear, simple terms.

        ## Explanation Structure:
        1. **High-Level Purpose**: What does this code accomplish?
        2. **How It Works**: Step-by-step breakdown of the logic
        3. **Key Concepts**: Important patterns or techniques used
        4. **Dependencies**: External libraries or modules used
        5. **Gotchas**: Tricky parts or potential pitfalls
        6. **Context**: Where this fits in the larger system

        ## Explanation Guidelines:
        - Use plain language (avoid unnecessary jargon)
        - Provide analogies when helpful
        - Break complex logic into digestible pieces
        - Highlight the "why" behind design decisions

        ## For Nix Code:
        - Explain the Nix language features used
        - Describe module system patterns
        - Clarify attribute set manipulations
        - Show evaluation order and lazy evaluation

        Provide a clear, comprehensive explanation.
      '';
    };

    # Hooks for Claude Code
    # These run automatically at specific lifecycle events
    hooks = {
      # Pre-tool-use hook: Block dangerous commands
      pre-tool-use = ''
        #!/usr/bin/env bash
        # Block dangerous commands before execution
        # This hook runs before Claude executes any tool

        set -euo pipefail

        # Read tool call from stdin (JSON format)
        tool_call=$(cat)

        # Extract command if it's a shell command
        if echo "$tool_call" | grep -q '"name":"run_shell_command"'; then
          command=$(echo "$tool_call" | ${pkgs.jq}/bin/jq -r '.parameters.command // empty')

          # List of dangerous commands to block
          dangerous_patterns=(
            "rm -rf"
            "sudo rm"
            "dd if="
            "mkfs"
            "nh os switch"
            "nh os boot"
            "sudo nixos-rebuild"
            "sudo darwin-rebuild"
            "> /dev/sd"
          )

          # Check if command matches any dangerous pattern
          for pattern in "''${dangerous_patterns[@]}"; do
            if echo "$command" | grep -q "$pattern"; then
              echo "BLOCKED: Dangerous command detected: $pattern" >&2
              echo "Please run system commands manually for safety." >&2
              exit 1
            fi
          done
        fi

        # Allow the command
        exit 0
      '';

      # Post-tool-use hook: Auto-format Nix files
      post-tool-use = ''
        #!/usr/bin/env bash
        # Auto-format Nix files after modification
        # This hook runs after Claude modifies any files

        set -euo pipefail

        # Read tool result from stdin
        tool_result=$(cat)

        # Check if any .nix files were modified
        if echo "$tool_result" | grep -q '\.nix'; then
          echo "[post-hook] Formatting modified Nix files..." >&2

          # Extract modified files and format them
          modified_files=$(echo "$tool_result" | ${pkgs.jq}/bin/jq -r '.files[]? // empty' 2>/dev/null || echo "")

          if [ -n "$modified_files" ]; then
            for file in $modified_files; do
              if [[ "$file" == *.nix ]]; then
                if [ -f "$file" ]; then
                  echo "[post-hook] Formatting $file" >&2
                  ${pkgs.nixfmt-rfc-style}/bin/nixfmt "$file" 2>/dev/null || true
                fi
              fi
            done
          fi
        fi

        exit 0
      '';
    };

    # JSON settings for Claude Code
    # See: https://docs.anthropic.com/claude-code/reference/settings
    settings = {
      # Editor configuration
      editor = {
        preferredEditor = "hx"; # Helix - terminal-native, fast
      };

      # File filtering
      fileFiltering = {
        respectGitIgnore = true; # Exclude git-ignored files
        enableRecursiveFileSearch = true; # Search subdirectories
      };

      # Auto-approve safe read-only operations
      autoApprove = {
        readOperations = true; # Auto-approve file reads, ls, grep
        writeOperations = false; # Always prompt for writes
      };

      # Session configuration
      session = {
        maxTurns = -1; # Unlimited turns (-1)
        saveHistory = true; # Save conversation history
      };

      # Tool restrictions for safety
      # Note: This is NOT a security mechanism - use hooks for enforcement
      dangerousCommands = {
        block = [
          "rm -rf"
          "sudo rm"
          "dd"
          "mkfs"
          "nh os switch"
          "sudo nixos-rebuild"
          "sudo darwin-rebuild"
        ];
      };

      # UI preferences
      ui = {
        theme = "default"; # UI theme
        showTips = true; # Show helpful tips
        showBanner = false; # Hide startup banner for cleaner output
      };

      # Formatting
      formatting = {
        autoFormat = true; # Auto-format files after editing
        formatCommand = "nix fmt"; # Use nix fmt for Nix files
      };

      # Memory/Context configuration
      # Claude Code automatically loads CLAUDE.md from the repository
      # You can create .claude/ directory for additional context
      context = {
        loadProjectContext = true; # Load CLAUDE.md automatically
        contextFiles = [
          "CLAUDE.md"
          "CONVENTIONS.md"
        ]; # Files to load as context
      };

      # Telemetry (optional)
      telemetry = {
        enabled = false; # Disable telemetry for privacy
      };
    };

    # Note: MCP servers are configured in home/{nixos,darwin}/mcp.nix
    # The following servers are available:
    # - memory: Knowledge graph-based persistent memory
    # - nixos: NixOS package and config search
    # - kagi: Search and summarization (requires KAGI_API_KEY)
    # - openai: Rust documentation support (requires OPENAI_API_KEY)
    # - docs-mcp-server: Documentation indexing
    # - rust-docs-bevy: Bevy crate documentation
    #
    # To configure MCP servers for claude-code, edit:
    # - home/nixos/mcp.nix (for NixOS)
    # - home/darwin/mcp.nix (for macOS)
  };
}
