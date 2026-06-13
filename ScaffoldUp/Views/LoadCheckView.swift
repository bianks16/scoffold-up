//
//  LoadCheckView.swift  (Screen 04 — Load Check)
//  ScaffoldUp
//
//  Per-tier platform load (materials + people) checked against the duty-class
//  capacity. Overloaded tiers are flagged red with advice to spread the load.
//  The inspection gate is surfaced at the top. iOS 14 safe.
//

import SwiftUI

struct LoadCheckView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScreenScaffold("Load Check", subtitle: "Platform load vs \(store.config.dutyClass.displayName)") {

            GateBanner(permitted: store.workPermitted, redReason: store.tag.reason)

            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Capacity per tier").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                            Text(store.weight(perTierAllowable)).font(Theme.title(22)).foregroundColor(Theme.textPrimary)
                            Text("\(store.kNLabel(perTierAllowable)) · \(store.area(store.config.platformAreaPerTier)) platform")
                                .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(store.config.dutyClass.shortName) duty").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                            Text("\(Formatters.decimal(store.config.dutyClass.loadPerSqmKN, digits: 2)) kN/m²")
                                .font(Theme.heading(16)).foregroundColor(store.config.dutyClass.color)
                            Text("\(store.weight(store.config.dutyClass.loadPerSqmKg))/m²").font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                        }
                    }
                    Text("One worker + tools is counted as \(store.weight(Physics.personLoadKg)).")
                        .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                }
            }

            if !store.overloadedTiers.isEmpty {
                CardView(tint: Theme.danger.opacity(0.6)) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.octagon.fill").foregroundColor(Theme.danger)
                        Text("\(store.overloadedTiers.count) tier(s) overloaded — reduce or spread the load before working.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                    }
                }
            }

            SectionHeader(title: "Tiers", subtitle: "Drag to set the material load", systemImage: "scalemass.fill")
            ForEach(store.tiers) { tier in
                TierLoadCard(tier: tier, permitted: store.workPermitted)
                    .environmentObject(store)
            }
        }
    }

    private var perTierAllowable: Double {
        store.config.dutyClass.loadPerSqmKg * store.config.platformAreaPerTier
    }
}

// MARK: - Per-tier editable load card

private struct TierLoadCard: View {
    @EnvironmentObject var store: AppStore
    let tier: Tier
    let permitted: Bool

    @State private var material: Double = 0
    @State private var people: Int = 1
    @State private var loaded = false

    private var allowable: Double { store.config.dutyClass.loadPerSqmKg * store.config.platformAreaPerTier }
    private var total: Double { material + Double(people) * Physics.personLoadKg }
    private var ratio: Double { allowable <= 0 ? 0 : total / allowable }
    private var overloaded: Bool { total > allowable }
    private var nearLimit: Bool { !overloaded && ratio >= 0.85 }
    private var tint: Color { overloaded ? Theme.danger : (nearLimit ? Theme.warning : Theme.success) }

    var body: some View {
        CardView(tint: overloaded ? Theme.danger.opacity(0.55) : nil) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tier.label).font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                    if overloaded { TagChip(text: "OVERLOAD", color: Theme.danger, filled: true, icon: "exclamationmark.triangle.fill") }
                    else if nearLimit { TagChip(text: "NEAR LIMIT", color: Theme.warning, filled: true) }
                    else { TagChip(text: "OK", color: Theme.success, filled: true, icon: "checkmark") }
                    Spacer()
                    Text(Formatters.percent(ratio * 100)).font(Theme.heading(16)).foregroundColor(tint)
                }

                RatioBar(ratio: ratio, height: 14, tint: tint)
                HStack {
                    Text("\(store.weight(total)) on board").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("limit \(store.weight(allowable))").font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                }

                // Material slider
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("MATERIALS").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text(store.weight(material)).font(Theme.mono(12)).foregroundColor(Theme.textPrimary)
                    }
                    Slider(value: $material, in: 0...max(allowable * 1.6, 100), step: 10,
                           onEditingChanged: { editing in if !editing { commit() } })
                        .accentColor(tint)
                }

                // People stepper
                HStack {
                    Image(systemName: "person.2.fill").foregroundColor(Theme.tube)
                    Text("Workers on tier").font(Theme.body()).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Stepper("\(people)", value: $people, in: 0...8).labelsHidden()
                        .onChange(of: people) { _ in commit() }
                    Text("\(people)").font(Theme.heading(16)).foregroundColor(Theme.textPrimary).frame(width: 26)
                }

                Text(ScaffoldEngine.loadAdvice(
                        LoadAssessment(tierIndex: tier.index, area: store.config.platformAreaPerTier,
                                       allowableKg: allowable, materialKg: material,
                                       peopleKg: Double(people) * Physics.personLoadKg),
                        duty: store.config.dutyClass))
                    .font(Theme.caption(12)).foregroundColor(tint)

                if !permitted {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill").foregroundColor(Theme.danger).font(.system(size: 11))
                        Text("Do not load — scaffold not approved for work.").font(Theme.caption(11)).foregroundColor(Theme.danger)
                    }
                }
            }
        }
        .onAppear {
            if !loaded { material = tier.materialLoadKg; people = tier.peopleCount; loaded = true }
        }
    }

    private func commit() {
        store.setTierLoad(tier, materialKg: material, people: people)
    }
}
