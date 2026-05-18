# WezTerm Native Multiplexer Skill

Detected terminal: WezTerm.

Use `wezterm cli` for native multiplexing.

Supported actions:

- Split pane right: `wezterm cli split-pane --right --cwd "$PWD"`
- Split pane down: `wezterm cli split-pane --bottom --cwd "$PWD"`
- New tab: `wezterm cli spawn --cwd "$PWD"`
- New window: `wezterm cli spawn --new-window --cwd "$PWD"`
- Rename tab: `wezterm cli set-tab-title "TITLE"`
- Rename window: `wezterm cli set-window-title "TITLE"`
- Focus pane left/right/up/down: `wezterm cli activate-pane-direction Left|Right|Up|Down`
- Resize pane left/right/up/down: `wezterm cli adjust-pane-size Left|Right|Up|Down 5`
- Zoom pane: `wezterm cli zoom-pane --toggle`
- Close pane: `wezterm cli kill-pane`

Unsupported or unclear actions:

- Rename pane: no direct `wezterm cli` command in the detected CLI help. Say unsupported.

Do not suggest tmux for WezTerm-native panes.
