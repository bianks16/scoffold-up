//
//  RemindersView.swift  (Screen 17 — Reminders)
//  ScaffoldUp
//
//  Real local-notification reminders: tag re-inspection (at the due date),
//  storm re-check (after a chosen window) and rental return (at the hire end).
//  All wired to UNUserNotificationCenter via NotificationManager. iOS 14 safe.
//

import SwiftUI

struct RemindersView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var notifications: NotificationManager

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("remReinspection") private var remReinspection = true
    @AppStorage("remRental") private var remRental = true
    @State private var stormHours = 4
    @State private var toast: String?

    var body: some View {
        ScreenScaffold("Reminders", subtitle: "On-device, no account needed") {

            if let t = toast {
                CardView(tint: Theme.success.opacity(0.5)) {
                    HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.success)
                        Text(t).font(Theme.body()).foregroundColor(Theme.textPrimary) }
                }
            }

            // Master switch
            CardView {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Allow notifications", subtitle: notifications.isAuthorized ? "Allowed" : "Tap to request permission", systemImage: "bell.badge.fill")
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable reminders").font(Theme.body()).foregroundColor(Theme.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Theme.safety))
                    .onChange(of: notificationsEnabled) { on in handleMaster(on) }
                }
            }

            if notificationsEnabled {
                // Re-inspection
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Tag re-inspection", systemImage: "clock.arrow.circlepath")
                        Toggle(isOn: $remReinspection) {
                            Text("Remind at due date").font(Theme.body()).foregroundColor(Theme.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
                        .onChange(of: remReinspection) { _ in syncReinspection() }
                        if let due = store.tag.nextDueDate, store.tag.status == .green {
                            Text("Next: \(Formatters.date(due)) (\(Formatters.relativeDays(to: due)))")
                                .font(Theme.caption(12)).foregroundColor(store.tagOverdue ? Theme.danger : Theme.textSecondary)
                        } else {
                            Text("Pass an inspection to set a due date.").font(Theme.caption(12)).foregroundColor(Theme.textMuted)
                        }
                    }
                }

                // Rental return
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Rental return", systemImage: "shippingbox.fill")
                        Toggle(isOn: $remRental) {
                            Text("Remind to return hire").font(Theme.body()).foregroundColor(Theme.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.info))
                        .onChange(of: remRental) { _ in syncRental() }
                        Text("Return by \(Formatters.date(store.rentalEnd)) (\(Formatters.relativeDays(to: store.rentalEnd)))")
                            .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                    }
                }

                // Storm re-check
                CardView {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Storm re-check", subtitle: "After bad weather", systemImage: "cloud.bolt.rain.fill")
                        StepperRow(label: "Remind me in", systemImage: "clock.fill", value: $stormHours, range: 1...48, suffix: " h")
                        ActionButton(title: "Schedule re-check reminder", systemImage: "alarm.fill", kind: .secondary) {
                            notifications.scheduleAfter(.storm, seconds: Double(stormHours) * 3600,
                                                        body: "\(store.config.name): re-check the scaffold after the weather event.")
                            flash("Storm re-check reminder set for \(stormHours)h")
                        }
                    }
                }

                ActionButton(title: "Send Test Notification", systemImage: "paperplane.fill", kind: .secondary) {
                    notifications.sendTest(body: "Reminders are working — \(store.config.name).")
                    flash("Test notification scheduled (3s)")
                }
            }

            CardView(tint: Theme.safety.opacity(0.4)) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill").foregroundColor(Theme.safety)
                    Text("Reminders fire locally on this device. If permission is denied, enable it in iOS Settings → Notifications.")
                        .font(Theme.caption(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
        .navigationBarTitle("Reminders", displayMode: .inline)
        .onAppear { notifications.refreshStatus() }
    }

    // MARK: - Wiring

    private func handleMaster(_ on: Bool) {
        if on {
            notifications.requestAuthorization { granted in
                if granted {
                    syncReinspection(); syncRental()
                    flash("Reminders enabled")
                } else {
                    notificationsEnabled = false
                    flash("Permission denied — enable in iOS Settings")
                }
            }
        } else {
            notifications.cancelAll()
            flash("Reminders turned off")
        }
    }

    private func syncReinspection() {
        guard notificationsEnabled else { return }
        if remReinspection, store.tag.status == .green, let due = store.tag.nextDueDate {
            notifications.scheduleOnce(.reinspection, at: due, body: "\(store.config.name): scaffold re-inspection is due.")
        } else {
            notifications.cancel(.reinspection)
        }
    }
    private func syncRental() {
        guard notificationsEnabled else { return }
        if remRental {
            notifications.scheduleOnce(.rental, at: store.rentalEnd, body: "\(store.config.name): scaffold hire is due back today.")
        } else {
            notifications.cancel(.rental)
        }
    }

    private func flash(_ msg: String) {
        withAnimation { toast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { withAnimation { toast = nil } }
    }
}
