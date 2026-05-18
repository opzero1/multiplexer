# Warp Native Multiplexer Skill

Detected terminal: Warp.

Warp has native tabs and panes. Public shell automation is more limited than Ghostty/WezTerm/Kitty. Prefer documented URI actions for tabs/windows and System Events only for explicit UI shortcuts.

Supported actions:

- New tab: `open "warp://action/new_tab?path=$PWD"`
- New window: `open "warp://action/new_window?path=$PWD"`
- Split pane right: `osascript -e 'tell application "System Events" to tell process "Warp" to keystroke "d" using command down'`
- Split pane down: `osascript -e 'tell application "System Events" to tell process "Warp" to keystroke "d" using {command down, shift down}'`

Unsupported or unclear actions:

- Rename tab/pane/window from shell: say unsupported unless Warp exposes a documented command in the current environment.
- Resize/focus/zoom pane from shell: say unsupported unless the user asks for keyboard shortcut guidance.

Do not suggest tmux for Warp-native panes.
