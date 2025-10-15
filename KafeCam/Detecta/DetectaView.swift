//
//  DetectaView.swift
//  KafeCam
//

import SwiftUI
import CoreML
import Vision

struct DetectaView: View {
    @Environment(\.dismiss) var dismiss      // ✅ para regresar al Home directamente
    @EnvironmentObject var historyStore: HistoryStore
    
    private let capturesService = CapturesService()
    
    @State private var prediction: String = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = true     // arranca directamente en cámara
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
                                Task {
                                    await saveAcceptedCapture()
                                }
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
        }
        // cámara en pantalla completa
        .fullScreenCover(isPresented: $showCamera) {
            ZStack {
                // vista de cámara
                CameraPreview(takePhotoTrigger: $takePhotoTrigger) { image in
                    self.capturedImage = image
                    self.classify(image: image)
                    self.showCamera = false
                    self.showSaveOptions = true
                }
                .ignoresSafeArea()

                // botones superpuestos
                VStack {
                    HStack {
                        // 🔙 Flecha para regresar al Home
                        Button(action: {
                            dismiss()  // ✅ cierra DetectaView completamente
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

                    // botón de captura
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

    // MARK: - Clasificación con CoreML
    func classify(image: UIImage) {
        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: KafeCamCM(configuration: config).model) else {
            prediction = "⚠️ Error al cargar modelo"
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            if let result = request.results?.first as? VNClassificationObservation {
                DispatchQueue.main.async {
                    prediction = "Predicción: \(result.identifier) (\(Int(result.confidence * 100))%)"
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

    // MARK: - Guardado local (sin Supabase)
    private func saveAcceptedCapture() async {
        guard let img = capturedImage else { return }
        historyStore.add(image: img, prediction: prediction)
        showSaveOptions = false
    }
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}

