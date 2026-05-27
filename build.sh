#!/bin/bash
set -e

swift build -c release

rm -rf build/
mkdir -p build/ShieldLock.app/Contents/MacOS
mkdir -p build/ShieldLock.app/Contents/Resources

# Generate macOS .icns file from docs/logo.png
if [ -f "docs/logo.png" ]; then
    echo "Generating macOS application icon..."
    mkdir -p ShieldLock.iconset
    sips -z 16 16     docs/logo.png --out ShieldLock.iconset/icon_16x16.png > /dev/null 2>&1
    sips -z 32 32     docs/logo.png --out ShieldLock.iconset/icon_16x16@2x.png > /dev/null 2>&1
    sips -z 32 32     docs/logo.png --out ShieldLock.iconset/icon_32x32.png > /dev/null 2>&1
    sips -z 64 64     docs/logo.png --out ShieldLock.iconset/icon_32x32@2x.png > /dev/null 2>&1
    sips -z 128 128   docs/logo.png --out ShieldLock.iconset/icon_128x128.png > /dev/null 2>&1
    sips -z 256 256   docs/logo.png --out ShieldLock.iconset/icon_128x128@2x.png > /dev/null 2>&1
    sips -z 256 256   docs/logo.png --out ShieldLock.iconset/icon_256x256.png > /dev/null 2>&1
    sips -z 512 512   docs/logo.png --out ShieldLock.iconset/icon_256x256@2x.png > /dev/null 2>&1
    sips -z 512 512   docs/logo.png --out ShieldLock.iconset/icon_512x512.png > /dev/null 2>&1
    sips -z 1024 1024 docs/logo.png --out ShieldLock.iconset/icon_512x512@2x.png > /dev/null 2>&1
    
    iconutil -c icns ShieldLock.iconset
    mv ShieldLock.icns build/ShieldLock.app/Contents/Resources/ShieldLock.icns
    rm -rf ShieldLock.iconset
fi

BIN_PATH=$(swift build -c release --show-bin-path)
cp "${BIN_PATH}/ShieldLock" build/ShieldLock.app/Contents/MacOS/ShieldLock

cat << 'EOF' > build/ShieldLock.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>ShieldLock</string>
	<key>CFBundleIconFile</key>
	<string>ShieldLock</string>
	<key>CFBundleIdentifier</key>
	<string>com.shieldlock.ShieldLock</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>ShieldLock</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSFaceIDUsageDescription</key>
	<string>ShieldLock requires Face ID / Touch ID permission to unlock your screen overlay.</string>
</dict>
</plist>
EOF

codesign --force --deep --sign - build/ShieldLock.app
