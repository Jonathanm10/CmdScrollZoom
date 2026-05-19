#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-CmdScrollZoom}"
APP_BUNDLE_IDENTIFIER="${APP_BUNDLE_IDENTIFIER:-com.jonathan.cmdscrollzoom}"

osascript -e "tell application id \"$APP_BUNDLE_IDENTIFIER\" to quit" >/dev/null 2>&1 || true
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
pkill -x cmd-scroll-zoom >/dev/null 2>&1 || true

tccutil reset Accessibility "$APP_BUNDLE_IDENTIFIER" >/dev/null 2>&1 || true
tccutil reset ListenEvent "$APP_BUNDLE_IDENTIFIER" >/dev/null 2>&1 || true

echo "Permissions reset for $APP_BUNDLE_IDENTIFIER"
echo "Now open $APP_NAME.app and re-enable it in Accessibility/Input Monitoring if macOS asks."
