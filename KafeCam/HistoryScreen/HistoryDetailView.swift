import SwiftUI

struct HistoryDetailView: View {
    @EnvironmentObject var historyStore: HistoryStore
    let entry: HistoryEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(uiImage: entry.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                    .padding()

                Text(entry.prediction)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    historyStore.toggleFavorite(for: entry)
                } label: {
                    Label(entry.isFavorite ? "Quitar de Favoritos" : "Agregar a Favoritos",
                          systemImage: entry.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(entry.isFavorite ? .red : .accentColor)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

