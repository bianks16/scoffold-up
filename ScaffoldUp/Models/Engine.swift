//
//  Engine.swift
//  ScaffoldUp
//
//  The scaffold safety engine — pure, testable functions that turn a
//  ScaffoldConfig into a component bill, a tie/anchor plan, base requirements
//  and per-tier load assessments. Formulas follow common single-width facade
//  scaffold practice (TG20-style) and are documented inline. iOS 14 safe.
//

import Foundation

// MARK: - Component bill of materials

struct ComponentItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String      // short formula / note
    let count: Int
    let icon: String
}

struct ComponentSpec {
    let items: [ComponentItem]
    var totalPieces: Int { items.reduce(0) { $0 + $1.count } }
    func count(_ name: String) -> Int { items.first { $0.name == name }?.count ?? 0 }
}

// MARK: - Tie / anchor plan

struct TiePlan {
    let required: Int
    let rows: Int
    let cols: Int
    let verticalSpacing: Double     // m
    let horizontalSpacing: Double   // m
    let faceArea: Double            // m²
    let areaPerTie: Double          // m² each tie restrains
    let needed: Bool
    let windNote: String
    let powerLineWarning: Bool
}

// MARK: - Base / foundation plan

struct BasePlan {
    let standardLines: Int
    let basePlates: Int
    let baseJacks: Int          // screw jacks (uneven ground)
    let soleBoards: Int
    let useJacks: Bool
    let advice: [String]
}

// MARK: - Load assessment for one tier

struct LoadAssessment: Identifiable {
    let id = UUID()
    let tierIndex: Int
    let area: Double            // m²
    let allowableKg: Double
    let materialKg: Double
    let peopleKg: Double
    var totalKg: Double { materialKg + peopleKg }
    var ratio: Double { allowableKg <= 0 ? 0 : totalKg / allowableKg }
    var overloaded: Bool { totalKg > allowableKg }
    var nearLimit: Bool { !overloaded && ratio >= 0.85 }
    var remainingKg: Double { max(allowableKg - totalKg, 0) }
}

// MARK: - Engine

enum ScaffoldEngine {

    // ---- Component bill ----

    static func components(for config: ScaffoldConfig, deckedTiers: Int) -> ComponentSpec {
        let b = max(config.bays, 1)
        let L = max(config.lifts, 1)
        let decked = max(min(deckedTiers, L), 0)
        let type = config.type
        let boardsWide = max(PlatformWidth(rawValue: config.platformWidthRaw)?.boards ?? 4,
                             config.dutyClass.minBoardsWide)

        // Standards: inner + outer rows, (b+1) positions each, one tube per lift.
        let standardLines = 2 * (b + 1)
        let standards = standardLines * L

        // Ledgers: both faces, b bays, at every lift level plus the base = (L+1).
        let ledgers = 2 * b * (L + 1)

        // Transoms: across the width at every standard position and level.
        let transoms = (b + 1) * (L + 1)

        // Diagonal braces: a façade brace bay roughly every 4 bays, full height,
        // plus a set of ledger/plan braces per lift.
        let bracedBays = max(1, Int((Double(b) / 4.0).rounded(.up)))
        let braces = bracedBays * L + L

        // Platform boards across decked working lifts.
        let boards = boardsWide * b * decked

        // Toe boards around each decked platform (outer run + two ends).
        let toeBoards = (b + 2) * decked

        // Guardrails: principal + intermediate on the outer face of each platform.
        let guardrails = 2 * b * decked + 2 * decked

        // Ladders: one access ladder per lift.
        let ladders = L

        // Base plates: one under every standard line.
        let basePlates = standardLines

        // Couplers: loose couplers only on tube & clamp (two per connection);
        // system scaffolds use far fewer (braces + ties only).
        let couplers: Int
        if type.usesLooseCouplers {
            couplers = (ledgers + transoms + braces) * 2
        } else {
            couplers = braces * 2
        }

        var items: [ComponentItem] = [
            ComponentItem(name: "Standards", detail: "2×(bays+1) lines × lifts",
                          count: standards, icon: "arrow.up.to.line"),
            ComponentItem(name: "Ledgers", detail: "longitudinal, both faces",
                          count: ledgers, icon: "rectangle.split.3x1.fill"),
            ComponentItem(name: "Transoms", detail: "cross members per node",
                          count: transoms, icon: "rectangle.split.2x1.fill"),
            ComponentItem(name: "Diagonal braces", detail: "façade + plan braces",
                          count: braces, icon: "line.diagonal"),
            ComponentItem(name: "Platform boards", detail: "\(boardsWide) wide × bays × decked",
                          count: boards, icon: "rectangle.grid.1x2.fill"),
            ComponentItem(name: "Toe boards", detail: "edge protection per platform",
                          count: toeBoards, icon: "rectangle.bottomthird.inset.filled"),
            ComponentItem(name: "Guardrails", detail: "principal + intermediate",
                          count: guardrails, icon: "rectangle.tophalf.inset.filled"),
            ComponentItem(name: "Ladders", detail: "one per lift",
                          count: ladders, icon: "figure.stairs"),
            ComponentItem(name: config.unevenGround ? "Screw jacks" : "Base plates",
                          detail: "under every standard",
                          count: basePlates, icon: "square.split.bottomrightquarter.fill")
        ]

        if couplers > 0 {
            items.append(ComponentItem(name: "Couplers", detail: type.usesLooseCouplers ? "two per joint" : "brace fittings",
                                       count: couplers, icon: "link"))
        }

        if config.type.needsTies {
            let tie = tiePlan(for: config)
            items.append(ComponentItem(name: "Wall ties / anchors", detail: "to anchor plan",
                                       count: tie.required, icon: "pin.fill"))
        }

        return ComponentSpec(items: items)
    }

