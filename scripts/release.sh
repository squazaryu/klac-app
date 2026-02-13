#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<USAGE
Usage:
  ./scripts/release.sh v1.0.0 [--notes-file path] [--dry-run] [--skip-push]

Examples:
  ./scripts/release.sh v1.0.0
  ./scripts/release.sh v1.0.1 --notes-file RELEASE_NOTES.md
  ./scripts/release.sh v1.0.2 --dry-run
USAGE
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

VERSION=""
NOTES_FILE=""
DRY_RUN=0
SKIP_PUSH=0

while [ $# -gt 0 ]; do
  case "$1" in
    v*)
      VERSION="$1"
      ;;
    --notes-file)
      shift
      NOTES_FILE="${1:-}"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --skip-push)
      SKIP_PUSH=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [ -z "$VERSION" ]; then
  echo "Error: version is required (format: vX.Y.Z)"
  exit 1
fi

if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must match vX.Y.Z"
  exit 1
fi

if [ -n "$NOTES_FILE" ] && [ ! -f "$NOTES_FILE" ]; then
  echo "Error: notes file not found: $NOTES_FILE"
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: worktree is not clean. Commit or stash changes first."
  exit 1
fi

if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "Error: tag already exists locally: $VERSION"
  exit 1
fi

if git ls-remote --tags origin "refs/tags/$VERSION" | grep -q "$VERSION"; then
  echo "Error: tag already exists on remote: $VERSION"
  exit 1
fi

VERSION_NO_V="${VERSION#v}"
BUILD_NUMBER="$(date +%Y%m%d%H%M)"
ZIP_PATH="$ROOT_DIR/dist/Klac-${VERSION}.zip"
APP_PATH="$ROOT_DIR/dist/Klac.app"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] Would build app for version $VERSION_NO_V (build $BUILD_NUMBER)"
  echo "[dry-run] Would package zip: $ZIP_PATH"
  echo "[dry-run] Would create tag: $VERSION"
  if [ "$SKIP_PUSH" -eq 0 ]; then
    echo "[dry-run] Would push main and $VERSION"
    echo "[dry-run] Would create GitHub release with asset"
  fi
  exit 0
fi

APP_VERSION="$VERSION_NO_V" BUILD_NUMBER="$BUILD_NUMBER" ./scripts/build_app.sh

rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

git tag -a "$VERSION" -m "Release $VERSION"

if [ "$SKIP_PUSH" -eq 0 ]; then
  git push origin main
  git push origin "$VERSION"

  if [ -n "$NOTES_FILE" ]; then
    gh release create "$VERSION" "$ZIP_PATH" --title "$VERSION" --notes-file "$NOTES_FILE"
  else
    gh release create "$VERSION" "$ZIP_PATH" --title "$VERSION" --generate-notes
  fi

  echo "Release published: $VERSION"
  echo "Asset: $ZIP_PATH"
else
  echo "Created local tag only: $VERSION"
  echo "Asset built: $ZIP_PATH"
fi
