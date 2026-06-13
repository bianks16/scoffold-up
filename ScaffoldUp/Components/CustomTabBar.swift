//
//  CustomTabBar.swift
//  ScaffoldUp
//
//  Custom themed tab bar (not the system TabView chrome). iOS 14 safe.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case builder, spec, safety, log, more
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .builder: return "Builder"
        case .spec:    return "Spec"
        case .safety:  return "Safety"
        case .log:     return "Log"
        case .more:    return "More"
        }
    }
    var icon: String {
        switch self {
        case .builder: return "square.stack.3d.up.fill"
        case .spec:    return "list.bullet.rectangle.fill"
        case .safety:  return "checkmark.shield.fill"
        case .log:     return "doc.text.fill"
        case .more:    return "ellipsis.circle.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selection: AppTab
    var badge: Int = 0   // shown on the Safety tab (risk count)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selection = tab }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            Image(systemName: tab.icon)
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(selection == tab ? Theme.safety : Theme.textSecondary)
                                .scaleEffect(selection == tab ? 1.12 : 1.0)
                            if tab == .safety && badge > 0 {
                                Text("\(badge)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(Theme.danger))
                                    .offset(x: 12, y: -10)
                            }
                        }
                        Text(tab.title)
                            .font(.system(size: 10, weight: selection == tab ? .bold : .medium, design: .rounded))
                            .foregroundColor(selection == tab ? Theme.safety : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 6)
        .background(
            BlurView(style: .systemThinMaterialDark)
                .overlay(Theme.surface.opacity(0.6))
                .overlay(Rectangle().fill(Theme.stroke).frame(height: 1), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
}
