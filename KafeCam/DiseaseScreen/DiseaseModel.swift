//
//  DiseaseModel.swift
//  KafeCam
//
//  Created by Bruno Rivera on 11/09/25.
//

import Foundation

struct DiseaseModel: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var scientificName: String?
    var description: String
    var impact: String
    var prevention: String
    var imageName: String
}

let sampleDiseases: [DiseaseModel] = [
    .init(name: "Roya del café", scientificName: "Hemileia vastratix", description: "La Roya del café es una enfermedad fúngica 🦠 causada por el hongo Hemileia vastatrix. Se manifiesta como manchas amarillas o anaranjadas 🟡 en el envés (parte de abajo) de las hojas del cafeto, que luego se convierten en polvo. Estas lesiones hacen que la hoja se seque, se vuelva de color café y se caiga. 🍂", impact: "El impacto de la roya del café es significativo para los agricultores 🧑‍🌾 y la producción. La caída de las hojas debilita la planta, lo que reduce la producción de frutos ☕️ y puede causar la muerte de la planta. Esto lleva a grandes pérdidas económicas 💸 en la cosecha y aumenta los costos de manejo de la plantación. Es una de las amenazas más graves para el cultivo del café a nivel mundial. 🌍", prevention: "This is a placeholder for the Roya del café disease and its prevention methods", imageName: "Roya"),
]
