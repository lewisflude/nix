# Development Shells

This directory provides reproducible development environments for a variety of project types and workflows, using Nix flakes and Home Manager.

## 🚀 Quick Start

### 1. Interactive Shell Selection
```bash
nix develop ~/.config/nix#shell-selector
select_dev_shell
```

### 2. Direct Shell Usage
```bash
# Project-specific environments
nix develop ~/.config/nix#nextjs          # Next.js projects
nix develop ~/.config/nix#react-native    # Mobile development
nix develop ~/.config/nix#api-backend     # Backend APIs

# General purpose environments
nix develop ~/.config/nix#node            # Node.js/TypeScript
nix develop ~/.config/nix#python          # Python
nix develop ~/.config/nix#rust            # Rust
nix develop ~/.config/nix#go              # Go
nix develop ~/.config/nix#web             # Full-stack web
nix develop ~/.config/nix#devops          # DevOps/Infra
```

### 3. Project-based with direnv
1. Copy a template for your project:
   ```bash
   cp ~/.config/nix/shells/envrc-templates/node .envrc  # or nextjs, python, etc.
   direnv allow
   ```
2. The environment loads automatically when you `cd` into the project directory.

---

## 🧩 Available Environments

### Project-Specific Shells
| Shell           | Description             | Key Tools                                 |
|-----------------|-------------------------|-------------------------------------------|
| `nextjs`        | Next.js React projects  | Node.js 22, pnpm, TypeScript, Tailwind    |
| `react-native`  | Mobile app development  | React Native CLI, CocoaPods, Watchman     |
| `api-backend`   | Backend API services    | Node.js, Prisma, PostgreSQL, Redis        |

### General Purpose Shells
| Shell      | Description           | Key Tools                                 |
|------------|-----------------------|-------------------------------------------|
| `node`     | Node.js/TypeScript    | Node.js 22, pnpm, TypeScript, ESLint      |
| `python`   | Python development    | Python 3.12, Poetry, pytest, Black        |
| `rust`     | Rust development      | rustc, cargo, clippy, rust-analyzer       |
| `go`       | Go development        | Go, gopls, golangci-lint                  |
| `web`      | Full-stack web        | Node.js, Sass, Tailwind                   |
| `solana`   | Blockchain dev        | Solana CLI, Anchor, Rust                  |
| `devops`   | Infra/DevOps          | kubectl, terraform, docker, AWS CLI       |

### Utility Shells
| Shell            | Description                        | Features                  |
|------------------|------------------------------------|---------------------------|
| `shell-selector` | Interactive environment selection  | fzf-based, project wizard |

---

## ⚡ Features
- **Auto-dependencies:**
  - Node.js: Installs npm/pnpm/yarn deps
  - Python: Creates venv, installs requirements
  - Mobile: Installs iOS pods as needed
- **Environment variables:**
  - `NODE_ENV=development`, `RUST_BACKTRACE=1`, DB URLs, etc.
- **Aliases:**
  - `dev`, `build`, `test`, `lint`, and project-specific shortcuts

---

## 📁 Directory Structure

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
│   ├── api
│   ├── mobile
│   ├── nextjs
│   ├── node
│   ├── python
│   └── rust
└── README.md                # This file
```

---

## ➕ Adding New Environments

1. **Create a shell definition:**
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
2. **Add to `shells/default.nix`:**
   ```nix
   devShells = {
     my-project = import ./projects/my-project.nix { inherit pkgs; };
     # ... other shells
   };
   ```
3. **Create a .envrc template:**
   ```bash
   # shells/envrc-templates/my-project
   use flake ~/.config/nix#my-project
   export MY_VAR=value
   ```
4. **Update the shell selector:**
   Add your new environment to the `shells` array in `utils/shell-selector.nix`.

---

## ✅ Best Practices
1. Use direnv for automatic environment loading
2. Prefer project-specific environments when possible
3. Follow consistent naming patterns
4. Document changes and test new shells on all platforms

---

For more details, see the main [README.md](../README.md).
