//
//  OnboardingView.swift
//  ScaffoldUp
//
//  Four onboarding screens, first launch only. Each has a unique interaction:
//  (1) tap-to-spark, (2) drag knob to set duty, (3) scroll-driven parallax with
//  steppers, (4) slide-to-start confirm gesture. Choices are written into the
//  AppStore configuration. iOS 14 safe (PageTabViewStyle, withAnimation).
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    let onComplete: () -> Void

    @State private var page = 0

    // Draft configuration
    @State private var type: ScaffoldType = .facade
    @State private var duty: DutyClass = .general
    @State private var bays = 4
    @State private var lifts = 3
    @State private var bayLenRaw = BayLength.b25.rawValue
    @State private var widthRaw = PlatformWidth.w090.rawValue
    @State private var liftHeight = 2.0
    @State private var wind: WindExposure = .moderate
    @State private var uneven = false
    @State private var power = false

    var body: some View {
        ZStack {
            SteelBackground(showFrame: true)

            VStack(spacing: 0) {
                HStack {
                    Text("\(page + 1) / 4").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                    Spacer()
                    Button("Skip") { finish() }
                        .font(Theme.caption(14)).foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.Space.l)
                .padding(.top, Theme.Space.m)

                TabView(selection: $page) {
                    TypePage(type: $type).tag(0)
                    DutyPage(duty: $duty).tag(1)
                    DimPage(bays: $bays, lifts: $lifts, bayLenRaw: $bayLenRaw,
                            widthRaw: $widthRaw, liftHeight: $liftHeight).tag(2)
                    SitePage(wind: $wind, uneven: $uneven, power: $power, onStart: finish).tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == page ? Theme.safety : Theme.stroke)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.vertical, 12)

                if page < 3 {
                    ActionButton(title: primaryTitle, systemImage: "arrow.right", kind: .primary) { advance() }
                        .padding(.horizontal, Theme.Space.l)
                        .padding(.bottom, Theme.Space.l)
                } else {
                    // Page 4 uses the slide-to-start control inside SitePage.
                    Color.clear.frame(height: 1).padding(.bottom, Theme.Space.l)
                }
            }
        }
    }

    private var primaryTitle: String {
        switch page { case 0: return "Set Type"; case 1: return "Set Duty"; default: return "Set Size" }
    }
    private func advance() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { page = min(page + 1, 3) }
    }
    private func finish() {
        var c = ScaffoldConfig()
        c.name = store.config.name
        c.type = type; c.dutyClass = duty
        c.bays = bays; c.lifts = lifts
        c.bayLengthRaw = bayLenRaw; c.platformWidthRaw = widthRaw; c.liftHeight = liftHeight
        c.windExposure = wind; c.unevenGround = uneven; c.nearPowerLines = power
        store.updateConfig(c)
        onComplete()
    }
}

// MARK: - Page 1: Scaffold type (tap to spark)

private struct TypePage: View {
    @Binding var type: ScaffoldType
    @State private var sparks: [Spark] = []
    @State private var pulse = false
    struct Spark: Identifiable { let id = UUID(); let angle: Double; var go = false }

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            header("Pick your scaffold type", "Tap the frame to spark it — sets the kit & rules")

            ZStack {
                ForEach(sparks) { s in
                    Rectangle().fill(Theme.safety)
                        .frame(width: 6, height: 6)
                        .offset(x: s.go ? CGFloat(cos(s.angle)) * 80 : 0,
                                y: s.go ? CGFloat(sin(s.angle)) * 80 : 0)
                        .opacity(s.go ? 0 : 1)
                }
                RoundedRectangle(cornerRadius: 22).fill(Theme.tubeGradient)
                    .frame(width: 108, height: 108)
                    .scaleEffect(pulse ? 1.05 : 0.97)
                    .overlay(Image(systemName: type.icon).font(.system(size: 44, weight: .bold)).foregroundColor(.white))
                    .shadow(color: Theme.accent.opacity(0.45), radius: 12)
            }
            .frame(height: 120)
            .onTapGesture { spark() }

            VStack(spacing: 10) {
                ForEach(ScaffoldType.allCases) { t in
                    SelectRow(icon: t.icon, title: t.displayName, subtitle: t.subtitle,
                              selected: type == t) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { type = t }
                        spark()
                    }
                }
            }
            .padding(.horizontal, Theme.Space.l)
            Spacer(minLength: 0)
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true } }
        .onDisappear { pulse = false }
    }

    private func spark() {
        sparks = (0..<10).map { Spark(angle: Double($0) / 10 * 2 * .pi) }
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.55)) { for i in sparks.indices { sparks[i].go = true } }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { sparks.removeAll() }
    }
}

