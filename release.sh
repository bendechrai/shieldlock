#!/bin/bash
set -e

# 1. Prompt for version
read -p "Enter release version (e.g., 1.0.0): " VERSION
if [ -z "$VERSION" ]; then
    echo "Version cannot be empty."
    exit 1
fi

TAG="v$VERSION"

# 2. Check git status is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Git working directory is not clean. Please commit or stash your changes first."
    exit 1
fi

# 3. Build the application
echo "Building ShieldLock in release mode..."
./build.sh

# 4. Package the app bundle
echo "Packaging ShieldLock.app into zip..."
if [ -f "ShieldLock.zip" ]; then
    rm ShieldLock.zip
fi
cd build
zip -q -r ../ShieldLock.zip ShieldLock.app
cd ..

# 5. Compute SHA256 checksum
SHA256=$(shasum -a 256 ShieldLock.zip | awk '{print $1}')
echo "Created ShieldLock.zip successfully."
echo "SHA256 checksum: $SHA256"

# 6. Create and push Git tag
echo "Creating Git tag $TAG..."
git tag -a "$TAG" -m "Release $TAG"
git push origin "$TAG"

# 7. Create GitHub Release and upload assets
echo "Creating GitHub release $TAG..."
gh release create "$TAG" ./ShieldLock.zip --title "$TAG" --notes "Release version $VERSION"

# 8. Output Homebrew Cask snippet
echo ""
echo "=========================================================="
echo "Release $TAG successfully created on GitHub!"
echo "=========================================================="
echo "Copy the snippet below to update your Homebrew Cask tap:"
echo ""
echo "cask \"shieldlock\" do"
echo "  version \"$VERSION\""
echo "  sha256 \"$SHA256\""
echo ""
echo "  url \"https://github.com/bendechrai/shieldlock/releases/download/v#{version}/ShieldLock.zip\""
echo "  name \"ShieldLock\""
echo "  desc \"Transparent screen locker for macOS\""
echo "  homepage \"https://github.com/bendechrai/shieldlock\""
echo ""
echo "  app \"ShieldLock.app\""
echo "end"
echo "=========================================================="
echo ""

# 9. Clean up temporary zip file
rm ShieldLock.zip
