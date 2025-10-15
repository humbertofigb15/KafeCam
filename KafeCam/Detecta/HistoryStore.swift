import SwiftUI
import Foundation

@MainActor
class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []

    // Agrega una nueva entrada al historial
    func add(image: UIImage, prediction: String) {
        let new = HistoryEntry(image: image, prediction: prediction, date: Date(), isFavorite: false)
        entries.insert(new, at: 0)
    }

    // Alterna favorito
    func toggleFavorite(for entry: HistoryEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].isFavorite.toggle()
        }
    }

    // Lista de favoritos
    var favorites: [HistoryEntry] {
        entries.filter { $0.isFavorite }
    }

    // Recarga de ejemplo (sin backend)
    func syncLocal() {
        // Aquí podrías cargar desde UserDefaults o archivo local si lo agregamos después
        print("Historial cargado localmente (\(entries.count) entradas)")
    }
}
