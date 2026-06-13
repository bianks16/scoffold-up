//
//  Models.swift
//  ScaffoldUp
//
//  Shared data contract: enums, value-type Codable models and the AppData root
//  aggregate persisted as a single JSON document. iOS 14 safe (Foundation only).
//

import SwiftUI

// MARK: - Scaffold type

enum ScaffoldType: String, Codable, CaseIterable, Identifiable {
    case frame, tubeClamp, facade, mobileTower
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .frame:       return "Frame"
        case .tubeClamp:   return "Tube & Clamp"
        case .facade:      return "Facade"
        case .mobileTower: return "Mobile Tower"
        }
    }
    var subtitle: String {
        switch self {
        case .frame:       return "Prefab H-frames, fast erect"
        case .tubeClamp:   return "Tubes + couplers, fully custom"
        case .facade:      return "System scaffold along a wall"
        case .mobileTower: return "Free-standing rolling tower"
        }
    }
    var icon: String {
        switch self {
        case .frame:       return "square.grid.3x3.fill"
        case .tubeClamp:   return "link"
        case .facade:      return "building.2.fill"
        case .mobileTower: return "cart.fill"
        }
    }
    /// Mobile towers are free-standing — wall ties don't apply.
    var needsTies: Bool { self != .mobileTower }
    /// Tube & clamp builds use loose couplers at every connection.
    var usesLooseCouplers: Bool { self == .tubeClamp }
}

// MARK: - Duty class (EN 12811 / TG20 working load classes)

enum DutyClass: String, Codable, CaseIterable, Identifiable {
    case light, general, heavy
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:   return "Light Duty"
        case .general: return "General Duty"
        case .heavy:   return "Heavy Duty"
        }
    }
    var shortName: String {
        switch self {
        case .light:   return "Light"
        case .general: return "General"
        case .heavy:   return "Heavy"
        }
    }
    /// Uniformly distributed load capacity of the platform, kN/m².
    var loadPerSqmKN: Double {
        switch self {
        case .light:   return 0.75   // inspection / light access (Class 1)
        case .general: return 1.50   // general building work (Class 2/3)
        case .heavy:   return 3.00   // masonry / heavy materials (Class 4)
        }
    }
    /// Same capacity expressed in kg/m².
    var loadPerSqmKg: Double { loadPerSqmKN * 1000.0 / 9.81 }

    var usage: String {
        switch self {
        case .light:   return "Inspection & light access — no material storage"
        case .general: return "General trades — plastering, painting, cladding"
        case .heavy:   return "Bricklaying & heavy material storage"
        }
    }
    /// Boards required across the platform for this duty (TG20 typical).
    var minBoardsWide: Int {
        switch self {
        case .light:   return 3
        case .general: return 4
        case .heavy:   return 5
        }
    }
    var color: Color {
        switch self {
        case .light:   return Theme.info
        case .general: return Theme.accent
        case .heavy:   return Theme.caution
        }
    }
}

// MARK: - Wind exposure

enum WindExposure: String, Codable, CaseIterable, Identifiable {
    case sheltered, moderate, exposed
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    /// Multiplier applied to the base tie/anchor count.
    var tieFactor: Double {
        switch self {
        case .sheltered: return 0.85
        case .moderate:  return 1.0
        case .exposed:   return 1.35
        }
    }
    var icon: String {
        switch self {
        case .sheltered: return "wind"
        case .moderate:  return "wind"
        case .exposed:   return "tornado"
        }
    }
}

// MARK: - Tag status

enum TagStatus: String, Codable, CaseIterable, Identifiable {
    case green, red
    var id: String { rawValue }
    var displayName: String { self == .green ? "Approved" : "Do Not Use" }
    var headline: String { self == .green ? "SAFE TO WORK" : "DO NOT CLIMB" }
    var color: Color { self == .green ? Theme.success : Theme.danger }
    var icon: String { self == .green ? "checkmark.seal.fill" : "xmark.octagon.fill" }
}

// MARK: - History events

enum HistoryKind: String, Codable, CaseIterable, Identifiable {
    case created, bayAdded, bayRemoved, liftAdded, liftRemoved
    case inspected, taggedGreen, taggedRed, stormChecked, loadEdited, dismantled, configChanged
    var id: String { rawValue }

