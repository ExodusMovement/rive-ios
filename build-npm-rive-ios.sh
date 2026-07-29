#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
NPM_PACKAGE_DIR="$PROJECT_ROOT/exodus-rive-ios-runtime"
XCFRAMEWORK_DIR="$PROJECT_ROOT/archive/RiveRuntime.xcframework"
PODSPEC_FILE="$NPM_PACKAGE_DIR/RiveRuntime.podspec"

DO_PUBLISH=true

# Parse flags
for arg in "$@"; do
  case $arg in
    --no-publish)
      DO_PUBLISH=false
      shift
      ;;
    *)
      echo "❓ Unknown option: $arg"
      echo "Usage: $0 [--publish]"
      exit 1
      ;;
  esac
done

# 1. Update submodule
echo "🔄 Updating rive-runtime submodule..."
git submodule init
git submodule update --remote -- submodules/rive-runtime

# 2. Clean & build
echo "🧹 Cleaning archive dir..."
rm -rf "$PROJECT_ROOT/archive"
echo "🚀 Building rive-ios runtime..."
PATH="$PWD/submodules/rive-runtime/build:$PATH" ./scripts/build.sh all release
./scripts/build_framework.sh -c Release

if [ ! -d "$XCFRAMEWORK_DIR" ]; then
  echo "❌ Build failed: $XCFRAMEWORK_DIR not found."
  exit 1
fi

# Strip demo riv file
find "$XCFRAMEWORK_DIR" -name 'rating_animation.riv' -print -delete || true

# 3. Copy xcframework to npm package
DEST_DIR="$NPM_PACKAGE_DIR"
echo "📦 Copying built xcframework to npm package..."
mkdir -p "$DEST_DIR"
rm -rf "$DEST_DIR/RiveRuntime.xcframework"
cp -R "$XCFRAMEWORK_DIR" "$DEST_DIR/"

echo "✅ Done! Copied to $DEST_DIR/RiveRuntime.xcframework"

# 3.5. SHA256 for reference
echo "🔑 SHA256 of built xcframework:"
( cd "$DEST_DIR" && tar -cf - RiveRuntime.xcframework | shasum -a 256 )

# 4. Version bump + publish if requested
BASE_VERSION=$(cat "$PROJECT_ROOT/VERSION")
PKG_JSON="$NPM_PACKAGE_DIR/package.json"

if [ ! -f "$PKG_JSON" ]; then
  echo "❌ package.json not found in $NPM_PACKAGE_DIR"
  exit 1
fi

CURRENT_VERSION=$(node -p "require('$PKG_JSON').version")

if [ "$DO_PUBLISH" = true ]; then
  if [ "$CURRENT_VERSION" == "$BASE_VERSION" ]; then
    IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
    patch=$((patch + 1))
    NEW_VERSION="$major.$minor.$patch"
  else
    NEW_VERSION="$BASE_VERSION"
  fi

  echo "🔢 Current version: $CURRENT_VERSION"
  echo "➡️  Publishing new version: $NEW_VERSION"

  # bump package.json
  npm version --no-git-tag-version "$NEW_VERSION" --prefix "$NPM_PACKAGE_DIR"

  # bump podspec
  sed -i.bak -E "s/spec.version[[:space:]]*=.*/spec.version      = \"$NEW_VERSION\"/" "$PODSPEC_FILE"
  rm -f "$PODSPEC_FILE.bak"

  # publish
  cd "$NPM_PACKAGE_DIR"
  npm publish --access public
  echo "✅ Published @exodus/rive-ios-runtime@$NEW_VERSION"

  # cleanup after publish
  echo "🗑️  Cleaning up built xcframework..."
  rm -rf "$DEST_DIR/RiveRuntime.xcframework"
  rm -rf "$PROJECT_ROOT/archive"
  echo "✅ Cleanup complete"
else
  echo "⚡ Build complete (no publish)"
fi
