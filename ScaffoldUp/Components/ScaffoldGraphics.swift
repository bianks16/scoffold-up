//
//  ScaffoldGraphics.swift
//  ScaffoldUp
//
//  The isometric scaffold drawing (tubular blue lines, boarded platforms,
//  diagonal braces, a hanging scaff-tag) plus the reusable green/red tag badge.
//  Pure Shape/Path geometry — iOS 14 safe, no Canvas (iOS 15+).
//

import SwiftUI

// MARK: - Isometric layout helper (value type — avoids nested funcs in ViewBuilder)

struct IsoLayout {
    let ox: CGFloat
    let frontBottomY: CGFloat
    let cellW: CGFloat
    let cellH: CGFloat
    let depthX: CGFloat
    let depthY: CGFloat
    let bays: Int
    let lifts: Int

    init(size: CGSize, bays: Int, lifts: Int) {
        let b = max(bays, 1), L = max(lifts, 1)
        let unitW = CGFloat(b) + 0.55
        let unitH = CGFloat(L) * 1.1 + 0.5
        let scale = min(size.width / unitW, size.height / unitH) * 0.9
        self.cellW = scale
        self.cellH = scale * 1.1
        self.depthX = scale * 0.55
        self.depthY = scale * 0.5
        let drawW = CGFloat(b) * cellW + depthX
        let drawH = CGFloat(L) * cellH + depthY
        self.ox = (size.width - drawW) / 2
        self.frontBottomY = (size.height - drawH) / 2 + drawH
        self.bays = b
        self.lifts = L
    }

    func front(_ col: Int, _ lift: Int) -> CGPoint {
        CGPoint(x: ox + CGFloat(col) * cellW, y: frontBottomY - CGFloat(lift) * cellH)
    }
    func back(_ col: Int, _ lift: Int) -> CGPoint {
        let f = front(col, lift); return CGPoint(x: f.x + depthX, y: f.y - depthY)
    }
}

struct ScaffoldIsometricView: View {
    let bays: Int
    let lifts: Int
    let deckedLevels: Set<Int>     // tier indices that are decked (0-based)
    var tagStatus: TagStatus = .green
    var highlightTier: Int? = nil

    var body: some View {
        GeometryReader { geo in
            let lay = IsoLayout(size: geo.size, bays: bays, lifts: lifts)
            ZStack {
                backFace(lay)
                depthTransoms(lay)
                ForEach(Array(deckedLevels).sorted(), id: \.self) { t in
                    if t < lay.lifts { deck(lay, level: t + 1, highlight: highlightTier == t) }
                }
                frontLedgers(lay)
                frontUprights(lay)
                braces(lay)
                basePlates(lay)
                tagGlyph(at: lay.front(lay.bays, lay.lifts), status: tagStatus)
            }
        }
    }

