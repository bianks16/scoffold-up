//
//  ScaffoldUpApp.swift
//  ScaffoldUp
//
//  App entry point. Injects the global AppStore + NotificationManager, applies
//  the persisted theme (light/dark/system) and flushes data to disk on
//  backgrounding. No login / welcome / auth screens. iOS 14 safe.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@main
struct ScaffoldUpApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.dark.rawValue

    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceRaw) ?? .dark }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifications)
                .preferredColorScheme(appearance.colorScheme)
                .onAppear { configureGlobalAppearance() }
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active { store.flush() }
        }
    }

    /// List/Form are UITableView-backed on iOS 14; clear their background so the
    /// steel backdrop shows through, and make navigation bars transparent.
    private func configureGlobalAppearance() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.titleTextAttributes = [.foregroundColor: UIColor(hex: 0xA7BAD6)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(hex: 0xE9F1FE)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(hex: 0xFACC15)
    }
}
