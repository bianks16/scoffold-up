//
//  ScaffTagView.swift  (Screen 08 — Scaff-Tag)
//  ScaffoldUp
//
//  The digital scaff-tag: green/red status, install & re-inspection dates,
//  inspector and load restriction — the physical tag, on the phone. iOS 14 safe.
//

import SwiftUI

struct ScaffTagView: View {
    @EnvironmentObject var store: AppStore
    @State private var share: ShareItem?

    private var tag: ScaffTag { store.tag }

    var body: some View {
        ScreenScaffold("Scaff-Tag", subtitle: "Digital access tag") {

            // The tag itself
            tagCard

            CardView {
                VStack(spacing: 0) {
                    detailRow("Status", tag.status.headline, tag.status.color, tag.status.icon)
                    divider
                    detailRow("Installed", Formatters.date(tag.installedDate), Theme.textPrimary, "calendar")
                    divider
                    detailRow("Last inspection", tag.lastInspectionDate.map { Formatters.date($0) } ?? "—", Theme.textPrimary, "checklist")
                    divider
                    detailRow("Next re-inspection",
                              tag.nextDueDate.map { Formatters.date($0) } ?? "—",
                              store.tagOverdue ? Theme.danger : (store.tagExpiringSoon ? Theme.warning : Theme.textPrimary),
                              "clock.arrow.circlepath")
                    divider
                    detailRow("Inspector", tag.inspector.isEmpty ? "—" : tag.inspector, Theme.textPrimary, "person.fill")
                    divider
                    detailRow("Restriction", tag.restriction, Theme.safety, "exclamationmark.triangle.fill")
                }
            }

            if store.tagOverdue {
                CardView(tint: Theme.danger.opacity(0.6)) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.exclamationmark.fill").foregroundColor(Theme.danger)
                        Text("Re-inspection overdue. The tag is no longer valid — re-inspect before anyone climbs.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                    }
                }
            } else if store.tagExpiringSoon {
                CardView(tint: Theme.warning.opacity(0.5)) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill").foregroundColor(Theme.warning)
                        Text("Re-inspection due soon — schedule it from Reminders.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    }
                }
            }

            NavigationLink(destination: InspectionView()) {
                ActionLabelView(title: tag.status == .green ? "Re-inspect" : "Inspect Now",
                                systemImage: "checklist", kind: .safety)
            }.buttonStyle(PlainButtonStyle())

            ActionButton(title: "Share Tag", systemImage: "square.and.arrow.up", kind: .secondary) { shareTag() }

            CardView {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "What the colours mean", systemImage: "info.circle.fill")
                    legend(.green, "Inspected and safe to work to the stated duty class.")
                    legend(.red, "Incomplete or defective — do not climb or load.")
                }
            }
        }
        .navigationBarTitle("Scaff-Tag", displayMode: .inline)
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
    }

    private var tagCard: some View {
        VStack(spacing: 0) {
            // hanging hole
            Circle().stroke(Theme.textOnAccent.opacity(0.4), lineWidth: 3).frame(width: 18, height: 18).padding(.top, 10)
            VStack(spacing: 10) {
                Text("SCAFFOLD TAG").font(.system(size: 13, weight: .heavy, design: .rounded)).tracking(2).foregroundColor(Theme.textOnAccent.opacity(0.8))
                ZStack {
                    Circle().fill(tag.status.color).frame(width: 92, height: 92)
                    Image(systemName: tag.status.icon).font(.system(size: 40, weight: .bold)).foregroundColor(.white)
                }
                Text(tag.status.headline).font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(Theme.textOnAccent)
                Text(store.config.name).font(Theme.caption(12)).foregroundColor(Theme.textOnAccent.opacity(0.8))
                Text(tag.restriction).font(Theme.caption(11)).foregroundColor(Theme.textOnAccent.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.bottom, Theme.Space.l)
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.l).fill(Theme.safetyGradient))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).stroke(Theme.textOnAccent.opacity(0.2), lineWidth: 1.5))
        .shadow(color: Theme.safety.opacity(0.4), radius: 14, y: 6)
    }

    private var divider: some View { Rectangle().fill(Theme.stroke).frame(height: 1).padding(.vertical, 2) }

    private func detailRow(_ l: String, _ v: String, _ tint: Color, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.textMuted).font(.system(size: 13)).frame(width: 18)
            Text(l).font(Theme.body(14)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(v).font(Theme.heading(14)).foregroundColor(tint).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 9)
    }

    private func legend(_ status: TagStatus, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(status.color).frame(width: 12, height: 12).padding(.top, 2)
            Text(text).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
        }
    }

    private func shareTag() {
        let text = """
        SCAFFOLD TAG — \(tag.status.headline)
        \(store.config.name)
        Type: \(store.config.type.displayName) · \(store.config.dutyClass.displayName)
        Installed: \(Formatters.date(tag.installedDate))
        Last inspection: \(tag.lastInspectionDate.map { Formatters.date($0) } ?? "—")
        Next re-inspection: \(tag.nextDueDate.map { Formatters.date($0) } ?? "—")
        Inspector: \(tag.inspector)
        Restriction: \(tag.restriction)
        — Generated by Scaffold Up (indicative; competent person approval required).
        """
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScaffTag.txt")
        try? text.write(to: url, atomically: true, encoding: .utf8)
        share = ShareItem(url: url)
    }
}
