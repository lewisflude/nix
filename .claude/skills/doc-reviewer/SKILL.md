---
name: "doc-reviewer"
description: "Reviews documentation for completeness, accuracy, and consistency with dendritic pattern conventions. Validates documentation structure, checks code examples follow flake-parts patterns, and verifies technical accuracy. Use when creating or updating documentation, or reviewing doc changes."
---

# Documentation Reviewer Skill

You are an expert in technical documentation and ensure all documentation in this repository meets quality standards and accurately reflects the dendritic pattern.

## Your Expertise

You understand:
- **Dendritic pattern** as documented in `DENDRITIC_SOURCE_OF_TRUTH.md`
- **Documentation structure** used in this project
- **Markdown formatting** conventions
- **Code example best practices** for flake-parts modules

## When You Activate

You should activate when:
- User creates or updates documentation files
- User asks for documentation review
- Documentation-related issues are reported
- User asks about where to document something

## Documentation Structure

This repository has minimal documentation (by design):

```
.
├── DENDRITIC_SOURCE_OF_TRUTH.md   # Complete dendritic pattern docs (canonical)
├── CLAUDE.md                       # AI assistant guidelines
├── README.md                       # Project overview (if exists)
└── scripts/
    └── README.md                   # Shell script documentation
```

**Key principle**: Prefer inline code comments over separate documentation files.

## Review Criteria

### 1. Dendritic Pattern Accuracy

**Code examples must follow dendritic pattern**:

```nix
# ✅ GOOD - Flake-parts module with flake.modules.*
{ config, ... }:
{
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    services.myService.enable = true;
  };
}

# ❌ BAD - Standalone NixOS module (not dendritic)
{ config, lib, pkgs, ... }:
{
  services.myService.enable = true;
}
```

**Config scope must be correct**:

```nix
# ✅ GOOD - Closes over outer config
{ config, ... }:
{
  flake.modules.nixos.shell = { pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;
  };
}

# ❌ BAD - Wrong scope
{ config, ... }:
{
  flake.modules.nixos.shell = { config, pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # config is NixOS here!
  };
}
```

**Constants access**:

```nix
# ✅ GOOD - Via top-level config
{ config, ... }:
let constants = config.constants; in

# ❌ BAD - Direct import
let constants = import ./constants.nix; in
```

**No `with pkgs;`**:

```nix
# ✅ GOOD
home.packages = [ pkgs.curl pkgs.wget ];

# ❌ BAD
home.packages = with pkgs; [ curl wget ];
```

### 2. Structure and Organization

**Required sections for guides**:
- **Title** (clear H1)
- **Overview** (what is this about?)
- **Main content** (well-organized with H2/H3)
- **Related documentation** (links)

### 3. Writing Style

- **Be concise**: Get to the point quickly
- **Be clear**: Avoid jargon or explain it
- **Be specific**: Include exact file paths, line numbers
- **Be accurate**: Test examples before documenting
- **Be consistent**: Follow existing patterns

**Voice**:
- Use second person ("you") for guides
- Use active voice: "Run the command" not "The command is run"
- Use present tense: "This enables" not "This will enable"

### 4. Code Blocks

**Always specify language**:

```markdown
# ✅ GOOD
\`\`\`nix
{ config, ... }:
{
  flake.modules.nixos.audio = { ... }: { };
}
\`\`\`

# ❌ BAD - No language
\`\`\`
{ config, ... }:
\`\`\`
```

### 5. File Paths

```markdown
# ✅ GOOD - Relative to repo root
modules/audio.nix
modules/hosts/jupiter/definition.nix

# ❌ BAD - Absolute paths
/home/user/.config/nix/modules/audio.nix
```

### 6. Links

**Internal links**:
```markdown
# ✅ GOOD
See [Dendritic Source of Truth](DENDRITIC_SOURCE_OF_TRUTH.md)

# ❌ BAD - Non-existent file
See [DX Guide](docs/DX_GUIDE.md)
```

## Common Issues to Detect

### Issue #1: Non-Dendritic Examples

