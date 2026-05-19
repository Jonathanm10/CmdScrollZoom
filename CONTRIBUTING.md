# Contributing

Thanks for taking the time to improve CmdScrollZoom.

## Development Setup

You need macOS 13 or newer and Swift 5.9 or newer.

Build the executable:

```sh
swift build -c release
```

Build and relaunch the app bundle:

```sh
scripts/relaunch-app.sh
```

The app needs Accessibility permission before event taps can work. Some macOS versions may also require Input Monitoring permission.

## Signing

Local development can use an Apple Development certificate or ad-hoc signing. The build script selects a signing identity automatically when one is available.

To avoid colliding with another installed copy, use your own bundle identifier:

```sh
APP_BUNDLE_IDENTIFIER="com.example.cmdscrollzoom" scripts/relaunch-app.sh
```

## Validation

Before opening a pull request, run:

```sh
swift build -c release
bash -n scripts/build-app.sh
bash -n scripts/relaunch-app.sh
bash -n scripts/reset-permissions.sh
```

For event-tap diagnostics:

```sh
CmdScrollZoom.app/Contents/MacOS/cmd-scroll-zoom --diagnose
```

## Pull Requests

- Keep changes focused.
- Do not commit generated `.app` bundles or `.build` output.
- Include testing notes, especially for macOS permission or event-tap behavior.
- Document user-facing behavior changes in `README.md`.
