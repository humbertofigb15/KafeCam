//
//  HistoryModel.swift
//  KafeCam
//
//  Created by Grecia Saucedo on 09/09/25.
//
import SwiftUI

struct HistoryView: View {
    private let accentColor = Color(red: 134/255, green: 155/255, blue: 116/255)
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tus fotos")
                    .font(.largeTitle.bold())
                    .foregroundColor(accentColor)
                    .padding(.horizontal)
                
                List(sampleHistory) { rec in
                    Button {
                        path.append(rec)
                    } label: {
                        HistoryCard(record: rec)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Historial")
            .navigationDestination(for: PhotoRecord.self) { rec in
                HistoryDetailMock(record: rec, accentColor: accentColor)
            }
        }
        .tint(accentColor)
    }
}

// Tarjeta
struct HistoryCard: View {
    let record: PhotoRecord
    
    var body: some View {
        HStack(spacing: 12) {
            Image(record.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipped()
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(record.disease)
                    .font(.headline)
                    .lineLimit(1)
                
                if let location = record.location {
                    Text(location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(record.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// Detalle
struct HistoryDetailMock: View {
    let record: PhotoRecord
    var accentColor: Color
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(record.imageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.disease)
                        .font(.largeTitle.bold())
                        .foregroundColor(accentColor)
                    
                    HStack(spacing: 8) {
                        Text(record.date)
                        if let location = record.location { Text("• \(location)") }
                    }
                    .foregroundStyle(.secondary)
                    
                    Text("Aquí podrían mostrarse notas o recomendaciones sobre la enfermedad.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview
#Preview {
    HistoryView()
}
