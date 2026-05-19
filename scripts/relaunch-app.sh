#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="${APP_NAME:-CmdScrollZoom}"
APP="$ROOT/$APP_NAME.app"

"$ROOT/scripts/build-app.sh" >/dev/null
open -n "$APP"
echo "Relaunched $APP"
