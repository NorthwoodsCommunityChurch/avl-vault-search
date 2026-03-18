#!/bin/bash
set -euo pipefail

# Vault Search Build Script
# Builds the app using xcodegen + xcodebuild, signs it (including Sparkle), and creates a zip

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="VaultSearch"
SCHEME="VaultSearch"
BUILD_DIR="$SCRIPT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
APP_CONTENTS="$APP_PATH/Contents"

echo "=== Building $APP_NAME ==="

# Step 1: Generate Xcode project
echo "[1/5] Generating Xcode project..."
if ! command -v xcodegen &>/dev/null; then
    echo "Error: xcodegen not found. Install with: brew install xcodegen"
    exit 1
fi
xcodegen generate --quiet

# Step 2: Build
echo "[2/5] Building release..."
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

# Step 3: Clear extended attributes (OneDrive adds these)
echo "[3/5] Clearing extended attributes..."
xattr -cr "$APP_PATH"

# Step 4: Bundle Sparkle framework and sign everything
echo "[4/5] Signing Sparkle framework and app..."

# Find Sparkle framework from SPM build artifacts
SPARKLE_FW=$(find "$BUILD_DIR" -path "*/Sparkle.framework" -not -path "*/Intermediates/*" | head -1)
if [ -n "$SPARKLE_FW" ] && [ -d "$SPARKLE_FW" ]; then
    # Ensure Frameworks directory exists
    mkdir -p "$APP_CONTENTS/Frameworks"

    # Copy Sparkle framework (always fresh copy to avoid stale xattrs)
    rm -rf "$APP_CONTENTS/Frameworks/Sparkle.framework"
    cp -R "$SPARKLE_FW" "$APP_CONTENTS/Frameworks/"
    xattr -cr "$APP_CONTENTS/Frameworks/Sparkle.framework"

    # Add rpath so binary can find the framework
    install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_CONTENTS/MacOS/$APP_NAME" 2>/dev/null || true

    # Sign Sparkle nested components inside-out
    SPARKLE_B="$APP_CONTENTS/Frameworks/Sparkle.framework/Versions/B"
    if [ -d "$SPARKLE_B" ]; then
        [ -d "$SPARKLE_B/XPCServices/Installer.xpc" ] && codesign --force --sign - "$SPARKLE_B/XPCServices/Installer.xpc"
        [ -d "$SPARKLE_B/XPCServices/Downloader.xpc" ] && codesign --force --sign - "$SPARKLE_B/XPCServices/Downloader.xpc"
        [ -d "$SPARKLE_B/Updater.app" ] && codesign --force --sign - "$SPARKLE_B/Updater.app"
        [ -f "$SPARKLE_B/Autoupdate" ] && codesign --force --sign - "$SPARKLE_B/Autoupdate"
    fi
    codesign --force --sign - "$APP_CONTENTS/Frameworks/Sparkle.framework"
    echo "  Sparkle framework signed"
else
    echo "  Warning: Sparkle.framework not found in build artifacts"
fi

# Sign the app itself
codesign --force --deep --sign - "$APP_PATH"

# Step 5: Create zip
echo "[5/5] Creating zip..."
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_CONTENTS/Info.plist")
ZIP_NAME="VaultSearch-v${VERSION}-aarch64.zip"
cd "$BUILD_DIR/Build/Products/Release"
ditto -c -k --keepParent "$APP_NAME.app" "$SCRIPT_DIR/$ZIP_NAME"
cd "$SCRIPT_DIR"

echo ""
echo "=== Build Complete ==="
echo "App:     $APP_PATH"
echo "Zip:     $SCRIPT_DIR/$ZIP_NAME"
echo "Version: $VERSION"
