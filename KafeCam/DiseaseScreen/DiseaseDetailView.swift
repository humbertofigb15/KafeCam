//
//  DiseaseDetailView.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import SwiftUI

struct DiseaseDetailView: View {
    let disease: DiseaseModel
    private let labels = ["Descripción", "Impacto", "Prevención", "Ficha"]
    private let accentColor = Color(red: 88/255, green: 129/255, blue: 87/255)
    
    @State private var selectedScreen = 0
    
    var body: some View {
        
        let descriptions = [
            "\(disease.description)",
            "\(disease.impact)",
            "\(disease.prevention)",
        ]
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(disease.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 8){
                    Text(disease.name)
                        .font(.largeTitle.bold())
                        .foregroundStyle(accentColor)
                    
                    if disease.scientificName != nil {
                        Text((disease.scientificName)!)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Picker("Choose description", selection: $selectedScreen) {
                    ForEach(labels.indices, id: \.self) { index in
                        Text(labels[index])
                            .foregroundStyle(.white)
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                if descriptions.indices.contains(selectedScreen) {
                    Text(descriptions[selectedScreen])
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Detalles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DiseaseDetailView(disease: DiseaseModel(name: "Roya del café", description: "Esta es una descripción sobre las características de la roya del café.", impact: "Esta es una descripción sobre el impacto negativo de la roya del café.", prevention: "Esta es una descripción sobre las medidas de prevención para la roya del café.", imageName: "Roya"))
}
