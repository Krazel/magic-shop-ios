#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DESTINATION="${MAGIC_SHOP_DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro}"

cd "$PROJECT_ROOT"
swift --version
xcodebuild -version

# Core-only verification: Package.swift deliberately excludes App/ and World/.
swift test

# iOS target and XCTest verification.
xcodebuild \
  -project MagicShop.xcodeproj \
  -scheme MagicShop \
  -configuration Debug \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  test
