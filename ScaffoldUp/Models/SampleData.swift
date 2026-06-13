//
//  SampleData.swift
//  ScaffoldUp
//
//  First-launch seed: a realistic facade scaffold with a passed inspection,
//  a green tag and starter history so every screen has live data immediately.
//

import Foundation

enum SampleData {

    /// Default per-day rental rate for a component (used by the cost screen).
    static func defaultRate(for name: String) -> Double {
        switch name {
        case "Standards":            return 0.18
        case "Ledgers":              return 0.14
        case "Transoms":             return 0.14
        case "Diagonal braces":      return 0.20
        case "Platform boards":      return 0.22
        case "Toe boards":           return 0.10
        case "Guardrails":           return 0.10
        case "Ladders":              return 1.40
        case "Base plates", "Screw jacks": return 0.28
        case "Couplers":             return 0.05
        case "Wall ties / anchors":  return 0.32
        default:                     return 0.15
        }
    }

    static func make() -> AppData {
        var data = AppData()

        var config = ScaffoldConfig()
        config.name = "North Facade — Block A"
        config.type = .facade
        config.dutyClass = .general
        config.bayLengthRaw = BayLength.b25.rawValue
        config.platformWidthRaw = PlatformWidth.w090.rawValue
        config.liftHeight = 2.0
        config.bays = 4
        config.lifts = 3
        config.windExposure = .moderate
        config.unevenGround = false
        config.nearPowerLines = false
        data.config = config

        // Three decked tiers with sensible starting loads (top lift near the limit
        // to showcase the load-check warning out of the box).
        data.tiers = [
            Tier(index: 0, decked: true, materialLoadKg: 300, peopleCount: 2,
                 notes: "Access lift — keep clear of material storage.", lastInspectedPassed: true),
            Tier(index: 1, decked: true, materialLoadKg: 550, peopleCount: 2,
                 notes: "Cladding work in progress.", lastInspectedPassed: true),
            Tier(index: 2, decked: true, materialLoadKg: 1150, peopleCount: 1,
                 notes: "Material landing — watch the load.", lastInspectedPassed: true)
        ]

        // A passed first inspection → green tag.
        let now = Date()
        let applicable = InspectionPoint.allCases.filter { $0.applies(to: config.type) }
        let inspection = Inspection(
            date: now,
            inspector: "J. Mason",
            passedPoints: applicable.map { $0.rawValue },
            failedPoints: [],
            isStormCheck: false,
            note: "Initial hand-over inspection — all points satisfactory."
        )
        data.inspections = [inspection]

        let interval = 7
        let nextDue = Calendar.current.date(byAdding: .day, value: interval, to: now)
        data.tag = ScaffTag(
            status: .green,
            installedDate: now,
            lastInspectionDate: now,
            nextDueDate: nextDue,
            inspector: "J. Mason",
            restriction: "\(config.dutyClass.displayName) · max \(Formatters.decimal(config.dutyClass.loadPerSqmKg, digits: 0)) kg/m²",
            reason: "All inspection points passed."
        )

        // Default rental lines (quantities reconciled live against the engine).
        let spec = ScaffoldEngine.components(for: config, deckedTiers: 3)
        data.costLines = spec.items.map { item in
            CostLine(name: item.name, quantity: Double(item.count),
                     unitRatePerDay: defaultRate(for: item.name), includeInTotal: true)
        }
        data.rentalStart = now
        data.rentalDays = 14

        data.history = [
            HistoryEvent(kind: .taggedGreen, date: now, detail: "Green tag issued by J. Mason."),
            HistoryEvent(kind: .inspected, date: now, detail: "Hand-over inspection — 0 defects."),
            HistoryEvent(kind: .created,
                         date: Calendar.current.date(byAdding: .hour, value: -3, to: now) ?? now,
                         detail: "North Facade — Block A · facade scaffold, 4 bays × 3 lifts.")
        ]

        return data
    }
}
