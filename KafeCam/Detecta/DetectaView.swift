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
    
    private let capturesService = CapturesService() // (no se usa en este flujo local, lo dejamos por si lo reactivas)

    @State private var prediction: String = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = true     // arranca directamente en cámara
    @State private var takePhotoTrigger = false
    @State private var showSaveOptions = false

    // ✅ NUEVO: datos “reales” del modelo para no parsear desde el texto
    @State private var lastIdentifier: String = ""
    @State private var lastConfidencePct: Double = 0.0   // 0–100

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
                    // ✅ Guardamos datos “reales” para usar en la notificación
                    lastIdentifier = result.identifier
                    lastConfidencePct = Double(result.confidence * 100.0)
                    prediction = "Predicción: \(result.identifier) (\(Int(lastConfidencePct))%)"
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

    // MARK: - Guardado local (Consulta) + notificación para crear pin en mapa
    private func saveAcceptedCapture() async {
        guard let img = capturedImage else { return }

        // 1) Mantén flujo actual: guardar en “Consulta” (HistoryStore)
        historyStore.add(image: img, prediction: prediction)
        showSaveOptions = false

        // 2) 🔔 Notificar al mapa para crear pin automático con última ubicación y estatus por %
        NotificationCenter.default.post(
            name: .kafeCreatePin,
            object: nil,
            userInfo: [
                "probabilidad": lastConfidencePct, // Double 0–100
                "label": lastIdentifier,           // opcional, por si quieres usarlo luego
                "fecha": Date()
            ]
        )

        // (opcional) si quieres regresar al Home automáticamente después de aceptar:
            dismiss()
    }
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}
import Foundation

extension Notification.Name {
    static let kafeCreatePin = Notification.Name("kafeCreatePin")
    static let kafePinAdded = Notification.Name("kafePinAdded")
    static let kafePinAddFailedNoLocation = Notification.Name("kafePinAddFailedNoLocation")
}
