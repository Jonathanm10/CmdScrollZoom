#!/usr/bin/env bash
set -euo pipefail

osascript -e 'tell application "CmdScrollZoom" to quit' >/dev/null 2>&1 || true
pkill -x cmd-scroll-zoom >/dev/null 2>&1 || true

tccutil reset Accessibility com.jonathan.cmdscrollzoom >/dev/null 2>&1 || true
tccutil reset ListenEvent com.jonathan.cmdscrollzoom >/dev/null 2>&1 || true

echo "Permissions reset for com.jonathan.cmdscrollzoom"
echo "Now open CmdScrollZoom.app and re-enable it in Accessibility/Input Monitoring if macOS asks."
