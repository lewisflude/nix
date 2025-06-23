# Development Shells

This directory contains organized development environments for different project types and workflows.

## Quick Start

### Using Shell Selector
```bash
# Interactive shell selection
nix develop ~/.config/nix#shell-selector
select_dev_shell

# Quick project setup
nix develop ~/.config/nix#shell-selector  
setup_project
```

### Direct Shell Usage
```bash
# Project-specific environments
nix develop ~/.config/nix#nextjs          # Next.js projects
nix develop ~/.config/nix#react-native    # Mobile development
nix develop ~/.config/nix#api-backend     # Backend APIs

# General purpose environments  
nix develop ~/.config/nix#node            # Node.js/TypeScript
nix develop ~/.config/nix#python          # Python development
nix develop ~/.config/nix#rust            # Rust development
nix develop ~/.config/nix#go              # Go development
nix develop ~/.config/nix#web             # Full-stack web
nix develop ~/.config/nix#devops          # Infrastructure/DevOps
```

## Project Setup with .envrc

### 1. Copy Template
```bash
# For Next.js projects
cp ~/.config/nix/shells/envrc-templates/nextjs .envrc

# For React Native projects  
cp ~/.config/nix/shells/envrc-templates/mobile .envrc

# For API backends
cp ~/.config/nix/shells/envrc-templates/api .envrc
```

### 2. Enable direnv
```bash
direnv allow
```

### 3. Automatic Environment Loading
The environment will automatically load when you `cd` into the project directory.

## Available Environments

### Project-Specific Shells

| Shell | Description | Key Tools |
|-------|-------------|-----------|
| `nextjs` | Next.js React projects | Node.js 22, pnpm, TypeScript, Tailwind |
| `react-native` | Mobile app development | React Native CLI, CocoaPods, Watchman |
| `api-backend` | Backend API services | Node.js, Prisma, PostgreSQL, Redis |

### General Purpose Shells

| Shell | Description | Key Tools |
|-------|-------------|-----------|
| `node` | Node.js/TypeScript | Node.js 22, pnpm, TypeScript, ESLint |
| `python` | Python development | Python 3.12, Poetry, pytest, Black |
| `rust` | Rust development | rustc, cargo, clippy, rust-analyzer |
| `go` | Go development | Go, gopls, golangci-lint |
| `web` | Full-stack web | Node.js, Sass, Tailwind |
| `solana` | Blockchain development | Solana CLI, Anchor, Rust |
| `devops` | Infrastructure/DevOps | kubectl, terraform, docker, AWS CLI |

### Utility Shells

| Shell | Description | Features |
|-------|-------------|----------|
| `shell-selector` | Interactive environment selection | fzf-based selection, project wizard |

## Features

### Auto-Dependencies
- **Node.js projects**: Auto-installs npm/pnpm/yarn dependencies
- **Python projects**: Creates virtual environments, installs requirements
- **Mobile projects**: Auto-installs iOS pods when needed

### Environment Variables
Each environment sets appropriate development variables:
- `NODE_ENV=development`
- `RUST_BACKTRACE=1`
- Database URLs for API projects
- Platform-specific configurations

### Aliases
Convenient aliases for common commands:
- `dev` - Start development server
- `build` - Build project
- `test` - Run tests  
- `lint` - Run linter
- Project-specific shortcuts

## Directory Structure

```
shells/
├── default.nix              # Main shells configuration
├── projects/                # Project-specific shells
│   ├── nextjs.nix
│   ├── react-native.nix
│   └── api-backend.nix
├── utils/                   # Utility shells
│   └── shell-selector.nix
├── envrc-templates/         # .envrc templates for direnv
│   ├── nextjs
│   ├── mobile
│   ├── api
│   ├── node
│   ├── python
│   └── rust
└── README.md               # This file
```

## Adding New Environments

### 1. Create Shell Definition
```nix
# shells/projects/my-project.nix
{ pkgs, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # your tools here
  ];
  
  shellHook = ''
    echo "🚀 My Project environment loaded"
    # setup commands
  '';
}
```

### 2. Add to shells/default.nix  
```nix
devShells = {
  my-project = import ./projects/my-project.nix { inherit pkgs; };
  # ... other shells
};
```

### 3. Create .envrc Template
```bash
# shells/envrc-templates/my-project
use flake ~/.config/nix#my-project

# Project-specific setup
export MY_VAR=value
```

### 4. Update Shell Selector
Add your new environment to the `shells` array in `utils/shell-selector.nix`.

## Best Practices

1. **Use direnv**: Set up `.envrc` files for automatic environment loading
2. **Project-specific**: Choose the most specific environment for your project type  
3. **Consistent naming**: Follow the established naming patterns
4. **Document changes**: Update this README when adding new environments
5. **Test thoroughly**: Ensure new shells work across different systems