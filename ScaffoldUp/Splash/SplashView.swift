//
//  SplashView.swift
//  ScaffoldUp
//
//  Thematic launch animation. Three+ simultaneously animated layers:
//  (1) gradient + grid sweep + diagonal shimmer, (2) an isometric scaffold that
//  draws itself in lift-by-lift with a swinging crane hook, (3) the logo/title
//  spring entrance with a safety tag that ignites, then a designed scale-up exit.
//  A single coordinator timer drives the staged sequence; every looping
//  animation is torn down in onDisappear. iOS 14 safe.
//

import SwiftUI

// MARK: - A taller scaffold outline for the splash (drawn via trim)

private struct SplashScaffold: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let dx = w * 0.18, dy = h * 0.07
        let cols: [CGFloat] = [0.12, 0.50, 0.88]
        let levels: [CGFloat] = [1.0, 0.74, 0.48, 0.22, 0.04]

        // front uprights
        for c in cols { p.move(to: CGPoint(x: w * c, y: h * levels[0])); p.addLine(to: CGPoint(x: w * c, y: h * levels.last!)) }
        // back uprights
        for c in cols { p.move(to: CGPoint(x: w * c + dx, y: h * levels[0] - dy)); p.addLine(to: CGPoint(x: w * c + dx, y: h * levels.last! - dy)) }
        // ledgers + transoms per level
        for lv in levels {
            let y = h * lv
            p.move(to: CGPoint(x: w * cols.first!, y: y)); p.addLine(to: CGPoint(x: w * cols.last!, y: y))
            p.move(to: CGPoint(x: w * cols.first! + dx, y: y - dy)); p.addLine(to: CGPoint(x: w * cols.last! + dx, y: y - dy))
            for c in cols { p.move(to: CGPoint(x: w * c, y: y)); p.addLine(to: CGPoint(x: w * c + dx, y: y - dy)) }
        }
        // diagonal braces, left bay
        for i in 0..<(levels.count - 1) {
            let y0 = h * levels[i], y1 = h * levels[i + 1]
            if i % 2 == 0 { p.move(to: CGPoint(x: w * cols[0], y: y0)); p.addLine(to: CGPoint(x: w * cols[1], y: y1)) }
            else { p.move(to: CGPoint(x: w * cols[1], y: y0)); p.addLine(to: CGPoint(x: w * cols[0], y: y1)) }
        }
        return p
    }
}

struct SplashView: View {
    let onFinish: () -> Void

    @State private var isVisible = true

    // Staged reveals
    @State private var showGrid = false
    @State private var showStructure = false
    @State private var drawScaffold: CGFloat = 0
    @State private var showTag = false
    @State private var showLogo = false
    @State private var exiting = false

    // Looping layers
    @State private var shimmer = false
    @State private var hookSwing = false
    @State private var tagGlow = false

    // Single coordinator timer
    @State private var timer: Timer?
    @State private var elapsed: Double = 0

    var body: some View {
        ZStack {
            // ---- Layer 1: background + grid + shimmer ----
            Theme.background.ignoresSafeArea()

            SteelGrid(spacing: 34)
                .stroke(Theme.tube.opacity(showGrid ? 0.12 : 0), lineWidth: 0.8)
                .ignoresSafeArea()

            LinearGradient(colors: [.clear, Theme.tube.opacity(0.16), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(width: 240)
                .rotationEffect(.degrees(22))
                .offset(x: shimmer ? 320 : -320, y: shimmer ? 220 : -220)
                .ignoresSafeArea()
                .opacity(showGrid ? 1 : 0)

            // ---- Layer 2: scaffold draws in + crane hook ----
            ZStack(alignment: .top) {
                // crane jib + swinging hook line
                Path { p in
                    p.move(to: CGPoint(x: 20, y: 26)); p.addLine(to: CGPoint(x: 210, y: 14))
                }
                .stroke(Theme.tubeSoft.opacity(showStructure ? 0.5 : 0), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 230, height: 30)
                .offset(y: -150)

                Rectangle()
                    .fill(Theme.tubeSoft.opacity(showStructure ? 0.5 : 0))
                    .frame(width: 1.5, height: 46)
                    .offset(x: hookSwing ? 36 : -36, y: -150)
                    .overlay(
                        Image(systemName: "link")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.safety.opacity(showStructure ? 0.9 : 0))
                            .offset(x: hookSwing ? 36 : -36, y: -124)
                    )

                SplashScaffold()
                    .trim(from: 0, to: drawScaffold)
                    .stroke(Theme.tube, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 190, height: 200)
                    .opacity(showStructure ? 1 : 0)
            }
            .scaleEffect(exiting ? 1.7 : 1)
            .opacity(exiting ? 0 : 1)
            .offset(y: -10)

            // ---- Layer 3: logo + title + igniting tag ----
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.tube, lineWidth: 3)
                        .frame(width: 96, height: 96)
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Theme.tube)

                    // safety tag igniting at the corner
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Theme.safety)
                        .frame(width: 26, height: 32)
                        .overlay(Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(Theme.success))
                        .shadow(color: Theme.safety.opacity(tagGlow ? 0.8 : 0.3), radius: tagGlow ? 14 : 5)
                        .scaleEffect(showTag ? 1 : 0.1)
                        .opacity(showTag ? 1 : 0)
                        .offset(x: 52, y: -40)
                }
                .scaleEffect(showLogo ? (exiting ? 1.5 : 1) : 0.4)
                .opacity(showLogo ? (exiting ? 0 : 1) : 0)

                VStack(spacing: 5) {
                    Text("SCAFFOLD UP")
                        .font(.system(size: 31, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .tracking(2.5)
                    Text("Build it safe before you climb.")
                        .font(Theme.caption(13))
                        .foregroundColor(Theme.safety)
                }
                .opacity(showLogo ? (exiting ? 0 : 1) : 0)
                .offset(y: showLogo ? 0 : 18)
            }
        }
        .onAppear { start() }
        .onDisappear { teardown() }
    }

    // MARK: - Animation control

    private func start() {
        isVisible = true
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { hookSwing = true }
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) { shimmer = true }
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { tagGlow = true }

        elapsed = 0
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            elapsed += 0.05
            tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isVisible else { return }
        if elapsed >= 0.1 && !showGrid { withAnimation(.easeOut(duration: 0.6)) { showGrid = true } }
        if elapsed >= 0.5 && !showStructure {
            withAnimation(.easeInOut(duration: 0.4)) { showStructure = true }
            withAnimation(.easeInOut(duration: 1.0)) { drawScaffold = 1 }   // scaffold rises
        }
        if elapsed >= 1.6 && !showTag { withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { showTag = true } }
        if elapsed >= 1.9 && !showLogo { withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { showLogo = true } }
        if elapsed >= 2.5 && !exiting { withAnimation(.easeIn(duration: 0.5)) { exiting = true } }
        if elapsed >= 3.05 { timer?.invalidate(); timer = nil; onFinish() }
    }

    private func teardown() {
        isVisible = false
        timer?.invalidate(); timer = nil
        // reset loop state so no animation leaks into the main app
        shimmer = false; hookSwing = false; tagGlow = false
        showGrid = false; showStructure = false; showTag = false; showLogo = false
        drawScaffold = 0
    }
}
