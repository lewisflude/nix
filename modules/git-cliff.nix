# Git Cliff - Changelog generator
{ config, ... }:
{
  flake.modules.homeManager.git-cliff =
    { ... }:
    {
      programs.git-cliff = {
        enable = true;

        settings = {
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

          git = {
            conventional_commits = true;
            filter_unconventional = true;
            split_commits = false;
            commit_parsers = [
              {
                message = "^feat";
                group = "🚀 Features";
              }
              {
                message = "^fix";
                group = "🐛 Bug Fixes";
              }
              {
                message = "^doc";
                group = "📚 Documentation";
              }
              {
                message = "^perf";
                group = "⚡ Performance";
              }
              {
                message = "^refactor";
                group = "🚜 Refactor";
              }
              {
                message = "^style";
                group = "🎨 Styling";
              }
              {
                message = "^test";
                group = "🧪 Testing";
              }
              {
                message = "^chore\\(release\\): prepare for";
                skip = true;
              }
              {
                message = "^chore";
                group = "⚙️ Miscellaneous Tasks";
              }
              {
                body = ".*breaking.*";
                group = "⚠️ Breaking Changes";
              }
            ];
            tag_prefix = "v";
            sort_commits = "oldest";
          };

          bump = {
            features_always_bump_minor = true;
            breaking_always_bump_major = true;
          };
        };
      };

      home.shellAliases = {
        "gc-check" = "git-cliff --unreleased --dry-run";
        "gc-gen" = "git-cliff --output CHANGELOG.md";
        "gc-bump" = "git-cliff --bump --output CHANGELOG.md";
      };
    };
}
