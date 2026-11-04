# Terminal and Neovim Configuration for Debian

This package adapts the configuration files moved from Windows to Debian. It
contains no tokens, SSH keys, or passwords.

The highlight is Neovim, configured as an IDE for Java and Spring Boot: jdtls,
code generation and refactoring, Maven/Gradle builds, tests, JaCoCo coverage,
debugging, and Spring Boot Language Server. See the
[Neovim README](nvim/README.md) and the [keybindings guide](nvim/ATALHOS.md).

## What was adapted

| Source | Debian implementation |
| --- | --- |
| PowerShell profile | PowerShell 7-compatible profile on Linux, without Git for Windows paths |
| PowerShell functions and aliases | Equivalent version for Bash, the default Debian shell |
| Oh My Posh theme | The same `lucas.omp.json`, shared by Bash and PowerShell |
| Windows Terminal | Script that creates a new GNOME Terminal profile with the One Dark font and palette |
| Neovim | Java/Spring Boot IDE with Java paths discovered through `PATH`/`JAVA_HOME`, all installed JDKs registered, and the integrated terminal using the Linux shell |

The installer creates symbolic links from `~/.config` to this repository, so
any change (including `lazy-lock.json` updates made by `:Lazy sync`) appears in
`git status`. Therefore, keep the repository in the same location after
installation; if you move it, run `./install.sh` again. The installer moves old
configurations to `~/.config-backups`.
The GNOME Terminal script creates the **Lucas One Dark** profile on its first run
and only updates it on subsequent runs; the previous profile is not deleted.

## 1. Install the required programs

First install the dependencies available in Debian:

```bash
sudo apt update
sudo apt install -y \
  git curl unzip build-essential ripgrep fd-find fzf zoxide eza bat \
  wl-clipboard xclip trash-cli nodejs npm openjdk-21-jdk maven uuid-runtime
```

### Neovim 0.12 or later

The Debian 13 `neovim` package provides the 0.10 series, but this configuration
uses Neovim 0.12 APIs. Use the included installer, which installs the official
stable version for your user only:

```bash
chmod +x scripts/install-neovim-latest.sh
./scripts/install-neovim-latest.sh
exec bash
nvim --version
```

The binary is located at `~/.local/bin/nvim`; the system package is not removed.

### Oh My Posh and the font

Install Oh My Posh using the official method for Linux:

```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
exec bash
oh-my-posh font list | grep -i jet
oh-my-posh font install JetBrainsMono
fc-cache -f
```

If `JetBrainsMono` does not appear in the list, choose another Nerd Font there
and then adjust the `font` property in `terminal/apply-gnome-terminal.sh`.

## 2. Apply the configurations

From the root of this package:

```bash
chmod +x install.sh terminal/apply-gnome-terminal.sh
./install.sh
exec bash
```

With no options, the installer links:

- `~/.config/nvim`;
- `~/.config/shell/lucas-terminal.bash` and its loading through `~/.bashrc`;
- `~/.inputrc`, which includes `/etc/inputrc` and makes `Ctrl+Backspace` delete the
  previous word;
- `~/.config/powershell/Microsoft.PowerShell_profile.ps1`;
- `~/.config/oh-my-posh/lucas.omp.json`, the prompt theme used by Bash and
  PowerShell (linked with `--bash` or `--powershell`).

To install only part of the configuration:

```bash
./install.sh --nvim
./install.sh --bash
./install.sh --powershell
./install.sh --check
```

Then apply the appearance in GNOME Terminal:

```bash
./terminal/apply-gnome-terminal.sh
```

Close and reopen the terminal. The created profile is called **Lucas One Dark**.
Transparency was reduced from 50% to 15% to preserve readability; on GNOME
Terminal versions without transparency support, the script simply ignores this
property.

The Windows Terminal shortcuts were not copied literally. GNOME Terminal keeps
its native shortcuts, such as `Ctrl+Shift+T` for a new tab, and leaves `Ctrl+T`
available for Neovim's integrated terminal.

## 3. First Neovim startup

Open the editor with internet access:

```bash
nvim
```

`lazy.nvim` will be downloaded and will install the plugins at the versions in
`lazy-lock.json`. At the same time, Mason installs language servers and tools in
the background (jdtls, debugger and Java tests, Spring Boot Tools, SonarLint,
lemminx, and others), notifying you when each one finishes. After the
notifications stop, restart Neovim (`Ctrl+Alt+Q`) and run:

```vim
:NeotestJava setup
:checkhealth
```

`:NeotestJava setup` downloads the JUnit Console Launcher used by the test
panel (neotest); it asks for confirmation before downloading. `:Mason` shows
installation progress and lets you reinstall a package that failed.

Java is located in this order:

1. The `JAVA_HOME` variable, when set;
2. The real path of the `java` command found in `PATH`.

Check in the terminal:

```bash
java -version
readlink -f "$(command -v java)"
```

For Neovim copy/paste to work in GNOME/Wayland, `wl-copy` must be available.
The `wl-clipboard` package installed above provides it.

## 4. PowerShell 7 on Linux (optional)

Bash remains the system shell. PowerShell is used only in the GNOME Terminal
**Lucas PowerShell** profile, which displays the history suggestion list as you
type (`PredictionViewStyle ListView`).

Install from Microsoft's official repository
(<https://learn.microsoft.com/pt-br/powershell/scripting/install/install-debian>):

```bash
source /etc/os-release
curl -fsSLO "https://packages.microsoft.com/config/debian/$VERSION_ID/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
sudo apt update && sudo apt install -y powershell
```

Then install the profile modules, link the profile, and create the terminal
profile:

```bash
pwsh -NoLogo -Command \
  'Install-Module posh-git,Terminal-Icons,PSFzf -Scope CurrentUser -Force'
./install.sh --powershell
./terminal/apply-gnome-terminal.sh
```

In GNOME Terminal, open a tab with the **Lucas PowerShell** profile from the
menu next to the new-tab button. **Lucas One Dark** remains the default and
opens Bash.

To make Neovim's integrated terminal open PowerShell instead of Bash:

```bash
export NVIM_TERMINAL_SHELL='pwsh -NoLogo'
nvim
```

To make this permanent, add the `export` to the end of
`~/.config/shell/lucas-terminal.bash`.

## Preserved commands

- `dc`, `dco`, `di`, `dn`, `dv`, `ds`: Docker namespaces;
- `ll`, `lt`: modern listing with `eza` when available;
- `z`: frequency-based navigation with `zoxide`;
- `Ctrl+R`: fuzzy Bash/PowerShell history;
- `reload`: reloads the shell profile;
- `ep`: opens the shell configuration in the editor.
