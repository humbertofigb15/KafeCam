//
//  HistoryView.swift
//  KafeCam
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    private let accentColor = Color(red: 134/255.0, green: 155/255.0, blue: 116/255.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tus fotos")
                .font(.largeTitle.bold())
                .foregroundColor(accentColor)
                .padding(.horizontal)

            if historyStore.entries.isEmpty {
                ContentUnavailableView(
                    "Sin fotos",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Aún no guardas fotos. Captura una en Detecta y guárdala aquí.")
                )
            } else {
                List(historyStore.entries) { entry in
                    HistoryRow(entry: entry)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accentColor)
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6))
                Image(uiImage: entry.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipped()
                    .cornerRadius(12)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.prediction)
                    .font(.headline)
                    .lineLimit(1)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

#Preview {
    HistoryView()
        .environmentObject(HistoryStore())
}

