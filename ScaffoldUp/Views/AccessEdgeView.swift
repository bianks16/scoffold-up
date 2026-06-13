//
//  AccessEdgeView.swift  (Screen 09 — Access & Edge Protection)
//  ScaffoldUp
//
//  Perimeter safety: guardrails, toe boards, ladder access and falling-object
//  protection, with counts from the component engine and a cross-section. iOS 14 safe.
//

import SwiftUI

struct AccessEdgeView: View {
    @EnvironmentObject var store: AppStore
    private var spec: ComponentSpec { store.componentSpec }

    var body: some View {
        ScreenScaffold("Access & Edge Protection", subtitle: "Stop falls of people and objects") {

            HStack(spacing: 10) {
                StatTile(value: "\(spec.count("Guardrails"))", label: "Guardrails", systemImage: "rectangle.tophalf.inset.filled", tint: Theme.success)
                StatTile(value: "\(spec.count("Toe boards"))", label: "Toe boards", systemImage: "rectangle.bottomthird.inset.filled", tint: Theme.safety)
                StatTile(value: "\(spec.count("Ladders"))", label: "Ladders", systemImage: "figure.stairs", tint: Theme.tube)
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Platform cross-section", systemImage: "square.dashed.inset.filled")
                    EdgeProtectionDrawing().frame(height: 150)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Edge protection", systemImage: "checkmark.shield.fill")
                    requirement("Principal guardrail", "Top rail ~950 mm above the platform.", "rectangle.tophalf.inset.filled", Theme.success)
                    requirement("Intermediate guardrail", "Gap to any rail no more than 470 mm.", "rectangle.split.1x2.fill", Theme.tube)
                    requirement("Toe board", "≥ 150 mm to stop tools and debris falling.", "rectangle.bottomthird.inset.filled", Theme.safety)
                    requirement("Brick guards / netting", "Add where materials are stacked at the edge.", "square.grid.4x3.fill", Theme.caution)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Access", systemImage: "figure.stairs")
                    requirement("Ladder access", "One per lift, tied at the top, extends ~1 m above the platform.", "figure.stairs", Theme.tube)
                    requirement("Trap doors", "Self-closing access hatches on internal ladder bays.", "door.left.hand.closed", Theme.info)
                    requirement("Clear platform", "Keep boards free of trip hazards and stored material.", "rectangle.grid.1x2.fill", Theme.accent)
                }
            }

            CardView(tint: Theme.danger.opacity(0.5)) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.to.line.compact").foregroundColor(Theme.danger)
                    Text("Protect people below: barrier off the drop zone, fit toe boards and brick guards, and never throw materials down.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                }
            }
        }
    }

    private func requirement(_ title: String, _ detail: String, _ icon: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.16)).frame(width: 34, height: 34)
                Image(systemName: icon).foregroundColor(tint).font(.system(size: 15, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.heading(14)).foregroundColor(Theme.textPrimary)
                Text(detail).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct EdgeProtectionDrawing: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let deckY = h * 0.78
            ZStack {
                // platform
                Rectangle().fill(Theme.tube.opacity(0.25)).frame(width: w * 0.8, height: 12).position(x: w / 2, y: deckY)
                Rectangle().fill(Theme.tube).frame(width: w * 0.8, height: 2).position(x: w / 2, y: deckY - 6)
                // standards (left/right)
                ForEach([0.1, 0.9], id: \.self) { f in
                    Rectangle().fill(Theme.tube).frame(width: 4, height: h * 0.7).position(x: w * CGFloat(f), y: deckY - h * 0.33)
                }
                // principal + intermediate guardrails (front edge = right)
                Rectangle().fill(Theme.success).frame(width: w * 0.8, height: 3).position(x: w / 2, y: deckY - h * 0.55)
                Rectangle().fill(Theme.tube).frame(width: w * 0.8, height: 3).position(x: w / 2, y: deckY - h * 0.30)
                // toe board
                Rectangle().fill(Theme.safety).frame(width: w * 0.8, height: 9).position(x: w / 2, y: deckY - 14)
                // worker glyph
                Image(systemName: "figure.stand").font(.system(size: 34)).foregroundColor(Theme.textSecondary.opacity(0.6))
                    .position(x: w * 0.4, y: deckY - 28)
                // labels
                Text("Top rail").font(Theme.caption(9)).foregroundColor(Theme.success).position(x: w * 0.5, y: deckY - h * 0.55 - 10)
                Text("Toe board").font(Theme.caption(9)).foregroundColor(Theme.safety).position(x: w * 0.5, y: deckY + 2)
            }
        }
    }
}
