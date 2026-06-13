//
//  StormRecheckView.swift  (Screen 10 — Storm / Re-check)
//  ScaffoldUp
//
//  After bad weather the scaffold must be re-checked before use. This runs a
//  focused checklist of the key nodes, records the weather event and (on a pass)
//  re-validates the tag. iOS 14 safe.
//

import SwiftUI

struct StormRecheckView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false

    @State private var event = "High winds"
    @State private var eventDate = Date()
    @State private var inspector = ""
    @State private var passed: Set<InspectionPoint> = []
    @State private var loaded = false
    @State private var done = false

    // The key nodes to re-check after a storm.
    private let keyPoints: [InspectionPoint] = [.base, .plumb, .bracing, .ties, .platform, .toeBoard, .guardrail]
    private var points: [InspectionPoint] { keyPoints.filter { $0.applies(to: store.config.type) } }
    private var failing: [InspectionPoint] { points.filter { !passed.contains($0) } }
    private var willPass: Bool { failing.isEmpty }

    var body: some View {
        ScreenScaffold("Storm / Re-check", subtitle: "Re-inspect key nodes after weather") {

            CardView(tint: Theme.caution.opacity(0.5)) {
                HStack(spacing: 10) {
                    Image(systemName: "cloud.bolt.rain.fill").foregroundColor(Theme.caution)
                    Text("After high winds, heavy rain or impact, a scaffold must be re-checked before anyone uses it.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }

            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Weather event", systemImage: "tornado")
                    Picker("", selection: $event) {
                        ForEach(["High winds", "Storm / rain", "Snow / ice", "Impact", "Other"], id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle())
                    HStack {
                        Text("Date").font(Theme.body()).foregroundColor(Theme.textSecondary)
                        Spacer()
                        DatePicker("", selection: $eventDate, displayedComponents: .date).labelsHidden().accentColor(Theme.caution)
                    }
                    LabeledField(label: "Checked by", text: $inspector, placeholder: "Name")
                }
            }

            SectionHeader(title: "Key nodes", subtitle: "Confirm nothing has shifted", systemImage: "checklist")
            VStack(spacing: 9) {
                ForEach(points) { point in
                    StormRow(point: point, passed: passed.contains(point)) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if passed.contains(point) { passed.remove(point) } else { passed.insert(point) }
                        }
                    }
                }
            }

            if !failing.isEmpty {
                CardView(tint: Theme.danger.opacity(0.5)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(failing.count) node(s) failed — keep the red tag and rectify:")
                            .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                        ForEach(failing) { f in
                            Text("• \(f.title)").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }

            ActionButton(title: willPass ? "Pass Re-check & Re-validate Tag" : "Record Storm Re-check",
                         systemImage: "cloud.bolt.rain.fill",
                         kind: willPass ? .safety : .danger) {
                UIApplication.shared.dismissKeyboard()
                store.addHistory(.stormChecked, "\(event) on \(Formatters.date(eventDate)).")
                store.runInspection(passed: passed, inspector: inspector.isEmpty ? "Site Supervisor" : inspector,
                                    isStorm: true, note: "Storm re-check after \(event).")
                if willPass, notificationsEnabled, notifications.isAuthorized, let due = store.tag.nextDueDate {
                    notifications.scheduleOnce(.reinspection, at: due, body: "\(store.config.name): re-inspection due.")
                }
                withAnimation { done = true }
            }

            if done {
                CardView(tint: (willPass ? Theme.success : Theme.danger).opacity(0.6)) {
                    HStack(spacing: 10) {
                        Image(systemName: willPass ? "checkmark.seal.fill" : "xmark.octagon.fill")
                            .foregroundColor(willPass ? Theme.success : Theme.danger)
                        Text(willPass ? "Storm re-check passed — tag re-validated."
                                      : "Storm re-check recorded — tag stays RED.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
        .navigationBarTitle("Storm Re-check", displayMode: .inline)
        .onAppear {
            if !loaded {
                inspector = store.tag.inspector.isEmpty ? "Site Supervisor" : store.tag.inspector
                loaded = true
            }
        }
    }
}

private struct StormRow: View {
    let point: InspectionPoint
    let passed: Bool
    let toggle: () -> Void
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22)).foregroundColor(passed ? Theme.success : Theme.textMuted)
                Image(systemName: point.icon).foregroundColor(Theme.caution).frame(width: 22)
                Text(point.title).font(Theme.body(14)).foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(passed ? Theme.success.opacity(0.10) : Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(passed ? Theme.success.opacity(0.4) : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
