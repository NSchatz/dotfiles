# Fish Shell Configuration — Catppuccin Mocha Rice

# ── Disable greeting ─────────────────────────────────────────
set -g fish_greeting

# ── Exit early if non-interactive ────────────────────────────
if not status is-interactive
    return
end

# ── Environment ──────────────────────────────────────────────
if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else
    set -gx EDITOR nano
    set -gx VISUAL nano
end
set -gx BROWSER firefox
set -gx PATH $HOME/.local/bin $PATH

# ── Starship prompt ──────────────────────────────────────────
if type -q starship
    starship init fish | source
end

# ── Tool initialization ─────────────────────────────────────
# zoxide (smart cd)
if type -q zoxide
    zoxide init fish --cmd cd | source
end

# fzf key bindings (Ctrl+R history, Ctrl+T files)
if type -q fzf
    fzf --fish | source
end

# ── Abbreviations (expand inline — visible in history) ───────
# Modern CLI replacements
if type -q eza
    abbr -a ls 'eza --color=always --group-directories-first --icons'
    abbr -a ll 'eza -la --color=always --group-directories-first --icons'
    abbr -a lt 'eza -aT --color=always --group-directories-first --icons --level=3'
    abbr -a la 'eza -a --color=always --group-directories-first --icons'
end

if type -q bat
    abbr -a cat 'bat --style=auto'
end

if type -q rg
    abbr -a grep rg
end

if type -q fd
    abbr -a find fd
end

if type -q btop
    abbr -a top btop
end


# Navigation
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
abbr -a mkdir 'mkdir -pv'

# Hyprland shortcuts
abbr -a hyprcheck 'hyprctl configerrors'
abbr -a hyprreload 'hyprctl reload'
abbr -a hyprclients 'hyprctl clients'
abbr -a hyprlayers 'hyprctl layers'

# Git shortcuts
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gp 'git push'
abbr -a gl 'git log --oneline --graph -20'
abbr -a gd 'git diff'

# ── Fastfetch on terminal launch ─────────────────────────────
# Only in interactive shells, not inside tmux/screen
if type -q fastfetch; and not set -q TMUX; and not set -q STY
    fastfetch
end

# ── Catppuccin Fish theme ────────────────────────────────────
# Install with: fisher install catppuccin/fish
# Then apply:   fish_config theme save "Catppuccin Mocha"
