{ pkgs, ... }: {
  programs.git-cliff = {
    enable = true;
    
    settings = {
      # 1. General Changelog Formatting
      changelog = {
        header = "# Changelog\n\nAll notable changes to this project will be documented in this file.\n";
        body = ''
          {% if version %}
              ## [{{ version | trim_start_matches(pat="v") }}] - {{ timestamp | date(format="%Y-%m-%d") }}
          {% else %}
              ## [unreleased]
          {% endif %}
          {% for group, commits in commits | group_by(attribute="group") %}
              ### {{ group | upper_first }}
              {% for commit in commits %}
                  - {% if commit.scope %}*({{ commit.scope }})* {% endif %}{{ commit.message | upper_first }} ([{{ commit.id | truncate(length=7, end="") }}](https://github.com/{{ remote.github.owner }}/{{ remote.github.repo }}/commit/{{ commit.id }}))
              {% endfor %}
          {% endfor %}
        '';
        footer = "\n";
        trim = true;
      };

      # 2. Parsing Conventional Commits
      git = {
        conventional_commits = true;
        filter_unconventional = true;
        split_commits = false;
        commit_parsers = [
          { message = "^feat"; group = "🚀 Features"; }
          { message = "^fix"; group = "🐛 Bug Fixes"; }
          { message = "^doc"; group = "📚 Documentation"; }
          { message = "^perf"; group = "⚡ Performance"; }
          { message = "^refactor"; group = "🚜 Refactor"; }
          { message = "^style"; group = "🎨 Styling"; }
          { message = "^test"; group = "🧪 Testing"; }
          { message = "^chore\\(release\\): prepare for"; skip = true; }
          { message = "^chore"; group = "⚙️ Miscellaneous Tasks"; }
          { body = ".*breaking.*"; group = "⚠️ Breaking Changes"; }
        ];
        # Prefix for your git tags (e.g., v1.0.0)
        tag_prefix = "v";
        sort_commits = "oldest";
      };

      # 3. SemVer Bumping Logic
      bump = {
        features_always_bump_minor = true;
        breaking_always_bump_major = true;
      };
    };
  };

  # Useful aliases to make changelog generation a one-liner
  home.shellAliases = {
    "gc-check" = "git-cliff --unreleased --dry-run"; # Preview the next release
    "gc-gen"   = "git-cliff --output CHANGELOG.md";  # Update the file
    "gc-bump"  = "git-cliff --bump --output CHANGELOG.md"; # Bump version + update file
  };
}