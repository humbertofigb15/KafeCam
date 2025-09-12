//
//  DiseaseRowView.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import SwiftUI

struct DiseaseRowView: View {
    let disease: DiseaseModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(disease.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipped()
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(disease.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if disease.scientificName != nil {
                    Text((disease.scientificName)!)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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

#Preview {
    ForEach(sampleDiseases) { item in
        DiseaseRowView(disease: DiseaseModel(name: item.name, scientificName: item.scientificName, description: item.description, impact: item.impact, prevention: item.prevention, imageName: item.imageName))
    }
}
