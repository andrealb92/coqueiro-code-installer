#!/usr/bin/env bash
#
# Cqro Code — installer
# Clones the private cqro-code-cli repo, installs dependencies, builds and
# links the `cqro` binary so it's usable from anywhere via `cqro`.
#
# This script is public, but the Cqro Code source it clones is not — you need
# access to andrealb92/cqro-code-cli (SSH key or HTTPS credentials with
# permission on that repo) for the clone step to succeed.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/andrealb92/cqro-code-installer/main/install.sh | bash
#   CQRO_SSH=1 curl -fsSL https://raw.githubusercontent.com/andrealb92/cqro-code-installer/main/install.sh | bash
#
set -euo pipefail

REPO_HTTPS="https://github.com/andrealb92/cqro-code-cli.git"
REPO_SSH="git@github.com:andrealb92/cqro-code-cli.git"
DEFAULT_DIR="${CQRO_DIR:-$HOME/.cqro-code}"
BIN_NAME="cqro"

# Color helpers (no-op when not a TTY)
if [ -t 1 ]; then
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  RED=$'\033[0;31m'
  NC=$'\033[0m'
else
  GREEN=""; YELLOW=""; BLUE=""; RED=""; NC=""
fi

log()  { printf "${GREEN}>>${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}!!${NC} %s\n" "$*"; }
fail() { printf "${RED}xx${NC} %s\n" "$*" >&2; exit 1; }

# --- Validate prerequisites -------------------------------------------------
command -v git  >/dev/null 2>&1 || fail "git is required."
command -v bun  >/dev/null 2>&1 || fail "bun is required. Install it first: https://bun.sh"
command -v npm  >/dev/null 2>&1 || fail "npm is required."

# --- Pick clone URL ---------------------------------------------------------
URL="$REPO_HTTPS"
if [ "${CQRO_SSH:-0}" = "1" ]; then
  URL="$REPO_SSH"
fi

# -----------------------------------------------------------------------------
log "Installing Cqro Code CLI from $( [ "$URL" = "$REPO_SSH" ] && echo SSH || echo HTTPS )"
log "Target directory: $DEFAULT_DIR"

if [ -d "$DEFAULT_DIR/.git" ]; then
  warn "Directory already exists — updating instead of cloning."
  git -C "$DEFAULT_DIR" pull --ff-only || warn "Could not update; continuing with existing code."
else
  mkdir -p "$(dirname "$DEFAULT_DIR")"
  log "Cloning repository..."
  git clone "$URL" "$DEFAULT_DIR" || \
    fail "Clone failed. For a private repo, ensure you have access and try again. For SSH, set CQRO_SSH=1 and add your SSH key to GitHub."
fi

log "Installing dependencies..."
cd "$DEFAULT_DIR"
bun install || fail "bun install failed."

if [ -f scripts/build.ts ] || [ -d dist ]; then
  log "Building bundle..."
  bun run build || warn "Build failed; falling back to running from source."
fi

log "Linking global binary '$BIN_NAME'..."
npm link || fail "npm link failed. Try running with sudo."

log "Verifying..."
if command -v "$BIN_NAME" >/dev/null 2>&1; then
  "$BIN_NAME" --version
else
  warn "'$BIN_NAME' not found in PATH. Ensure the npm bin directory is in your PATH."
fi

echo ""
echo "${GREEN}Done!${NC} You can now run ${BLUE}${BIN_NAME}${NC} from anywhere."
