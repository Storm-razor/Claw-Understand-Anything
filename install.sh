#!/usr/bin/env bash
# Understand-Anything installer for OpenClaw (macOS / Linux)
#
# Usage:
#   ./install.sh
#   ./install.sh openclaw
#   ./install.sh --update
#   ./install.sh --uninstall
#   ./install.sh --help
#
# Curl-pipe usage:
#   curl -fsSL https://raw.githubusercontent.com/Storm-razor/Claw-Understand-Anything/main/install.sh | bash
#
# Environment:
#   UA_REPO_URL   Override git clone URL
#   UA_REPO_DIR   Override checkout directory
#   UA_SKILLS_DIR Override installed skills directory
#   UA_PLUGIN_DIR Override installed plugin directory
#   UA_DIR        Backward-compatible alias for UA_REPO_DIR

set -euo pipefail

REPO_URL="${UA_REPO_URL:-https://github.com/Storm-razor/Claw-Understand-Anything.git}"
REPO_DIR="${UA_REPO_DIR:-${UA_DIR:-$HOME/.openclaw/workspace/.understand-anything/repo}}"
SKILLS_DIR="${UA_SKILLS_DIR:-$HOME/.openclaw/workspace/skills/understand-anything}"
PLUGIN_DIR="${UA_PLUGIN_DIR:-$HOME/.openclaw/workspace/.understand-anything-plugin}"

platform_id() { printf '%s\n' 'openclaw'; }

validate_platform_arg() {
  local id="${1:-}"
  if [[ -n "$id" && "$id" != "$(platform_id)" ]]; then
    printf 'Unknown platform: %s\n' "$id" >&2
    printf 'Supported: %s\n' "$(platform_id)" >&2
    exit 1
  fi
}

clone_or_update() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    printf -- '→ Updating existing checkout at %s\n' "$REPO_DIR"
    git -C "$REPO_DIR" pull --ff-only
  else
    printf -- '→ Cloning %s → %s\n' "$REPO_URL" "$REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
  fi
}

plugin_source_dir() { printf '%s\n' "$REPO_DIR/understand-anything-plugin"; }
skills_source_dir() { printf '%s\n' "$(plugin_source_dir)/skills"; }

ensure_sources_exist() {
  local plugin_src skills_src
  plugin_src="$(plugin_source_dir)"
  skills_src="$(skills_source_dir)"
  if [[ ! -d "$plugin_src" ]]; then
    printf 'Plugin directory not found: %s\n' "$plugin_src" >&2
    exit 1
  fi
  if [[ ! -d "$skills_src" ]]; then
    printf 'Skills directory not found: %s\n' "$skills_src" >&2
    exit 1
  fi
}

replace_dir_with_copy() {
  local src="$1" dst="$2"
  rm -rf "$dst"
  mkdir -p "$dst"
  cp -R "$src/." "$dst"
}

copy_plugin_root() {
  local src
  src="$(plugin_source_dir)"
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  replace_dir_with_copy "$src" "$PLUGIN_DIR"
  printf '  ✓ copied plugin → %s\n' "$PLUGIN_DIR"
}

copy_skills() {
  local src
  src="$(skills_source_dir)"
  mkdir -p "$(dirname "$SKILLS_DIR")"
  replace_dir_with_copy "$src" "$SKILLS_DIR"
  printf '  ✓ copied skills → %s\n' "$SKILLS_DIR"
}

sync_installation() {
  ensure_sources_exist
  printf -- '→ Copying plugin files\n'
  copy_plugin_root
  printf -- '→ Copying skills files\n'
  copy_skills
}

cmd_install() {
  clone_or_update
  sync_installation

  printf '\n✓ Installed Understand-Anything for %s\n' "$(platform_id)"
  printf '  Repo checkout: %s\n' "$REPO_DIR"
  printf '  Plugin path:   %s\n' "$PLUGIN_DIR"
  printf '  Skills path:   %s\n' "$SKILLS_DIR"
  printf '  Restart OpenClaw to pick up the copied skills.\n'
  printf '\n  Optional environment overrides:\n'
  printf '  export UA_REPO_DIR=%q\n' "$REPO_DIR"
  printf '  export UA_PLUGIN_DIR=%q\n' "$PLUGIN_DIR"
  printf '  export UA_SKILLS_DIR=%q\n' "$SKILLS_DIR"
}

cmd_uninstall() {
  printf -- '→ Removing copied OpenClaw installation\n'
  if [[ -e "$SKILLS_DIR" ]]; then
    rm -rf "$SKILLS_DIR"
    printf '  ✓ removed %s\n' "$SKILLS_DIR"
  else
    printf '  • not found: %s\n' "$SKILLS_DIR"
  fi

  if [[ -e "$PLUGIN_DIR" ]]; then
    rm -rf "$PLUGIN_DIR"
    printf '  ✓ removed %s\n' "$PLUGIN_DIR"
  else
    printf '  • not found: %s\n' "$PLUGIN_DIR"
  fi

  if [[ -d "$REPO_DIR" ]]; then
    printf '\nThe checkout at %s was kept.\n' "$REPO_DIR"
    printf 'To remove it: rm -rf "%s"\n' "$REPO_DIR"
  fi
}

cmd_update() {
  if [[ ! -d "$REPO_DIR/.git" ]]; then
    printf 'No installation found at %s. Run install first.\n' "$REPO_DIR" >&2
    exit 1
  fi

  clone_or_update
  sync_installation
  printf '✓ Updated OpenClaw installation.\n'
}

usage() {
  cat <<USAGE
Understand-Anything installer for OpenClaw

Usage:
  install.sh [openclaw]   Install for OpenClaw
  install.sh --update     Pull latest changes and recopy plugin + skills
  install.sh --uninstall  Remove copied plugin + skills
  install.sh --help

Supported platform:
  - openclaw

Default paths:
  Repo:   \$HOME/.openclaw/workspace/.understand-anything/repo
  Plugin: \$HOME/.openclaw/workspace/.understand-anything-plugin
  Skills: \$HOME/.openclaw/workspace/skills/understand-anything

Environment:
  UA_REPO_URL   Override git clone URL
  UA_REPO_DIR   Override checkout directory
  UA_SKILLS_DIR Override installed skills directory
  UA_PLUGIN_DIR Override installed plugin directory
  UA_DIR        Backward-compatible alias for UA_REPO_DIR
USAGE
}

main() {
  case "${1:-}" in
    -h|--help)
      usage
      ;;
    --update)
      cmd_update
      ;;
    --uninstall)
      cmd_uninstall
      ;;
    "")
      cmd_install
      ;;
    -*)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      validate_platform_arg "$1"
      cmd_install
      ;;
  esac
}

main "$@"
