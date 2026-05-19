import ApplicationServices
import AppKit
import CoreGraphics
import Foundation

private enum IOHIDPhase {
    static let began: Int64 = 1 << 0
    static let changed: Int64 = 1 << 1
    static let ended: Int64 = 1 << 2
}

private struct Config {
    var modifier: CGEventFlags = .maskCommand
    var sensitivity: Double = 0.012
    var invert: Bool = false
    var endDelay: TimeInterval = 0.08
    var diagnose = false
}

private final class CmdScrollZoom {
    private let config: Config
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var retryTimer: Timer?
    private var endingWorkItem: DispatchWorkItem?
    private var gestureIsActive = false
    private var didLogWaitingForPermissions = false

    init(config: Config) {
        self.config = config
    }

    func start() {
        requestAccessibilityIfNeeded()

        if installEventTap() {
            logActive()
            return
        }

        logWaitingForPermissions()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            if self.installEventTap() {
                timer.invalidate()
                self.retryTimer = nil
                self.logActive()
            }
        }
    }

    func stop() {
        retryTimer?.invalidate()
        retryTimer = nil
        finishGestureIfNeeded()

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
    }

    private func logWaitingForPermissions() {
        guard !didLogWaitingForPermissions else {
            return
        }

        didLogWaitingForPermissions = true
        fputs(
            """
            En attente des permissions macOS.
            Autorise CmdScrollZoom dans System Settings > Privacy & Security > Accessibility.
            Selon ta version de macOS, Input Monitoring peut aussi etre necessaire.

            """,
            stderr
        )
    }

    private func logActive() {
        print("cmd-scroll-zoom actif. \(modifierLabel(config.modifier)) + molette = pinch zoom.")
    }

    private func installEventTap() -> Bool {
        if eventTap != nil {
            return true
        }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: refcon
        )

        guard let eventTap else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }

        let flags = currentModifierFlags(event: event)
        guard flags.contains(config.modifier) else {
            finishGestureIfNeeded()
            return Unmanaged.passUnretained(event)
        }

        let delta = scrollDelta(from: event)
        guard delta != 0 else {
            return nil
        }

        let sign: Double = config.invert ? -1 : 1
        let magnification = delta * config.sensitivity * sign

        if !gestureIsActive {
            postMagnification(0, phase: IOHIDPhase.began)
        }

        gestureIsActive = true

        postMagnification(magnification, phase: IOHIDPhase.changed)
        scheduleGestureEnd()

        return nil
    }

    private func postMagnification(_ magnification: Double, phase: Int64) {
        guard let event = CGEvent(source: nil) else {
            return
        }

        event.type = CGEventType(rawValue: 29) ?? .null
        event.setIntegerValueField(CGEventField(rawValue: 110)!, value: 8)
        event.setIntegerValueField(CGEventField(rawValue: 132)!, value: phase)
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification)
        event.post(tap: .cghidEventTap)
    }

    private func scheduleGestureEnd() {
        endingWorkItem?.cancel()

        let item = DispatchWorkItem { [weak self] in
            self?.finishGestureIfNeeded()
        }
        endingWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + config.endDelay, execute: item)
    }

    private func finishGestureIfNeeded() {
        guard gestureIsActive else {
            return
        }

        endingWorkItem?.cancel()
        endingWorkItem = nil
        postMagnification(0, phase: IOHIDPhase.ended)
        gestureIsActive = false
    }
}

private func currentModifierFlags(event: CGEvent) -> CGEventFlags {
    let modifierMask: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
    let eventFlags = event.flags.intersection(modifierMask)
    if !eventFlags.isEmpty {
        return eventFlags
    }

    return CGEventSource.flagsState(.hidSystemState).intersection(modifierMask)
}

private func scrollDelta(from event: CGEvent) -> Double {
    let lineDelta = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
    if lineDelta != 0 {
        return Double(lineDelta)
    }

    let pointDelta = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
    if pointDelta != 0 {
        return Double(pointDelta) / 10
    }

    let fixedPointDelta = event.getIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1)
    if fixedPointDelta != 0 {
        return Double(fixedPointDelta) / 65536
    }

    return 0
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let app = Unmanaged<CmdScrollZoom>.fromOpaque(userInfo).takeUnretainedValue()
    return app.handle(type: type, event: event)
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let zoom: CmdScrollZoom

    init(config: Config) {
        self.zoom = CmdScrollZoom(config: config)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        zoom.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        zoom.stop()
    }
}

private func requestAccessibilityIfNeeded() {
    guard !AXIsProcessTrusted() else {
        return
    }

    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
}

private func runDiagnostics(config: Config) -> Never {
    print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "<none>")")
    print("Executable: \(CommandLine.arguments.first ?? "<unknown>")")
    print("AX trusted: \(AXIsProcessTrusted())")

    let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
    let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
        userInfo: nil
    )

    print("Session event tap: \(tap == nil ? "FAILED" : "OK")")

    if let tap {
        CFMachPortInvalidate(tap)
    }

    print("Modifier: \(modifierLabel(config.modifier))")
    print("Sensitivity: \(config.sensitivity)")
    exit(tap == nil ? 1 : 0)
}

private func parseConfig() -> Config {
    var config = Config()
    var args = Array(CommandLine.arguments.dropFirst())

    while let arg = args.first {
        args.removeFirst()

        switch arg {
        case "--modifier":
            guard let value = args.first else {
                usageAndExit()
            }
            args.removeFirst()
            config.modifier = parseModifier(value)
        case "--sensitivity":
            guard let value = args.first, let number = Double(value), number > 0 else {
                usageAndExit()
            }
            args.removeFirst()
            config.sensitivity = number
        case "--invert":
            config.invert = true
        case "--end-delay":
            guard let value = args.first, let number = Double(value), number > 0 else {
                usageAndExit()
            }
            args.removeFirst()
            config.endDelay = number
        case "--diagnose":
            config.diagnose = true
        case "--help", "-h":
            usageAndExit(status: 0)
        default:
            usageAndExit()
        }
    }

    return config
}

private func parseModifier(_ value: String) -> CGEventFlags {
    switch value.lowercased() {
    case "cmd", "command":
        return .maskCommand
    case "ctrl", "control":
        return .maskControl
    case "opt", "option", "alt":
        return .maskAlternate
    case "shift":
        return .maskShift
    default:
        usageAndExit()
    }
}

private func modifierLabel(_ flags: CGEventFlags) -> String {
    if flags == .maskCommand { return "Cmd" }
    if flags == .maskControl { return "Ctrl" }
    if flags == .maskAlternate { return "Option" }
    if flags == .maskShift { return "Shift" }
    return "Modifier"
}

private func usageAndExit(status: Int32 = 2) -> Never {
    print(
        """
        Usage:
          cmd-scroll-zoom [--modifier cmd|ctrl|option|shift] [--sensitivity 0.012] [--invert] [--end-delay 0.08] [--diagnose]

        Examples:
          cmd-scroll-zoom
          cmd-scroll-zoom --modifier ctrl --sensitivity 0.018
          cmd-scroll-zoom --invert
          cmd-scroll-zoom --diagnose
        """
    )
    exit(status)
}

private let config = parseConfig()

if config.diagnose {
    runDiagnostics(config: config)
}

private let delegate = AppDelegate(config: config)
private let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
