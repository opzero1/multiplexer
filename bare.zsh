# opencode bare helpers
# b/s run opencode with project config, external skills, and external plugins suppressed.

_opencode_bare_json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

_opencode_bare_config_content() {
  local escaped_prompt="$(_opencode_bare_json_escape "$1")"
  printf '{"agent":{"bare":{"mode":"primary","prompt":"%s","permission":{"skill":"deny"}}}}' "$escaped_prompt"
}

b() {
  local system_prompt="Answer normally."
  local model="openai/gpt-5.3-codex-spark"
  local skip_permissions=1
  local -a extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--system)
        [[ $# -lt 2 ]] && { print -u2 -- "b: -s requires an argument"; return 1; }
        system_prompt="$2"
        shift 2
        ;;
      --system=*)
        system_prompt="${1#*=}"
        shift
        ;;
      -m|--model)
        [[ $# -lt 2 ]] && { print -u2 -- "b: -m requires an argument"; return 1; }
        model="$2"
        shift 2
        ;;
      --model=*)
        model="${1#*=}"
        shift
        ;;
      --safe)
        skip_permissions=0
        shift
        ;;
      -h|--help)
        printf '%s\n' \
          'Usage: b [-s <system-prompt>] [-m <provider/model>] [--safe] [prompt]' \
          '' \
          'Runs opencode in a bare one-shot mode:' \
          '  - No project config / AGENTS.md' \
          '  - No external skills' \
          '  - No external plugins' \
          '  - Empty opencode config dir' \
          '  - Primary agent prompt from -s/--system' \
          '  - Model defaults to openai/gpt-5.3-codex-spark' \
          '' \
          'Options:' \
          '  -s, --system <text>   Set the bare agent system prompt' \
          '  -m, --model <model>   Override model, including provider prefix' \
          '  --safe                Do not pass --dangerously-skip-permissions' \
          '  -h, --help            Show this help'
        return 0
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  mkdir -p /tmp/empty-opencode-config

  local -a permission_args=()
  [[ "$skip_permissions" -eq 1 ]] && permission_args=(--dangerously-skip-permissions)

  OPENCODE_DISABLE_PROJECT_CONFIG=1 \
  OPENCODE_DISABLE_EXTERNAL_SKILLS=1 \
  OPENCODE_DISABLE_CLAUDE_CODE=1 \
  OPENCODE_PURE=1 \
  OPENCODE_CONFIG_DIR=/tmp/empty-opencode-config \
  OPENCODE_CONFIG_CONTENT="$(_opencode_bare_config_content "$system_prompt")" \
  opencode run \
    --agent bare \
    --model "$model" \
    "${permission_args[@]}" \
    "${extra_args[@]}"
}

s() {
  b -m openai/gpt-5.3-codex-spark "$@"
}

