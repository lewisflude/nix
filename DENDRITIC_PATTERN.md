# The Dendritic Pattern

A conformance reference for the Dendritic Nix configuration pattern.

---

## Definition

The Dendritic Pattern is an aspect-oriented architecture for Nix configuration codebases. It uses a single top-level module evaluation into which every Nix file is imported as a module of the same class. Each file represents a feature — not a host, user, or configuration class — and declares that feature's configuration across all applicable lower-level configuration classes (NixOS, home-manager, nix-darwin, etc.) in one place. Lower-level configurations are composed from within the top-level configuration, and values are shared through it.

The pattern is independent of any specific library or framework. It is commonly implemented with [flake-parts](https://flake.parts), but this is not required.

---

## Terminology

The following terms have precise meanings throughout this document.

| Term | Definition |
|---|---|
| **Top-level configuration** | The outermost module system evaluation. Every Nix file in the project is a module of this evaluation. When using flake-parts, this is the flake-parts configuration. |
| **Top-level module** | A module imported into the top-level configuration. In a conforming project, every Nix file (except the entry point) is one of these. |
| **Lower-level configuration** | A configuration evaluation nested within the top-level, such as a NixOS, home-manager, or nix-darwin evaluation. |
| **Configuration class** | A distinct kind of module evaluation: `nixos`, `homeManager`, `darwin`, `nixOnDroid`, `nixvim`, etc. Each has its own option namespace and semantics. |
| **Feature** (or **aspect**) | A cross-cutting concern that a user cares about — e.g., "ssh", "gaming", "shell", "admin privileges." A feature may span multiple configuration classes. |
| **Feature closure** | The property that everything needed for a feature to work is co-located in the same file or directory subtree named after that feature. |
| **Entry point** | The single file that bootstraps the top-level evaluation (typically `flake.nix`). This is the only file exempt from the uniform module class invariant. |

---

## Invariants

A project conforms to the Dendritic Pattern if and only if all of the following invariants hold. The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are used as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

### 1. Uniform module class

Every Nix file, except the entry point, MUST be a module of the top-level configuration and MUST belong to the same module class.

There MUST be exactly one interpretation of what any given Nix file is. A reader should never need to ask "is this a NixOS module, a home-manager module, a package, or something else?" The answer is always: it is a top-level module.

**Rationale:** This eliminates an entire category of structural ambiguity. When every file has the same type, tooling can auto-import them, authors can navigate by feature name alone, and no file requires external context to understand its role.

### 2. Feature-centric decomposition

Files and directories MUST be named after the feature they implement, not after the host, user, or configuration class they apply to.

The organizational axis of the codebase MUST be *what* is being configured (the feature), not *where* it is applied (the host) or *how* it is classified (the configuration class).

**Rationale:** This is the "matrix flip" described by Pol Dellaiera. Host-centric organization duplicates feature logic across hosts; class-centric organization scatters a single feature across disconnected files. Feature-centric organization makes each feature a self-contained unit.

### 3. Cross-class co-location

All configuration for a given feature, across all applicable configuration classes, MUST reside in the same file or the same directory subtree.

A single feature MUST NOT be split across files that are organized by configuration class (e.g., a `nixos/ssh.nix` and a separate `home-manager/ssh.nix`).

**Rationale:** This is the feature closure property. When a feature breaks or needs modification, there is exactly one place to look. The file or directory *is* the feature.

### 4. Automatic importing

All top-level modules MUST be imported into the top-level configuration without explicit, manually-maintained import paths between modules.

No module SHOULD contain an `imports` list that references sibling modules by relative path. A module MAY import external modules (e.g., from flake inputs) but MUST NOT encode the project's internal file tree in import paths.

**Rationale:** Manual imports create coupling between a file's identity and its path. They must be maintained when files are renamed, moved, or split. Automatic importing makes the file tree a flat namespace of features from the module system's perspective.

### 5. Top-level value sharing

Inter-module communication MUST use one of:

- `let`-bindings scoped within a single file (for values local to that feature)
- Options declared in the top-level configuration (for values shared across features)

Values MUST NOT be passed into lower-level evaluations via `specialArgs`, `extraSpecialArgs`, or equivalent mechanisms for the purpose of making top-level values available in lower-level modules.

**Rationale:** `specialArgs` is the duct tape of non-dendritic configurations — it exists because lower-level modules cannot otherwise reach values defined elsewhere. In the Dendritic Pattern, every file is a top-level module with access to the full top-level `config`, making `specialArgs` pass-through unnecessary.

### 6. Top-level orchestration

Lower-level configurations MUST be declared and composed from within the top-level configuration.

Features contribute lower-level modules as values in the top-level config (typically using the `deferredModule` type or equivalent). Host definitions then select which feature modules to include. The top-level configuration is the single place where lower-level evaluations are assembled and triggered.

**Rationale:** If lower-level configurations are assembled outside the top-level (e.g., directly in `flake.nix` with ad-hoc imports), features lose the ability to contribute across classes from a single location, and the uniformity of invariant 1 breaks down.

### 7. Minimal entry point

The entry point (typically `flake.nix`) MUST be limited to:

- Declaring inputs (dependencies)
- Bootstrapping the top-level evaluation
- Importing all top-level modules (via a single expression or auto-import call)

The entry point MUST NOT contain feature logic, host definitions, module declarations, or configuration values.

**Rationale:** A minimal entry point is the natural consequence of pushing all logic into top-level modules. It also means the entry point rarely needs to change — new features are added by creating files, not by editing a central manifest.

---

## Derived Properties

The following properties are not independent rules. They emerge automatically when the invariants hold. They are listed here because they are frequently cited as benefits, and because their absence can signal an invariant violation.

### File path independence

Since all files are the same type (invariant 1) and auto-imported (invariant 4), a file's path is meaningful only to the author as a feature name. Files can be freely renamed, moved, and split without updating import lists or breaking references.

**If you find that moving a file requires changing code in other files, an invariant is likely violated.**

### Self-documenting paths

Since files are named after features (invariant 2) and contain everything about that feature (invariant 3), a file path is sufficient to know what a file does. Navigating the codebase by feature name becomes the primary discovery mechanism.

**If you find yourself asking "what kind of module is this file?", invariant 1 is violated.**

### Incremental features

Since all files are auto-imported (invariant 4) and multiple modules can contribute to the same aspect via merge semantics, adding capability to an existing feature is as simple as creating a new file that contributes to the same top-level option path. Disabling a feature can be done by removing the file or prefixing its path to exclude it from auto-import (e.g., the `/_` convention with import-tree).

**If adding a feature requires editing files other than the new feature file, an invariant is likely violated.**

### No import path maintenance

Since auto-import is required (invariant 4) and specialArgs is prohibited as a communication channel (invariant 5), there are no `imports = [ ../../../foo.nix ]` chains to maintain and no `specialArgs` pass-through boilerplate to keep consistent.

### Composability across class boundaries

Since features co-locate all their class-specific configuration (invariant 3) and share values through the top-level (invariant 5), a feature like "ssh" can define NixOS firewall rules, darwin system preferences, and home-manager user config in one place, sharing values like port numbers via `let`-bindings without any inter-file coordination.

---

## Anti-Patterns

Each anti-pattern below violates one or more invariants. The violated invariants are noted.

### Class-centric file tree

```
modules/
  nixos/
    ssh.nix
    gaming.nix
  home-manager/
    ssh.nix
    gaming.nix
```

**Violates:** Invariant 2 (feature-centric decomposition), Invariant 3 (cross-class co-location).

SSH configuration is scattered across two directories organized by class. Changing the SSH port requires editing two files in two locations. The correct structure names files by feature and co-locates all classes within each:

```
modules/
  ssh.nix        # contains nixos, home-manager, darwin config for ssh
  gaming.nix     # contains nixos, home-manager config for gaming
```

### Host-centric file tree

```
modules/
  laptop.nix     # all config for the laptop
  desktop.nix    # all config for the desktop
  server.nix     # all config for the server
```

**Violates:** Invariant 2 (feature-centric decomposition).

Features shared between hosts (e.g., shell config, SSH) will be duplicated or extracted into a tangled web of shared imports. Host files SHOULD exist only to declare *which* features a host includes, not to *implement* features.

### `specialArgs` pass-through

```nix
# flake.nix or host definition
lib.nixosSystem {
  specialArgs = { inherit inputs self; };
  modules = [ ... ];
}
```

...used so that a NixOS module can access `inputs` or `self`:

```nix
# some nixos module
{ inputs, ... }: {
  environment.systemPackages = [ inputs.some-flake.packages.x86_64-linux.default ];
}
```

**Violates:** Invariant 5 (top-level value sharing).

In a dendritic setup, this module would be a top-level module with direct access to `inputs` via the top-level module arguments, and it would contribute a lower-level NixOS module via `flake.modules.nixos.*` or equivalent.

### Manual import chains

```nix
# modules/desktop.nix
{
  imports = [
    ./hardware/nvidia.nix
    ../features/ssh.nix
    ../features/gaming.nix
  ];
}
```

**Violates:** Invariant 4 (automatic importing).

Modules reference each other by relative path, creating coupling between file identity and file location. Renaming or moving any referenced file requires updating every module that imports it.

### Logic-heavy entry point

```nix
# flake.nix
{
  outputs = inputs: {
    nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hardware/laptop.nix
        ./nixos/base.nix
        ./nixos/desktop.nix
        inputs.home-manager.nixosModules.home-manager
        { home-manager.users.alice = import ./home/alice.nix; }
      ];
    };
    # ...more configurations assembled here
  };
}
```

**Violates:** Invariant 7 (minimal entry point), Invariant 6 (top-level orchestration), Invariant 5 (specialArgs), Invariant 4 (automatic importing).

This is the canonical non-dendritic flake. The entry point contains host definitions, manual imports, specialArgs, and configuration assembly. In a dendritic setup, `flake.nix` would be roughly five lines: inputs, and a single `mkFlake` call with an auto-import.

### Mixed file semantics

A project where some `.nix` files are NixOS modules, others are home-manager modules, others are package definitions, and others are plain attribute sets.

**Violates:** Invariant 1 (uniform module class).

Every file having a different type means the reader must determine each file's role from context, and auto-importing becomes impossible because different files must be routed to different evaluations.

---

## Common Misconceptions

**"Dendritic is just flake-parts."**
No. Flake-parts is the most common implementation vehicle, but the pattern predates its exclusive association with flake-parts and can be implemented with `lib.evalModules` directly or with alternative top-level module systems. The invariants make no reference to flake-parts.

**"Dendritic is boilerplate reduction."**
Boilerplate reduction is a side effect, not the point. The pattern is a structural commitment to feature-centric, aspect-oriented organization with a uniform module class. Some configurations may involve *more* initial ceremony (e.g., defining top-level options for value sharing) in exchange for better long-term properties.

**"Dendritic means I lose access to the NixOS/home-manager module system."**
No. Lower-level configurations are still full NixOS/home-manager evaluations with their own module systems. The Dendritic Pattern governs how these evaluations are *organized and composed* from above, not how they work internally.

**"It's only useful for multi-host setups."**
The benefits are most pronounced with multiple hosts, users, and configuration classes. But the structural clarity of uniform file types and feature-centric naming has value even for single-host configurations, and adopting the pattern early avoids a costly refactor later.

**"It's not declarative because the same code works on multiple systems."**
A feature file that contributes NixOS *and* darwin modules is not dynamic — it is contributing two separate, fully declarative module values. The per-host configuration selects which modules to include. Evaluation remains deterministic and declarative.

---

## Implementation Notes

This section is non-normative. It describes common tooling choices in the Dendritic community.

### Top-level evaluation: flake-parts

[flake-parts](https://flake.parts) provides a module system for flake outputs. Its [`flake.modules`](https://flake.parts/options/flake-parts-modules.html) option (via `flakeModules.modules`) provides typed storage for lower-level modules using `deferredModule`, with merge semantics that allow multiple feature files to contribute to the same aspect.

A typical entry point:

```nix
# flake.nix
{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:nixos/nixpkgs/25.11";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
}
```

### Auto-importing: import-tree

[import-tree](https://github.com/vic/import-tree) recursively imports all `.nix` files under a directory as modules. Files with `/_` in their path are ignored, providing a convention for disabling modules.

### Lower-level module storage: `deferredModule`

The `deferredModule` type from Nixpkgs allows module values to be stored as options and merged when multiple files contribute to the same aspect. This is the mechanical foundation that makes cross-class co-location work — a feature file sets `flake.modules.nixos.ssh = { ... }` and `flake.modules.homeManager.ssh = { ... }`, and these are later included in the appropriate lower-level evaluations.

### Input management: flake-file

[flake-file](https://github.com/vic/flake-file) allows each module to declare the flake inputs it needs, keeping dependency declarations co-located with the features that use them.

---

## Conformance Checklist

Use this for quick evaluation. Each item maps to an invariant. All items must hold for full conformance.

- [ ] **Every `.nix` file (except the entry point) is a top-level module of the same class.** No NixOS modules, home-manager modules, package expressions, or plain attribute sets exist as standalone files. *(Invariant 1)*

- [ ] **Files and directories are named after features, not hosts, users, or configuration classes.** The top level of the modules directory reads like a feature list, not a host inventory or class taxonomy. *(Invariant 2)*

- [ ] **Each feature's configuration across all applicable classes is co-located.** There is no `nixos/` vs `home-manager/` split for the same feature. *(Invariant 3)*

- [ ] **No module contains import paths to sibling modules.** All top-level modules are auto-imported. Internal file paths do not appear in `imports` lists. *(Invariant 4)*

- [ ] **`specialArgs` and `extraSpecialArgs` are not used for value sharing between the top-level and lower-level configurations.** Inter-module values flow through top-level config options or file-scoped `let`-bindings. *(Invariant 5)*

- [ ] **Lower-level configurations are declared and assembled within the top-level configuration.** Host/user definitions compose feature modules from the top-level config namespace. *(Invariant 6)*

- [ ] **The entry point contains only inputs, the top-level evaluation call, and a single auto-import expression.** No feature logic, no host definitions, no module lists. *(Invariant 7)*

---

## Attribution

This document synthesizes the work of:

- [Shahar "Dawn" Or (@mightyiam)](https://github.com/mightyiam/dendritic) — pattern definition and canonical reference
- [Victor Borja (@vic)](https://vic.github.io/dendrix/Dendritic.html) — aspect-oriented framing, dendrix project, tooling
- [Pol Dellaiera](https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/) — "Flipping the Configuration Matrix" concept
- [Doc-Steve](https://github.com/Doc-Steve/dendritic-design-with-flake-parts) — design guide
- The [Dendritic community](https://matrix.to/#/#dendritic:matrix.org)
