#!/bin/bash
set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="ChatMemoirApp"

echo "=== ChatMemoir IPA Builder ==="
echo ""

killall xcodebuild 2>/dev/null || true

echo "[1/3] Resolving packages..."
cd "$PROJECT_DIR"
xcodebuild -resolvePackageDependencies -scheme "$SCHEME" 2>&1 | tail -3

echo ""
echo "[2/3] Building for iOS Simulator (requires Xcode)..."
echo ""

xcodebuild build \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    2>&1 | grep -E "error:|warning:|Build succeeded|BUILD" | head -20

BUILD_EXIT=${PIPESTATUS[0]}

echo ""
if [ $BUILD_EXIT -eq 0 ]; then
    echo "✅ Simulator build succeeded!"
    echo ""
    echo "To create IPA for device:"
    echo "  1. Open Package.swift in Xcode"
    echo "  2. Select Product > Archive"
    echo "  3. Distribute App > Development"
else
    echo "⚠️  Build had issues. Open in Xcode to debug:"
    echo "  open $PROJECT_DIR/Package.swift"
fi
