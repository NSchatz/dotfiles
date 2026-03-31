# dotfiles

Hyprland rice managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Contents |
|---------|----------|
| `hypr` | Hyprland config (main, keybinds, window rules, animations, autostart, monitors, hyprlock, hypridle) |
| `waybar` | Waybar bar config + CSS |
| `kitty` | Kitty terminal config |
| `swaync` | SwayNC notification center config + CSS |
| `rofi` | Rofi launcher config + Catppuccin theme |
| `wlogout` | Wlogout layout + CSS |
| `fish` | Fish shell config, plugins, completions, functions, themes |
| `starship` | Starship prompt config |
| `gtk` | GTK 3/4 theming + cursor fallback |
| `uwsm` | uwsm environment variables |
| `vscode` | Code OSS settings |

## Quick Start

```bash
# Install stow
sudo pacman -S --needed stow

# Clone
git clone git@github.com:NSchatz/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Stow everything
stow */

# Or stow selectively
stow hypr waybar kitty
```

## Updating

Edits to `~/.config/*` files are reflected in the repo immediately (they're symlinks). Just `cd ~/dotfiles && git add -A && git commit`.

To add new files to an existing package, place them in the correct path inside the package directory and restow:

```bash
stow -R hypr
```
