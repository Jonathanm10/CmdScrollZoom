# CmdScrollZoom

Mini utilitaire macOS: transforme `Cmd + molette` en evenement de magnification, comme un pinch trackpad, sans les autres fonctions de Mac Mouse Fix.

## Build

```sh
swift build -c release
```

## App visible pour les permissions macOS

Le plus simple est de construire le bundle `.app`:

```sh
scripts/build-app.sh
open CmdScrollZoom.app
```

L'app reste dans:

```sh
/Users/jonathan/Perso/CmdScrollZoom/CmdScrollZoom.app
```

Tu peux aussi la montrer directement dans Finder:

```sh
open -R /Users/jonathan/Perso/CmdScrollZoom/CmdScrollZoom.app
```

Autorise `CmdScrollZoom.app` dans `System Settings > Privacy & Security > Accessibility`. Selon ta version de macOS, `Input Monitoring` peut aussi etre necessaire.

Si macOS continue a ouvrir les permissions alors que l'app est deja cochee, reset l'entree TCC:

```sh
scripts/reset-permissions.sh
open CmdScrollZoom.app
```

Diagnostic:

```sh
CmdScrollZoom.app/Contents/MacOS/cmd-scroll-zoom --diagnose
```

## Lancer

```sh
.build/release/cmd-scroll-zoom
```

Options utiles:

```sh
.build/release/cmd-scroll-zoom --modifier ctrl
.build/release/cmd-scroll-zoom --sensitivity 0.018
.build/release/cmd-scroll-zoom --invert
```

macOS doit autoriser le binaire ou l'app dans `System Settings > Privacy & Security > Accessibility`. Selon la version de macOS, `Input Monitoring` peut aussi etre necessaire.

Le zoom fonctionne dans les apps qui reagissent au geste pinch/magnification macOS, par exemple Safari, Preview/Apercu, Maps, certains canvas et apps graphiques. Les apps qui n'ecoutent que `Cmd + +` ou leur propre systeme de zoom peuvent l'ignorer.
