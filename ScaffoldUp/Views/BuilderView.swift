//
//  BuilderView.swift  (Screen 01 — Scaffold Builder, main)
//  ScaffoldUp
//
//  The isometric scaffold, the live scaff-tag / access gate, the configuration
//  summary and the primary actions (Add Bay, Add Lift, Inspect, Configure).
//  Per-tier rows link to the Section Detail screen. iOS 14 safe.
//

import SwiftUI

struct BuilderView: View {
    @EnvironmentObject var store: AppStore
    var switchTab: (AppTab) -> Void

    @State private var renaming = false
    @State private var draftName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scaffold Builder").font(Theme.title(27)).foregroundColor(Theme.textPrimary)
                        Button(action: { draftName = store.config.name; renaming = true }) {
                            HStack(spacing: 5) {
                                Text(store.config.name).font(Theme.caption(13)).foregroundColor(Theme.textSecondary)
                                Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(Theme.tube)
                            }
                        }.buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                    TagChip(text: store.config.dutyClass.shortName, color: store.config.dutyClass.color, filled: true)
                }
                .padding(.top, 4)

                // Isometric scaffold
                CardView {
                    VStack(spacing: 10) {
                        ScaffoldIsometricView(
                            bays: store.config.bays, lifts: store.config.lifts,
                            deckedLevels: Set(store.tiers.filter { $0.decked }.map { $0.index }),
                            tagStatus: store.tag.status
                        )
                        .frame(height: 230)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.config.bays)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.config.lifts)

                        HStack {
                            Label("\(store.config.bays) bays", systemImage: "rectangle.split.3x1.fill")
                            Spacer()
                            Label("\(store.config.lifts) lifts", systemImage: "square.stack.3d.up.fill")
                            Spacer()
                            Label(store.config.type.displayName, systemImage: store.config.type.icon)
                        }
                        .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    }
                }

                // Tag + access gate
                CardView(tint: store.tag.status.color.opacity(0.5)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ScaffTagBadge(status: store.tag.status)
                            Spacer()
                            if let d = store.tag.lastInspectionDate {
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("Last inspected").font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                                    Text(Formatters.date(d)).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        GateBanner(permitted: store.workPermitted, redReason: store.tag.reason)
                        if store.tagOverdue {
                            Text("Re-inspection overdue — tag no longer valid.")
                                .font(Theme.caption(11)).foregroundColor(Theme.danger)
                        }
                    }
                }

                // Summary stats
                HStack(spacing: 10) {
                    StatTile(value: store.len(store.config.height), label: "Height", systemImage: "arrow.up.to.line", tint: Theme.tube)
                    StatTile(value: store.len(store.config.facadeLength), label: "Facade", systemImage: "ruler.fill", tint: Theme.info)
                }
                HStack(spacing: 10) {
                    StatTile(value: "\(store.componentSpec.totalPieces)", label: "Components", systemImage: "shippingbox.fill", tint: Theme.accent)
                    StatTile(value: "\(store.config.bays * store.config.lifts)", label: "Sections", systemImage: "square.grid.3x3.fill", tint: Theme.safety)
                }

                // Primary actions
                HStack(spacing: 10) {
                    ActionButton(title: "Add Bay", systemImage: "plus.rectangle.on.rectangle", kind: .primary,
                                 fullWidth: true) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.addBay() }
                    }
                    .opacity(store.config.bays < store.maxBays ? 1 : 0.5)
                    ActionButton(title: "Add Lift", systemImage: "plus.square.on.square", kind: .primary,
                                 fullWidth: true) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.addLift() }
                    }
                    .opacity(store.config.lifts < store.maxLifts ? 1 : 0.5)
                }
                HStack(spacing: 10) {
                    ActionButton(title: "Remove Bay", systemImage: "minus.rectangle", kind: .secondary, fullWidth: true) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.removeBay() }
                    }
                    .opacity(store.config.bays > 1 ? 1 : 0.5)
                    ActionButton(title: "Remove Lift", systemImage: "minus.square", kind: .secondary, fullWidth: true) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.removeLift() }
                    }
                    .opacity(store.config.lifts > 1 ? 1 : 0.5)
                }

                NavigationLink(destination: InspectionView()) {
                    ActionLabelView(title: store.tag.status == .green ? "Re-run Inspection" : "Inspect & Tag",
                                    systemImage: "checklist", kind: .safety)
                }.buttonStyle(PlainButtonStyle())

                NavigationLink(destination: ConfigEditorView()) {
                    ActionLabelView(title: "Configure Scaffold", systemImage: "slider.horizontal.3", kind: .secondary)
                }.buttonStyle(PlainButtonStyle())

                // Tiers
                SectionHeader(title: "Tiers", subtitle: "Tap a lift for load, photos & detail", systemImage: "square.stack.3d.up.fill")
                ForEach(store.tiers) { tier in
                    NavigationLink(destination: SectionDetailView(tierID: tier.id)) {
                        TierRow(tier: tier, assessment: ScaffoldEngine.assess(tier: tier, config: store.config))
                    }.buttonStyle(PlainButtonStyle())
                }
            }
            .padding(Theme.Space.m)
            .padding(.bottom, 120)
        }
        .steelScreen()
        .sheet(isPresented: $renaming) {
            RenameSheet(name: $draftName) { store.renameScaffold(draftName); renaming = false }
        }
    }
}

