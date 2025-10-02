//
//  DetectaView.swift
//  KafeCam
//

import SwiftUI
import CoreML
import Vision

struct DetectaView: View {
    @EnvironmentObject var historyStore: HistoryStore
    private let capturesService = CapturesService()
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
                            Task {
                                await saveAcceptedCapture()
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

    // Guarda en Supabase: usa (o crea) un plot por defecto y registra la captura
    private func saveAcceptedCapture() async {
        guard let img = capturedImage, let data = img.jpegData(compressionQuality: 0.9) else { return }
        do {
            _ = try await capturesService.saveCaptureToDefaultPlot(imageData: data, takenAt: Date(), deviceModel: UIDevice.current.model)
            // Mantén UX local actual
            historyStore.add(image: img, prediction: prediction)
            showSaveOptions = false
        } catch {
            // feedback mínimo
            prediction = "⚠️ No se pudo guardar la foto"
        }
    }
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}