    private func backFace(_ lay: IsoLayout) -> some View {
        Path { p in
            for col in 0...lay.bays { p.move(to: lay.back(col, 0)); p.addLine(to: lay.back(col, lay.lifts)) }
            for lift in 0...lay.lifts { p.move(to: lay.back(0, lift)); p.addLine(to: lay.back(lay.bays, lift)) }
        }
        .stroke(Theme.tubeSoft.opacity(0.35), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }

    private func depthTransoms(_ lay: IsoLayout) -> some View {
        Path { p in
            for col in 0...lay.bays {
                for lift in 0...lay.lifts { p.move(to: lay.front(col, lift)); p.addLine(to: lay.back(col, lift)) }
            }
        }
        .stroke(Theme.tubeSoft.opacity(0.45), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    private func frontLedgers(_ lay: IsoLayout) -> some View {
        Path { p in
            for lift in 0...lay.lifts { p.move(to: lay.front(0, lift)); p.addLine(to: lay.front(lay.bays, lift)) }
        }
        .stroke(Theme.tube, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
    }

    private func frontUprights(_ lay: IsoLayout) -> some View {
        Path { p in
            for col in 0...lay.bays { p.move(to: lay.front(col, 0)); p.addLine(to: lay.front(col, lay.lifts)) }
        }
        .stroke(Theme.tube, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
    }

    private func braces(_ lay: IsoLayout) -> some View {
        Path { p in
            var bc = 0
            while bc < lay.bays {
                for lift in 0..<lay.lifts {
                    if lift % 2 == 0 { p.move(to: lay.front(bc, lift)); p.addLine(to: lay.front(bc + 1, lift + 1)) }
                    else { p.move(to: lay.front(bc + 1, lift)); p.addLine(to: lay.front(bc, lift + 1)) }
                }
                bc += 4
            }
        }
        .stroke(Theme.safety.opacity(0.85), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    }

    private func basePlates(_ lay: IsoLayout) -> some View {
        Path { p in
            let s: CGFloat = max(lay.cellW * 0.12, 3)
            for col in 0...lay.bays {
                let f = lay.front(col, 0)
                p.addRect(CGRect(x: f.x - s, y: f.y - 1.5, width: s * 2, height: 3))
                let bk = lay.back(col, 0)
                p.addRect(CGRect(x: bk.x - s, y: bk.y - 1.5, width: s * 2, height: 3))
            }
        }
        .fill(Theme.tubeSoft.opacity(0.5))
    }

    // Platform parallelogram with board lines.
    private func deck(_ lay: IsoLayout, level: Int, highlight: Bool) -> some View {
        let fl = lay.front(0, level), fr = lay.front(lay.bays, level)
        let br = lay.back(lay.bays, level), bl = lay.back(0, level)
        return ZStack {
            Path { p in p.move(to: fl); p.addLine(to: fr); p.addLine(to: br); p.addLine(to: bl); p.closeSubpath() }
                .fill((highlight ? Theme.safety : Theme.tube).opacity(highlight ? 0.32 : 0.18))
            Path { p in
                for k in 1..<5 {
                    let t = CGFloat(k) / 5.0
                    let a = CGPoint(x: fl.x + (bl.x - fl.x) * t, y: fl.y + (bl.y - fl.y) * t)
                    let c = CGPoint(x: fr.x + (br.x - fr.x) * t, y: fr.y + (br.y - fr.y) * t)
                    p.move(to: a); p.addLine(to: c)
                }
            }
            .stroke((highlight ? Theme.safetyHi : Theme.tubeSoft).opacity(0.7), lineWidth: 1)
            Path { p in p.move(to: fl); p.addLine(to: fr); p.addLine(to: br); p.addLine(to: bl); p.closeSubpath() }
                .stroke(highlight ? Theme.safety : Theme.tube, lineWidth: highlight ? 2 : 1.2)
        }
    }

    private func tagGlyph(at point: CGPoint, status: TagStatus) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.tubeSoft.opacity(0.6)).frame(width: 1.5, height: 12)
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.safety)
                .frame(width: 26, height: 32)
                .overlay(
                    VStack(spacing: 2) {
                        Circle().fill(status.color).frame(width: 12, height: 12)
                        Rectangle().fill(Theme.textOnAccent.opacity(0.5)).frame(width: 16, height: 1.4)
                        Rectangle().fill(Theme.textOnAccent.opacity(0.35)).frame(width: 16, height: 1.4)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.textOnAccent.opacity(0.25), lineWidth: 1))
                .shadow(color: Theme.safety.opacity(0.4), radius: 5)
        }
        .position(x: point.x + 16, y: point.y + 18)
    }
}

// MARK: - Reusable scaff-tag badge (green/red)

struct ScaffTagBadge: View {
    let status: TagStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7).fill(Theme.safetyGradient)
                    .frame(width: compact ? 34 : 44, height: compact ? 42 : 54)
                VStack(spacing: 3) {
                    Image(systemName: status.icon)
                        .font(.system(size: compact ? 14 : 18, weight: .bold))
                        .foregroundColor(status.color)
                    if !compact {
                        Rectangle().fill(Theme.textOnAccent.opacity(0.4)).frame(width: 24, height: 1.5)
                        Rectangle().fill(Theme.textOnAccent.opacity(0.3)).frame(width: 24, height: 1.5)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(status.headline).font(Theme.heading(compact ? 13 : 15)).foregroundColor(status.color)
                Text(status.displayName).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            }
        }
    }
}