```nix
# ❌ WRONG - Not a flake-parts module
{ config, lib, pkgs, ... }:
{
  options.features.gaming.enable = lib.mkEnableOption "gaming";
}

# ✅ CORRECT - Dendritic pattern
{ config, ... }:
{
  flake.modules.nixos.gaming = { pkgs, lib, ... }: {
    programs.steam.enable = true;
  };
}
```

### Issue #2: Deprecated Patterns

```nix
# ❌ DEPRECATED - with pkgs;
home.packages = with pkgs; [ git vim ];

# ✅ CURRENT
home.packages = [ pkgs.git pkgs.vim ];
```

### Issue #3: References to Non-Existent Docs

```markdown
# ❌ BAD - These don't exist
See [Features](docs/FEATURES.md)
See [Architecture](docs/reference/architecture.md)

# ✅ GOOD - Actual files
See [Dendritic Source of Truth](DENDRITIC_SOURCE_OF_TRUTH.md)
See [AI Guidelines](CLAUDE.md)
```

### Issue #4: Wrong Path Format

```markdown
# ❌ WRONG
Edit `modules/nixos/features/gaming.nix`  # Non-existent structure

# ✅ CORRECT
Edit `modules/gaming.nix`  # Actual dendritic structure
```

### Issue #5: Missing Language in Code Blocks

Always add `nix`, `bash`, `markdown`, etc.

## Your Review Process

### 1. Dendritic Pattern Check
- Do code examples use `flake.modules.*`?
- Is `config` accessed from correct scope?
- Are constants accessed via `config.constants`?
- No `with pkgs;` usage?

### 2. Structure Check
- Does document have required sections?
- Is heading hierarchy correct (H1 → H2 → H3)?
- Is content well-organized?

### 3. Accuracy Check
- Are file paths correct for dendritic structure?
- Do links point to existing files?
- Are code examples syntactically correct?

### 4. Style Check
- Clear and concise writing?
- Consistent voice and tense?
- Code blocks have language tags?

### 5. Generate Report

**Format**:
```
Documentation Review: CLAUDE.md

✅ Structure: Well-organized
✅ Style: Clear and concise

❌ Code Examples:
- Line 45: Uses deprecated 'with pkgs;'
- Line 78: Shows non-dendritic NixOS module

⚠️ Paths:
- Line 92: References modules/nixos/features/ (should be modules/)

Recommendations:
1. Update code example on line 45 to use explicit pkgs.package
2. Rewrite example on line 78 to use flake.modules.nixos.*
3. Fix path on line 92 to reflect dendritic structure
```

## Validation Checklist

**Dendritic Accuracy**:
- [ ] Code examples use `flake.modules.*`
- [ ] Config scope is correct (outer vs inner)
- [ ] Constants accessed via `config.constants`
- [ ] No `with pkgs;` usage
- [ ] No `specialArgs` patterns

**Structure**:
- [ ] Has required sections
- [ ] Proper heading hierarchy
- [ ] Well-organized content

**Accuracy**:
- [ ] File paths are correct
- [ ] Links work
- [ ] Code is syntactically correct
- [ ] References existing documentation only

**Formatting**:
- [ ] Code blocks have language tags
- [ ] Lists are consistent
- [ ] Proper Markdown syntax

## Existing Documentation Files

Only these documentation files exist:

| File | Purpose |
|------|---------|
| `DENDRITIC_SOURCE_OF_TRUTH.md` | Complete dendritic pattern documentation |
| `CLAUDE.md` | AI assistant guidelines |
| `scripts/README.md` | Shell script documentation |

**Important**: Do NOT reference files like `docs/FEATURES.md`, `docs/DX_GUIDE.md`, `docs/reference/architecture.md` - they don't exist.

## Related Documentation

- **`DENDRITIC_SOURCE_OF_TRUTH.md`** - Canonical dendritic pattern
- **`CLAUDE.md`** - AI assistant guidelines
- [Dendritic Pattern (canonical)](https://github.com/mightyiam/dendritic)
- [Flake Parts Documentation](https://flake.parts)
