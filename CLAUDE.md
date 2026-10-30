# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

This is a Neovim configuration that uses Lazy.nvim as the plugin manager. There are no traditional build, test, or lint commands since this is a configuration repository.

**Plugin Management:**
- Plugins are managed through `lazy-lock.json` - this file locks plugin versions
- Plugin specifications are in `lua/universenvim/plugins/` organized by category
- To update plugins, use `:Lazy update` in Neovim
- To sync plugins to lockfile versions, use `:Lazy restore` in Neovim

**Configuration Testing:**
- Test the configuration by running `nvim` and checking for errors
- Use `:checkhealth` in Neovim to diagnose issues
- Check startup time with `:StartupTime` (provided by vim-startuptime plugin)

## Architecture Overview

**Core Structure:**
- `init.lua` - Entry point that calls `universenvim.config.setup()`
- `lua/universenvim/config/` - Core configuration (keymaps, options, autocommands, constants)
- `lua/universenvim/plugins/` - Plugin specifications organized by category
- `lua/universenvim/utils/` - Utility functions for plugin management and LSP

**Plugin Organization:**
The plugins are categorized into logical groups with dedicated directories:
- `core/` - Essential plugins (plenary, dressing, persistence)
- `additionals/` - Optional utilities (vim-startuptime)
- `coding/` - Development tools (LSP, DAP, linting, formatting, git, treesitter)
- `editor/` - Text editing enhancements (telescope, flash, cmp, trouble)
- `ui/` - User interface (bufferline, lualine, nvim-tree, noice, whichkey)
- `langs/` - Language-specific configurations (TypeScript, Go, Docker, etc.)

**Key Patterns:**
- All plugin files return a table/array compatible with Lazy.nvim spec
- Utility functions in `universenvim.utils` provide common operations
- LSP configurations use Mason for automatic server installation
- Configuration uses a merge pattern combining constants and setup options
- Plugin dependencies are explicitly declared in each plugin spec

**Entry Flow:**
1. `init.lua` calls `universenvim.config.setup()`
2. Config loads keymaps, options, autocommands, and constants
3. Lazy.nvim imports plugin specs from categorized directories
4. Utils setup initializes formatter and LSP root caching

**Language Support:**
The configuration includes dedicated language support for:
- TypeScript/JavaScript (with tailwind)
- Go
- C/C++ (clangd)
- Docker
- YAML/JSON
- Markdown
- Flutter/Dart
- CMake

**Key Dependencies:**
- Lazy.nvim for plugin management
- Mason for LSP server installation
- Telescope for fuzzy finding
- nvim-cmp for completion
- conform.nvim for formatting
- nvim-lint for linting
- nvim-dap for debugging

## Code Style Guidelines

- DO NOT add redundant comments in code
- Keep configurations minimal and clean

## Completion

**Tab Behavior:**
- Tab navigates the nvim-cmp completion menu
- If no cmp menu, Tab handles LuaSnip expansion/jumping
- Otherwise falls back to normal Tab behavior