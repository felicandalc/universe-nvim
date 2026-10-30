<h1 align="center">Universe Nvim</h1>

<div align="center">
    <a href="https://github.com/felicandalc/universe-nvim/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/felicandalc/universe-nvim?style=flat-square&logo=starship&color=DCD7C9&labelColor=2C3639&logoColor=DCD7C9" /></a>
    <a href="https://github.com/felicandalc/universe-nvim/LICENSE"><img alt="License" src="https://img.shields.io/github/license/felicandalc/universe-nvim?style=flat-square&color=DCD7C9&labelColor=2C3639" /></a>
    <img alt="PRs Welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square&color=DCD7C9&labelColor=2C3639" />
    <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/felicandalc/universe-nvim/next?style=flat-square&color=DCD7C9&labelColor=2C3639" />
    <img alt="Neovim version" src="https://img.shields.io/badge/Neovim->=0.12-57A143?style=flat-square&logo=neovim&color=DCD7C9&labelColor=2C3639" />
</div>

<hr />
<br />

<details>
  <summary>Contents</summary>
  <ul>
    <li><a href="#introduction">Introduction</a></li>
    <li>
      Getting Started
        <ul>
          <li><a href="#pre-requisites">Pre-requisites</a></li>
          <li><a href="#installation">Installation</a></li>
        </ul>
    </li>
  </ul>
</details>

### Introduction

This is a lightweight and fast Neovim configuration fully written in [Lua](https://www.lua.org/), it is being constantly iterated.
You can freely use it <strong>out-of-the-box</strong> or you can install it and modify it to meet your personal requirements.

### Pre-requisites

Neovim **0.12 or later** (latest [stable release](https://github.com/neovim/neovim/releases/tag/stable)). Distro packages are often older; use the official tarball, AppImage or installer if yours is.

| Tool | Why | Required |
| --- | --- | --- |
| `git`, `curl`, `tar`, `unzip`, `gzip` | lazy.nvim, Mason and parser downloads | yes |
| C compiler (`cc`/`gcc`/`clang`, MSVC or `zig` on Windows) and `make` | treesitter parsers, telescope-fzf-native, LuaSnip jsregexp | yes |
| [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md) 0.26.1+ | nvim-treesitter (`main`) builds parsers with it. Install it from your package manager or the GitHub release, not npm | yes |
| [ripgrep](https://github.com/BurntSushi/ripgrep), [fd](https://github.com/sharkdp/fd) | Telescope `live_grep` / `find_files` | yes |
| Node.js 22.13+ and npm | TypeScript, ESLint, Tailwind, JSON, YAML, Docker LSPs, prettier, markdownlint, markdown-preview. yaml-language-server will not start on older Node | for those languages |
| Python 3 (+ `venv`) | cmakelang, cmakelint | for CMake |
| Go | gopls, goimports, gofumpt, gomodifytags, impl, delve | for Go |
| `clangd` | C/C++ LSP. Mason installs it except on Linux arm64, where it has no build; Xcode ships it on macOS | for C/C++ on Linux arm64 |
| Clipboard tool | `pbcopy` (macOS, built in), `wl-clipboard` or `xclip` (Linux), built in on Windows. Without one, Neovim falls back to OSC 52 when the terminal supports it | no |
| `libsqlite3` | yanky.nvim history (not used on Windows) | yes on Linux |
| `gh`, `lazygit` | octo.nvim, the lazygit terminal | no |
| [Nerd Font](https://www.nerdfonts.com) | icons | no |

Mason packages that need a missing toolchain (Node, Python, Go) are skipped instead of failing; install the toolchain and restart Neovim to get them.

<details open="open">
<summary>macOS (Homebrew)</summary>

```sh
xcode-select --install
brew install neovim git ripgrep fd tree-sitter-cli node python go gh lazygit
```

</details>

<details>
<summary>Linux</summary>

```sh
# Debian / Ubuntu (install Neovim itself from the official release, apt ships an old one)
sudo apt install git curl tar unzip gzip build-essential ripgrep fd-find python3 python3-venv golang-go libsqlite3-dev clangd xclip wl-clipboard
sudo ln -s "$(command -v fdfind)" /usr/local/bin/fd
# apt's Node.js is too old for yaml-language-server; NodeSource ships a current one (npm included)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install nodejs
# tree-sitter CLI: download the binary from https://github.com/tree-sitter/tree-sitter/releases

# Fedora
sudo dnf install neovim git curl tar unzip gzip gcc gcc-c++ make ripgrep fd-find tree-sitter-cli nodejs npm python3 golang sqlite-devel clang-tools-extra xclip wl-clipboard

# Arch
sudo pacman -S neovim git curl tar unzip gzip base-devel ripgrep fd tree-sitter-cli nodejs npm python go sqlite clang xclip wl-clipboard
```

</details>

<details>
<summary>Windows (winget or scoop)</summary>

```powershell
winget install Neovim.Neovim Git.Git BurntSushi.ripgrep.MSVC sharkdp.fd zig.zig Kitware.CMake OpenJS.NodeJS.LTS Python.Python.3.12 GoLang.Go Microsoft.PowerShell 7zip.7zip
# or
scoop install neovim git ripgrep fd zig cmake make nodejs-lts python go pwsh 7zip
```

Install the `tree-sitter` CLI from its [GitHub releases](https://github.com/tree-sitter/tree-sitter/releases) and put it on `PATH`. Set `git config --global core.autocrlf false` (the repo also ships a `.gitattributes`).

</details>

After installing, start Neovim, let lazy.nvim, Mason and nvim-treesitter finish, then run `:checkhealth`.

### Installation

<details open="open">
<summary>For Linux/MacOS users</summary>

<br />

- Create a backup

  ```sh
  mv ~/.config/nvim ~/.config/nvim.bak
  mv ~/.local/share/nvim ~/.local/share/nvim.bak
  ```

- Clone configuration

  ```sh
  git clone https://github.com/felicandalc/universe-nvim ~/.config/nvim
  ```

</details>

<details>
<summary>For Windows users</summary>

<br />

- Create a backup

  ```sh
  Move-Item -Path $HOME\AppData\Local\nvim -Destination $HOME\AppData\Local\nvim.bak
  Move-Item -Path $HOME\AppData\Local\nvim-data -Destination $HOME\AppData\Local\nvim-data.bak
  ```

- Clone configuration

  ```sh
  git clone https://github.com/felicandalc/universe-nvim $HOME\AppData\Local\nvim
  ```

</details>
