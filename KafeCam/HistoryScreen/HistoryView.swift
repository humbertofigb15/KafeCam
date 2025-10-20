import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    
    var body: some View {
        NavigationView {
            List(historyStore.entries) { entry in
                NavigationLink(destination: ConsultaDetailView(entry: entry)) {
                    HistoryRow(entry: entry)
                }
            }
            .navigationTitle("Historial")
        }
    }
}
