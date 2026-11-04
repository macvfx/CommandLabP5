#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h:h}"
release_root="$root_dir/Release"
info_plist="$root_dir/Resources/Info.plist"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist")"
build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$info_plist")"
release_dir="$release_root/P5-Command-Lab-${version}+${build}"
stage_dir="$release_dir/stage"
app_source="$root_dir/Build/P5 Command Lab.app"
dmg="$release_dir/P5.Command.Lab-${version}.dmg"
checksum="$release_dir/P5.Command.Lab-${version}.sha256.txt"
receipt="$release_dir/P5.Command.Lab-${version}.release.txt"
notary_json="$release_dir/P5.Command.Lab-${version}.notary.json"
notary_profile="${MAC_APP_NOTARY_PROFILE:-notary-profile}"

mkdir -p "$release_dir" "$stage_dir"

cd "$root_dir"
swift test
zsh scripts/build_app.sh release

architectures="$(lipo -archs "$app_source/Contents/MacOS/P5CommandLab")"
[[ "$architectures" == *arm64* && "$architectures" == *x86_64* ]] || {
  echo "Release binary is not universal: $architectures" >&2
  exit 1
}

codesign --verify --deep --strict --verbose=2 "$app_source"

ditto "$app_source" "$stage_dir/P5 Command Lab.app"
hdiutil create \
  -volname "P5 Command Lab" \
  -srcfolder "$stage_dir" \
  -ov \
  -format UDZO \
  "$dmg"

signing_identity="${P5_SIGNING_IDENTITY:-}"
if [[ -z "$signing_identity" ]]; then
  signing_identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" '/Developer ID Application/ { print $2; exit }')"
fi
if [[ -z "$signing_identity" ]]; then
  signing_identity="$(security find-identity -v -p codesigning 2>/dev/null | awk -F\" 'NF >= 2 { print $2; exit }')"
fi
if [[ -n "$signing_identity" ]]; then
  codesign --force --timestamp --sign "$signing_identity" "$dmg"
fi

notary_status="Not attempted"
notary_id="—"
if xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1; then
  if xcrun notarytool submit "$dmg" \
      --keychain-profile "$notary_profile" \
      --wait \
      --output-format json > "$notary_json"; then
    notary_status="$(plutil -extract status raw -o - "$notary_json" 2>/dev/null || echo Unknown)"
    notary_id="$(plutil -extract id raw -o - "$notary_json" 2>/dev/null || echo Unknown)"
    if [[ "$notary_status" == "Accepted" ]]; then
      xcrun stapler staple "$dmg"
      xcrun stapler validate "$dmg"
    fi
  else
    notary_status="Submission failed"
  fi
else
  notary_status="Keychain profile unavailable"
fi

shasum -a 256 "$dmg" > "$checksum"
{
  echo "P5 Command Lab release"
  echo "Version: $version"
  echo "Build: $build"
  echo "Architectures: $architectures"
  echo "Notarization: $notary_status"
  echo "Notarization ID: $notary_id"
  echo "DMG: ${dmg:t}"
  echo "SHA-256: $(awk '{print $1}' "$checksum")"
} > "$receipt"

if [[ "$notary_status" == "Accepted" ]]; then
  spctl --assess --type open --context context:primary-signature -v "$dmg"
else
  echo "Notarization did not complete; the signed Release DMG remains available for manual notarization." >&2
fi

echo "$dmg"
echo "$checksum"
echo "$receipt"
