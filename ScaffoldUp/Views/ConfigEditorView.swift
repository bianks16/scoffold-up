//
//  ConfigEditorView.swift  (Screen 02 — Add Bay / Lift & full configuration)
//  ScaffoldUp
//
//  Edit the whole scaffold configuration on a draft, preview the resulting part
//  count / anchors live, then apply. Applying a structural change drops the
//  green tag (re-inspection required). iOS 14 safe.
//

import SwiftUI

struct ConfigEditorView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var draft = ScaffoldConfig()
    @State private var loaded = false
    @State private var applied = false

    private var previewSpec: ComponentSpec {
        ScaffoldEngine.components(for: draft, deckedTiers: max(draft.lifts, 1))
    }
    private var previewTie: TiePlan { ScaffoldEngine.tiePlan(for: draft) }

    var body: some View {
        ScreenScaffold("Configure", subtitle: "Build out bays, lifts, sizes & site") {

            // Live preview
            CardView(tint: Theme.tube.opacity(0.4)) {
                VStack(spacing: 12) {
                    ScaffoldIsometricView(bays: draft.bays, lifts: draft.lifts,
                                          deckedLevels: Set(0..<draft.lifts), tagStatus: store.tag.status)
                        .frame(height: 180)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: draft.bays)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: draft.lifts)
                    HStack(spacing: 14) {
                        previewMetric("Height", store.len(draft.height))
                        previewMetric("Facade", store.len(draft.facadeLength))
                        previewMetric("Parts", "\(previewSpec.totalPieces)")
                        previewMetric("Anchors", draft.type.needsTies ? "\(previewTie.required)" : "—")
                    }
                }
            }

            // Type
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Scaffold type", systemImage: "square.grid.3x3.fill")
                    ForEach(ScaffoldType.allCases) { t in
                        ChoiceRow(icon: t.icon, title: t.displayName, subtitle: t.subtitle, selected: draft.type == t) {
                            withAnimation { draft.type = t }
                        }
                    }
                }
            }

            // Duty
            CardView {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Duty class", subtitle: "Sets the safe platform load", systemImage: "scalemass.fill")
                    Picker("", selection: $draft.dutyClass) {
                        ForEach(DutyClass.allCases) { Text($0.shortName).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle())
                    Text("\(draft.dutyClass.usage) · \(Formatters.decimal(draft.dutyClass.loadPerSqmKN, digits: 2)) kN/m²")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }

            // Bays & lifts
            CardView {
                VStack(spacing: 14) {
                    StepperRow(label: "Bays", systemImage: "rectangle.split.3x1.fill", value: $draft.bays, range: 1...store.maxBays)
                    Divider().background(Theme.stroke)
                    StepperRow(label: "Lifts", systemImage: "square.stack.3d.up.fill", value: $draft.lifts, range: 1...store.maxLifts)
                }
            }

            // Sizes
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Sizes", systemImage: "ruler.fill")
                    sizePicker("Bay length", BayLength.allCases.map { ($0.label, $0.rawValue) }, $draft.bayLengthRaw)
                    sizePicker("Platform width", PlatformWidth.allCases.map { ($0.label, $0.rawValue) }, $draft.platformWidthRaw)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("LIFT HEIGHT").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        HStack {
                            Slider(value: $draft.liftHeight, in: 1.5...2.5, step: 0.1).accentColor(Theme.accent)
                            Text("\(Formatters.decimal(draft.liftHeight, digits: 1)) m").font(Theme.mono(13)).foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            }

            // Site
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Site conditions", systemImage: "wind")
                    Text("WIND EXPOSURE").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                    Picker("", selection: $draft.windExposure) {
                        ForEach(WindExposure.allCases) { Text($0.displayName).tag($0) }
                    }.pickerStyle(SegmentedPickerStyle())
                    Toggle(isOn: $draft.unevenGround) {
                        Label("Uneven / soft ground", systemImage: "square.split.bottomrightquarter.fill")
                            .font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }.toggleStyle(SwitchToggleStyle(tint: Theme.caution))
                    Toggle(isOn: $draft.nearPowerLines) {
                        Label("Near power lines", systemImage: "bolt.trianglebadge.exclamationmark.fill")
                            .font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }.toggleStyle(SwitchToggleStyle(tint: Theme.danger))
                }
            }

            if draft != store.config {
                CardView(tint: Theme.warning.opacity(0.5)) {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.warning)
                        Text("Applying changes drops the tag to RED — re-inspect before use.")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    }
                }
            }

            ActionButton(title: applied ? "Applied ✓" : "Apply Configuration", systemImage: "checkmark.circle.fill") {
                store.updateConfig(draft)
                withAnimation { applied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { presentationMode.wrappedValue.dismiss() }
            }
            .disabled(draft == store.config)
            .opacity(draft == store.config ? 0.5 : 1)
        }
        .navigationBarTitle("Configure", displayMode: .inline)
        .onAppear { if !loaded { draft = store.config; loaded = true } }
    }

    private func previewMetric(_ l: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(Theme.heading(15)).foregroundColor(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.6)
            Text(l).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
        }.frame(maxWidth: .infinity)
    }
    private func sizePicker(_ label: String, _ options: [(String, Double)], _ binding: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased()).font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
            Picker(label, selection: binding) {
                ForEach(options, id: \.1) { Text($0.0).tag($0.1) }
            }.pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: - Choice row

struct ChoiceRow: View {
    let icon: String; let title: String; var subtitle: String = ""; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(selected ? .white : Theme.tube).frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(Theme.heading(14)).foregroundColor(selected ? .white : Theme.textPrimary)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(Theme.caption(11)).foregroundColor(selected ? .white.opacity(0.85) : Theme.textSecondary)
                    }
                }
                Spacer()
                if selected { Image(systemName: "checkmark.circle.fill").foregroundColor(.white) }
            }
            .padding(11)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.s).fill(selected ? Theme.accent : Theme.surfaceAlt))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
