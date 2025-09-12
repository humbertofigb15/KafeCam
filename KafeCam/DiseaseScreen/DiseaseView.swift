//
//  DiseaseView.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import SwiftUI

struct DiseaseView: View {
    @State private var path = NavigationPath()
    private let accentColor = Color(red: 88/255, green: 129/255, blue: 87/255)
    private let darkColor = Color(red: 82/255,  green: 76/255,  blue: 41/255)
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Enciclopedia de enfermedades")
                    .font(.largeTitle.bold())
                    .foregroundStyle(accentColor)
                    .padding(.horizontal)
                
                List(sampleDiseases) { item in
                    Button {
                        path.append(item)
                    } label: {
                        DiseaseRowView(disease: item)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Enfermedades")
            .navigationDestination(for: DiseaseModel.self) { item in
                DiseaseDetailView(disease: item)
            }
        }
    }
}

#Preview {
    DiseaseView()
}
