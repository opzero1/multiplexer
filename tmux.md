# tmux Multiplexer Skill

Detected environment: attached tmux session.

Use tmux commands only when `$TMUX` is set.

Supported actions:

- Split pane right: `tmux split-window -h -c "$PWD"`
- Split pane down: `tmux split-window -v -c "$PWD"`
- Rename pane: `tmux select-pane -T "TITLE"`
- Rename tab/window: `tmux rename-window "TITLE"`
- Resize pane left/right/up/down: `tmux resize-pane -L 5`, `tmux resize-pane -R 5`, `tmux resize-pane -U 5`, `tmux resize-pane -D 5`
- Focus pane left/right/up/down: `tmux select-pane -L`, `tmux select-pane -R`, `tmux select-pane -U`, `tmux select-pane -D`
- Zoom pane: `tmux resize-pane -Z`
- Close pane: `tmux kill-pane`
- Close tab/window: `tmux kill-window`
- New tab/window: `tmux new-window -c "$PWD"`
