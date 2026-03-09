#!/bin/bash
set -euo pipefail

# Vault Search Build Script
# Builds the app using xcodegen + xcodebuild, signs it, and creates a zip

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="VaultSearch"
SCHEME="VaultSearch"
BUILD_DIR="$SCRIPT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

echo "=== Building $APP_NAME ==="

# Step 1: Generate Xcode project
echo "[1/4] Generating Xcode project..."
if ! command -v xcodegen &>/dev/null; then
    echo "Error: xcodegen not found. Install with: brew install xcodegen"
    exit 1
fi
xcodegen generate --quiet

# Step 2: Build
echo "[2/4] Building release..."
xcodebuild \
    -project "$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -quiet \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build failed - $APP_PATH not found"
    exit 1
fi

# Step 3: Clear extended attributes (OneDrive adds these) and sign
echo "[3/4] Signing app..."
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"

# Step 4: Create zip
echo "[4/4] Creating zip..."
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
ZIP_NAME="VaultSearch-v${VERSION}-aarch64.zip"
cd "$BUILD_DIR/Build/Products/Release"
ditto -c -k --keepParent "$APP_NAME.app" "$SCRIPT_DIR/$ZIP_NAME"
cd "$SCRIPT_DIR"

echo ""
echo "=== Build Complete ==="
echo "App:     $APP_PATH"
echo "Zip:     $SCRIPT_DIR/$ZIP_NAME"
echo "Version: $VERSION"
