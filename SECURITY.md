# Security Policy

CmdScrollZoom uses macOS Accessibility APIs and a session event tap to translate mouse scroll input into native magnification events.

## Reporting a Vulnerability

Please report security issues privately by opening a GitHub security advisory if the repository has advisories enabled. If not, contact the maintainer directly through the repository owner's public GitHub profile.

Do not include exploit details in a public issue until the issue has been reviewed.

## Privacy Notes

CmdScrollZoom does not intentionally collect, store, or transmit user data.

The app listens for scroll-wheel events through a macOS event tap. It uses those events only to detect the configured modifier plus scroll gesture and post magnification events locally.
