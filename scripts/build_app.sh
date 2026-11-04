#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h:h}"
configuration="${1:-release}"
build_dir="$root_dir/Build"
app_dir="$build_dir/P5 Command Lab.app"

cd "$root_dir"
build_args=(-c "$configuration")
if [[ "$configuration" == "release" ]]; then
  build_args+=(--arch arm64 --arch x86_64)
fi
swift build "${build_args[@]}"
binary_dir="$(swift build "${build_args[@]}" --show-bin-path)"

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$binary_dir/P5CommandLab" "$app_dir/Contents/MacOS/P5CommandLab"
cp "$root_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
xcrun actool \
  --compile "$app_dir/Contents/Resources" \
  --platform macosx \
  --minimum-deployment-target 13.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$build_dir/asset-info.plist" \
  "$root_dir/Resources/Assets.xcassets"

signing_identity="${P5_SIGNING_IDENTITY:-}"
if [[ -z "$signing_identity" ]]; then
  signing_identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" '/Developer ID Application/ { print $2; exit }')"
fi
if [[ -z "$signing_identity" ]]; then
  signing_identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" 'NF >= 2 { print $2; exit }')"
fi

if [[ -n "$signing_identity" ]]; then
  codesign --force --deep --options runtime --sign "$signing_identity" "$app_dir"
  echo "Signed with stable identity: $signing_identity"
else
  codesign --force --sign - "$app_dir"
  echo "Warning: no signing identity was found; this development build is ad-hoc signed."
  echo "Keychain may ask again after the executable is rebuilt. Set P5_SIGNING_IDENTITY to use a stable identity."
fi

echo "$app_dir"
