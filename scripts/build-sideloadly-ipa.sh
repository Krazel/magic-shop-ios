#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${MAGIC_SHOP_DERIVED_DATA:-${RUNNER_TEMP:-$PROJECT_ROOT/.build}/MagicShopDeviceDerivedData}"
IPA_OUTPUT="${MAGIC_SHOP_IPA_OUTPUT:-$PROJECT_ROOT/outputs/MagicShop-unsigned-sideloadly.ipa}"
PACKAGE_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$PACKAGE_ROOT"
}
trap cleanup EXIT

mkdir -p "$(dirname "$IPA_OUTPUT")" "$PACKAGE_ROOT/Payload"

xcodebuild build \
  -project "$PROJECT_ROOT/MagicShop.xcodeproj" \
  -scheme MagicShop \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release-iphoneos/MagicShop.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected device app was not produced at: $APP_PATH" >&2
  exit 1
fi

ditto "$APP_PATH" "$PACKAGE_ROOT/Payload/MagicShop.app"
rm -f "$IPA_OUTPUT"
ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_ROOT/Payload" "$IPA_OUTPUT"

echo "Created unsigned Sideloadly IPA: $IPA_OUTPUT"
