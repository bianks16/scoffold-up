//
//  HistoryView.swift  (Screen 16 — History)
//  ScaffoldUp
//
//  A reverse-chronological feed of everything that happened to the scaffold:
//  bays/lifts added, inspections, tag changes, storm checks, load edits. iOS 14 safe.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScreenScaffold("History", subtitle: "Timeline of scaffold events") {
            if store.history.isEmpty {
                EmptyStateView(systemImage: "clock.arrow.circlepath", title: "No history yet",
                               message: "Build, inspect and tag the scaffold to populate the timeline.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.history.enumerated()), id: \.element.id) { idx, event in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                ZStack {
                                    Circle().fill(event.kind.tint.opacity(0.18)).frame(width: 34, height: 34)
                                    Image(systemName: event.kind.icon).font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(event.kind.tint)
                                }
                                if idx < store.history.count - 1 {
                                    Rectangle().fill(Theme.stroke).frame(width: 2).frame(maxHeight: .infinity)
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(event.kind.label).font(Theme.heading(14)).foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(Formatters.relativeDays(to: event.date)).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                                }
                                if !event.detail.isEmpty {
                                    Text(event.detail).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                                }
                                Text(Formatters.dateTime(event.date)).font(Theme.caption(10)).foregroundColor(Theme.textMuted)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
        }
    }
}
