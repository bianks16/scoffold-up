//
//  TieAnchorView.swift  (Screen 05 — Tie & Anchor Plan)
//  ScaffoldUp
//
//  Wall ties / anchors by face area and height, with a visual anchor grid on the
//  facade and a wind-load note. Free-standing mobile towers show a stability
//  note instead. iOS 14 safe.
//

import SwiftUI

struct TieAnchorView: View {
    @EnvironmentObject var store: AppStore
    private var plan: TiePlan { store.tiePlan }

    var body: some View {
        ScreenScaffold("Tie & Anchor Plan", subtitle: "Wall ties by area, height & wind") {

            if !plan.needed {
                CardView(tint: Theme.info.opacity(0.5)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack { Image(systemName: "cart.fill").foregroundColor(Theme.info)
                            Text("Free-standing tower").font(Theme.heading(15)).foregroundColor(Theme.textPrimary) }
                        Text("Mobile towers aren't tied to a wall. Stay within the safe height-to-base ratio, use outriggers/stabilisers and never move the tower with people or materials on it.")
                            .font(Theme.body()).foregroundColor(Theme.textSecondary)
                    }
                }
            } else {
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Anchors required").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                            Text("\(plan.required)").font(Theme.title(34)).foregroundColor(Theme.safety)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            metric("Grid", "\(plan.rows) × \(plan.cols)")
                            metric("Face area", store.area(plan.faceArea))
                            metric("Per tie", store.area(plan.areaPerTie))
                        }
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Anchor points", subtitle: "Pattern on the facade", systemImage: "pin.fill")
                        AnchorGridView(rows: plan.rows, cols: plan.cols)
                            .frame(height: 170)
                        HStack {
                            Label("V spacing \(store.len(plan.verticalSpacing))", systemImage: "arrow.up.and.down")
                            Spacer()
                            Label("H spacing \(store.len(plan.horizontalSpacing))", systemImage: "arrow.left.and.right")
                        }.font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    }
                }
            }

            CardView(tint: Theme.warning.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: store.config.windExposure.icon).foregroundColor(Theme.warning)
                    Text(plan.windNote).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }

            if plan.powerLineWarning {
                CardView(tint: Theme.danger.opacity(0.6)) {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill").foregroundColor(Theme.danger)
                        Text("Near power lines: keep ties and tubes clear of conductors. Isolate or insulate and maintain the required exclusion zone.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Tie guidance", systemImage: "info.circle.fill")
                    bullet("Use through-ties or anchor ties into sound masonry, not into render alone.")
                    bullet("Test a sample of anchors with a calibrated tester before loading.")
                    bullet("Add extra ties where the scaffold is sheeted or netted (more wind load).")
                }
            }
        }
    }

    private func metric(_ l: String, _ v: String) -> some View {
        HStack(spacing: 6) {
            Text(l).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            Text(v).font(Theme.heading(14)).foregroundColor(Theme.textPrimary)
        }
    }
    private func bullet(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Theme.tube).frame(width: 5, height: 5).padding(.top, 6)
            Text(s).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Anchor grid drawing

private struct AnchorGridView: View {
    let rows: Int
    let cols: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                // facade
                RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceAlt)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.stroke, lineWidth: 1))
                // brick hint lines
                Path { p in
                    var y: CGFloat = 18
                    while y < h { p.move(to: CGPoint(x: 6, y: y)); p.addLine(to: CGPoint(x: w - 6, y: y)); y += 18 }
                }.stroke(Theme.stroke.opacity(0.6), lineWidth: 0.5)

                // anchors
                ForEach(0..<rows, id: \.self) { r in
                    ForEach(0..<cols, id: \.self) { c in
                        let x = w * (CGFloat(c) + 0.5) / CGFloat(max(cols, 1))
                        let y = h - h * (CGFloat(r) + 0.5) / CGFloat(max(rows, 1))
                        ZStack {
                            Circle().fill(Theme.safety.opacity(0.25)).frame(width: 22, height: 22)
                            Image(systemName: "pin.fill").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.safety)
                        }
                        .position(x: x, y: y)
                    }
                }
            }
        }
    }
}
