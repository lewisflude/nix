# Nix Practices

Compiled best practices and anti-patterns for Nix, NixOS, and Home Manager, as
they apply to **this repository**.

This is a companion to two other documents, and does not duplicate them:

| Document               | Scope                                                    |
| ---------------------- | -------------------------------------------------------- |
| `CLAUDE.md`            | Hard rules for agents (never rebuild, never create docs) |
| `DENDRITIC_PATTERN.md` | Module architecture — how files compose into systems     |
| `NIX_PRACTICES.md`     | Nix language, packaging, and option-writing craft (here) |

Precedence when they conflict: `CLAUDE.md` > `DENDRITIC_PATTERN.md` >
`NIX_PRACTICES.md` > upstream community advice.

Each rule below states what to do, why, and — where applicable — what enforces
it. Rules marked **[auto]** are already enforced by `nix fmt` or
`nix flake check`; the rest are review-time judgement.

---

## 1. Language

### 1.1 No `with` for scope injection **[auto: statix]**

```nix
# Bad
buildInputs = with pkgs; [ curl jq ];
# Also bad — file-level `with`
with (import <nixpkgs> { });

# Good
buildInputs = [ pkgs.curl pkgs.jq ];
# Also good, for long lists
buildInputs = builtins.attrValues { inherit (pkgs) curl jq; };
```

`with` scoping rules are not intuitive (a `with`-bound name loses to any
enclosing `let`/lambda binding, silently), and static analysis cannot resolve
names through it. This repo bans it outright — see `CLAUDE.md`.

### 1.2 Prefer `let ... in` over `rec`

```nix
# Bad — shadowing turns into `infinite recursion`, reported far from the cause
rec { a = 1; b = a + 2; }

# Good
let a = 1; in { inherit a; b = a + 2; }

# Also good, when the set genuinely needs to reference itself
let argset = { a = 1; b = argset.a + 2; }; in argset
```

Exception: `rec` inside `stdenv.mkDerivation` to reuse `version` in `src` is
accepted upstream, but `finalAttrs` (§4.2) is better.

### 1.3 Quote URLs **[auto: statix W12]**

`url = "https://example.com";` — never bare. Unquoted URIs are deprecated by
RFC 45.

### 1.4 `//` does not merge nested sets

```nix
{ a = { b = 1; }; } // { a = { c = 3; }; }   # → { a = { c = 3; }; }  — `b` is gone
lib.recursiveUpdate { a = { b = 1; }; } { a = { c = 3; }; }  # → both keys
```

In module bodies you rarely need either: the module system merges definitions
for you. Reach for `//` only on plain data.

### 1.5 Mechanical lints **[auto]**

`statix` (pinned via `modules/per-system/treefmt.nix`) enforces these on every
`nix fmt` and in `nix flake check`:

| Code | Lint                     | Code | Lint                  |
| ---- | ------------------------ | ---- | --------------------- |
| W01  | `bool_comparison`        | W12  | `unquoted_uri`        |
| W02  | `empty_let_in`           | W14  | `empty_inherit`       |
| W03  | `manual_inherit`         | W17  | `deprecated_to_path`  |
| W04  | `manual_inherit_from`    | W18  | `bool_simplification` |
| W05  | `legacy_let_syntax`      | W19  | `useless_has_attr`    |
| W06  | `collapsible_let_in`     | W20  | `repeated_keys`       |
| W07  | `eta_reduction`          | W23  | `empty_list_concat`   |
| W08  | `useless_parens`         |      |                       |
| W10  | `empty_pattern`          |      |                       |
| W11  | `redundant_pattern_bind` |      |                       |

`deadnix` removes unused bindings (`no-lambda-arg = true`, so unused function
arguments are allowed — module signatures need them). `nixfmt` owns layout;
never hand-format around it.

A small exclude list exists in `modules/per-system/treefmt.nix`. Do not widen it
to silence a lint — fix the code.

---

## 2. Reproducibility

### 2.1 No lookup paths

`<nixpkgs>` resolves through `$NIX_PATH`, which is machine state. Two machines
evaluate it differently. This repo is a flake: take nixpkgs from `inputs`, and
inside modules take packages from the `pkgs` argument.

### 2.2 No `--impure`, no `builtins.getEnv`

