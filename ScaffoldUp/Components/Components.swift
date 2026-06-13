//
//  Components.swift
//  ScaffoldUp
//
//  Reusable UI kit: action buttons, cards, chips, stat tiles, progress bars,
//  styled inputs, segmented selectors and empty state. iOS 14 safe (custom
//  ButtonStyles, value-form overlay/background).
//

import SwiftUI

// MARK: - Button styles

struct ActionButtonStyle: ButtonStyle {
    enum Kind { case primary, safety, secondary, danger }
    var kind: Kind = .primary
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.heading(15))
            .foregroundColor(foreground)
            .padding(.vertical, 13)
            .padding(.horizontal, 18)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .stroke(kind == .secondary ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.4)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch kind {
        case .primary:   return Theme.textOnBlue
        case .safety:    return Theme.textOnAccent
        case .secondary: return Theme.accentHi
        case .danger:    return .white
        }
    }
    @ViewBuilder private var background: some View {
        switch kind {
        case .primary:   Theme.accentGradient
        case .safety:    Theme.safetyGradient
        case .secondary: Theme.surfaceHi
        case .danger:    LinearGradient(colors: [Theme.danger, Theme.danger.opacity(0.82)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct ActionButton: View {
    let title: String
    var systemImage: String? = nil
    var kind: ActionButtonStyle.Kind = .primary
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let img = systemImage { Image(systemName: img) }
                Text(title)
            }
        }
        .buttonStyle(ActionButtonStyle(kind: kind, fullWidth: fullWidth))
    }
}

// MARK: - Card container

struct CardView<Content: View>: View {
    var padding: CGFloat = Theme.Space.m
    var tint: Color? = nil
    let content: () -> Content
    init(padding: CGFloat = Theme.Space.m, tint: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding; self.tint = tint; self.content = content
    }
    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m)
                    .stroke(tint ?? Theme.stroke, lineWidth: tint == nil ? 1 : 1.4)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 9, x: 0, y: 5)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var tint: Color = Theme.tube

    var body: some View {
        HStack(spacing: 9) {
            if let img = systemImage {
                Image(systemName: img).foregroundColor(tint).font(.system(size: 15, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.heading(17)).foregroundColor(Theme.textPrimary)
                if let s = subtitle {
                    Text(s).font(Theme.caption()).foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Status chip

struct TagChip: View {
    let text: String
    var color: Color = Theme.accent
    var filled: Bool = false
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon { Image(systemName: icon).font(.system(size: 9, weight: .bold)) }
            Text(text)
        }
        .font(Theme.caption(11))
        .foregroundColor(filled ? Theme.textOnAccent : color)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(filled ? color : color.opacity(0.16)))
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let value: String
    let label: String
    var systemImage: String
    var tint: Color = Theme.tube

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage).font(.system(size: 15, weight: .bold)).foregroundColor(tint)
            Text(value).font(Theme.title(21)).foregroundColor(Theme.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
        }
        .padding(Theme.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(tint.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Linear progress / ratio bar

struct RatioBar: View {
    var ratio: Double           // 0...(>1 for overload)
    var height: CGFloat = 12
    var tint: Color = Theme.success

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(min(max(ratio, 0), 1)))
                // 100% limit marker
                Rectangle().fill(Theme.textPrimary.opacity(0.35))
                    .frame(width: 1.5)
                    .position(x: geo.size.width - 1, y: height / 2)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Styled inputs

struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            TextField(placeholder, text: $text)
                .font(Theme.body())
                .foregroundColor(Theme.textPrimary)
                .keyboardType(keyboard)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
        }
    }
}

struct LabeledNumberField: View {
    let label: String
    @Binding var value: Double
    var suffix: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            HStack {
                TextField("0", text: Binding(
                    get: { value == 0 ? "" : Formatters.decimal(value, digits: 2) },
                    set: { value = max(0, Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0) }
                ))
                .keyboardType(.decimalPad)
                .font(Theme.body())
                .foregroundColor(Theme.textPrimary)
                if !suffix.isEmpty {
                    Text(suffix).font(Theme.caption()).foregroundColor(Theme.textSecondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
        }
    }
}

// MARK: - Stepper row (for bays / lifts / counts)

struct StepperRow: View {
    let label: String
    var systemImage: String = "number"
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...20
    var suffix: String = ""
    var onChange: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).foregroundColor(Theme.tube).frame(width: 22)
            Text(label).font(Theme.body()).foregroundColor(Theme.textPrimary)
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") { if value > range.lowerBound { value -= 1; onChange?(value) } }
                Text("\(value)\(suffix)").font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
                    .frame(minWidth: 38)
                stepButton("plus") { if value < range.upperBound { value += 1; onChange?(value) } }
            }
        }
    }
    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accentHi)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.surfaceHi))
                .overlay(Circle().stroke(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var systemImage: String = "tray"
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.tube.opacity(0.7))
            Text(title).font(Theme.heading(16)).foregroundColor(Theme.textPrimary)
            Text(message).font(Theme.caption()).foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Inspection-gate banner (work blocked when the tag is red/overdue)

struct GateBanner: View {
    let permitted: Bool
    var redReason: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: permitted ? "checkmark.shield.fill" : "hand.raised.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(permitted ? Theme.success : Theme.danger)
            VStack(alignment: .leading, spacing: 2) {
                Text(permitted ? "Access permitted" : "Access blocked")
                    .font(Theme.heading(15))
                    .foregroundColor(permitted ? Theme.success : Theme.danger)
                Text(permitted ? "Green tag valid — safe to work."
                               : (redReason.isEmpty ? "Pass an inspection to issue a green tag." : redReason))
                    .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(13)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m)
            .fill((permitted ? Theme.success : Theme.danger).opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
            .stroke((permitted ? Theme.success : Theme.danger).opacity(0.5), lineWidth: 1.2))
    }
}

// MARK: - Screen scaffold (title bar + scroll content on steel backdrop)

struct ScreenScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    let content: () -> Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title; self.subtitle = subtitle; self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.title(27)).foregroundColor(Theme.textPrimary)
                    if let s = subtitle {
                        Text(s).font(Theme.caption()).foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.top, 4)
                content()
            }
            .padding(Theme.Space.m)
            .padding(.bottom, 120)   // clear the custom tab bar
        }
        .steelScreen()
    }
}
