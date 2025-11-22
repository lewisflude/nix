{
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        showCommandLog = false;
        showFileTree = true;
      };
      update = {
        method = "background";
        days = 7;
      };

      # Custom commands for enhanced git workflow
      customCommands = [
        # Conventional commit with interactive prompts
        {
          key = "C";
          context = "files";
          description = "Conventional Commit (interactive)";
          prompts = [
            {
              type = "menu";
              key = "Type";
              title = "Commit Type";
              options = [
                { name = "feat"; description = "New feature"; value = "feat"; }
                { name = "fix"; description = "Bug fix"; value = "fix"; }
                { name = "docs"; description = "Documentation"; value = "docs"; }
                { name = "style"; description = "Code style/formatting"; value = "style"; }
                { name = "refactor"; description = "Code refactoring"; value = "refactor"; }
                { name = "perf"; description = "Performance improvement"; value = "perf"; }
                { name = "test"; description = "Add/update tests"; value = "test"; }
                { name = "chore"; description = "Maintenance"; value = "chore"; }
                { name = "ci"; description = "CI/CD changes"; value = "ci"; }
                { name = "build"; description = "Build system"; value = "build"; }
                { name = "revert"; description = "Revert change"; value = "revert"; }
              ];
            }
            {
              type = "input";
              key = "Scope";
              title = "Scope (optional, press enter to skip)";
              initialValue = "";
            }
            {
              type = "input";
              key = "Message";
              title = "Commit Message";
            }
            {
              type = "input";
              key = "Body";
              title = "Body (optional, press enter to skip)";
              initialValue = "";
            }
          ];
          command = ''
            SCOPE_PART=""
            if [ -n "{{.Form.Scope}}" ]; then
              SCOPE_PART="({{.Form.Scope}})"
            fi

            BODY_PART=""
            if [ -n "{{.Form.Body}}" ]; then
              BODY_PART=$'\n\n'"{{.Form.Body}}"
            fi

            git commit -m "{{.Form.Type}}$SCOPE_PART: {{.Form.Message}}$BODY_PART"
          '';
          loadingText = "Creating conventional commit...";
        }

        # Quick commit and push
        {
          key = "P";
          context = "files";
          description = "Commit all & Push";
          prompts = [
            {
              type = "input";
              key = "Message";
              title = "Commit Message";
            }
          ];
          command = "git add -A && git commit -m '{{.Form.Message}}' && git push";
          loadingText = "Committing and pushing...";
        }

        # Create PR via GitHub CLI
        {
          key = "p";
          context = "localBranches";
          description = "Create GitHub PR";
          command = "gh pr create --web";
          loadingText = "Opening PR creation...";
        }

        # View GitHub CI status
        {
          key = "c";
          context = "localBranches";
          description = "View CI Status";
          command = "gh run list --limit 5";
          subprocess = true;
        }

        # Sync with main/master
        {
          key = "s";
          context = "localBranches";
          description = "Sync with main";
          command = "git fetch origin && git merge origin/main";
          loadingText = "Syncing with main...";
        }

        # Clean merged branches
        {
          key = "D";
          context = "localBranches";
          description = "Delete merged branches";
          command = ''
            git branch --merged | grep -v "\\*\\|main\\|master" | xargs -r git branch -d
          '';
          loadingText = "Cleaning merged branches...";
        }
      ];
    };
  };
}
