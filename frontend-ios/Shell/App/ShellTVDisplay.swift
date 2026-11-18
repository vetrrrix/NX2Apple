import Foundation
import ShellUI

/// The external-display setting's door for ShellMain.m (Objective-C): what the TV scene's hand-off reads (`mode`), and
/// where the engine's in-game-menu pick of `DM_TV_DISPLAY` lands (`applyEngineValue`). The value lives in
/// `ShellSettingsStore`, so the settings row, the menu and the hand-off read one place.
@objc(ShellTVDisplay)
final class ShellTVDisplay: NSObject {
    /// 0 = phone only (the display never gets the window), 1 = TV at 720p (the game stays handheld), 2 = TV at 1080p (docked).
    @objc static var mode: Int {
        switch ShellSettingsStore.current.tvDisplay {
        case "off": return 0
        case "720p": return 1
        default: return 2
        }
    }

    /// The change notification's name as ShellMain.m wants it (a string; Swift code uses `ShellSettingsStore.tvDisplayDidChange`).
    @objc static var changeNotificationName: String { ShellSettingsStore.tvDisplayDidChange.rawValue }

    /// The engine's pick of `DM_TV_DISPLAY`: store it, and the change notification re-runs the hand-off — the picture
    /// moves to the display, comes back to the phone, or changes mode without undocking.
    @objc(applyEngineValue:) static func apply(engineValue: String) {
        ShellSettingsStore.current.storeTVDisplay(engineValue)
    }
}
