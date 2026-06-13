//
//  Theme.swift
//  ScaffoldUp
//
//  Central design system: dark blue-steel scaffolding palette with safety-yellow
//  tag accents (adaptive light/dark), gradients, typography, spacing tokens and
//  cached formatters. All APIs used here are iOS 14.0 safe.
//

import SwiftUI
import UIKit

// MARK: - Dynamic color helpers

extension Color {
    /// Builds a color that adapts to the active interface style. The Settings
    /// theme toggle (preferredColorScheme) flips these automatically.
    static func dynamic(light: UInt, dark: UInt) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    init(hex: UInt, alpha: Double = 1.0) {
        self = Color(UIColor(hex: hex, alpha: alpha))
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: Double = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}

// MARK: - Theme namespace

enum Theme {

    // Backgrounds (dark dominant; light variant is a soft steel-blue)
    static let bgTop      = Color.dynamic(light: 0xEAF1FB, dark: 0x0D1622)
    static let bgBottom   = Color.dynamic(light: 0xD7E4F5, dark: 0x080F18)
    static let surface    = Color.dynamic(light: 0xFFFFFF, dark: 0x172638)
    static let surfaceAlt = Color.dynamic(light: 0xEFF5FD, dark: 0x142031)
    static let surfaceHi  = Color.dynamic(light: 0xE3EDFA, dark: 0x1F3247)
    static let stroke     = Color.dynamic(light: 0xCBD9EC, dark: 0x2B405A)

    // Tubular structure lines (scaffold drawing)
    static let tube       = Color.dynamic(light: 0x2F73E8, dark: 0x38BDF8)
    static let tubeSoft   = Color.dynamic(light: 0x6CA0F2, dark: 0x7DD3FC)

    // Text
    static let textPrimary   = Color.dynamic(light: 0x0D1622, dark: 0xE9F1FE)
    static let textSecondary = Color.dynamic(light: 0x55657E, dark: 0xA7BAD6)
    static let textMuted     = Color.dynamic(light: 0x94A3B8, dark: 0x647698)
    static let textOnAccent  = Color(hex: 0x0D1622)        // dark text on yellow/blue buttons
    static let textOnBlue     = Color(hex: 0xFFFFFF)

    // Brand / accents
    static let accent     = Color.dynamic(light: 0x2F73E8, dark: 0x2F73E8) // construction blue
    static let accentDeep = Color.dynamic(light: 0x1E5AC8, dark: 0x1E5AC8)
    static let accentHi   = Color.dynamic(light: 0x1E5AC8, dark: 0x6CA0F2)

    // Safety yellow (the scaff-tag accent)
    static let safety     = Color.dynamic(light: 0xE6A700, dark: 0xFACC15)
    static let safetyHi   = Color.dynamic(light: 0xF5B500, dark: 0xFDE047)

    // Semantic
    static let success = Color.dynamic(light: 0x16A34A, dark: 0x22C55E)  // green tag
    static let warning = Color.dynamic(light: 0xE6A700, dark: 0xFACC15)  // load attention
    static let caution = Color.dynamic(light: 0xEA580C, dark: 0xF97316)  // orange warning
    static let danger  = Color.dynamic(light: 0xDC2626, dark: 0xEF4444)  // red tag / forbidden
    static let info    = Color.dynamic(light: 0x2563EB, dark: 0x60A5FA)

    // Gradients
    static var background: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
    }
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var safetyGradient: LinearGradient {
        LinearGradient(colors: [safetyHi, safety], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var tubeGradient: LinearGradient {
        LinearGradient(colors: [tubeSoft, tube], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // Spacing scale
    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 32
    }

    // Corner radii
    enum Radius {
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let pill: CGFloat = 100
    }

    // Typography (system fonts with rounded/weighted styling)
    static func title(_ size: CGFloat = 26) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat = 19) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular, design: .rounded) }
    static func mono(_ size: CGFloat = 13) -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium, design: .rounded) }
}

// MARK: - Physical constants used across the safety engine

enum Physics {
    /// Conservative allowance for one worker including tools (kg).
    static let personLoadKg: Double = 100
    /// kg → kN (×g, g = 9.81 m/s²).
    static func kN(fromKg kg: Double) -> Double { kg * 9.81 / 1000.0 }
}

// MARK: - Formatters (cached; iOS 14 safe — no Swift `.formatted()`)

enum Formatters {
    static func currency(_ value: Double, code: String, symbol: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.currencySymbol = symbol
        f.maximumFractionDigits = value.rounded() == value ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? "\(symbol)\(Int(value))"
    }

    static func decimal(_ value: Double, digits: Int = 1) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = digits
        f.minimumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func percent(_ value: Double) -> String { "\(Int(value.rounded()))%" }

    private static let medium: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let withTime: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
    private static let shortDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()

    static func date(_ d: Date) -> String { medium.string(from: d) }
    static func dateTime(_ d: Date) -> String { withTime.string(from: d) }
    static func dayMonth(_ d: Date) -> String { shortDay.string(from: d) }

    static func relativeDays(to date: Date) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: Date()),
                                      to: cal.startOfDay(for: date)).day ?? 0
        if days == 0 { return "Today" }
        if days > 0 { return "in \(days)d" }
        return "\(-days)d ago"
    }
}

// MARK: - Keyboard dismissal (no @FocusState on iOS 14)

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
