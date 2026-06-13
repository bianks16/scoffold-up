//
//  AppStore.swift
//  ScaffoldUp
//
//  The single source of truth (@EnvironmentObject). Owns AppData, the scaffold
//  configuration, the inspection/tag safety state and every derived calculation
//  (components, ties, base, loads, cost) so numbers match across all screens.
//  iOS 14 safe.
//

import SwiftUI

final class AppStore: ObservableObject {
    @Published private(set) var data: AppData

    private let persistence = PersistenceManager.shared
    private let photoStore = PhotoStore.shared

    let maxBays = 12
    let maxLifts = 10

    init() {
        self.data = persistence.load()
        reconcileTiers()
        reconcileCostLines()
    }

    // MARK: - Settings-backed preferences

    var units: UnitSystem {
        UnitSystem(rawValue: UserDefaults.standard.string(forKey: "unitSystem") ?? "metric") ?? .metric
    }
    var currency: CurrencyCode {
        CurrencyCode(rawValue: UserDefaults.standard.string(forKey: "currencyCode") ?? "gbp") ?? .gbp
    }
    var tagIntervalDays: Int {
        let v = UserDefaults.standard.integer(forKey: "tagIntervalDays")
        return v == 0 ? 7 : v
    }

    // MARK: - Unit conversion / formatting

    func len(_ meters: Double, digits: Int = 1) -> String {
        let v = units == .metric ? meters : meters * 3.28084
        return "\(Formatters.decimal(v, digits: digits)) \(units.lengthUnit)"
    }
    func area(_ sqm: Double, digits: Int = 1) -> String {
        let v = units == .metric ? sqm : sqm * 10.7639
        return "\(Formatters.decimal(v, digits: digits)) \(units.areaUnit)"
    }
    func weight(_ kg: Double, digits: Int = 0) -> String {
        let v = units == .metric ? kg : kg * 2.20462
        return "\(Formatters.decimal(v, digits: digits)) \(units.weightUnit)"
    }
    /// kN reference label (always shown for loads, per spec).
    func kNLabel(_ kg: Double) -> String {
        "\(Formatters.decimal(Physics.kN(fromKg: kg), digits: 1)) kN"
    }
    func money(_ value: Double) -> String {
        Formatters.currency(value, code: currency.code, symbol: currency.symbol)
    }

    // MARK: - Config access

    var config: ScaffoldConfig { data.config }
    var tiers: [Tier] { data.tiers.sorted { $0.index < $1.index } }
    var deckedTiersCount: Int { data.tiers.filter { $0.decked }.count }
    var tag: ScaffTag { data.tag }
    var inspections: [Inspection] { data.inspections.sorted { $0.date > $1.date } }
    var photos: [ScaffoldPhoto] { data.photos.sorted { $0.createdAt > $1.createdAt } }
    var history: [HistoryEvent] { data.history.sorted { $0.date > $1.date } }

    // MARK: - Derived engine outputs

    var componentSpec: ComponentSpec {
        ScaffoldEngine.components(for: config, deckedTiers: max(deckedTiersCount, 1))
    }
    var tiePlan: TiePlan { ScaffoldEngine.tiePlan(for: config) }
    var basePlan: BasePlan { ScaffoldEngine.basePlan(for: config) }
    var loadAssessments: [LoadAssessment] { ScaffoldEngine.assessAll(tiers: tiers, config: config) }
    var overloadedTiers: [LoadAssessment] { loadAssessments.filter { $0.overloaded } }
    var nearLimitTiers: [LoadAssessment] { loadAssessments.filter { $0.nearLimit } }

    // MARK: - Tag derived state

    var tagOverdue: Bool {
        guard tag.status == .green, let due = tag.nextDueDate else { return false }
        return due < Date()
    }
    var tagExpiringSoon: Bool {
        guard tag.status == .green, !tagOverdue, let due = tag.nextDueDate else { return false }
        let days = Calendar.current.dateComponents([.day],
                    from: Calendar.current.startOfDay(for: Date()),
                    to: Calendar.current.startOfDay(for: due)).day ?? 99
        return days <= 2
    }
    /// True when work is permitted (the inspection gate).
    var workPermitted: Bool { tag.status == .green && !tagOverdue }

    /// One-line risk summary for badges.
    var riskCount: Int {
        var n = 0
        if tag.status == .red { n += 1 }
        if tagOverdue { n += 1 }
        n += overloadedTiers.count
        return n
    }

    // MARK: - Config mutations

    func renameScaffold(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        data.config.name = trimmed.isEmpty ? "Untitled Scaffold" : trimmed
        save()
    }

