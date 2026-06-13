//
//  SettingsView.swift  (Screen 18 — Settings)
//  ScaffoldUp
//
//  Units, currency, theme, tag interval, onboarding replay, data reset and a
//  JSON backup export — all wired to real persistence and behaviour. Not a user
//  profile. iOS 14 safe.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager

    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage("currencyCode") private var currencyRaw = CurrencyCode.gbp.rawValue
    @AppStorage("tagIntervalDays") private var tagInterval = 7
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var confirm: ConfirmAction?
    @State private var share: ShareItem?
    @State private var toast: String?

    enum ConfirmAction: Int, Identifiable { case reset, wipe; var id: Int { rawValue } }

    var body: some View {
        ScreenScaffold("Settings", subtitle: "Local preferences — no account, no cloud") {

            if let t = toast {
                CardView(tint: Theme.success.opacity(0.5)) {
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                        Text(t).font(Theme.body()).foregroundColor(Theme.textPrimary) }
                }
            }

            // Appearance
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Appearance", subtitle: "Applies instantly", systemImage: "paintpalette.fill")
                    Picker("", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }.pickerStyle(SegmentedPickerStyle())
                }
            }

            // Units
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Units", subtitle: "Lengths, areas & weights", systemImage: "ruler.fill")
                    Picker("", selection: $unitRaw) {
                        ForEach(UnitSystem.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: unitRaw) { _ in store.objectWillChange.send(); flash("Units updated") }
                    Text("Example: height \(store.len(store.config.height)) · load \(store.weight(store.config.dutyClass.loadPerSqmKg))/m² (\(store.kNLabel(store.config.dutyClass.loadPerSqmKg))/m²)")
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                }
            }

            // Currency
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Currency", systemImage: "sterlingsign.circle.fill")
                    Picker("", selection: $currencyRaw) {
                        ForEach(CurrencyCode.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                    .pickerStyle(MenuPickerStyle()).accentColor(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(10)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
                    .onChange(of: currencyRaw) { _ in store.objectWillChange.send() }
                    Text("Example: \(Formatters.currency(1250, code: currentCurrency.code, symbol: currentCurrency.symbol))")
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                }
            }

            // Tag interval
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Re-inspection interval", subtitle: "Days until the next tag check", systemImage: "clock.arrow.circlepath")
                    Stepper(value: $tagInterval, in: 1...30) {
                        Text("Every \(tagInterval) day\(tagInterval == 1 ? "" : "s")").font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }
                    Text("Applied when the next inspection passes. A 7-day cycle is common for working scaffolds.")
                        .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                }
            }

            // Presets / quick jump
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Scaffold presets", systemImage: "slider.horizontal.3")
                    NavigationLink(destination: ConfigEditorView()) {
                        ActionLabelView(title: "Edit Type / Duty / Size", systemImage: "square.stack.3d.up.fill", kind: .secondary)
                    }.buttonStyle(PlainButtonStyle())
                }
            }

            // Data
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Data & backup", systemImage: "tray.full.fill")
                    ActionButton(title: "Export Backup (JSON)", systemImage: "square.and.arrow.up", kind: .secondary) { exportBackup() }
                    ActionButton(title: "Replay Onboarding", systemImage: "sparkles", kind: .secondary) {
                        hasCompletedOnboarding = false
                        flash("Onboarding will show on next launch")
                    }
                    ActionButton(title: "Reset Sample Data", systemImage: "arrow.counterclockwise") { confirm = .reset }
                    ActionButton(title: "Clear All Data", systemImage: "trash", kind: .danger) { confirm = .wipe }
                }
            }

            // About
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "About", systemImage: "info.circle.fill")
                    aboutRow("App", "Scaffold Up")
                    aboutRow("Version", "1.0")
                    aboutRow("Mode", "Offline · No account")
                    Text("Indicative for planning only. Final approval to work rests with a competent person; erect strictly to the manufacturer's instructions.")
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                }
            }
        }
        .navigationBarTitle("Settings", displayMode: .inline)
        .actionSheet(item: $confirm) { action in confirmSheet(action) }
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
    }

    // MARK: - Helpers

    private var currentCurrency: CurrencyCode { CurrencyCode(rawValue: currencyRaw) ?? .gbp }

    private func aboutRow(_ l: String, _ v: String) -> some View {
        HStack { Text(l).font(Theme.body()).foregroundColor(Theme.textSecondary)
            Spacer(); Text(v).font(Theme.body()).foregroundColor(Theme.textPrimary) }
    }

    private func flash(_ msg: String) {
        withAnimation { toast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { toast = nil } }
    }

    private func exportBackup() {
        if let url = store.exportURL() { share = ShareItem(url: url) }
        else { flash("Couldn't build backup") }
    }

    private func confirmSheet(_ action: ConfirmAction) -> ActionSheet {
        switch action {
        case .reset:
            return ActionSheet(title: Text("Reset to Sample Data?"),
                               message: Text("Replaces the current scaffold with the demo project."),
                               buttons: [.destructive(Text("Reset")) { store.resetToSampleData(); flash("Sample data restored") }, .cancel()])
        case .wipe:
            return ActionSheet(title: Text("Clear All Data?"),
                               message: Text("Permanently deletes everything on this device."),
                               buttons: [.destructive(Text("Delete Everything")) { store.wipeAll(); flash("All data cleared") }, .cancel()])
        }
    }
}
