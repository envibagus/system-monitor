#!/bin/bash
set -euo pipefail

# Build System Monitor as a proper .app bundle
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="System Monitor"
BUNDLE_ID="com.systemmonitor.app"
BUILD_DIR="$PROJECT_DIR/.build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

echo "Building SystemMonitor..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

BINARY="$BUILD_DIR/release/SystemMonitor"
if [ ! -f "$BINARY" ]; then
    # Fallback to arch-specific path
    BINARY=$(find "$BUILD_DIR" -name "SystemMonitor" -type f -path "*/release/*" | head -1)
fi

if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found after build"
    exit 1
fi

echo "Creating app bundle..."

# Clean previous bundle
rm -rf "$APP_DIR"

# Create bundle structure
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_DIR/Contents/MacOS/SystemMonitor"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SystemMonitor</string>
    <key>CFBundleIdentifier</key>
    <string>com.systemmonitor.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>System Monitor</string>
    <key>CFBundleDisplayName</key>
    <string>System Monitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST

# Create PkgInfo
echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

echo ""
echo "App bundle created at: $APP_DIR"
echo ""
echo "To install: cp -r \"$APP_DIR\" /Applications/"
echo "To run:     open \"$APP_DIR\""