_cx_system_prompt() {
  local shell_name="${SHELL:t}"
  local git_info="not in a git worktree"
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_info="root=$(command git rev-parse --show-toplevel 2>/dev/null), branch=$(command git branch --show-current 2>/dev/null)"
  fi

  local installed=()
  local cmd
  for cmd in git gh docker podman kubectl helm terraform brew mise bun node npm pnpm yarn python python3 pip pipx cargo go rustup rg fd jq yq fzf ssh scp rsync curl wget; do
    command -v "$cmd" >/dev/null 2>&1 && installed+=("$cmd")
  done
  [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1 && installed+=(tmux-attached)
  [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1 && installed+=(zellij-attached)

  printf '%s\n' \
    "$(_cx_github_skills)" \
    "" \
    "" \
    "Current terminal context:" \
    "- shell: ${shell_name:-unknown}" \
    "- os: $(uname -a 2>/dev/null)" \
    "- terminal: ${TERM_PROGRAM:-unknown} ${TERM:-unknown}" \
    "- cwd: $PWD" \
    "- git: $git_info" \
    "- installed common CLI tools: ${installed[*]:-none detected}" \
    "When the user asks for a command, provide the command first. When troubleshooting, give the shortest diagnostic sequence that can confirm the cause."
}

_cx_github_skills() {
  local base_url="${CX_SKILLS_BASE_URL:-https://raw.githubusercontent.com/opzero1/multiplexer/main}"
  local skills=""
  local skill
  for skill in base "$(_cx_terminal_skill_name)" "$(_cx_mux_skill_name)"; do
    [[ -z "$skill" ]] && continue
    skills+="$(_cx_fetch_skill "$base_url/$skill.md")"
    skills+=$'\n\n'
  done

  if [[ -n "${skills//[$'\n\t ']/}" ]]; then
    printf '%s' "$skills"
    return 0
  fi

  printf '%s\n' \
    'You are an action-oriented terminal expert. Prefer the detected terminal emulator native controls. Do not suggest or run tmux unless TMUX is set. Do not suggest or run zellij unless ZELLIJ is set. If a terminal-control action is unsupported, say unsupported instead of inventing a fallback.'
}

_cx_fetch_skill() {
  command curl -fsSL "$1" 2>/dev/null
}

_cx_terminal_skill_name() {
  _cx_is_ghostty && { printf ghostty; return; }
  [[ -n "$WEZTERM_PANE" ]] && { printf wezterm; return; }
  [[ -n "$KITTY_WINDOW_ID" ]] && { printf kitty; return; }
  _cx_is_warp && { printf warp; return; }
  [[ "$TERM_PROGRAM" == "iTerm.app" ]] && { printf iterm2; return; }
  [[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && { printf apple-terminal; return; }
}

_cx_mux_skill_name() {
  [[ -n "$TMUX" ]] && { printf tmux; return; }
  [[ -n "$ZELLIJ" ]] && { printf zellij; return; }
}

_cx_try_terminal_action() {
  local request="${(L)*}"
  if [[ "$request" == *split* && "$request" == *pane* ]]; then
    _cx_split_pane "$request" || _cx_unsupported "split pane"
    return 0
  fi
  if [[ "$request" == *rename* && "$request" == *tab* ]]; then
    _cx_rename_tab "$@" || _cx_unsupported "rename tab"
    return 0
  fi
  if [[ "$request" == *rename* && "$request" == *pane* ]]; then
    _cx_rename_pane "$@" || _cx_unsupported "rename pane"
    return 0
  fi
  if [[ "$request" == *rename* && "$request" == *window* ]]; then
    _cx_rename_window "$@" || _cx_unsupported "rename window"
    return 0
  fi
  if [[ "$request" == *new* && "$request" == *tab* ]] || [[ "$request" == *open* && "$request" == *tab* ]]; then
    _cx_new_tab || _cx_unsupported "new tab"
    return 0
  fi
  if [[ "$request" == *new* && "$request" == *window* ]] || [[ "$request" == *open* && "$request" == *window* ]]; then
    _cx_new_window || _cx_unsupported "new window"
    return 0
  fi
  if [[ "$request" == *resize* && "$request" == *pane* ]]; then
    _cx_resize_pane "$request" || _cx_unsupported "resize pane"
    return 0
  fi
  if [[ "$request" == *zoom* && "$request" == *pane* ]]; then
    _cx_zoom_pane || _cx_unsupported "zoom pane"
    return 0
  fi
  if [[ "$request" == *close* && "$request" == *pane* ]]; then
    _cx_close_pane || _cx_unsupported "close pane"
    return 0
  fi
  if [[ "$request" == *close* && "$request" == *tab* ]]; then
    _cx_close_tab || _cx_unsupported "close tab"
    return 0
  fi
  if [[ "$request" == *focus* && "$request" == *pane* ]] || [[ "$request" == *select* && "$request" == *pane* ]]; then
    _cx_focus_pane "$request" || _cx_unsupported "focus pane"
    return 0
  fi
  return 1
}

_cx_split_pane() {
  local direction="$(_cx_direction "$1")"
  if _cx_is_ghostty && command -v osascript >/dev/null 2>&1; then
    command osascript -e "tell application \"Ghostty\" to tell selected tab of front window to split focused terminal direction $direction"
    return $?
  fi
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli split-pane "$(_cx_wezterm_split_flag "$direction")" --cwd "$PWD"
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ launch --type=window --location="$(_cx_kitty_split_location "$direction")" --cwd=current
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && command -v osascript >/dev/null 2>&1; then
    [[ "$direction" == "down" || "$direction" == "up" ]] && command osascript -e 'tell application "iTerm2" to tell current session of current window to split horizontally with default profile' && return $?
    command osascript -e 'tell application "iTerm2" to tell current session of current window to split vertically with default profile'
    return $?
  fi
  if _cx_is_warp && command -v osascript >/dev/null 2>&1; then
    [[ "$direction" == "down" || "$direction" == "up" ]] && command osascript -e 'tell application "System Events" to tell process "Warp" to keystroke "d" using {command down, shift down}' && return $?
    command osascript -e 'tell application "System Events" to tell process "Warp" to keystroke "d" using command down'
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    [[ "$direction" == "down" || "$direction" == "up" ]] && command tmux split-window -v -c "$PWD" && return $?
    command tmux split-window -h -c "$PWD"
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action new-pane --direction "$direction"
    return $?
  fi
  return 1
}

_cx_new_tab() {
  if _cx_is_ghostty && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "Ghostty" to new tab in front window'
    return $?
  fi
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli spawn --cwd "$PWD"
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ launch --type=tab --cwd=current
    return $?
  fi
  if _cx_is_warp && command -v open >/dev/null 2>&1; then
    command open "warp://action/new_tab?path=$PWD"
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "System Events" to tell process "iTerm2" to keystroke "t" using command down'
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "t" using command down'
    return $?
  fi
  return 1
}

_cx_new_window() {
  if _cx_is_ghostty && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "Ghostty" to new window'
    return $?
  fi
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli spawn --new-window --cwd "$PWD"
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ launch --type=os-window --cwd=current
    return $?
  fi
  if _cx_is_warp && command -v open >/dev/null 2>&1; then
    command open "warp://action/new_window?path=$PWD"
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "System Events" to tell process "iTerm2" to keystroke "n" using command down'
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]] && command -v osascript >/dev/null 2>&1; then
    command osascript -e 'tell application "System Events" to tell process "Terminal" to keystroke "n" using command down'
    return $?
  fi
  return 1
}

_cx_rename_tab() {
  local title="$(_cx_extract_title "$@")"
  [[ -z "$title" ]] && return 1
  if _cx_is_ghostty && command -v osascript >/dev/null 2>&1; then
    command osascript -e "tell application \"Ghostty\" to set name of selected tab of front window to \"$(_cx_applescript_escape "$title")\""
    return $?
  fi
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli set-tab-title "$title"
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ set-tab-title "$title"
    return $?
  fi
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && command -v osascript >/dev/null 2>&1; then
    command osascript -e "tell application \"iTerm2\" to set name of current tab of current window to \"$(_cx_applescript_escape "$title")\""
    return $?
  fi
  printf '\033]0;%s\007' "$title"
}

_cx_rename_pane() {
  local title="$(_cx_extract_title "$@")"
  [[ -z "$title" ]] && return 1
  if _cx_is_ghostty && command -v osascript >/dev/null 2>&1; then
    command osascript -e "tell application \"Ghostty\" to set name of focused terminal of selected tab of front window to \"$(_cx_applescript_escape "$title")\"" >/dev/null 2>&1
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ set-window-title "$title"
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux select-pane -T "$title"
    return $?
  fi
  printf '\033]2;%s\007' "$title"
}

_cx_unsupported() {
  print -u2 -- "cx: $1 is not supported by the detected terminal control interface (${TERM_PROGRAM:-unknown}, TERM=${TERM:-unknown})."
}

_cx_rename_window() {
  local title="$(_cx_extract_title "$@")"
  [[ -z "$title" ]] && return 1
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli set-window-title "$title"
    return $?
  fi
  _cx_rename_tab "rename tab to $title"
}

_cx_resize_pane() {
  local direction="$(_cx_direction "$1")"
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli adjust-pane-size "$(_cx_wezterm_direction "$direction")" 5
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ resize-window --axis="$(_cx_kitty_resize_axis "$direction")" --increment="$(_cx_kitty_resize_increment "$direction")"
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux resize-pane "-$(_cx_tmux_direction_flag "$direction")" 5
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action resize "$direction"
    return $?
  fi
  return 1
}

_cx_zoom_pane() {
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli zoom-pane --toggle
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux resize-pane -Z
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action toggle-pane-frames
    return $?
  fi
  return 1
}

_cx_close_pane() {
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli kill-pane
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ close-window
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux kill-pane
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action close-pane
    return $?
  fi
  return 1
}

_cx_close_tab() {
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ close-tab
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux kill-window
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action close-tab
    return $?
  fi
  return 1
}

_cx_focus_pane() {
  local direction="$(_cx_direction "$1")"
  if [[ -n "$WEZTERM_PANE" ]] && command -v wezterm >/dev/null 2>&1; then
    command wezterm cli activate-pane-direction "$(_cx_wezterm_direction "$direction")"
    return $?
  fi
  if [[ -n "$KITTY_WINDOW_ID" ]] && command -v kitten >/dev/null 2>&1; then
    command kitten @ focus-window --match "neighbor:$(_cx_kitty_focus_direction "$direction")"
    return $?
  fi
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    command tmux select-pane "-$(_cx_tmux_direction_flag "$direction")"
    return $?
  fi
  if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
    command zellij action move-focus "$direction"
    return $?
  fi
  return 1
}

_cx_extract_title() {
  local text="$*"
  local lower="${(L)text}"
  local marker
  for marker in " to " " as " " named "; do
    if [[ "$lower" == *"$marker"* ]]; then
      printf '%s' "${text#*${marker}}"
      return 0
    fi
  done
  return 1
}

_cx_direction() {
  local request="$1"
  [[ "$request" == *left* ]] && { printf left; return; }
  [[ "$request" == *down* || "$request" == *below* || "$request" == *bottom* ]] && { printf down; return; }
  [[ "$request" == *up* || "$request" == *above* || "$request" == *top* ]] && { printf up; return; }
  printf right
}

_cx_wezterm_split_flag() {
  [[ "$1" == "down" || "$1" == "up" ]] && printf -- '--bottom' || printf -- '--right'
}

_cx_wezterm_direction() {
  case "$1" in
    left) printf Left ;;
    down) printf Down ;;
    up) printf Up ;;
    *) printf Right ;;
  esac
}

