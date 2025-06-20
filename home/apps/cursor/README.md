# Cursor Configuration

A modular, portable Cursor/VSCode configuration for Nix home-manager.

## Structure

- **`default.nix`**: Main entry point that combines all configuration modules
- **`settings.nix`**: Core editor settings and general configuration
- **`language-settings.nix`**: Language-specific settings and formatters  
- **`ai-settings.nix`**: Cursor AI assistant configuration
- **`extensions.nix`**: Organized extension management by category
- **`constants.nix`**: Shared constants and file ignore patterns
- **`user-config.nix`**: Optional user/machine-specific settings

## Usage

The configuration automatically combines all modules. For user-specific settings:

1. Copy `user-config.nix` to customize for your setup
2. Uncomment and set your Git signing key, SSH paths, etc.
3. The configuration will automatically include it if present

## Principles

- **DRY**: No duplication between files
- **Modular**: Easy to enable/disable feature sets
- **Portable**: No hardcoded user-specific values in main config
- **Conservative**: Respects VSCode defaults unless there's a clear benefit to override 