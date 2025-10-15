//
//  DetectaView.swift
//  KafeCam
//

import SwiftUI
import CoreML
import Vision

struct DetectaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: HistoryStore
    
    @State private var prediction: String = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = true
    @State private var takePhotoTrigger = false
    @State private var showSaveOptions = false

    var body: some View {
        ZStack {
            if let image = capturedImage {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(12)

                    Text(prediction)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()

                    if showSaveOptions {
                        HStack(spacing: 40) {
                            Button("❌ Rechazar") {
                                capturedImage = nil
                                prediction = ""
                                showSaveOptions = false
                                showCamera = true
                            }
                            .foregroundColor(.red)

                            Button("✅ Aceptar") {
                                historyStore.add(image: image, prediction: prediction)
                                showSaveOptions = false
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ZStack {
                // Vista de cámara
                CameraPreview(takePhotoTrigger: $takePhotoTrigger) { image in
                    self.capturedImage = image
                    self.classify(image: image)
                    self.showCamera = false
                    self.showSaveOptions = true
                }
                .ignoresSafeArea()

                // Botones superpuestos
                VStack {
                    HStack {
                        // 🔙 Flecha para regresar al Home
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                                .padding(.leading, 20)
                                .padding(.top, 20)
                        }
                        Spacer()
                    }

                    Spacer()

                    // Botón de captura
                    Button(action: { takePhotoTrigger = true }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Clasificación con CoreML adaptada a tu estructura
    func classify(image: UIImage) {
        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: KafeCamCM(configuration: config).model) else {
            prediction = "⚠️ Error al cargar modelo"
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            if let result = request.results?.first as? VNClassificationObservation {
                DispatchQueue.main.async {
                    let label = result.identifier.lowercased()
                    let confidence = Int(result.confidence * 100)
                    
                    // Divide etiquetas tipo "roya enfermo" o "manganeso sospecha"
                    let components = label.components(separatedBy: CharacterSet.whitespacesAndNewlines)
                    let tipo = components.first?.capitalized ?? ""
                    let estado = components.dropFirst().first?.capitalized ?? ""
                    
                    // Mostrar texto formateado según caso
                    if tipo == "Sana" {
                        prediction = "🌿 Planta sana (\(confidence)%)"
                    } else {
                        var emoji = "🦠"
                        if estado == "Sospecha" { emoji = "⚠️" }
                        else if estado == "Enfermo" { emoji = "🚨" }

                        let descripcion = "Posible deficiencia de \(tipo.lowercased()) (\(estado.lowercased()))"
                        prediction = "\(emoji) \(descripcion) (\(confidence)%)"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    prediction = "⚠️ No se pudo clasificar la imagen"
                }
            }
        }

        guard let ciImage = CIImage(image: image) else {
            prediction = "⚠️ Imagen inválida"
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    prediction = "⚠️ Error al procesar la imagen"
                }
            }
        }
    }
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}