If an evaluation needs `--impure` to succeed, the dependency belongs in
`flake.nix` inputs or in a `config.*` option instead.

### 2.3 Never inline a secret

Everything in the Nix store is world-readable. Secrets come from sops-nix and
are referenced **by path at runtime**:

```nix
# Good — the service reads the file itself
tokenFile = config.sops.secrets.GITHUB_TOKEN.path;

# Bad — the token is now in /nix/store, and in git history
token = "ghp_...";
```

Guard optional secrets rather than assuming they exist; see the
`secretAvailable` helper in `modules/ai-cli-lib.nix`.

### 2.4 Pin sources by hash

Use `pkgs.fetchurl` / `fetchFromGitHub` / `fetchgit` with an explicit `hash`.
Avoid `builtins.fetchurl`, `builtins.fetchGit`, and `builtins.fetchTarball` in
package definitions: they are impure, uncacheable, and **block evaluation** on
the network, so a slow fetch stalls the whole evaluation rather than one build.

### 2.5 Avoid import-from-derivation (IFD)

Importing a path that must be built first serialises evaluation behind a build
and defeats parallel evaluation. Prefer generating a lockfile-derived JSON and
reading it with `builtins.fromJSON`, or vendoring the generated Nix.

---

## 3. Module authoring (NixOS, Darwin, Home Manager)

### 3.1 Conditionals go inside the config, not around it

```nix
# Bad — evaluating the condition forces `config`, risking infinite recursion
if config.services.foo.enable then { ... } else { }

# Good
lib.mkIf config.services.foo.enable { ... }
```

The same applies to lists and attrs: `lib.optionals`, `lib.optionalAttrs`,
`lib.optionalString`.

### 3.2 Platform gating is explicit

```nix
lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.claude-desktop ]
```

Use `pkgs.stdenv.hostPlatform.isLinux` / `.isDarwin` — not
`builtins.currentSystem`, and not a bare `stdenv.isLinux` (deprecated alias).

### 3.3 Priority discipline

- `lib.mkDefault` — a value a host may want to override. Use freely in shared
  feature modules.
- `lib.mkForce` — you are overriding something you do not control. Every use
  wants a comment saying what it beats.
- `lib.mkBefore` / `lib.mkAfter` — ordering in lists (e.g. `nixpkgs.overlays` in
  `modules/nixpkgs.nix`), not a substitute for priority.

If two modules fight over one value, the fix is usually an option, not a
`mkForce`.

### 3.4 Options are typed and documented

When you add an option, give it a real `type`, a `default`, and a `description`.
Use `defaultText` when the default is a computed expression, so docs do not leak
store paths (see `modules/alerts.nix`).

### 3.5 Do not reach across the module boundary

Read values from `config.*` (platform scope) or the repo's top-level
`config.constants` / `config.username`. Never `import ../lib/foo.nix` directly,
and never thread values through `specialArgs`. This is the dendritic rule; see
`DENDRITIC_PATTERN.md`.

### 3.6 Prefer upstream options to hand-written files

An option that already exists is tested, typed, and migrates with the release.
Reach for `environment.etc` / `home.file` / `xdg.configFile` only when no option
covers the setting. Verify the option exists before using it (§6).

---

## 4. Packaging

### 4.1 Overlays are a last resort

Order of preference: use the package as-is → `package.override { }` (change
inputs) → `package.overrideAttrs` (change the derivation) → an overlay in
`overlays/` (change it _everywhere_, including for every dependent, forcing a
rebuild of the closure).

### 4.2 `finalAttrs` over `rec`

```nix
stdenv.mkDerivation (finalAttrs: {
  pname = "foo";
  version = "1.2.3";
  src = fetchFromGitHub { tag = "v${finalAttrs.version}"; hash = "..."; };
})
```

This survives `overrideAttrs` correctly, where `rec` does not.

### 4.3 `pname` + `version`, not `name`

And for local sources, pin the store name so a parent-directory rename does not
cause a rebuild:

```nix
src = builtins.path { path = ./.; name = "myproject"; };
```

### 4.4 CLI tools are POG scripts

New command-line tooling goes in `pkgs/pog-scripts/` — typed flags, `--help`,
and shellcheck for free. Not a bare `writeShellScriptBin`, and not a new file in
`scripts/` (see `CLAUDE.md`).

