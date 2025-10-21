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
    @State private var showConsulta = false

    @State private var lastStatus: PlotStatus = .sano
    @State private var lastConfidencePct: Double = 0.0
    @State private var lastDiseaseName: String = ""

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
                                guard let image = capturedImage else { return }
                                historyStore.add(
                                    image: image,
                                    prediction: prediction,
                                    diseaseName: lastDiseaseName.isEmpty ? nil : lastDiseaseName,
                                    status: lastStatus
                                )
                                showSaveOptions = false
                                showConsulta = true
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            cameraView
        }
        .sheet(isPresented: $showConsulta) {
            if let entry = historyStore.entries.first {
                ConsultaDetailView(entry: entry)
            }
        }
    }

    private var cameraView: some View {
        ZStack {
            CameraPreview(takePhotoTrigger: $takePhotoTrigger) { image in
                capturedImage = image
                classify(image: image)
                showCamera = false
                showSaveOptions = true
            }
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
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
                Button {
                    takePhotoTrigger = true
                } label: {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                }
                .padding(.bottom, 40)
            }
        }
    }

    func classify(image: UIImage) {
        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: KafeCamFinal(configuration: config).model) else {
            prediction = "⚠️ Error al cargar modelo"
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            if let result = request.results?.first as? VNClassificationObservation {
                let label = result.identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let confidence = Double(result.confidence * 100.0)
                let parsed = parseStatus(from: label)
                let status = parsed.status
                let diseaseName = parsed.diseaseName

                DispatchQueue.main.async {
                    lastStatus = status
                    lastConfidencePct = confidence
                    lastDiseaseName = diseaseName

                    switch status {
                    case .sano:
                        prediction = "🌿 Planta sana (\(Int(confidence))%)"
                    case .sospecha:
                        prediction = diseaseName.isEmpty ?
                            "⚠️ Sospecha (\(Int(confidence))%)" :
                            "⚠️ Sospecha de \(diseaseName.capitalized) (\(Int(confidence))%)"
                    case .enfermo:
                        prediction = diseaseName.isEmpty ?
                            "🚨 Enfermo (\(Int(confidence))%)" :
                            "🚨 \(diseaseName.capitalized) (\(Int(confidence))%)"
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
            do { try handler.perform([request]) }
            catch {
                DispatchQueue.main.async {
                    prediction = "⚠️ Error al procesar la imagen"
                }
            }
        }
    }
}

private func parseStatus(from raw: String) -> (status: PlotStatus, diseaseName: String) {
    let parts = raw.split(separator: " ").map { String($0) }

    if parts.count == 1 {
        let word = parts[0]
        if ["sana","sano","saludable","healthy"].contains(word) {
            return (.sano, "")
        }
        return (.sospecha, word)
    } else {
        let disease = parts.dropLast().joined(separator: " ")
        let state = parts.last ?? ""
        switch state {
        case "sospecha","sospechoso","suspected": return (.sospecha, disease)
        case "enfermo","enfermedad","diseased","sick": return (.enfermo, disease)
        case "sano","sana","healthy": return (.sano, disease)
        default: return (.sospecha, disease)
        }
    }
}
