//
//  RootTabView.swift
//  ScaffoldUp
//
//  Main app shell: custom tab bar + per-tab NavigationView stacks. The Safety,
//  Log and More tabs are hub screens linking the remaining views. iOS 14 safe.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .builder

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .builder: stack { BuilderView(switchTab: { tab = $0 }) }
                case .spec:    stack { ComponentCountView() }
                case .safety:  stack { SafetyHubView() }
                case .log:     stack { LogHubView() }
                case .more:    stack { MoreView() }
                }
            }
            CustomTabBar(selection: $tab, badge: store.riskCount)
        }
    }

    private func stack<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        NavigationView { content() }.navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Reusable navigation row (card style)

struct NavRow<Destination: View>: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    var tint: Color = Theme.tube
    var badge: Int = 0
    var badgeColor: Color = Theme.danger
    let destination: Destination

    init(icon: String, title: String, subtitle: String = "", tint: Color = Theme.tube,
         badge: Int = 0, badgeColor: Color = Theme.danger, @ViewBuilder destination: () -> Destination) {
        self.icon = icon; self.title = title; self.subtitle = subtitle
        self.tint = tint; self.badge = badge; self.badgeColor = badgeColor; self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11).fill(tint.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: icon).foregroundColor(tint).font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()
                if badge > 0 { TagChip(text: "\(badge)", color: badgeColor, filled: true) }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.textMuted)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Safety hub

struct SafetyHubView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScreenScaffold("Safety", subtitle: "Inspection gate, tag, loads & anchoring") {
            CardView(tint: store.workPermitted ? Theme.success.opacity(0.45) : Theme.danger.opacity(0.5)) {
                HStack {
                    ScaffTagBadge(status: store.tag.status)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(store.workPermitted ? "Work permitted" : "Work blocked")
                            .font(Theme.heading(14)).foregroundColor(store.workPermitted ? Theme.success : Theme.danger)
                        if let due = store.tag.nextDueDate {
                            Text("Re-check \(Formatters.relativeDays(to: due))")
                                .font(Theme.caption(11)).foregroundColor(store.tagOverdue ? Theme.danger : Theme.textSecondary)
                        }
                    }
                }
            }

            SectionHeader(title: "Access control", systemImage: "checkmark.shield.fill")
            VStack(spacing: 12) {
                NavRow(icon: "checklist", title: "Inspection", subtitle: "Run the access checklist",
                       tint: Theme.accent, badge: store.tag.status == .red ? 1 : 0) { InspectionView() }
                NavRow(icon: store.tag.status.icon, title: "Scaff-Tag", subtitle: store.tag.restriction,
                       tint: store.tag.status.color) { ScaffTagView() }
                NavRow(icon: "cloud.bolt.rain.fill", title: "Storm / Re-check", subtitle: "After bad weather",
                       tint: Theme.caution) { StormRecheckView() }
            }

            SectionHeader(title: "Loads & structure", systemImage: "scalemass.fill")
            VStack(spacing: 12) {
                NavRow(icon: "scalemass.fill", title: "Load Check", subtitle: "Platform load vs duty class",
                       tint: Theme.warning, badge: store.overloadedTiers.count, badgeColor: Theme.danger) { LoadCheckView() }
                NavRow(icon: "pin.fill", title: "Tie & Anchor Plan", subtitle: store.config.type.needsTies ? "\(store.tiePlan.required) anchors" : "Free-standing tower",
                       tint: Theme.tube) { TieAnchorView() }
                NavRow(icon: "square.split.bottomrightquarter.fill", title: "Base & Foundation",
                       subtitle: store.config.unevenGround ? "Screw jacks" : "Base plates", tint: Theme.info) { BaseFoundationView() }
                NavRow(icon: "rectangle.tophalf.inset.filled", title: "Access & Edge Protection",
                       subtitle: "Guardrails, toe boards, ladders", tint: Theme.success) { AccessEdgeView() }
            }
        }
    }
}

// MARK: - Log hub

struct LogHubView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScreenScaffold("Log & Records", subtitle: "Sections, sign-offs, photos & reports") {
            VStack(spacing: 12) {
                NavRow(icon: "square.stack.3d.up.fill", title: "Sections / Tiers",
                       subtitle: "\(store.tiers.count) lifts · per-tier detail", tint: Theme.tube) { SectionListView() }
                NavRow(icon: "signature", title: "Sign-off Log",
                       subtitle: "\(store.inspections.count) inspections recorded", tint: Theme.accent) { SignOffLogView() }
                NavRow(icon: "clock.arrow.circlepath", title: "History",
                       subtitle: "\(store.history.count) events", tint: Theme.info) { HistoryView() }
                NavRow(icon: "photo.on.rectangle.angled", title: "Marker Photos",
                       subtitle: "\(store.photos.count) photos", tint: Theme.success) { PhotoView() }
                NavRow(icon: "sterlingsign.circle.fill", title: "Material & Rental Cost",
                       subtitle: store.money(store.totalRentalCost) + " · \(store.rentalDays) days", tint: Theme.safety) { CostView() }
                NavRow(icon: "doc.text.fill", title: "Reports (PDF)",
                       subtitle: "Scaffold passport export", tint: Theme.caution) { ReportsView() }
            }
        }
    }
}

// MARK: - More hub

struct MoreView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        ScreenScaffold("More", subtitle: "Reminders & app preferences") {
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: store.config.name, subtitle: "\(store.config.type.displayName) · \(store.config.dutyClass.displayName)", systemImage: "square.stack.3d.up.fill")
                    HStack(spacing: 18) {
                        miniMetric("Bays", "\(store.config.bays)")
                        miniMetric("Lifts", "\(store.config.lifts)")
                        miniMetric("Height", store.len(store.config.height))
                        miniMetric("Parts", "\(store.componentSpec.totalPieces)")
                    }
                }
            }
            VStack(spacing: 12) {
                NavRow(icon: "bell.badge.fill", title: "Reminders",
                       subtitle: "Re-inspection, storm, rental return", tint: Theme.safety) { RemindersView() }
                NavRow(icon: "gearshape.fill", title: "Settings",
                       subtitle: "Units, currency, theme, tag interval", tint: Theme.textSecondary) { SettingsView() }
            }

            CardView {
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.safety)
                        Text("Disclaimer").font(Theme.heading(14)).foregroundColor(Theme.textPrimary) }
                    Text("Figures are indicative for planning only. Final approval to work rests with a competent person; erect strictly to the manufacturer's instructions.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
    private func miniMetric(_ l: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(Theme.heading(15)).foregroundColor(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
            Text(l).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}
