//
//  HistoryModel.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 09/09/25.
//

import SwiftUI

struct HistoryView: View {
    private let accentColor = Color(red: 134/255.0, green: 155/255.0, blue: 116/255.0)
    @StateObject private var vm = GalleryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tus fotos")
                .font(.largeTitle.bold())
                .foregroundColor(accentColor)
                .padding(.horizontal)

            if vm.rows.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Sin fotos",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Aún no guardas fotos. Captura una en Detecta y guárdala aquí."))
            } else {
                List(vm.rows) { rec in
                    NavigationLink {
                        HistoryDetailPlaceholder(row: rec, accentColor: accentColor)
                    } label: {
                        HistoryRowPlaceholder(row: rec)
                            .contentShape(Rectangle())
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accentColor)
        .overlay { if vm.isLoading { ProgressView() } }
        .task { await vm.load() }
    }
}

struct HistoryRowPlaceholder: View {
    let row: CaptureRow
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))
                Image(systemName: "leaf.fill").foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(row.title).font(.headline).lineLimit(1)
                Text(row.subtitle).font(.subheadline).foregroundStyle(.secondary)
                Text(row.dateText).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct HistoryDetailPlaceholder: View {
    let row: CaptureRow
    var accentColor: Color
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6))
                    Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                }
                .frame(height: 260)

                VStack(alignment: .leading, spacing: 8) {
                    Text(row.title)
                        .font(.largeTitle.bold())
                        .foregroundColor(accentColor)
                    Text(row.subtitle).foregroundStyle(.secondary)
                    Text(row.dateText).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}