    /// Apply a configuration; structural changes drop the green tag (re-inspect).
    func updateConfig(_ new: ScaffoldConfig) {
        let old = data.config
        let structural =
            old.type != new.type || old.dutyClass != new.dutyClass ||
            old.bayLengthRaw != new.bayLengthRaw || old.platformWidthRaw != new.platformWidthRaw ||
            old.liftHeight != new.liftHeight || old.bays != new.bays || old.lifts != new.lifts ||
            old.windExposure != new.windExposure || old.unevenGround != new.unevenGround ||
            old.nearPowerLines != new.nearPowerLines
        data.config = new
        reconcileTiers()
        reconcileCostLines()
        if structural {
            invalidateTag(reason: "Configuration changed — re-inspect before use.")
            addHistory(.configChanged, "Configuration updated.")
        }
        save()
    }

    func addBay() {
        guard data.config.bays < maxBays else { return }
        data.config.bays += 1
        reconcileCostLines()
        invalidateTag(reason: "Bay added — re-inspect before use.")
        addHistory(.bayAdded, "Now \(data.config.bays) bays · facade \(len(config.facadeLength)).")
        save()
    }
    func removeBay() {
        guard data.config.bays > 1 else { return }
        data.config.bays -= 1
        reconcileCostLines()
        invalidateTag(reason: "Bay removed — re-inspect before use.")
        addHistory(.bayRemoved, "Now \(data.config.bays) bays.")
        save()
    }
    func addLift() {
        guard data.config.lifts < maxLifts else { return }
        data.config.lifts += 1
        reconcileTiers()
        reconcileCostLines()
        invalidateTag(reason: "Lift added — re-inspect before use.")
        addHistory(.liftAdded, "Now \(data.config.lifts) lifts · height \(len(config.height)).")
        save()
    }
    func removeLift() {
        guard data.config.lifts > 1 else { return }
        data.config.lifts -= 1
        reconcileTiers()
        reconcileCostLines()
        invalidateTag(reason: "Lift removed — re-inspect before use.")
        addHistory(.liftRemoved, "Now \(data.config.lifts) lifts.")
        save()
    }

    // MARK: - Tiers

    func updateTier(_ tier: Tier) {
        if let i = data.tiers.firstIndex(where: { $0.id == tier.id }) {
            data.tiers[i] = tier
            save()
        }
    }
    func setTierLoad(_ tier: Tier, materialKg: Double, people: Int) {
        guard let i = data.tiers.firstIndex(where: { $0.id == tier.id }) else { return }
        data.tiers[i].materialLoadKg = max(0, materialKg)
        data.tiers[i].peopleCount = max(0, people)
        addHistory(.loadEdited, "\(data.tiers[i].label): \(weight(max(0, materialKg))) + \(max(0, people)) on board.")
        save()
    }
    func toggleDecked(_ tier: Tier) {
        guard let i = data.tiers.firstIndex(where: { $0.id == tier.id }) else { return }
        data.tiers[i].decked.toggle()
        reconcileCostLines()
        save()
    }
    func attachPhoto(toTier tier: Tier, image: UIImage) {
        guard let name = photoStore.save(image),
              let i = data.tiers.firstIndex(where: { $0.id == tier.id }) else { return }
        if let old = data.tiers[i].photoFileName { photoStore.delete(named: old) }
        data.tiers[i].photoFileName = name
        save()
    }

    private func reconcileTiers() {
        let target = max(data.config.lifts, 1)
        var result: [Tier] = []
        for idx in 0..<target {
            if let existing = data.tiers.first(where: { $0.index == idx }) {
                result.append(existing)
            } else {
                result.append(Tier(index: idx, decked: true, materialLoadKg: 0, peopleCount: 1))
            }
        }
        data.tiers = result
    }

    // MARK: - Inspection & tag (the safety gate)

    func runInspection(passed: Set<InspectionPoint>, inspector: String, isStorm: Bool, note: String) {
        let applicable = InspectionPoint.allCases.filter { $0.applies(to: config.type) }
        let failed = applicable.filter { !passed.contains($0) }
        let now = Date()
        let name = inspector.trimmingCharacters(in: .whitespaces).isEmpty ? "Inspector" : inspector

        let record = Inspection(
            date: now, inspector: name,
            passedPoints: applicable.filter { passed.contains($0) }.map { $0.rawValue },
            failedPoints: failed.map { $0.rawValue },
            isStormCheck: isStorm, note: note
        )
        data.inspections.insert(record, at: 0)

        let passedAll = failed.isEmpty
        data.tag.status = passedAll ? .green : .red
        data.tag.lastInspectionDate = now
        data.tag.inspector = name
        if passedAll {
            data.tag.installedDate = data.inspections.count == 1 ? now : data.tag.installedDate
            data.tag.nextDueDate = Calendar.current.date(byAdding: .day, value: tagIntervalDays, to: now)
            data.tag.restriction = "\(config.dutyClass.displayName) · max \(weight(config.dutyClass.loadPerSqmKg))/m²"
            data.tag.reason = isStorm ? "Storm re-check passed — safe to work." : "All inspection points passed."
        } else {
            data.tag.nextDueDate = nil
            data.tag.restriction = "Do not use — \(failed.count) defect(s) to fix"
            data.tag.reason = "Failed: " + failed.prefix(3).map { $0.title }.joined(separator: ", ")
        }

        for i in data.tiers.indices { data.tiers[i].lastInspectedPassed = passedAll }

        if isStorm { addHistory(.stormChecked, "Storm re-check by \(name).") }
        addHistory(.inspected, "\(passedAll ? "Passed" : "Failed (\(failed.count))") by \(name).")
        addHistory(passedAll ? .taggedGreen : .taggedRed,
                   passedAll ? "Green tag issued." : "Red tag — \(failed.count) defect(s).")
        save()
    }

