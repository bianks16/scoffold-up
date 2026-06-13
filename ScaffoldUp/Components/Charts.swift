//
//  Charts.swift
//  ScaffoldUp
//
//  Hand-drawn charts (Swift Charts is iOS 16+). Bar and donut, built with
//  Shape/Path/GeometryReader. iOS 14 safe.
//

import SwiftUI

struct ChartDatum: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    var color: Color = Theme.tube
}

// MARK: - Horizontal bar chart (component counts / loads)

struct HBarChart: View {
    let data: [ChartDatum]
    var valueSuffix: String = ""

    private var maxValue: Double { max(data.map { $0.value }.max() ?? 1, 1) }

    var body: some View {
        VStack(spacing: 9) {
            ForEach(data) { d in
                HStack(spacing: 8) {
                    Text(d.label).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        .frame(width: 92, alignment: .leading).lineLimit(1).minimumScaleFactor(0.7)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceAlt).frame(height: 14)
                            Capsule()
                                .fill(LinearGradient(colors: [d.color, d.color.opacity(0.6)],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(geo.size.width * CGFloat(d.value / maxValue), 4), height: 14)
                        }
                    }
                    .frame(height: 14)
                    Text(Formatters.decimal(d.value, digits: 0) + valueSuffix)
                        .font(Theme.mono(11)).foregroundColor(Theme.textPrimary)
                        .frame(width: 52, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Donut chart

struct DonutChart: View {
    let data: [ChartDatum]
    var size: CGFloat = 150
    var lineWidth: CGFloat = 24
    var centerTitle: String = ""
    var centerSubtitle: String = "total"

    private var total: Double { max(data.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        ZStack {
            ForEach(Array(segments().enumerated()), id: \.offset) { _, seg in
                Circle()
                    .trim(from: seg.start, to: seg.end)
                    .stroke(seg.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 0) {
                Text(centerTitle.isEmpty ? Formatters.decimal(total, digits: 0) : centerTitle)
                    .font(Theme.title(20)).foregroundColor(Theme.textPrimary)
                Text(centerSubtitle).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }

    private func segments() -> [(start: CGFloat, end: CGFloat, color: Color)] {
        var result: [(CGFloat, CGFloat, Color)] = []
        var running: Double = 0
        for d in data {
            let start = running / total
            running += d.value
            result.append((CGFloat(start), CGFloat(running / total), d.color))
        }
        return result
    }
}

struct ChartLegend: View {
    let items: [ChartDatum]
    var suffix: String = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items) { item in
                HStack(spacing: 8) {
                    Circle().fill(item.color).frame(width: 9, height: 9)
                    Text(item.label).font(Theme.caption()).foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(Formatters.decimal(item.value, digits: 0) + suffix)
                        .font(Theme.caption()).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }
}
