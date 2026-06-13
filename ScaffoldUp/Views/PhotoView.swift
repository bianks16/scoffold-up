//
//  PhotoView.swift  (Screen 12 — Marker Photo)
//  ScaffoldUp
//
//  Photos of the erected scaffold and key nodes (anchors, base, edge protection)
//  with captions and a category. PHPicker needs no photo-library permission.
//  iOS 14 safe.
//

import SwiftUI

struct PhotoView: View {
    @EnvironmentObject var store: AppStore
    @State private var picking = false
    @State private var editing: ScaffoldPhoto?

    var body: some View {
        ScreenScaffold("Marker Photos", subtitle: "Document the build & key nodes") {

            ActionButton(title: "Add Photo", systemImage: "photo.badge.plus") { picking = true }

            if store.photos.isEmpty {
                EmptyStateView(systemImage: "photo.on.rectangle.angled", title: "No photos yet",
                               message: "Add photos of anchors, the base, edge protection and the overall scaffold, then tap one to label it.")
            } else {
                let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                LazyVGrid(columns: cols, spacing: 12) {
                    ForEach(store.photos) { photo in
                        Button(action: { editing = photo }) { PhotoCell(photo: photo) }
                            .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $picking) {
            PhotoLibraryPicker { image in
                // Save immediately with defaults; the user labels it by tapping the cell.
                store.addPhoto(image, caption: "", detail: "", category: "General", tierIndex: nil)
            }
        }
        .sheet(item: $editing) { photo in PhotoEditSheet(photo: photo) }
    }
}

// MARK: - Photo cell

private struct PhotoCell: View {
    @EnvironmentObject var store: AppStore
    let photo: ScaffoldPhoto
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let img = store.image(for: photo.imageFileName) {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(height: 120).frame(maxWidth: .infinity).clipped()
                } else {
                    Rectangle().fill(Theme.surfaceAlt).frame(height: 120)
                        .overlay(Image(systemName: "photo").foregroundColor(Theme.textMuted))
                }
                TagChip(text: photo.category, color: Theme.safety, filled: true).padding(6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(photo.caption.isEmpty ? "Tap to label" : photo.caption)
                    .font(Theme.heading(13))
                    .foregroundColor(photo.caption.isEmpty ? Theme.textMuted : Theme.textPrimary).lineLimit(1)
                Text(Formatters.date(photo.createdAt)).font(Theme.caption(10)).foregroundColor(Theme.textSecondary)
            }
            .padding(8)
        }
        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m).stroke(Theme.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }
}

// MARK: - Edit photo sheet

private struct PhotoEditSheet: View {
    @EnvironmentObject var store: AppStore
    @State var photo: ScaffoldPhoto
    @Environment(\.presentationMode) private var presentationMode

    private let categories = ["General", "Anchors", "Base", "Edge protection", "Access"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Space.m) {
                    if let img = store.image(for: photo.imageFileName) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(height: 220).frame(maxWidth: .infinity).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                    }
                    LabeledField(label: "Caption", text: $photo.caption, placeholder: "e.g. North anchor row")
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CATEGORY").font(Theme.caption(11)).foregroundColor(Theme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { c in
                                    Button(action: { photo.category = c }) {
                                        Text(c).font(Theme.caption(12))
                                            .foregroundColor(photo.category == c ? Theme.textOnAccent : Theme.textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(Capsule().fill(photo.category == c ? Theme.safety : Theme.surfaceAlt))
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    LabeledField(label: "Detail", text: $photo.detail, placeholder: "Optional note")
                    ActionButton(title: "Save Changes", systemImage: "checkmark") {
                        UIApplication.shared.dismissKeyboard()
                        store.updatePhoto(photo); presentationMode.wrappedValue.dismiss()
                    }
                    ActionButton(title: "Delete Photo", systemImage: "trash", kind: .danger) {
                        store.deletePhoto(photo); presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding(Theme.Space.m)
            }
            .steelScreen(showFrame: false)
            .navigationBarTitle("Photo", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}
