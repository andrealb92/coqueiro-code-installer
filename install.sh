#!/usr/bin/env bash
#
# Coqueiro Code — installer
# Clones the (private) repo, installs dependencies, builds and links the
# `coqueiro` binary (and its short alias `cqro`) so it's usable from anywhere.
#
# This is the source of truth for the script; it's mirrored to the public
# andrealb92/coqueiro-code-installer repo (raw.githubusercontent.com can't serve
# files from a private repo without auth, so the public one-liner points
# there instead of here). Keep the two in sync when editing.
#
# Usage:
#   One-command: curl -fsSL https://raw.githubusercontent.com/andrealb92/coqueiro-code-installer/main/install.sh | bash
#   Local:       bash scripts/install.sh
#
set -euo pipefail

REPO_HTTPS="https://github.com/andrealb92/coqueiro-code-cli.git"
REPO_SSH="git@github.com:andrealb92/coqueiro-code-cli.git"
# `CQRO_*` are the variable names from before the rename to Coqueiro Code.
DEFAULT_DIR="${COQUEIRO_DIR:-${CQRO_DIR:-$HOME/.coqueiro-cli}}"
LEGACY_DIR="$HOME/.cqro-code"
CHANNEL="${COQUEIRO_CHANNEL:-${CQRO_CHANNEL:-release}}"
BIN_NAME="coqueiro"

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
if [ "${COQUEIRO_SSH:-${CQRO_SSH:-0}}" = "1" ]; then
  URL="$REPO_SSH"
fi

# -----------------------------------------------------------------------------
log "Installing Coqueiro Code CLI from $( [ "$URL" = "$REPO_SSH" ] && echo SSH || echo HTTPS )"
log "Target directory: $DEFAULT_DIR"

# A managed install made before the rename lives in ~/.cqro-code and is linked
# globally as `cqro`. Move it to the new default and drop the old global link
# (it would dangle once the directory moves); the link is recreated below.
if [ -z "${COQUEIRO_DIR:-}${CQRO_DIR:-}" ] && [ -d "$LEGACY_DIR/.git" ] && [ ! -e "$DEFAULT_DIR" ]; then
  log "Moving the Cqro Code install from $LEGACY_DIR to $DEFAULT_DIR..."
  mv "$LEGACY_DIR" "$DEFAULT_DIR" || fail "Could not move $LEGACY_DIR to $DEFAULT_DIR."
  git -C "$DEFAULT_DIR" remote set-url origin "$URL" || warn "Could not point the moved clone at $URL."
  npm rm -g cqro-code >/dev/null 2>&1 || warn "Could not remove the old global 'cqro' link; delete it by hand if it remains."
fi

if [ -d "$DEFAULT_DIR/.git" ]; then
  warn "Directory already exists — fetching and refreshing the installer."
  git -C "$DEFAULT_DIR" fetch --tags --prune --prune-tags --force origin || warn "Could not fetch; continuing with existing code."
  # Refresh the branch tip first so the installer logic and selection script are
  # current before the release tag is chosen below (an older managed install may
  # sit on a tag that predates them).
  git -C "$DEFAULT_DIR" checkout -B main origin/main >/dev/null 2>&1 || \
    git -C "$DEFAULT_DIR" checkout main >/dev/null 2>&1 || \
    warn "Could not refresh the branch; continuing with the existing checkout."
else
  mkdir -p "$(dirname "$DEFAULT_DIR")"
  log "Cloning repository..."
  git clone "$URL" "$DEFAULT_DIR" || \
    fail "Clone failed. For a private repo, ensure you have access and try again. For SSH, set COQUEIRO_SSH=1 and add your SSH key to GitHub."
fi

log "Installing dependencies (frozen lockfile)..."
cd "$DEFAULT_DIR"
bun install --frozen-lockfile || fail "bun install failed."

# Managed installs follow the stable release channel: the checkout sits detached
# on the newest `v*` tag so `coqueiro update` can move it safely and `coqueiro --version`
# can report exactly what is installed. Selection goes through the same semver
# logic as `coqueiro update`, because git's version sort ranks `v0.1.0-rc.2` above
# `v0.1.0`. `COQUEIRO_CHANNEL=main` opts into the moving branch for bleeding-edge
# installs (those report as development and are never touched by `coqueiro update`).
if [ "$CHANNEL" = "main" ]; then
  log "Channel: main (bleeding edge — not tracked by 'coqueiro update')."
else
  LATEST_TAG="$(bun run scripts/latest-tag.ts "$DEFAULT_DIR" 2>/dev/null || true)"
  if [ -n "$LATEST_TAG" ]; then
    git checkout --detach "$LATEST_TAG" || fail "Could not check out stable tag $LATEST_TAG."
    log "Pinned to the newest stable tag: $LATEST_TAG"
  else
    warn "No stable tag (v*) found; staying on the current branch (development)."
  fi
fi

# The install above resolved the branch's lockfile; a release checkout can sit
# on a different tag with a different lockfile, so re-resolve before building.
if [ "$CHANNEL" != "main" ] && [ -n "${LATEST_TAG:-}" ]; then
  log "Installing the pinned release's dependencies..."
  bun install --frozen-lockfile || fail "bun install --frozen-lockfile failed for $LATEST_TAG."
fi

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
echo "${GREEN}Done!${NC} You can now run ${BLUE}${BIN_NAME}${NC} (or ${BLUE}cqro${NC}) from anywhere."