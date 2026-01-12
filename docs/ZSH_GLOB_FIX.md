# Zsh Glob Pattern Fix for Nix Flake Commands

## The Problem

In zsh, the `#` character is used for extended glob patterns. When you type:

```bash
nix run .#update-immersed
```

Zsh tries to interpret `.#update-immersed` as a glob pattern and throws an error:

```
zsh: no matches found: .#update-immersed
```

This happens because:

1. Zsh sees the `#` and thinks it's a glob pattern
2. The `NOMATCH` option is enabled (line 96 in `shell.nix`)
3. Zsh tries to expand the pattern, fails, and throws an error

## The Solution

We've added **automatic glob disabling** for all Nix commands via shell aliases:

```nix
# In home/common/features/core/shell.nix
shellAliases = {
  nix = "noglob nix";
  nix-build = "noglob nix build";
  nix-run = "noglob nix run";
  nix-develop = "noglob nix develop";
  nix-shell = "noglob nix-shell";
};
```

The `noglob` command tells zsh to skip glob expansion for that command.

## After Rebuilding

Once you rebuild your system (`nh os switch`), you'll be able to use:

```bash
# Works without quotes! ✅
nix run .#update-immersed
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
nix develop .#rust
```

## Manual Workarounds (Before Rebuild)

If you need to use these commands before rebuilding:

### Option 1: Quote the argument

```bash
nix run '.#update-immersed'
```

### Option 2: Escape the hash

```bash
nix run .\#update-immersed
```

### Option 3: Use noglob manually

```bash
noglob nix run .#update-immersed
```

### Option 4: Disable NOMATCH temporarily

```bash
setopt LOCAL_OPTIONS NO_NOMATCH
nix run .#update-immersed
```

## Why This Happens in Zsh and Not Bash

- **Bash**: Doesn't treat `#` as a special character by default
- **Zsh**: Has extended globbing enabled and treats `#` as a pattern quantifier (like `##` for matching multiple occurrences)

## Other Affected Commands

Any command that uses `#` in arguments will have this issue:

- `git reset HEAD#` → Should be `git reset 'HEAD#'`
- `wget 'http://example.com/page#anchor'` → Already needs quotes for other reasons
- `echo test#123` → Works fine (not a glob pattern context)

## Technical Details

The `noglob` command is a zsh built-in that:

1. Temporarily disables glob expansion
2. Runs the command
3. Re-enables glob expansion afterward

It's equivalent to:

```bash
setopt LOCAL_OPTIONS NO_GLOB
nix run .#update-immersed
setopt GLOB
```

But much more convenient!

## See Also

- [Zsh Manual: Glob Patterns](https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators)
- [Zsh FAQ: Glob Expansion](https://zsh.sourceforge.io/FAQ/zshfaq03.html)
