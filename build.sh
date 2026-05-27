#!/bin/bash
set -e

swift build -c release

rm -rf build/
mkdir -p build/ShieldLock.app/Contents/MacOS
mkdir -p build/ShieldLock.app/Contents/Resources

BIN_PATH=$(swift build -c release --show-bin-path)
cp "${BIN_PATH}/ShieldLock" build/ShieldLock.app/Contents/MacOS/ShieldLock

cat << 'EOF' > build/ShieldLock.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
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