// MARK: - Page 2: Duty class (drag knob)

private struct DutyPage: View {
    @Binding var duty: DutyClass
    private let levels = DutyClass.allCases

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            header("How heavy is the work?", "Drag the marker — sets the safe platform load")

            GeometryReader { geo in
                let trackW = geo.size.width - 60
                let seg = trackW / CGFloat(levels.count - 1)
                let index = levels.firstIndex(of: duty) ?? 1
                let knobX = 30 + CGFloat(index) * seg

                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceAlt).frame(height: 10)
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    Capsule().fill(Theme.safetyGradient).frame(width: knobX, height: 10)
                    Circle().fill(Theme.safety).frame(width: 34, height: 34)
                        .overlay(Image(systemName: "scalemass.fill").foregroundColor(Theme.textOnAccent).font(.system(size: 14, weight: .bold)))
                        .shadow(color: Theme.safety.opacity(0.5), radius: 6, y: 3)
                        .position(x: knobX, y: 5)
                        .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                            let clamped = min(max(v.location.x - 30, 0), trackW)
                            let idx = Int((clamped / seg).rounded())
                            let newLevel = levels[min(max(idx, 0), levels.count - 1)]
                            if newLevel != duty { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { duty = newLevel } }
                        })
                }
                .frame(height: 40)
                .position(x: geo.size.width / 2, y: 30)
            }
            .frame(height: 60)
            .padding(.horizontal, Theme.Space.l)

            HStack {
                ForEach(levels) { l in
                    Text(l.shortName).font(Theme.caption(12))
                        .foregroundColor(duty == l ? Theme.safety : Theme.textSecondary)
                        .fontWeight(duty == l ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Theme.Space.l)

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "scalemass.fill").foregroundColor(duty.color)
                        Text(duty.displayName).font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(Formatters.decimal(duty.loadPerSqmKN, digits: 2)) kN/m²")
                            .font(Theme.mono(13)).foregroundColor(Theme.safety)
                    }
                    Text(duty.usage).font(Theme.body()).foregroundColor(Theme.textSecondary)
                    Text("≈ \(Formatters.decimal(duty.loadPerSqmKg, digits: 0)) kg/m² · ≥ \(duty.minBoardsWide) boards wide")
                        .font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                }
            }
            .padding(.horizontal, Theme.Space.l)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Page 3: Dimensions (scroll parallax + steppers)

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct DimPage: View {
    @Binding var bays: Int
    @Binding var lifts: Int
    @Binding var bayLenRaw: Double
    @Binding var widthRaw: Double
    @Binding var liftHeight: Double
    @State private var offset: CGFloat = 0

    private var facade: Double { Double(bays) * bayLenRaw }
    private var height: Double { Double(lifts) * liftHeight }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                ScaffoldFrameMark()
                    .stroke(Theme.tube.opacity(0.18), lineWidth: 1.4)
                    .frame(width: 150, height: 180)
                    .offset(x: 95, y: -offset * 0.45 + 10)
                Image(systemName: "ruler.fill")
                    .font(.system(size: 120, weight: .thin))
                    .foregroundColor(Theme.tube.opacity(0.08))
                    .offset(x: -100, y: -offset * 0.28 + 40)

                VStack(spacing: Theme.Space.m) {
                    GeometryReader { proxy in
                        Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("scroll")).minY)
                    }.frame(height: 0)

                    header("Set the dimensions", "We size the frame & count the parts")
                        .offset(y: offset * 0.12)

                    CardView {
                        VStack(spacing: 14) {
                            StepperRow(label: "Bays (along facade)", systemImage: "rectangle.split.3x1.fill",
                                       value: $bays, range: 1...12)
                            Divider().background(Theme.stroke)
                            StepperRow(label: "Lifts (height tiers)", systemImage: "square.stack.3d.up.fill",
                                       value: $lifts, range: 1...10)
                        }
                    }.padding(.horizontal, Theme.Space.l)

                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            pickerRow("Bay length", BayLength.allCases.map { ($0.label, $0.rawValue) }, $bayLenRaw)
                            pickerRow("Platform width", PlatformWidth.allCases.map { ($0.label, $0.rawValue) }, $widthRaw)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("LIFT HEIGHT").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                                HStack {
                                    Slider(value: $liftHeight, in: 1.5...2.5, step: 0.1).accentColor(Theme.accent)
                                    Text("\(Formatters.decimal(liftHeight, digits: 1)) m").font(Theme.mono(13)).foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                    }.padding(.horizontal, Theme.Space.l)

                    CardView(tint: Theme.tube.opacity(0.4)) {
                        HStack(spacing: 18) {
                            metric("Facade", "\(Formatters.decimal(facade, digits: 1)) m", "rectangle.split.3x1.fill")
                            metric("Height", "\(Formatters.decimal(height, digits: 1)) m", "arrow.up.to.line")
                            metric("Sections", "\(bays * lifts)", "square.grid.3x3.fill")
                        }
                    }.padding(.horizontal, Theme.Space.l)

                    Spacer(minLength: 80)
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset = $0 }
    }

    private func metric(_ l: String, _ v: String, _ icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).foregroundColor(Theme.tube).font(.system(size: 14, weight: .bold))
            Text(v).font(Theme.heading(15)).foregroundColor(Theme.textPrimary)
            Text(l).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
    private func pickerRow(_ label: String, _ options: [(String, Double)], _ binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            Picker(label, selection: binding) {
                ForEach(options, id: \.1) { Text($0.0).tag($0.1) }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: - Page 4: Site conditions (slide-to-start)

private struct SitePage: View {
    @Binding var wind: WindExposure
    @Binding var uneven: Bool
    @Binding var power: Bool
    let onStart: () -> Void
    @State private var slide: CGFloat = 0
    @State private var armed = false

    var body: some View {
        VStack(spacing: Theme.Space.m) {
            header("Site conditions", "These raise the anchoring & base requirements")

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("WIND EXPOSURE").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    Picker("", selection: $wind) {
                        ForEach(WindExposure.allCases) { Text($0.displayName).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle())
                    Text("Exposed sites need more wall ties for wind load.")
                        .font(Theme.caption(11)).foregroundColor(Theme.textMuted)
                }
            }.padding(.horizontal, Theme.Space.l)

            CardView {
                VStack(spacing: 12) {
                    Toggle(isOn: $uneven) {
                        Label("Uneven / soft ground", systemImage: "square.split.bottomrightquarter.fill")
                            .font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }.toggleStyle(SwitchToggleStyle(tint: Theme.caution))
                    Divider().background(Theme.stroke)
                    Toggle(isOn: $power) {
                        Label("Near power lines", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                            .font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }.toggleStyle(SwitchToggleStyle(tint: Theme.danger))
                }
            }.padding(.horizontal, Theme.Space.l)

            Spacer(minLength: 0)

            // Slide-to-start (a confirm-drag gesture, distinct from the duty knob).
            GeometryReader { geo in
                let trackW = geo.size.width
                let knob: CGFloat = 56
                let maxX = trackW - knob
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.surfaceHi)
                        .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                    Capsule().fill(Theme.accentGradient).frame(width: slide + knob)
                    Text(armed ? "Release to build" : "Slide to start building")
                        .font(Theme.heading(14)).foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                    Circle().fill(Theme.safety)
                        .frame(width: knob - 10, height: knob - 10)
                        .overlay(Image(systemName: "hammer.fill").foregroundColor(Theme.textOnAccent).font(.system(size: 18, weight: .bold)))
                        .offset(x: slide + 5)
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                slide = min(max(v.translation.width, 0), maxX)
                                armed = slide > maxX * 0.75
                            }
                            .onEnded { _ in
                                if slide > maxX * 0.75 {
                                    withAnimation(.spring()) { slide = maxX }
                                    onStart()
                                } else {
                                    withAnimation(.spring()) { slide = 0; armed = false }
                                }
                            })
                }
            }
            .frame(height: 56)
            .padding(.horizontal, Theme.Space.l)
            .padding(.bottom, Theme.Space.l)
        }
    }
}

// MARK: - Shared pieces

private func header(_ title: String, _ subtitle: String) -> some View {
    VStack(spacing: 6) {
        Text(title).font(Theme.title(27)).multilineTextAlignment(.center).foregroundColor(Theme.textPrimary)
        Text(subtitle).font(Theme.caption(13)).foregroundColor(Theme.textSecondary).multilineTextAlignment(.center)
    }
    .padding(.horizontal, Theme.Space.l)
    .padding(.top, Theme.Space.l)
}

private struct SelectRow: View {
    let icon: String; let title: String; let subtitle: String; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(selected ? .white : Theme.tube).frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.heading(15)).foregroundColor(selected ? .white : Theme.textPrimary)
                    Text(subtitle).font(Theme.caption(11)).foregroundColor(selected ? .white.opacity(0.85) : Theme.textSecondary)
                }
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundColor(.white) }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(selected ? Theme.accent : Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
