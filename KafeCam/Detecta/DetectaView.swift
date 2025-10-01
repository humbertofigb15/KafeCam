//
//  DetectaView.swift
//  KafeCam
//

import SwiftUI
import CoreML
import Vision

struct DetectaView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var prediction: String = "Apunta la cámara a una hoja ☕️🍃"
    @State private var capturedImage: UIImage?
    @State private var showCamera = true
    @State private var takePhotoTrigger = false
    @State private var showSaveOptions = false

    var body: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
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
                            prediction = "Apunta la cámara a una hoja ☕️🍃"
                            showSaveOptions = false
                            showCamera = true
                        }
                        .foregroundColor(.red)

                        Button("✅ Aceptar") {
                            if let img = capturedImage {
                                historyStore.add(image: img, prediction: prediction)
                                showSaveOptions = false
                            }
                        }
                        .foregroundColor(.green)
                    }
                }
            } else {
                Text(prediction)
                    .font(.title2)
                    .padding()
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
            ZStack {
                CameraPreview(takePhotoTrigger: $takePhotoTrigger) { image in
                    self.capturedImage = image
                    self.classify(image: image)
                    self.showCamera = false
                    self.showSaveOptions = true
                }
                .ignoresSafeArea()

                VStack {
                    Spacer()
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

    // Clasificación con CoreML
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
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}