    private func invalidateTag(reason: String) {
        data.tag.status = .red
        data.tag.nextDueDate = nil
        data.tag.restriction = "Do not use — re-inspection required"
        data.tag.reason = reason
        for i in data.tiers.indices { data.tiers[i].lastInspectedPassed = nil }
    }

    func logDismantle() {
        invalidateTag(reason: "Scaffold marked for dismantling.")
        addHistory(.dismantled, "Dismantle logged for \(config.name).")
        save()
    }

    // MARK: - Photos

    func addPhoto(_ image: UIImage, caption: String, detail: String, category: String, tierIndex: Int?) {
        guard let name = photoStore.save(image) else { return }
        let photo = ScaffoldPhoto(caption: caption, detail: detail, category: category,
                                  imageFileName: name, tierIndex: tierIndex)
        data.photos.insert(photo, at: 0)
        save()
    }
    func updatePhoto(_ photo: ScaffoldPhoto) {
        if let i = data.photos.firstIndex(where: { $0.id == photo.id }) {
            data.photos[i] = photo; save()
        }
    }
    func deletePhoto(_ photo: ScaffoldPhoto) {
        photoStore.delete(named: photo.imageFileName)
        data.photos.removeAll { $0.id == photo.id }
        save()
    }
    func image(for name: String?) -> UIImage? { photoStore.loadImage(named: name) }

    // MARK: - Cost / rental

    var costLines: [CostLine] { data.costLines }

    func setRentalDays(_ days: Int) { data.rentalDays = max(1, days); save() }
    func setRentalStart(_ date: Date) { data.rentalStart = date; save() }
    var rentalDays: Int { data.rentalDays }
    var rentalStart: Date { data.rentalStart }
    var rentalEnd: Date {
        Calendar.current.date(byAdding: .day, value: data.rentalDays, to: data.rentalStart) ?? data.rentalStart
    }

    func updateCostLine(_ line: CostLine) {
        if let i = data.costLines.firstIndex(where: { $0.id == line.id }) {
            data.costLines[i] = line; save()
        }
    }
    var totalRentalCost: Double {
        data.costLines.filter { $0.includeInTotal }.reduce(0) { $0 + $1.cost(days: data.rentalDays) }
    }

    /// Keep one cost line per current component, refreshing quantities while
    /// preserving the user's edited rates / include flags.
    private func reconcileCostLines() {
        let spec = ScaffoldEngine.components(for: data.config, deckedTiers: max(data.tiers.filter { $0.decked }.count, 1))
        var result: [CostLine] = []
        for item in spec.items {
            if var existing = data.costLines.first(where: { $0.name == item.name }) {
                existing.quantity = Double(item.count)
                result.append(existing)
            } else {
                result.append(CostLine(name: item.name, quantity: Double(item.count),
                                       unitRatePerDay: SampleData.defaultRate(for: item.name),
                                       includeInTotal: true))
            }
        }
        data.costLines = result
    }

    // MARK: - History

    func addHistory(_ kind: HistoryKind, _ detail: String) {
        data.history.insert(HistoryEvent(kind: kind, date: Date(), detail: detail), at: 0)
        if data.history.count > 200 { data.history = Array(data.history.prefix(200)) }
    }

    // MARK: - Lifecycle

    private func save() {
        objectWillChange.send()
        persistence.save(data)
    }
    func flush() { persistence.flush(data) }

    func exportURL() -> URL? { persistence.exportData(data) }

    func resetToSampleData() {
        photoStore.clearAll()
        data = SampleData.make()
        reconcileTiers(); reconcileCostLines()
        persistence.saveNow(data)
        objectWillChange.send()
    }
    func wipeAll() {
        photoStore.clearAll()
        data = AppData()
        reconcileTiers(); reconcileCostLines()
        persistence.saveNow(data)
        objectWillChange.send()
    }
}
