# Apple Terminal Native Multiplexer Skill

Detected terminal: Apple Terminal.

Apple Terminal supports tabs/windows but does not provide native split panes like Ghostty/WezTerm/Kitty/iTerm2.

Supported actions:

- New tab: `osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down'`
- New window: `osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "n" using command down'`

Unsupported actions:

- Split pane: unsupported in Apple Terminal.
- Resize/focus/zoom/rename pane: unsupported in Apple Terminal.

Do not suggest tmux for Apple Terminal unless `$TMUX` is set.
