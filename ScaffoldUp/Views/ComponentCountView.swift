//
//  ComponentCountView.swift  (Screen 03 — Component Count / Spec)
//  ScaffoldUp
//
//  The full bill of materials for the current configuration: standards, ledgers,
//  transoms, braces, boards, toe boards, guardrails, ladders, base plates,
//  couplers and ties — each with the formula that produced it. iOS 14 safe.
//

import SwiftUI

struct ComponentCountView: View {
    @EnvironmentObject var store: AppStore

    private var spec: ComponentSpec { store.componentSpec }

    private var chartData: [ChartDatum] {
        let palette: [Color] = [Theme.tube, Theme.info, Theme.accent, Theme.safety,
                                Theme.success, Theme.caution, Theme.tubeSoft, Theme.warning,
                                Theme.accentHi, Theme.danger, Theme.textSecondary]
        return spec.items.enumerated().map { idx, item in
            ChartDatum(label: item.name, value: Double(item.count), color: palette[idx % palette.count])
        }
    }

    var body: some View {
        ScreenScaffold("Component Count", subtitle: "Bill of materials for \(store.config.bays) bays × \(store.config.lifts) lifts") {

            CardView {
                HStack(spacing: Theme.Space.l) {
                    DonutChart(data: chartData, size: 130, lineWidth: 20,
                               centerTitle: "\(spec.totalPieces)", centerSubtitle: "parts")
                    VStack(alignment: .leading, spacing: 6) {
                        infoLine("Type", store.config.type.displayName, "square.grid.3x3.fill")
                        infoLine("Duty", store.config.dutyClass.displayName, "scalemass.fill")
                        infoLine("Decked", "\(store.deckedTiersCount) of \(store.config.lifts) lifts", "rectangle.grid.1x2.fill")
                        infoLine("Boards", "≥ \(store.config.dutyClass.minBoardsWide) wide", "rectangle.split.3x1.fill")
                    }
                }
            }

            SectionHeader(title: "Specification", subtitle: "Tap-free reference list", systemImage: "list.bullet.rectangle.fill")
            VStack(spacing: 10) {
                ForEach(spec.items) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Theme.tube.opacity(0.15)).frame(width: 40, height: 40)
                            Image(systemName: item.icon).foregroundColor(Theme.tube).font(.system(size: 17, weight: .semibold))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                            Text(item.detail).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        Text("\(item.count)").font(Theme.title(20)).foregroundColor(Theme.safety)
                    }
                    .padding(13)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Count by part", systemImage: "chart.bar.fill")
                    HBarChart(data: chartData)
                }
            }

            CardView(tint: Theme.safety.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.safety)
                    Text("Indicative quantities for planning. Confirm against the manufacturer's component schedule before ordering.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func infoLine(_ l: String, _ v: String, _ icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundColor(Theme.tube).font(.system(size: 12)).frame(width: 16)
            Text(l).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text(v).font(Theme.caption(12)).foregroundColor(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}
