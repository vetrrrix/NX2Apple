import Foundation
import Testing
@testable import ShellUI

@MainActor @Suite struct ShellUXFeaturesTests {
    @Test func joiningGameDataStateCarriesProgressStringsAndLocksPlay() {
        let state = GameState.joiningGameData(percent: 45, doneSize: "2.3 GB", totalSize: "5.1 GB")
        #expect(state.isJoining)
        #expect(!GameState.needsGameData.isJoining)
        #expect(!GameState.playable.isJoining)
        #expect(state.artworkWarning == "Joining Data")
        #expect(state.title == "Joining game data (45%)")
        #expect(state.actionTitle == "Joining game data (45%)")
        #expect(state.explanation.contains("2.3 GB"))
        #expect(state.explanation.contains("5.1 GB"))
    }

    @Test func padMergePersistsInShellSettingsStoreAndProducesDMPadMerge() {
        let suite = "shellui.padmerge.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { UserDefaults().removePersistentDomain(forName: suite) }

        let store = ShellSettingsStore(defaults: defaults)
        #expect(!store.padMerge)
        #expect(store.gameDefaults["DM_PAD_MERGE"] == nil)

        store.storePadMerge(true)
        #expect(store.padMerge)
        #expect(store.gameDefaults["DM_PAD_MERGE"] == "1")
        #expect(ShellSettingsStore(defaults: defaults).padMerge)

        store.storePadMerge(false)
        #expect(!store.padMerge)
        #expect(store.gameDefaults["DM_PAD_MERGE"] == nil)
    }

    @Test func audioMixPersistsInShellSettingsStoreAndProducesDMAudioMix() {
        let suite = "shellui.audiomix.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { UserDefaults().removePersistentDomain(forName: suite) }

        let store = ShellSettingsStore(defaults: defaults)
        #expect(!store.audioMix)
        #expect(store.gameDefaults["DM_AUDIO_MIX"] == nil)
        #expect(ShellSettingsRows.audioMixRow(store).value == "0")

        ShellSettingsRows.apply(ShellSettingsRows.audioMix, value: "1", to: store)
        #expect(store.audioMix)
        #expect(store.gameDefaults["DM_AUDIO_MIX"] == "1")
        #expect(ShellSettingsRows.audioMixRow(store).value == "1")
        #expect(ShellSettingsStore(defaults: defaults).audioMix)

        ShellSettingsRows.apply(ShellSettingsRows.audioMix, value: "0", to: store)
        #expect(!store.audioMix)
        #expect(store.gameDefaults["DM_AUDIO_MIX"] == nil)
        #expect(defaults.object(forKey: ShellSettingsStore.audioMixKey) == nil)
    }

    @Test
    func showFPSPersistsInShellSettingsStoreAndProducesDMShowFPS() {
        let suite = "dev.nx2apple.tests.ux.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ShellSettingsStore(defaults: defaults)
        #expect(store.showFPS == nil)
        #expect(store.gameDefaults["DM_SHOW_FPS"] == nil)

        store.storeShowFPS(true)
        #expect(store.showFPS == true)
        #expect(store.gameDefaults["DM_SHOW_FPS"] == "1")
        #expect(ShellSettingsRows.showFPSRow(store).value == "1")
        #expect(defaults.object(forKey: ShellSettingsStore.showFPSKey) as? Bool == true)

        ShellSettingsRows.apply(ShellSettingsRows.showFPS, value: "0", to: store)
        #expect(store.showFPS == false)
        #expect(store.gameDefaults["DM_SHOW_FPS"] == "0")
        #expect(defaults.object(forKey: ShellSettingsStore.showFPSKey) as? Bool == false)

        let row = ShellSettingsRows.showFPSRow(store)
        #expect(row.id == ShellSettingsRows.showFPS)
        #expect(row.value == "0")
    }

    /// The external-display row (PLAN section 3): one row of three states, the docked 1080p default never stored, and a
    /// pick from the list reaching the store (which notifies so the picture can move at once).
    @Test func externalDisplayRowOffersThreeModesAndAppliesTheChoice() {
        let suite = "shellui.tvdisplay.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ShellSettingsStore(defaults: defaults)
        let row = ShellSettingsRows.tvDisplayRow(store)
        #expect(row.id == ShellSettingsRows.tvDisplay && row.value == "1080p")
        guard case .choice(let options) = row.kind else {
            Issue.record("the external display opens a list of choices")
            return
        }
        #expect(options.map(\.id) == ["off", "720p", "1080p"])
        #expect(options.map(\.label) == ["Phone only", "TV · 720p (light)", "TV · 1080p (docked)"])

        ShellSettingsRows.apply(ShellSettingsRows.tvDisplay, value: "720p", to: store)
        #expect(store.tvDisplay == "720p")
        #expect(ShellSettingsRows.tvDisplayRow(store).value == "720p")

        ShellSettingsRows.apply(ShellSettingsRows.tvDisplay, value: "hdmi", to: store)
        #expect(store.tvDisplay == "720p", "a mode the row does not offer is not stored")

        ShellSettingsRows.apply(ShellSettingsRows.tvDisplay, value: "1080p", to: store)
        #expect(store.tvDisplay == "1080p" && defaults.object(forKey: ShellSettingsStore.tvDisplayKey) == nil)
    }

    @Test func cloudConflictAndRestoreBackupLayersIsolateControllerFocus() {
        #expect(!LibraryView.optionsOpensShellSettings(under: .restoreBackup))
        #expect(!LibraryView.optionsOpensShellSettings(under: .cloudConflict))
        #expect(FocusLayer.restoreBackup.prefix == "rst.")
        #expect(FocusLayer.cloudConflict.prefix == "cld.")
        #expect(FocusLayer.isLive("rst.confirm", under: .restoreBackup))
        #expect(!FocusLayer.isLive("set.play", under: .restoreBackup))
        #expect(FocusLayer.isLive("cld.cloud", under: .cloudConflict))
        #expect(!FocusLayer.isLive("lib.play", under: .cloudConflict))
    }

    @Test func signingWarningBannerResolvesDistinctTitlesAcrossStates() {
        let hours = SigningWarningBanner(warning: .expiringHours(24), onDismiss: {})
        let soon = SigningWarningBanner(warning: .expiringSoon, onDismiss: {})
        let expired = SigningWarningBanner(warning: .expired, onDismiss: {})
        _ = (hours, soon, expired)
        #expect(SigningWarning.expiringHours(24) != SigningWarning.expiringSoon)
        #expect(SigningWarning.expiringSoon != SigningWarning.expired)
    }
}
