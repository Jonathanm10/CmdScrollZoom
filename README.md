# CmdScrollZoom

CmdScrollZoom is a small macOS utility that turns `Command + scroll wheel` into native magnification events, similar to a trackpad pinch gesture.

It is meant for mice and apps that already support macOS pinch/magnification gestures, such as Safari, Preview, Maps, and many canvas or graphics apps.

## Features

- Menu-bar-only macOS app.
- `Command + vertical scroll` emits native magnification events.
- Horizontal scroll passes through unchanged.
- Menu-bar actions for `Relaunch` and `Quit`.
- Configurable modifier, sensitivity, inversion, and gesture end delay.
- Diagnostic mode for Accessibility/event-tap troubleshooting.

## Requirements

- macOS 13 or newer.
- Swift 5.9 or newer.
- Accessibility permission in `System Settings > Privacy & Security > Accessibility`.
- Input Monitoring permission may also be required on some macOS versions.

## Build

Build the command-line executable:

```sh
swift build -c release
```

Build the `.app` bundle:

```sh
scripts/build-app.sh
open CmdScrollZoom.app
```

The generated app bundle is intentionally ignored by Git.

## Develop

After changing code, rebuild and relaunch the app with:

```sh
scripts/relaunch-app.sh
```

The build script signs the app with the first available `Developer ID Application` identity, then the first available `Apple Development` identity. If no signing identity is available, it falls back to ad-hoc signing.

You can override signing and bundle settings:

```sh
CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)" scripts/relaunch-app.sh
APP_BUNDLE_IDENTIFIER="com.example.cmdscrollzoom" scripts/relaunch-app.sh
APP_NAME="CmdScrollZoomDev" scripts/relaunch-app.sh
```

macOS Accessibility permissions are tied to the app identity. If you change signing identity or bundle identifier, remove the old app entry from Accessibility once, relaunch, and approve the new identity.

## Troubleshooting Permissions

Run diagnostics:

```sh
CmdScrollZoom.app/Contents/MacOS/cmd-scroll-zoom --diagnose
```

Reset permissions for the current bundle identifier:

```sh
scripts/reset-permissions.sh
open CmdScrollZoom.app
```

Or reset a custom bundle identifier:

```sh
APP_BUNDLE_IDENTIFIER="com.example.cmdscrollzoom" scripts/reset-permissions.sh
```

## Command-Line Options

Run the built executable directly:

```sh
.build/release/cmd-scroll-zoom
```

Useful options:

```sh
.build/release/cmd-scroll-zoom --modifier ctrl
.build/release/cmd-scroll-zoom --sensitivity 0.018
.build/release/cmd-scroll-zoom --invert
.build/release/cmd-scroll-zoom --diagnose
```

Full usage:

```text
cmd-scroll-zoom [--modifier cmd|ctrl|option|shift] [--sensitivity 0.012] [--invert] [--end-delay 0.08] [--diagnose]
```

## Limitations

CmdScrollZoom only helps apps that respond to native macOS magnification events. Apps that implement zoom exclusively through `Command + +`, `Command + -`, or custom shortcuts may ignore it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

CmdScrollZoom is available under the MIT License. See [LICENSE](LICENSE).
