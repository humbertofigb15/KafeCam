//
//  DiseaseView.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import SwiftUI

struct DiseaseView: View {
    // This is no longer needed if we use NavigationLink
    // @State private var path = NavigationPath()
    
    // 1. Define the grid layout with two flexible columns.
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private let accentColor = Color(red: 88/255, green: 129/255, blue: 87/255)
    private let darkColor = Color(red: 82/255,  green: 76/255,  blue: 41/255)
    
    var body: some View {
        // We can use a simpler NavigationStack initializer
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Enciclopedia de enfermedades")
                    .font(.largeTitle.bold())
                    .foregroundStyle(accentColor)
                    .padding(.horizontal)
                
                // 2. Replace the List with a ScrollView and LazyVGrid.
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(sampleDiseases) { item in
                            // 3. Use NavigationLink for cleaner navigation.
                            //    It works directly with your .navigationDestination modifier.
                            NavigationLink(value: item) {
                                DiseaseRowView(disease: item)
                            }
                            .buttonStyle(.plain) // Keeps the row's original style
                        }
                    }
                    .padding() // Add padding around the grid
                }
            }
            .navigationTitle("Enfermedades")
            .navigationBarTitleDisplayMode(.inline) // Optional: for a cleaner look
            .navigationDestination(for: DiseaseModel.self) { item in
                DiseaseDetailView(disease: item)
            }
        }
    }
}

#Preview {
    DiseaseView()
}
