#!/bin/zsh
# Builds "File to Address.app" into ./build. Pass --install to copy it to
# /Applications and launch it.
set -euo pipefail

cd "${0:A:h}/.."
APP_NAME="File to Address"
APP="build/${APP_NAME}.app"
# A stable signing identity keeps the Accessibility and Automation grants
# across rebuilds; ad-hoc signing ("-") would reset them every build.
SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -v -p codesigning | awk -F'"' '/Developer ID Application|Apple Development/ {print $2; exit}')}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/FileToAddress"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/FileToAddress"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key><string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key><string>com.johnalden.FileToAddress</string>
    <key>CFBundleExecutable</key><string>FileToAddress</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSAppleEventsUsageDescription</key><string>File to Address asks Finder for the path of the selected file.</string>
</dict>
</plist>
PLIST

codesign --force --options runtime --entitlements /dev/stdin --sign "$SIGN_IDENTITY" "$APP" <<ENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key><true/>
</dict>
</plist>
ENT
echo "Built $APP (signed: $SIGN_IDENTITY)"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x FileToAddress || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP" /Applications/
    open "/Applications/${APP_NAME}.app"
    echo "Installed to /Applications and launched"
fi