---

## 5. Home Manager

### 5.1 This repo sets `useGlobalPkgs = true`

Consequence: **`nixpkgs.*` options are inert inside Home Manager modules.**
`nixpkgs.overlays` and `nixpkgs.config` set in a `flake.modules.homeManager.*`
module will silently do nothing. Overlays belong in `overlays/` and are wired by
`modules/nixpkgs.nix` at the system level.

### 5.2 `stateVersion` is not a version to bump

`home.stateVersion` and `system.stateVersion` record the release whose _stateful
defaults_ your system was built against. Changing them can silently migrate data
formats. They are set once, centrally, from `config.constants.defaults` — leave
them alone.

### 5.3 Prefer `programs.<tool>` over dotfile copying

`programs.git.enable = true;` with structured settings beats
`home.file.".gitconfig".source = ./gitconfig;`. You get option merging, type
checking, and upgrade migrations. Fall back to `xdg.configFile` for tools with
no module.

### 5.4 Know which scope a package belongs in

System-wide daemons, kernel modules, hardware, and anything needed before login
→ `flake.modules.nixos.*`. User applications, dotfiles, shells, editors, tray
applets → `flake.modules.homeManager.*`. Duplicating a package in both scopes
causes confusing PATH precedence.

---

## 6. Verification

Before recommending or writing any option or package name:

```bash
nix run .#update-all       # deps
nix fmt                    # nixfmt + statix + deadnix + prettier + shfmt
nix flake check            # eval + pre-commit hooks
nix flake show             # what this flake actually exposes
```

For agents: use the `nixos` MCP server (`nix` / `nix_versions` tools) to confirm
that a NixOS / Home Manager / Darwin option path exists and that a package is in
the channel `flake.lock` actually pins. Never invent an option path. If it
cannot be verified, say so rather than guessing.

Humans: `nix search nixpkgs <name>`, `man configuration.nix`, and
<https://search.nixos.org>.

**Do not run rebuilds.** No `nh os switch`, `nixos-rebuild`, or `darwin-rebuild`
— propose the command and let the user run it. Builds are fine; activation is
not.

---

## 7. Review checklist

- [ ] No `with pkgs;` or file-level `with`
- [ ] No `rec` where `let` or `finalAttrs` would do
- [ ] No `<nixpkgs>`, `--impure`, or `builtins.getEnv`
- [ ] No `builtins.fetch*` in package definitions; every fetch has a hash
- [ ] No secrets in the store — sops `.path` references only
- [ ] Conditionals use `mkIf` / `optionals`, not `if` around a config block
- [ ] Every `mkForce` has a comment justifying it
- [ ] New options have `type`, `default`, `description`
- [ ] Values flow through `config.*`, not `specialArgs` or direct imports
- [ ] Module placed in the right scope (`nixos` vs `homeManager`)
- [ ] `nixpkgs.*` not set from a Home Manager module (`useGlobalPkgs`)
- [ ] `stateVersion` untouched
- [ ] New CLI tooling is a POG script
- [ ] `nix fmt` and `nix flake check` pass

---

## 8. Sources

- [nix.dev — Best practices](https://nix.dev/guides/best-practices.html) — the
  closest thing to canonical; §1 and §2 largely restate it.
- [nixpkgs contributing guide](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
  and `pkgs/README.md` — normative for packaging.
- [NixOS & Flakes Book — Best Practices](https://nixos-and-flakes.thiscute.world/best-practices/intro)
- [Mastering Nixpkgs Overlays](https://discourse.nixos.org/t/mastering-nixpkgs-overlays-techniques-and-best-practice/50068)
  — overlay anti-patterns in depth.
- [Stopping evaluation from blocking](https://jade.fyi/blog/nix-evaluation-blocking/)
  — why builtin fetchers and IFD hurt (§2.4, §2.5).
- [statix](https://github.com/oppiliappan/statix) /
  [deadnix](https://github.com/astro/deadnix) /
  [nixpkgs-hammering](https://github.com/jtojnar/nixpkgs-hammering) — the
  machine-checkable subset.
- [awesome-nix](https://nix-community.github.io/awesome-nix/) — index to
  everything else.