    var label: String {
        switch self {
        case .created:       return "Scaffold created"
        case .bayAdded:      return "Bay added"
        case .bayRemoved:    return "Bay removed"
        case .liftAdded:     return "Lift added"
        case .liftRemoved:   return "Lift removed"
        case .inspected:     return "Inspection run"
        case .taggedGreen:   return "Tagged GREEN"
        case .taggedRed:     return "Tagged RED"
        case .stormChecked:  return "Storm re-check"
        case .loadEdited:    return "Load updated"
        case .dismantled:    return "Dismantle logged"
        case .configChanged: return "Configuration changed"
        }
    }
    var icon: String {
        switch self {
        case .created:       return "plus.square.fill"
        case .bayAdded, .liftAdded:     return "plus.rectangle.on.rectangle"
        case .bayRemoved, .liftRemoved: return "minus.rectangle"
        case .inspected:     return "checklist"
        case .taggedGreen:   return "checkmark.seal.fill"
        case .taggedRed:     return "xmark.octagon.fill"
        case .stormChecked:  return "cloud.bolt.rain.fill"
        case .loadEdited:    return "scalemass.fill"
        case .dismantled:    return "trash.fill"
        case .configChanged: return "slider.horizontal.3"
        }
    }
    var tint: Color {
        switch self {
        case .taggedGreen: return Theme.success
        case .taggedRed, .dismantled: return Theme.danger
        case .stormChecked: return Theme.caution
        case .inspected: return Theme.accent
        default: return Theme.textSecondary
        }
    }
}

// MARK: - Units

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var displayName: String { self == .metric ? "Metric (m · kg)" : "Imperial (ft · lb)" }
    var lengthUnit: String { self == .metric ? "m" : "ft" }
    var areaUnit: String { self == .metric ? "m²" : "ft²" }
    var weightUnit: String { self == .metric ? "kg" : "lb" }
}

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case usd, eur, gbp, cad, aud
    var id: String { rawValue }
    var code: String { rawValue.uppercased() }
    var symbol: String {
        switch self {
        case .usd, .cad, .aud: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }
    var displayName: String {
        switch self {
        case .usd: return "US Dollar ($)"
        case .eur: return "Euro (€)"
        case .gbp: return "British Pound (£)"
        case .cad: return "Canadian Dollar ($)"
        case .aud: return "Australian Dollar ($)"
        }
    }
}

// MARK: - Standard component sizes (pickers keep inputs to real scaffold sizes)

enum BayLength: Double, Codable, CaseIterable, Identifiable {
    case b13 = 1.3, b18 = 1.8, b21 = 2.1, b25 = 2.5
    var id: Double { rawValue }
    var label: String { Formatters.decimal(rawValue, digits: 1) + " m" }
}

enum PlatformWidth: Double, Codable, CaseIterable, Identifiable {
    case w060 = 0.6, w090 = 0.9, w120 = 1.2
    var id: Double { rawValue }
    var label: String { Formatters.decimal(rawValue, digits: 1) + " m" }
    var boards: Int { Int((rawValue / 0.225).rounded()) }   // ~225 mm scaffold boards
}

// MARK: - Configuration (the scaffold the user is planning)

struct ScaffoldConfig: Codable, Equatable {
    var name: String = "Facade Scaffold"
    var type: ScaffoldType = .facade
    var dutyClass: DutyClass = .general
    var bayLengthRaw: Double = BayLength.b25.rawValue
    var platformWidthRaw: Double = PlatformWidth.w090.rawValue
    var liftHeight: Double = 2.0            // m per lift
    var bays: Int = 4                       // sections along the facade
    var lifts: Int = 3                      // tiers in height
    var windExposure: WindExposure = .moderate
    var unevenGround: Bool = false
    var nearPowerLines: Bool = false

    // Derived geometry (always metres internally)
    var bayLength: Double { bayLengthRaw }
    var platformWidth: Double { platformWidthRaw }
    var facadeLength: Double { Double(bays) * bayLength }
    var height: Double { Double(lifts) * liftHeight }
    var faceArea: Double { facadeLength * height }
    var platformAreaPerTier: Double { facadeLength * platformWidth }
}

// MARK: - Tier (a lift level / working platform — the addressable "section")

struct Tier: Identifiable, Codable, Equatable {
    var id = UUID()
    var index: Int                  // 0 = first lift above base
    var decked: Bool = true         // boarded as a working platform
    var materialLoadKg: Double = 0  // distributed materials placed on this tier
    var peopleCount: Int = 1        // workers expected on this tier
    var notes: String = ""
    var photoFileName: String? = nil
    var lastInspectedPassed: Bool? = nil

    var label: String { "Lift \(index + 1)" }
}

// MARK: - Inspection

