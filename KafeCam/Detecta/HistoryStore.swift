import SwiftUI

@MainActor
class HistoryStore: ObservableObject {
    @Published var entries: [HistoryEntry] = []

    func add(image: UIImage, prediction: String, diseaseName: String?, status: PlotStatus) {
        let newEntry = HistoryEntry(
            image: image,
            prediction: prediction,
            date: Date(),
            isFavorite: false,
            diseaseName: diseaseName,
            status: status
        )
        entries.insert(newEntry, at: 0)
    }

    func toggleFavorite(for entry: HistoryEntry) {
        if let index = entries.firstIndex(of: entry) {
            entries[index].isFavorite.toggle()
        }
    }

    func updateNotes(for entry: HistoryEntry, notes: String) {
        if let index = entries.firstIndex(of: entry) {
            entries[index].notes = notes
        }
    }

    var favorites: [HistoryEntry] {
        entries.filter { $0.isFavorite }
    }
}
