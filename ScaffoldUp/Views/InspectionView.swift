//
//  InspectionView.swift  (Screen 07 — Inspection)
//  ScaffoldUp
//
//  The access checklist that drives the whole safety system: every applicable
//  point must pass to issue a GREEN tag; any fail issues a RED tag with the
//  defects to fix. A pass schedules the next re-inspection reminder. iOS 14 safe.
//

import SwiftUI

struct InspectionView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var passed: Set<InspectionPoint> = []
    @State private var inspector = ""
    @State private var note = ""
    @State private var loaded = false
    @State private var showResult = false

    private var points: [InspectionPoint] { InspectionPoint.allCases.filter { $0.applies(to: store.config.type) } }
    private var failing: [InspectionPoint] { points.filter { !passed.contains($0) } }
    private var willPass: Bool { failing.isEmpty }

    var body: some View {
        ScreenScaffold("Inspection", subtitle: "Pass every point to release a green tag") {

            // Resulting tag preview
            CardView(tint: (willPass ? Theme.success : Theme.danger).opacity(0.55)) {
                HStack {
                    ScaffTagBadge(status: willPass ? .green : .red)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(willPass ? "Will issue GREEN" : "\(failing.count) defect(s)")
                            .font(Theme.heading(14)).foregroundColor(willPass ? Theme.success : Theme.danger)
                        Text("\(passed.count)/\(points.count) points pass")
                            .font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    }
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledField(label: "Inspector (competent person)", text: $inspector, placeholder: "Name")
                    HStack(spacing: 10) {
                        ActionButton(title: "Tick all pass", systemImage: "checkmark.circle", kind: .secondary, fullWidth: true) {
                            withAnimation { passed = Set(points) }
                        }
                        ActionButton(title: "Clear", systemImage: "xmark.circle", kind: .secondary, fullWidth: true) {
                            withAnimation { passed.removeAll() }
                        }
                    }
                }
            }

            SectionHeader(title: "Checklist", subtitle: "Tap to toggle pass / fail", systemImage: "checklist")
            VStack(spacing: 9) {
                ForEach(points) { point in
                    InspectionRow(point: point, passed: passed.contains(point)) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if passed.contains(point) { passed.remove(point) } else { passed.insert(point) }
                        }
                    }
                }
            }

            if !failing.isEmpty {
                CardView(tint: Theme.danger.opacity(0.5)) {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "To fix before tagging green", systemImage: "wrench.and.screwdriver.fill", tint: Theme.danger)
                        ForEach(failing) { f in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(Theme.danger).font(.system(size: 13)).padding(.top, 1)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(f.title).font(Theme.caption(13)).foregroundColor(Theme.textPrimary)
                                    Text(f.fixHint).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("NOTES").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                TextEditor(text: $note)
                    .frame(height: 70).padding(6)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(Theme.surfaceAlt))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s).stroke(Theme.stroke, lineWidth: 1))
                    .foregroundColor(Theme.textPrimary)
            }

            ActionButton(title: willPass ? "Pass & Issue Green Tag" : "Record & Issue Red Tag",
                         systemImage: willPass ? "checkmark.seal.fill" : "xmark.octagon.fill",
                         kind: willPass ? .safety : .danger) {
                runInspection()
            }

            if showResult, let last = store.inspections.first {
                resultCard(last)
            }
        }
        .navigationBarTitle("Inspection", displayMode: .inline)
        .onAppear {
            if !loaded {
                inspector = store.tag.inspector.isEmpty ? "Site Supervisor" : store.tag.inspector
                if let latest = store.inspections.first {
                    passed = Set(latest.passedPoints.compactMap { InspectionPoint(rawValue: $0) }).intersection(Set(points))
                } else { passed = Set(points) }
                loaded = true
            }
        }
    }

    private func runInspection() {
        UIApplication.shared.dismissKeyboard()
        store.runInspection(passed: passed, inspector: inspector, isStorm: false, note: note)
        if willPass, notificationsEnabled, notifications.isAuthorized, let due = store.tag.nextDueDate {
            notifications.scheduleOnce(.reinspection, at: due,
                                       body: "\(store.config.name): scaffold re-inspection is due.")
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showResult = true }
    }

    private func resultCard(_ insp: Inspection) -> some View {
        CardView(tint: insp.passed ? Theme.success.opacity(0.6) : Theme.danger.opacity(0.6)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: insp.resultStatus.icon).foregroundColor(insp.resultStatus.color)
                    Text(insp.passed ? "Green tag issued" : "Red tag issued")
                        .font(Theme.heading(16)).foregroundColor(insp.resultStatus.color)
                    Spacer()
                    Text(Formatters.dateTime(insp.date)).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                }
                Text(insp.passed
                     ? "Safe to work. Next re-inspection \(store.tag.nextDueDate.map { Formatters.relativeDays(to: $0) } ?? "scheduled")."
                     : "Do not use until the \(insp.failedPoints.count) defect(s) are fixed and re-inspected.")
                    .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
            }
        }
    }
}

// MARK: - Inspection row

private struct InspectionRow: View {
    let point: InspectionPoint
    let passed: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundColor(passed ? Theme.success : Theme.textMuted)
                Image(systemName: point.icon).foregroundColor(Theme.tube).frame(width: 22)
                Text(point.title).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(passed ? Theme.success.opacity(0.10) : Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(passed ? Theme.success.opacity(0.4) : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
