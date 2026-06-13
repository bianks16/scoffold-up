//
//  SectionViews.swift  (Screens 13 — Sections / Tiers list + detail)
//  ScaffoldUp
//
//  The per-tier section cards: elements, load, inspection status, photo, notes
//  and load history. iOS 14 safe.
//

import SwiftUI

// MARK: - Section list

struct SectionListView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScreenScaffold("Sections / Tiers", subtitle: "One card per lift") {
            ForEach(store.tiers) { tier in
                NavigationLink(destination: SectionDetailView(tierID: tier.id)) {
                    TierRow(tier: tier, assessment: ScaffoldEngine.assess(tier: tier, config: store.config))
                }.buttonStyle(PlainButtonStyle())
            }
            CardView(tint: Theme.tube.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill").foregroundColor(Theme.safety)
                    Text("Add lifts from the Builder. Each new lift starts undecked-safe and resets the tag for re-inspection.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Section detail

struct SectionDetailView: View {
    @EnvironmentObject var store: AppStore
    let tierID: UUID

    @State private var material: Double = 0
    @State private var people: Int = 1
    @State private var notes = ""
    @State private var loaded = false
    @State private var showPicker = false

    private var tier: Tier? { store.tiers.first { $0.id == tierID } }

    var body: some View {
        Group {
            if let tier = tier {
                content(tier)
            } else {
                EmptyStateView(systemImage: "square.stack.3d.up.slash", title: "Tier removed",
                               message: "This lift no longer exists.")
                    .steelScreen()
            }
        }
        .navigationBarTitle(tier?.label ?? "Tier", displayMode: .inline)
        .onAppear {
            if !loaded, let t = tier {
                material = t.materialLoadKg; people = t.peopleCount; notes = t.notes; loaded = true
            }
        }
        .sheet(isPresented: $showPicker) {
            PhotoLibraryPicker { image in
                if let t = tier { store.attachPhoto(toTier: t, image: image) }
            }
        }
    }

    private func content(_ tier: Tier) -> some View {
        let allowable = store.config.dutyClass.loadPerSqmKg * store.config.platformAreaPerTier
        let total = material + Double(people) * Physics.personLoadKg
        let ratio = allowable <= 0 ? 0 : total / allowable
        let overloaded = total > allowable
        let nearLimit = !overloaded && ratio >= 0.85
        let tint: Color = overloaded ? Theme.danger : (nearLimit ? Theme.warning : Theme.success)

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {

                // Status + decked toggle
                CardView(tint: tint.opacity(0.5)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(tier.label).font(Theme.title(22)).foregroundColor(Theme.textPrimary)
                            Spacer()
                            inspectionChip(tier.lastInspectedPassed)
                        }
                        Toggle(isOn: Binding(get: { tier.decked }, set: { _ in store.toggleDecked(tier) })) {
                            Label("Boarded working platform", systemImage: "rectangle.grid.1x2.fill")
                                .font(Theme.body()).foregroundColor(Theme.textPrimary)
                        }.toggleStyle(SwitchToggleStyle(tint: Theme.tube))
                    }
                }

                // Elements on this tier
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Elements on this lift", systemImage: "shippingbox.fill")
                        let bays = store.config.bays
                        let boardsWide = max(PlatformWidth(rawValue: store.config.platformWidthRaw)?.boards ?? 4, store.config.dutyClass.minBoardsWide)
                        elementRow("Platform boards", tier.decked ? boardsWide * bays : 0, "rectangle.grid.1x2.fill")
                        elementRow("Guardrails", tier.decked ? 2 * bays + 2 : 0, "rectangle.tophalf.inset.filled")
                        elementRow("Toe boards", tier.decked ? bays + 2 : 0, "rectangle.bottomthird.inset.filled")
                        elementRow("Transoms", bays + 1, "rectangle.split.2x1.fill")
                        elementRow("Ledgers (this level)", 2 * bays, "rectangle.split.3x1.fill")
                    }
                }

                // Load editor
                CardView(tint: overloaded ? Theme.danger.opacity(0.55) : nil) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SectionHeader(title: "Load", systemImage: "scalemass.fill")
                            Spacer()
                            Text(Formatters.percent(ratio * 100)).font(Theme.heading(16)).foregroundColor(tint)
                        }
                        RatioBar(ratio: ratio, height: 14, tint: tint)
                        HStack {
                            Text("\(store.weight(total)) on board").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                            Spacer()
                            Text("limit \(store.weight(allowable)) · \(store.kNLabel(allowable))").font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("MATERIALS").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                                Spacer(); Text(store.weight(material)).font(Theme.mono(12)).foregroundColor(Theme.textPrimary)
                            }
                            Slider(value: $material, in: 0...max(allowable * 1.6, 100), step: 10,
                                   onEditingChanged: { if !$0 { store.setTierLoad(tier, materialKg: material, people: people) } })
                                .accentColor(tint)
                        }
                        HStack {
                            Image(systemName: "person.2.fill").foregroundColor(Theme.tube)
                            Text("Workers").font(Theme.body()).foregroundColor(Theme.textPrimary)
                            Spacer()
                            Stepper("\(people)", value: $people, in: 0...8).labelsHidden()
                                .onChange(of: people) { _ in store.setTierLoad(tier, materialKg: material, people: people) }
                            Text("\(people)").font(Theme.heading(16)).foregroundColor(Theme.textPrimary).frame(width: 26)
                        }
                        if overloaded {
                            Text("Overloaded — spread the load across other lifts or remove material.")
                                .font(Theme.caption(12)).foregroundColor(Theme.danger)
                        }
                    }
                }

                // Photo
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Photo", systemImage: "camera.fill")
                        if let img = store.image(for: tier.photoFileName) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(height: 170).frame(maxWidth: .infinity).clipped()
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                            ActionButton(title: "Replace Photo", systemImage: "arrow.triangle.2.circlepath", kind: .secondary) { showPicker = true }
                        } else {
                            Button(action: { showPicker = true }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus").font(.system(size: 32)).foregroundColor(Theme.tube)
                                    Text("Add a photo of this lift").font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 24)
                                .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
                                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // Notes
                CardView {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Notes", systemImage: "note.text")
                        TextEditor(text: $notes)
                            .frame(height: 80).padding(6)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
                            .foregroundColor(Theme.textPrimary)
                        ActionButton(title: "Save Notes", systemImage: "checkmark", kind: .secondary) {
                            UIApplication.shared.dismissKeyboard()
                            var t = tier; t.notes = notes; store.updateTier(t)
                        }
                    }
                }
            }
            .padding(Theme.Space.m)
            .padding(.bottom, 40)
        }
        .steelScreen()
    }

    private func elementRow(_ name: String, _ count: Int, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.tube).frame(width: 20)
            Text(name).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(count)").font(Theme.heading(15)).foregroundColor(Theme.safety)
        }
    }

    private func inspectionChip(_ passed: Bool?) -> some View {
        Group {
            if passed == true { TagChip(text: "Inspected", color: Theme.success, filled: true, icon: "checkmark") }
            else if passed == false { TagChip(text: "Failed", color: Theme.danger, filled: true, icon: "xmark") }
            else { TagChip(text: "Not inspected", color: Theme.textMuted, filled: true) }
        }
    }
}
