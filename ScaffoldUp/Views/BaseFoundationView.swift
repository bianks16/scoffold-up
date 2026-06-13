//
//  BaseFoundationView.swift  (Screen 06 — Base & Foundation)
//  ScaffoldUp
//
//  Base plates vs adjustable screw jacks, sole boards and ground/slope advice
//  driven by the uneven-ground and height flags. iOS 14 safe.
//

import SwiftUI

struct BaseFoundationView: View {
    @EnvironmentObject var store: AppStore
    private var plan: BasePlan { store.basePlan }

    var body: some View {
        ScreenScaffold("Base & Foundation", subtitle: "What holds the scaffold up") {

            HStack(spacing: 10) {
                StatTile(value: "\(plan.standardLines)", label: "Standards", systemImage: "arrow.up.to.line", tint: Theme.tube)
                StatTile(value: plan.useJacks ? "\(plan.baseJacks)" : "\(plan.basePlates)",
                         label: plan.useJacks ? "Screw jacks" : "Base plates",
                         systemImage: "square.split.bottomrightquarter.fill",
                         tint: plan.useJacks ? Theme.caution : Theme.info)
                StatTile(value: "\(plan.soleBoards)", label: "Sole boards", systemImage: "rectangle.split.3x1.fill", tint: Theme.success)
            }

            CardView(tint: (plan.useJacks ? Theme.caution : Theme.success).opacity(0.45)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: plan.useJacks ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundColor(plan.useJacks ? Theme.caution : Theme.success)
                        Text(plan.useJacks ? "Uneven / soft ground" : "Firm, level ground")
                            .font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
                    }
                    Text(plan.useJacks
                         ? "Adjustable bases let you level the first lift on a slope. Don't extend jacks beyond the safe thread."
                         : "Standard steel base plates on timber sole boards spread the load into the ground.")
                        .font(Theme.body()).foregroundColor(Theme.textSecondary)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Foundation checklist", systemImage: "list.bullet.clipboard.fill")
                    ForEach(Array(plan.advice.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.tube).font(.system(size: 13)).padding(.top, 1)
                            Text(line).font(Theme.caption(13)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }

            // Base detail drawing
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Base detail", systemImage: "square.stack.3d.down.right.fill")
                    BaseDetailDrawing(useJacks: plan.useJacks).frame(height: 120)
                    HStack(spacing: 16) {
                        legendDot(Theme.tube, "Standard")
                        legendDot(plan.useJacks ? Theme.caution : Theme.info, plan.useJacks ? "Screw jack" : "Base plate")
                        legendDot(Theme.success, "Sole board")
                    }
                }
            }

            CardView(tint: Theme.safety.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.safety)
                    Text("Final base design — bearing capacity, slope and edge distances — must be confirmed by a competent person.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func legendDot(_ c: Color, _ l: String) -> some View {
        HStack(spacing: 5) { Circle().fill(c).frame(width: 9, height: 9)
            Text(l).font(Theme.caption(10)).foregroundColor(Theme.textSecondary) }
    }
}

private struct BaseDetailDrawing: View {
    let useJacks: Bool
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let groundY = h * 0.7
            ZStack {
                // ground
                Path { p in p.move(to: CGPoint(x: 0, y: groundY)); p.addLine(to: CGPoint(x: w, y: groundY + (useJacks ? 14 : 0))) }
                    .stroke(Theme.textMuted, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                ForEach(0..<3, id: \.self) { i in
                    let x = w * (CGFloat(i) + 0.5) / 3
                    let baseY = groundY + (useJacks ? CGFloat(i) * 7 : 0)
                    // sole board
                    Rectangle().fill(Theme.success.opacity(0.8)).frame(width: 46, height: 6).position(x: x, y: baseY + 8)
                    // base plate / jack
                    if useJacks {
                        Rectangle().fill(Theme.caution).frame(width: 5, height: 20).position(x: x, y: baseY - 2)
                        Rectangle().fill(Theme.caution.opacity(0.6)).frame(width: 18, height: 4).position(x: x, y: baseY + 4)
                    } else {
                        Rectangle().fill(Theme.info).frame(width: 22, height: 5).position(x: x, y: baseY + 2)
                    }
                    // standard
                    Rectangle().fill(Theme.tube).frame(width: 5, height: h * 0.45).position(x: x, y: baseY - h * 0.22 - 4)
                }
            }
        }
    }
}