    // ---- Tie / anchor plan ----

    static func tiePlan(for config: ScaffoldConfig) -> TiePlan {
        let b = max(config.bays, 1)
        let L = max(config.lifts, 1)

        // Base grid: a tie at alternate lifts and alternate standards (TG20 ~ a tie
        // roughly every 2 lifts vertically and every 2 bays horizontally).
        let rows = max(1, Int((Double(L) / 2.0).rounded(.up)))
        let cols = max(1, Int((Double(b + 1) / 2.0).rounded(.up)))
        let base = rows * cols

        let windAdjusted = Double(base) * config.windExposure.tieFactor
        let required = config.type.needsTies ? max(2, Int(windAdjusted.rounded(.up))) : 0

        let vSpacing = config.height / Double(max(rows, 1))
        let hSpacing = config.facadeLength / Double(max(cols, 1))
        let areaPerTie = required > 0 ? config.faceArea / Double(required) : 0

        let windNote: String
        switch config.windExposure {
        case .sheltered: windNote = "Sheltered site — standard tie density."
        case .moderate:  windNote = "Moderate exposure — standard tie pattern."
        case .exposed:   windNote = "Exposed site — tie count increased for wind load."
        }

        return TiePlan(required: required, rows: rows, cols: cols,
                       verticalSpacing: vSpacing, horizontalSpacing: hSpacing,
                       faceArea: config.faceArea, areaPerTie: areaPerTie,
                       needed: config.type.needsTies, windNote: windNote,
                       powerLineWarning: config.nearPowerLines)
    }

    // ---- Base / foundation plan ----

    static func basePlan(for config: ScaffoldConfig) -> BasePlan {
        let b = max(config.bays, 1)
        let standardLines = 2 * (b + 1)
        let useJacks = config.unevenGround
        // Sole boards spread base loads on soft/uneven ground — one per standard run.
        let soleBoards = useJacks ? standardLines : (b + 1)

        var advice: [String] = []
        advice.append(useJacks
            ? "Uneven ground: use adjustable screw jacks on every standard and level the first lift."
            : "Firm, level ground: steel base plates on timber sole boards.")
        advice.append("Sole boards must span the soft ground and sit flat — no rocking.")
        if config.nearPowerLines {
            advice.append("Near power lines: maintain safe clearance and isolate/insulate before erecting.")
        }
        if config.height >= 8 {
            advice.append("Tall scaffold (\(Formatters.decimal(config.height, digits: 1)) m): confirm ground bearing capacity.")
        }

        return BasePlan(standardLines: standardLines,
                        basePlates: useJacks ? 0 : standardLines,
                        baseJacks: useJacks ? standardLines : 0,
                        soleBoards: soleBoards,
                        useJacks: useJacks,
                        advice: advice)
    }

    // ---- Per-tier load assessment ----

    static func assess(tier: Tier, config: ScaffoldConfig) -> LoadAssessment {
        let area = config.platformAreaPerTier
        let allowable = config.dutyClass.loadPerSqmKg * area
        let people = Double(tier.peopleCount) * Physics.personLoadKg
        return LoadAssessment(tierIndex: tier.index, area: area,
                              allowableKg: allowable,
                              materialKg: tier.materialLoadKg,
                              peopleKg: people)
    }

    static func assessAll(tiers: [Tier], config: ScaffoldConfig) -> [LoadAssessment] {
        tiers.sorted { $0.index < $1.index }.map { assess(tier: $0, config: config) }
    }

    /// Advice string for an overloaded / near-limit tier.
    static func loadAdvice(_ a: LoadAssessment, duty: DutyClass) -> String {
        if a.overloaded {
            let over = a.totalKg - a.allowableKg
            var s = "Overloaded by \(Formatters.decimal(over, digits: 0)) kg. "
            s += "Spread the load across more bays or other lifts, remove material, "
            if duty != .heavy { s += "or upgrade to a higher duty class." }
            else { s += "or reduce the stack." }
            return s
        }
        if a.nearLimit {
            return "Approaching the limit (\(Formatters.percent(a.ratio * 100))). Avoid adding more material here."
        }
        return "Within the \(duty.shortName.lowercased()) duty limit. \(Formatters.decimal(a.remainingKg, digits: 0)) kg headroom."
    }
}
