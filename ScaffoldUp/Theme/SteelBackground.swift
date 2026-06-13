//
//  SteelBackground.swift
//  ScaffoldUp
//
//  The reusable dark blue-steel backdrop: gradient + fine grid + a faint
//  isometric scaffold frame mark. Drawn entirely with Shapes/Paths (no assets).
//  iOS 14 safe.
//

import SwiftUI

// MARK: - Grid shape

struct SteelGrid: Shape {
    var spacing: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var p = Path()
        var x: CGFloat = 0
        while x <= rect.width { p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: rect.height)); x += spacing }
        var y: CGFloat = 0
        while y <= rect.height { p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: rect.width, y: y)); y += spacing }
        return p
    }
}

// MARK: - A faint isometric scaffold frame glyph (decoration)

struct ScaffoldFrameMark: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let dx = w * 0.22, dy = h * 0.14   // isometric depth offset
        // front uprights
        p.move(to: CGPoint(x: w * 0.12, y: h)); p.addLine(to: CGPoint(x: w * 0.12, y: h * 0.10))
        p.move(to: CGPoint(x: w * 0.62, y: h)); p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.10))
        // back uprights
        p.move(to: CGPoint(x: w * 0.12 + dx, y: h - dy)); p.addLine(to: CGPoint(x: w * 0.12 + dx, y: h * 0.10 - dy))
        p.move(to: CGPoint(x: w * 0.62 + dx, y: h - dy)); p.addLine(to: CGPoint(x: w * 0.62 + dx, y: h * 0.10 - dy))
        // ledgers at 3 levels + transoms
        for f in [0.10, 0.40, 0.70, 1.0] {
            let y = h * CGFloat(f)
            p.move(to: CGPoint(x: w * 0.12, y: y)); p.addLine(to: CGPoint(x: w * 0.62, y: y))
            p.move(to: CGPoint(x: w * 0.12 + dx, y: y - dy)); p.addLine(to: CGPoint(x: w * 0.62 + dx, y: y - dy))
            p.move(to: CGPoint(x: w * 0.12, y: y)); p.addLine(to: CGPoint(x: w * 0.12 + dx, y: y - dy))
            p.move(to: CGPoint(x: w * 0.62, y: y)); p.addLine(to: CGPoint(x: w * 0.62 + dx, y: y - dy))
        }
        // a diagonal brace
        p.move(to: CGPoint(x: w * 0.12, y: h)); p.addLine(to: CGPoint(x: w * 0.62, y: h * 0.40))
        return p
    }
}

// MARK: - Backdrop view

struct SteelBackground: View {
    var showFrame: Bool = true

    var body: some View {
        ZStack {
            Theme.background
            SteelGrid(spacing: 30)
                .stroke(Theme.tube.opacity(0.06), lineWidth: 0.6)
            SteelGrid(spacing: 150)
                .stroke(Theme.tube.opacity(0.10), lineWidth: 1)

            if showFrame {
                ScaffoldFrameMark()
                    .stroke(Theme.tube.opacity(0.10),
                            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 150, height: 180)
                    .position(x: UIScreen.main.bounds.width - 80, y: 130)
            }
        }
        .ignoresSafeArea()
    }
}

/// Convenience modifier so any screen can sit on the steel backdrop.
extension View {
    func steelScreen(showFrame: Bool = true) -> some View {
        ZStack {
            SteelBackground(showFrame: showFrame)
            self
        }
    }
}