_cx_kitty_split_location() {
  case "$1" in
    left) printf hsplit ;;
    down) printf split ;;
    up) printf split ;;
    *) printf vsplit ;;
  esac
}

_cx_kitty_focus_direction() {
  [[ "$1" == "down" ]] && printf bottom && return
  [[ "$1" == "up" ]] && printf top && return
  printf '%s' "$1"
}

_cx_kitty_resize_axis() {
  [[ "$1" == "left" || "$1" == "right" ]] && printf horizontal || printf vertical
}

_cx_kitty_resize_increment() {
  [[ "$1" == "left" || "$1" == "up" ]] && printf -- '-5' || printf 5
}

_cx_tmux_direction_flag() {
  case "$1" in
    left) printf L ;;
    down) printf D ;;
    up) printf U ;;
    *) printf R ;;
  esac
}

_cx_applescript_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

_cx_is_ghostty() {
  [[ "$TERM_PROGRAM" == "Ghostty" || "$TERM_PROGRAM" == "ghostty" || "$TERM" == "xterm-ghostty" || -n "$GHOSTTY_RESOURCES_DIR" ]]
}

_cx_is_warp() {
  [[ "$TERM_PROGRAM" == "WarpTerminal" || "$TERM_PROGRAM" == "Warp" || -n "$WARP_IS_LOCAL_SHELL_SESSION" ]]
}

