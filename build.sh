#!/bin/bash

# Configuration
APP_NAME="nosleep"
BUNDLE_ID="com.fut.${APP_NAME}"
BUILD_DIR=".build"

APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

# 1. Clean previous build
rm -rf "${APP_BUNDLE}"

# 2. Build the executable with SwiftPM
swift build -c debug --product "${APP_NAME}"

# 3. Create .app bundle structure
mkdir -p "${MACOS}" "${RESOURCES}"

# 4. Copy the executable
cp -f "${BUILD_DIR}/debug/${APP_NAME}" "${MACOS}/"

# 5. Generate a minimal Info.plist WITH the usage description
cat > "${CONTENTS}/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSUserNotificationUsageDescription</key>
    <string>This app sends you reminders to shut down your laptop and get some rest.</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Notes on the Info.plist:
# last LSUIElement key makes the app run in the background without a dock icon or menu bar

# (will be added in future if needed)
# cp -f Assets/AppIcon.icns "${RESOURCES}/"

echo "\nApp bundle created at ${APP_BUNDLE}"

codesign --force --deep --sign - "${APP_BUNDLE}"

echo "\nApp bundle signed with ad-hoc ✨"
echo "Run with: open ${APP_BUNDLE}"