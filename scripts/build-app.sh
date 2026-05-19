#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="${APP_NAME:-CmdScrollZoom}"
APP_BUNDLE_IDENTIFIER="${APP_BUNDLE_IDENTIFIER:-com.jonathan.cmdscrollzoom}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-1}"
APP="$ROOT/$APP_NAME.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

codesign_identity() {
  if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    printf '%s\n' "$CODESIGN_IDENTITY"
    return
  fi

  security find-identity -v -p codesigning |
    awk -F'"' '
      /"Developer ID Application:/ { print $2; found=1; exit }
      /"Apple Development:/ && !candidate { candidate=$2 }
      END {
        if (!found && candidate) {
          print candidate
        }
      }
    '
}

osascript -e "tell application id \"$APP_BUNDLE_IDENTIFIER\" to quit" >/dev/null 2>&1 || true
pkill -x cmd-scroll-zoom >/dev/null 2>&1 || true
for _ in {1..30}; do
  if ! pgrep -x cmd-scroll-zoom >/dev/null 2>&1; then
    break
  fi
  sleep 0.1
done

swift build -c release --package-path "$ROOT" >&2

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp "$ROOT/.build/release/cmd-scroll-zoom" "$MACOS/cmd-scroll-zoom"

/usr/libexec/PlistBuddy -c "Clear dict" "$CONTENTS/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP_NAME" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP_NAME" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $APP_BUNDLE_IDENTIFIER" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $APP_BUILD_NUMBER" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $APP_VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string cmd-scroll-zoom" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleInfoDictionaryVersion string 6.0" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$CONTENTS/Info.plist"

chmod +x "$MACOS/cmd-scroll-zoom"
IDENTITY="$(codesign_identity)"
if [[ -n "$IDENTITY" ]]; then
  echo "Signing with $IDENTITY" >&2
  codesign --force --deep --sign "$IDENTITY" "$APP" >/dev/null
else
  echo "Signing ad-hoc because no Developer ID or Apple Development identity was found" >&2
  codesign --force --deep --sign - "$APP" >/dev/null
fi
echo "$APP"