cx() {
  if _cx_try_terminal_action "$@"; then
    return 0
  fi
  b -s "$(_cx_system_prompt "$@")" "$@"
}

cxi() {
  local system_prompt="$(_cx_system_prompt "$@")"
  local model="openai/gpt-5.3-codex-spark"
  local -a extra_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--system)
        [[ $# -lt 2 ]] && { print -u2 -- "cxi: -s requires an argument"; return 1; }
        system_prompt="$2"
        shift 2
        ;;
      --system=*)
        system_prompt="${1#*=}"
        shift
        ;;
      -m|--model)
        [[ $# -lt 2 ]] && { print -u2 -- "cxi: -m requires an argument"; return 1; }
        model="$2"
        shift 2
        ;;
      --model=*)
        model="${1#*=}"
        shift
        ;;
      -h|--help)
        printf '%s\n' \
          'Usage: cxi [-s <system-prompt>] [-m <provider/model>] [project]' \
          '' \
          'Starts an interactive opencode TUI terminal expert in bare mode.' \
          '' \
          'Options:' \
          '  -s, --system <text>   Override the generated terminal expert prompt' \
          '  -m, --model <model>   Override model, including provider prefix' \
          '  -h, --help            Show this help'
        return 0
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  mkdir -p /tmp/empty-opencode-config

  OPENCODE_DISABLE_PROJECT_CONFIG=1 \
  OPENCODE_DISABLE_EXTERNAL_SKILLS=1 \
  OPENCODE_DISABLE_CLAUDE_CODE=1 \
  OPENCODE_PURE=1 \
  OPENCODE_CONFIG_DIR=/tmp/empty-opencode-config \
  OPENCODE_CONFIG_CONTENT="$(_opencode_bare_config_content "$system_prompt")" \
  opencode \
    --agent bare \
    --model "$model" \
    "${extra_args[@]}"
}
