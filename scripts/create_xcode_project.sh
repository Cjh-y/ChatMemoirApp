#!/bin/bash
# This script creates an Xcode project for ChatMemoirApp and opens it.
# Once opened, you can Product → Archive → Export IPA.

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Opening ChatMemoirApp in Xcode..."
echo ""
echo "In Xcode:"
echo "  1. Select scheme: ChatMemoirApp"
echo "  2. Select destination: Any iOS Device (or your connected iPhone)"
echo "  3. Product → Archive"
echo "  4. In the Organizer, click 'Distribute App'"
echo "  5. Choose 'Development' or 'Ad Hoc'"
echo "  6. Export IPA"
echo ""

open "$PROJECT_DIR/Package.swift"