/// One checklist line in the access inspection.
enum InspectionPoint: String, Codable, CaseIterable, Identifiable {
    case base, plumb, ledgers, bracing, platform, toeBoard, guardrail, ties, ladder, couplers
    var id: String { rawValue }

    var title: String {
        switch self {
        case .base:      return "Base & foundation level and firm"
        case .plumb:     return "Standards plumb / vertical"
        case .ledgers:   return "Ledgers & transoms secure"
        case .bracing:   return "Diagonal bracing in place"
        case .platform:  return "Platform fully boarded & secured"
        case .toeBoard:  return "Toe boards fitted"
        case .guardrail: return "Double guardrails fitted"
        case .ties:      return "Wall ties / anchors per plan"
        case .ladder:    return "Safe ladder access"
        case .couplers:  return "Couplers tight, no damage"
        }
    }
    var icon: String {
        switch self {
        case .base:      return "square.split.bottomrightquarter.fill"
        case .plumb:     return "ruler.fill"
        case .ledgers:   return "rectangle.split.3x1.fill"
        case .bracing:   return "line.diagonal"
        case .platform:  return "rectangle.grid.1x2.fill"
        case .toeBoard:  return "rectangle.bottomthird.inset.filled"
        case .guardrail: return "rectangle.tophalf.inset.filled"
        case .ties:      return "pin.fill"
        case .ladder:    return "figure.stairs"
        case .couplers:  return "link"
        }
    }
    var fixHint: String {
        switch self {
        case .base:      return "Level the ground, add base plates/sole boards."
        case .plumb:     return "Re-plumb standards; adjust screw jacks."
        case .ledgers:   return "Refit and lock all ledgers and transoms."
        case .bracing:   return "Add the missing diagonal/façade braces."
        case .platform:  return "Fully board the lift and clip boards down."
        case .toeBoard:  return "Fit toe boards around the working platform."
        case .guardrail: return "Add principal + intermediate guardrails."
        case .ties:      return "Install wall ties to the anchor plan."
        case .ladder:    return "Provide a secured, correctly-angled ladder."
        case .couplers:  return "Re-torque couplers; replace damaged ones."
        }
    }
    /// Ties don't apply to free-standing mobile towers.
    func applies(to type: ScaffoldType) -> Bool {
        if self == .ties { return type.needsTies }
        return true
    }
}

/// A completed inspection record (also drives the sign-off log).
struct Inspection: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date = Date()
    var inspector: String = "Site Supervisor"
    var passedPoints: [String] = []     // raw values of passed InspectionPoint
    var failedPoints: [String] = []     // raw values of failed InspectionPoint
    var isStormCheck: Bool = false
    var note: String = ""

    var passed: Bool { failedPoints.isEmpty }
    var resultStatus: TagStatus { passed ? .green : .red }
    var failTitles: [String] {
        failedPoints.compactMap { InspectionPoint(rawValue: $0)?.title }
    }
}

// MARK: - Scaff-tag

struct ScaffTag: Codable, Equatable {
    var status: TagStatus = .red
    var installedDate: Date = Date()
    var lastInspectionDate: Date? = nil
    var nextDueDate: Date? = nil
    var inspector: String = ""
    var restriction: String = "Not yet inspected — do not use"
    var reason: String = "Awaiting first inspection"
}

// MARK: - Photo notes (Marker Photo)

struct ScaffoldPhoto: Identifiable, Codable, Equatable {
    var id = UUID()
    var caption: String = ""
    var detail: String = ""
    var category: String = "General"     // Anchors, Base, Edge protection, General
    var imageFileName: String?           // filename in Documents/Photos
    var tierIndex: Int? = nil
    var createdAt: Date = Date()
}

// MARK: - Cost / rental

struct CostLine: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var quantity: Double = 1
    var unitRatePerDay: Double = 0       // rental rate per item per day
    var includeInTotal: Bool = true

    func cost(days: Int) -> Double { quantity * unitRatePerDay * Double(days) }
}

// MARK: - History

struct HistoryEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: HistoryKind
    var date: Date = Date()
    var detail: String = ""
}

// MARK: - Root aggregate (single persisted JSON document)

struct AppData: Codable {
    var schemaVersion: Int = 1
    var config: ScaffoldConfig = ScaffoldConfig()
    var tiers: [Tier] = []
    var tag: ScaffTag = ScaffTag()
    var inspections: [Inspection] = []
    var photos: [ScaffoldPhoto] = []
    var costLines: [CostLine] = []
    var history: [HistoryEvent] = []
    var rentalStart: Date = Date()
    var rentalDays: Int = 14
}
