//
//  SignOffLogView.swift  (Screen 14 — Sign-off Log)
//  ScaffoldUp
//
//  The audit trail of every inspection / sign-off: who, when, green or red,
//  which points passed/failed and any note. iOS 14 safe.
//

import SwiftUI

struct SignOffLogView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScreenScaffold("Sign-off Log", subtitle: "Who released the tag, and when") {

            if store.inspections.isEmpty {
                EmptyStateView(systemImage: "signature", title: "No sign-offs yet",
                               message: "Run an inspection to create the first sign-off record.")
            } else {
                CardView {
                    HStack {
                        logStat("\(store.inspections.count)", "Records", Theme.tube)
                        Divider().frame(height: 34).background(Theme.stroke)
                        logStat("\(store.inspections.filter { $0.passed }.count)", "Green", Theme.success)
                        Divider().frame(height: 34).background(Theme.stroke)
                        logStat("\(store.inspections.filter { !$0.passed }.count)", "Red", Theme.danger)
                        Divider().frame(height: 34).background(Theme.stroke)
                        logStat("\(store.inspections.filter { $0.isStormCheck }.count)", "Storm", Theme.caution)
                    }
                }

                ForEach(store.inspections) { insp in
                    CardView(tint: insp.resultStatus.color.opacity(0.4)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: insp.resultStatus.icon).foregroundColor(insp.resultStatus.color)
                                Text(insp.passed ? "Green tag" : "Red tag")
                                    .font(Theme.heading(15)).foregroundColor(insp.resultStatus.color)
                                if insp.isStormCheck { TagChip(text: "Storm", color: Theme.caution, filled: true, icon: "cloud.bolt.rain.fill") }
                                Spacer()
                                Text(Formatters.dateTime(insp.date)).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
                            }
                            HStack(spacing: 14) {
                                Label(insp.inspector, systemImage: "person.fill")
                                Label("\(insp.passedPoints.count) pass", systemImage: "checkmark.circle.fill")
                                if !insp.failedPoints.isEmpty {
                                    Label("\(insp.failedPoints.count) fail", systemImage: "xmark.circle.fill")
                                }
                            }
                            .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)

                            if !insp.failTitles.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(insp.failTitles, id: \.self) { t in
                                        Text("• \(t)").font(Theme.caption(11)).foregroundColor(Theme.danger)
                                    }
                                }
                            }
                            if !insp.note.isEmpty {
                                Text(insp.note).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }

            CardView(tint: Theme.safety.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.safety)
                    Text("Records are kept on this device only. Export a PDF passport from Reports to share or archive.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func logStat(_ v: String, _ l: String, _ c: Color) -> some View {
        VStack(spacing: 2) {
            Text(v).font(Theme.title(20)).foregroundColor(c)
            Text(l).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}
