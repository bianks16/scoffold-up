//
//  CostView.swift  (Screen 11 — Material & Rental Cost)
//  ScaffoldUp
//
//  Rental cost of the scaffold by component and time: editable per-component
//  daily rates, rental window, live total and a cost-split chart. iOS 14 safe.
//

import SwiftUI

struct CostView: View {
    @EnvironmentObject var store: AppStore

    @State private var days: Int = 14
    @State private var startDate = Date()
    @State private var loaded = false

    private var chartData: [ChartDatum] {
        let palette: [Color] = [Theme.tube, Theme.info, Theme.accent, Theme.safety,
                                Theme.success, Theme.caution, Theme.tubeSoft, Theme.warning,
                                Theme.accentHi, Theme.danger, Theme.textSecondary]
        return store.costLines.enumerated()
            .filter { $0.element.includeInTotal && $0.element.cost(days: days) > 0 }
            .map { idx, line in ChartDatum(label: line.name, value: line.cost(days: days),
                                           color: palette[idx % palette.count]) }
    }

    var body: some View {
        ScreenScaffold("Material & Rental Cost", subtitle: "Estimate hire cost by time & parts") {

            CardView(tint: Theme.safety.opacity(0.45)) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Estimated rental").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        Text(store.money(store.totalRentalCost)).font(Theme.title(28)).foregroundColor(Theme.textPrimary)
                        Text("\(days) days · \(store.componentSpec.totalPieces) parts").font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                    }
                    Spacer()
                    Image(systemName: "sterlingsign.circle.fill").font(.system(size: 40)).foregroundColor(Theme.safety)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Rental window", systemImage: "calendar")
                    HStack {
                        Text("Start").font(Theme.body()).foregroundColor(Theme.textSecondary)
                        Spacer()
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden().accentColor(Theme.accent)
                            .onChange(of: startDate) { store.setRentalStart($0) }
                    }
                    StepperRow(label: "Hire length", systemImage: "clock.fill", value: $days, range: 1...365, suffix: " d") { d in
                        store.setRentalDays(d)
                    }
                    HStack {
                        Text("Return by").font(Theme.body()).foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text(Formatters.date(store.rentalEnd)).font(Theme.heading(14)).foregroundColor(Theme.safety)
                    }
                }
            }

            SectionHeader(title: "Rates per part / day", subtitle: "Tap a value to edit", systemImage: "slider.horizontal.3")
            VStack(spacing: 9) {
                ForEach(store.costLines) { line in
                    CostLineRow(line: line, days: days)
                }
            }

            if !chartData.isEmpty {
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Cost split", systemImage: "chart.bar.fill")
                        HBarChart(data: chartData, valueSuffix: "")
                    }
                }
            }

            CardView(tint: Theme.info.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.info)
                    Text("Rates are placeholders — set your hire company's daily rates. Excludes delivery, erect/dismantle labour and damage waiver.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
        .onAppear { if !loaded { days = store.rentalDays; startDate = store.rentalStart; loaded = true } }
    }
}

private struct CostLineRow: View {
    @EnvironmentObject var store: AppStore
    let line: CostLine
    let days: Int

    @State private var rateText = ""
    @State private var loaded = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: { toggle() }) {
                Image(systemName: line.includeInTotal ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20)).foregroundColor(line.includeInTotal ? Theme.success : Theme.textMuted)
            }.buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(line.name).font(Theme.heading(14)).foregroundColor(Theme.textPrimary)
                Text("\(Formatters.decimal(line.quantity, digits: 0)) × \(days) d").font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 3) {
                Text(store.currency.symbol).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                TextField("0", text: $rateText, onCommit: commit)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    .font(Theme.mono(13)).foregroundColor(Theme.textPrimary).frame(width: 52)
                    .onChange(of: rateText) { _ in commit() }
                Text("/d").font(Theme.caption(10)).foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceAlt))

            Text(store.money(line.cost(days: days)))
                .font(Theme.heading(14)).foregroundColor(line.includeInTotal ? Theme.safety : Theme.textMuted)
                .frame(width: 64, alignment: .trailing)
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
        .onAppear { if !loaded { rateText = Formatters.decimal(line.unitRatePerDay, digits: 2); loaded = true } }
    }

    private func toggle() {
        var l = line; l.includeInTotal.toggle(); store.updateCostLine(l)
    }
    private func commit() {
        let rate = max(0, Double(rateText.replacingOccurrences(of: ",", with: ".")) ?? 0)
        if rate != line.unitRatePerDay { var l = line; l.unitRatePerDay = rate; store.updateCostLine(l) }
    }
}