// MARK: - Tier row

struct TierRow: View {
    @EnvironmentObject var store: AppStore
    let tier: Tier
    let assessment: LoadAssessment

    private var tint: Color {
        if assessment.overloaded { return Theme.danger }
        if assessment.nearLimit { return Theme.warning }
        return Theme.success
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Theme.tube.opacity(0.16)).frame(width: 40, height: 40)
                Text("L\(tier.index + 1)").font(Theme.heading(15)).foregroundColor(Theme.tube)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tier.label).font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                    if tier.decked { TagChip(text: "Decked", color: Theme.tube) }
                    else { TagChip(text: "Open", color: Theme.textMuted) }
                    if tier.photoFileName != nil { Image(systemName: "photo.fill").font(.system(size: 10)).foregroundColor(Theme.success) }
                }
                RatioBar(ratio: assessment.ratio, height: 8, tint: tint)
                Text("\(store.weight(assessment.totalKg)) of \(store.weight(assessment.allowableKg)) · \(Formatters.percent(assessment.ratio * 100))")
                    .font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.textMuted)
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
    }
}

// MARK: - ActionLabel (button-styled label for NavigationLink)

struct ActionLabelView: View {
    let title: String
    var systemImage: String? = nil
    var kind: ActionButtonStyle.Kind = .primary

    var body: some View {
        HStack(spacing: 8) {
            if let img = systemImage { Image(systemName: img) }
            Text(title)
        }
        .font(Theme.heading(15))
        .foregroundColor(foreground)
        .padding(.vertical, 13).padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(background)
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
            .stroke(kind == .secondary ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.4))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }
    private var foreground: Color {
        switch kind {
        case .primary: return Theme.textOnBlue
        case .safety: return Theme.textOnAccent
        case .secondary: return Theme.accentHi
        case .danger: return .white
        }
    }
    @ViewBuilder private var background: some View {
        switch kind {
        case .primary: Theme.accentGradient
        case .safety: Theme.safetyGradient
        case .secondary: Theme.surfaceHi
        case .danger: LinearGradient(colors: [Theme.danger, Theme.danger.opacity(0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Rename sheet

struct RenameSheet: View {
    @Binding var name: String
    let onSave: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Space.l) {
                LabeledField(label: "Scaffold name", text: $name, placeholder: "e.g. North Facade — Block A")
                ActionButton(title: "Save Name", systemImage: "checkmark") {
                    onSave(); presentationMode.wrappedValue.dismiss()
                }
                Spacer()
            }
            .padding(Theme.Space.l)
            .steelScreen(showFrame: false)
            .navigationBarTitle("Rename", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
