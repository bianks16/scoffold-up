//
//  ReportsView.swift  (Screen 15 — Reports / Scaffold Passport)
//  ScaffoldUp
//
//  Compose a scaffold passport (config, spec, loads, ties/base, tag, cost) and
//  export a real PDF via UIGraphicsPDFRenderer + share sheet. iOS 14 safe
//  (NSAttributedString drawing — no Swift AttributedString).
//

import SwiftUI
import UIKit

enum ReportSection: String, CaseIterable, Identifiable {
    case overview, tag, components, loads, ties, base, cost
    var id: String { rawValue }
    var title: String {
        switch self {
        case .overview:   return "Configuration"
        case .tag:        return "Tag & Inspection"
        case .components: return "Component Spec"
        case .loads:      return "Load Check"
        case .ties:       return "Ties & Anchors"
        case .base:       return "Base & Foundation"
        case .cost:       return "Rental Cost"
        }
    }
    var icon: String {
        switch self {
        case .overview:   return "square.stack.3d.up.fill"
        case .tag:        return "checkmark.seal.fill"
        case .components: return "list.bullet.rectangle.fill"
        case .loads:      return "scalemass.fill"
        case .ties:       return "pin.fill"
        case .base:       return "square.split.bottomrightquarter.fill"
        case .cost:       return "sterlingsign.circle.fill"
        }
    }
}

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selected: Set<ReportSection> = Set(ReportSection.allCases)
    @State private var generated = false
    @State private var share: ShareItem?
    @State private var failed = false

    var body: some View {
        ScreenScaffold("Reports", subtitle: "Scaffold passport — export PDF") {

            HStack(spacing: 10) {
                ActionButton(title: "Preview", systemImage: "doc.text.magnifyingglass") {
                    withAnimation { generated = true }
                }
                ActionButton(title: "Export PDF", systemImage: "square.and.arrow.up", kind: .safety) { exportPDF() }
            }

            CardView {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Include sections", systemImage: "checklist")
                    ForEach(ReportSection.allCases) { section in
                        Toggle(isOn: Binding(get: { selected.contains(section) },
                                             set: { on in
                                                 if on { selected.insert(section) } else { selected.remove(section) }
                                                 generated = false
                                             })) {
                            Label(section.title, systemImage: section.icon)
                                .font(Theme.body()).foregroundColor(Theme.textPrimary)
                        }.toggleStyle(SwitchToggleStyle(tint: Theme.safety))
                    }
                }
            }

            if generated {
                SectionHeader(title: "Preview", subtitle: "Tap Export PDF to share", systemImage: "doc.text")
                ForEach(content(), id: \.0) { section, lines in
                    CardView {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Image(systemName: section.icon).foregroundColor(Theme.tube)
                                Text(section.title).font(Theme.heading(15)).foregroundColor(Theme.textPrimary) }
                            ForEach(lines, id: \.self) { line in
                                Text("• " + line).font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                            }
                            if lines.isEmpty { Text("• (no data)").font(Theme.caption(12)).foregroundColor(Theme.textMuted) }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Reports", displayMode: .inline)
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
        .alert(isPresented: $failed) {
            Alert(title: Text("Export failed"), message: Text("Couldn't build the PDF. Try again."), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Content

    private func content() -> [(ReportSection, [String])] {
        ReportSection.allCases.filter { selected.contains($0) }.map { ($0, lines(for: $0)) }
    }

    private func lines(for section: ReportSection) -> [String] {
        let c = store.config
        switch section {
        case .overview:
            return [
                "Name: \(c.name)",
                "Type: \(c.type.displayName) · Duty: \(c.dutyClass.displayName)",
                "Bays \(c.bays) × Lifts \(c.lifts) · Bay \(store.len(c.bayLength)) · Width \(store.len(c.platformWidth))",
                "Facade \(store.len(c.facadeLength)) · Height \(store.len(c.height)) · Face area \(store.area(c.faceArea))",
                "Site: \(c.windExposure.displayName) wind\(c.unevenGround ? ", uneven ground" : "")\(c.nearPowerLines ? ", near power lines" : "")"
            ]
        case .tag:
            let t = store.tag
            return [
                "Status: \(t.status.headline)",
                "Installed: \(Formatters.date(t.installedDate))",
                "Last inspection: \(t.lastInspectionDate.map { Formatters.date($0) } ?? "—") by \(t.inspector.isEmpty ? "—" : t.inspector)",
                "Next re-inspection: \(t.nextDueDate.map { Formatters.date($0) } ?? "—")",
                "Restriction: \(t.restriction)",
                "Inspections recorded: \(store.inspections.count)"
            ]
        case .components:
            return store.componentSpec.items.map { "\($0.name): \($0.count)" } + ["Total parts: \(store.componentSpec.totalPieces)"]
        case .loads:
            return store.loadAssessments.map { a in
                "Lift \(a.tierIndex + 1): \(store.weight(a.totalKg)) of \(store.weight(a.allowableKg)) (\(Formatters.percent(a.ratio * 100)))\(a.overloaded ? " — OVERLOAD" : "")"
            } + ["Capacity: \(Formatters.decimal(c.dutyClass.loadPerSqmKN, digits: 2)) kN/m² per platform"]
        case .ties:
            let tp = store.tiePlan
            if !tp.needed { return ["Free-standing tower — no wall ties."] }
            return [
                "Anchors required: \(tp.required)",
                "Grid: \(tp.rows) rows × \(tp.cols) columns",
                "Spacing: V \(store.len(tp.verticalSpacing)) · H \(store.len(tp.horizontalSpacing))",
                "Area per tie: \(store.area(tp.areaPerTie))",
                tp.windNote
            ]
        case .base:
            let bp = store.basePlan
            return [
                bp.useJacks ? "Adjustable screw jacks: \(bp.baseJacks)" : "Base plates: \(bp.basePlates)",
                "Sole boards: \(bp.soleBoards)",
                "Standards: \(bp.standardLines)"
            ] + bp.advice
        case .cost:
            return [
                "Hire window: \(store.rentalDays) days (return by \(Formatters.date(store.rentalEnd)))",
                "Estimated rental: \(store.money(store.totalRentalCost))"
            ] + store.costLines.filter { $0.includeInTotal }.map { "\($0.name): \(store.money($0.cost(days: store.rentalDays)))" }
        }
    }

    // MARK: - PDF

    private func exportPDF() {
        if let url = makePDF() { share = ShareItem(url: url) } else { failed = true }
    }

    private func makePDF() -> URL? {
        let pageW: CGFloat = 595, pageH: CGFloat = 842, margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ScaffoldUp-Passport.pdf")

        let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor(hex: 0x0D1622)]
        let sectionAttr: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor(hex: 0x2F73E8)]
        let bodyAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor(hex: 0x222222)]
        let metaAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor(hex: 0x888888)]

        do {
            try renderer.writePDF(to: url) { ctx in
                var y: CGFloat = margin
                ctx.beginPage()
                func ensure(_ h: CGFloat) { if y + h > pageH - margin { ctx.beginPage(); y = margin } }
                func draw(_ text: String, _ attr: [NSAttributedString.Key: Any], _ height: CGFloat) {
                    ensure(height)
                    (text as NSString).draw(in: CGRect(x: margin, y: y, width: pageW - margin * 2, height: height), withAttributes: attr)
                    y += height
                }

                draw("Scaffold Up — Scaffold Passport", titleAttr, 34)
                draw("Generated \(Formatters.date(Date())) · \(store.config.name)", metaAttr, 18)
                // Tag status line
                let tagColor = store.tag.status == .green ? UIColor(hex: 0x16A34A) : UIColor(hex: 0xDC2626)
                draw("TAG: \(store.tag.status.headline)", [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: tagColor], 20)
                y += 4
                ctx.cgContext.setStrokeColor(UIColor(hex: 0xCCCCCC).cgColor)
                ctx.cgContext.move(to: CGPoint(x: margin, y: y)); ctx.cgContext.addLine(to: CGPoint(x: pageW - margin, y: y)); ctx.cgContext.strokePath()
                y += 14

                for (section, lines) in content() {
                    draw(section.title, sectionAttr, 24)
                    for line in lines { draw("•  " + line, bodyAttr, 17) }
                    y += 10
                }

                draw("Indicative for planning only — final approval to work rests with a competent person. Erect to the manufacturer's instructions.", metaAttr, 30)
            }
            return url
        } catch { return nil }
    }
}
