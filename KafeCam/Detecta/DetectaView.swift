//
//  DetectaView.swift
//  KafeCam
//

import SwiftUI
import CoreML
import Vision
import CoreLocation

struct DetectaView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: HistoryStore
    @StateObject private var locationManager = SimpleLocationManager()
    
    @State private var prediction: String = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = true
    @State private var takePhotoTrigger = false
    @State private var showSaveOptions = false

    // Guardamos datos "reales" para la notificación al mapa
    @State private var lastStatus: PlotStatus = .sano
    @State private var lastConfidencePct: Double = 0.0  // 0–100
    @State private var lastDiseaseName: String = ""     // p.ej. "roya", "manganeso"

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
                                
                                // Save locally first for immediate feedback
                                historyStore.add(image: image, prediction: prediction)
                                
                                showSaveOptions = false

                                // Upload to Supabase with proper folder structure
                                Task {
                                    #if canImport(Supabase)
                                    do {
                                        // Save local copy
                                        if let uid = try? await SupaAuthService.currentUserId() {
                                            _ = LocalCapturesStore.shared.save(image: image, for: uid.uuidString)
                                        }
                                        
                                        // Upload to Supabase with location if available
                                        if let jpeg = image.jpegData(compressionQuality: 0.85) {
                                            let svc = CapturesService()
                                            
                                            // Get current location if available
                                            let lat = locationManager.lastLocation?.coordinate.latitude
                                            let lon = locationManager.lastLocation?.coordinate.longitude
                                            
                                            let capture = try await svc.saveCaptureToDefaultPlot(
                                                imageData: jpeg, 
                                                takenAt: Date(), 
                                                deviceModel: prediction.isEmpty ? "Foto" : prediction,  // Use full prediction string with emoji and percentage
                                                lat: lat,
                                                lon: lon
                                            )
                                            print("[Detecta] Capture saved successfully to Supabase: \(capture.photoKey)")
                                            if let lat = lat, let lon = lon {
                                                print("[Detecta] Location saved: \(lat), \(lon)")
                                            }
                                            
                                            // Refresh history to show the new capture
                                            await historyStore.syncFromSupabase()
                                        }
                                    } catch {
                                        print("[Detecta] Error saving capture: \(error)")
                                        // Local copy is still saved, so user doesn't lose the photo
                                    }
                                    #endif
                                }

                                // 3) Notificar al mapa para crear pin automático
                                NotificationCenter.default.post(
                                    name: .kafeCreatePin,
                                    object: nil,
                                    userInfo: [
                                        "estado": lastStatus.rawValue.lowercased(),
                                        "probabilidad": lastConfidencePct,
                                        "label": lastDiseaseName,
                                        "fecha": Date()
                                    ]
                                )

                                // 4) Volver al Home
                                dismiss()
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
                        Button(action: { dismiss() }) {
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

    // MARK: - Clasificación con CoreML (modelo devuelve e.g. "roya enfermo" | "manganeso sospecha" | "sana")
    func classify(image: UIImage) {
        let config = MLModelConfiguration()
        // Try to load the model using the generated class first, then fallback to bundle
        let vnModel: VNCoreMLModel
        do {
            // First try: Load compiled model directly from bundle
            if let url = Bundle.main.url(forResource: "KafeCamCM", withExtension: "mlmodelc") {
                let coreMLModel = try MLModel(contentsOf: url, configuration: config)
                vnModel = try VNCoreMLModel(for: coreMLModel)
            } else {
                // Fallback: Try to find any .mlmodelc in bundle
                let bundle = Bundle.main
                if let modelURL = bundle.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil)?.first {
                    let coreMLModel = try MLModel(contentsOf: modelURL, configuration: config)
                    vnModel = try VNCoreMLModel(for: coreMLModel)
                } else {
                    prediction = "⚠️ Error al cargar modelo"
                    return
                }
            }
        } catch {
            prediction = "⚠️ Error al cargar modelo: \(error.localizedDescription)"
            return
        }

        let request = VNCoreMLRequest(model: vnModel) { request, _ in
            if let result = request.results?.first as? VNClassificationObservation {
                let label = result.identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let confidence = Double(result.confidence * 100.0)

                // Parse robusto del label
                let parsed = parseStatus(from: label)
                let status = parsed.status              // .sano | .sospecha | .enfermo
                let diseaseName = parsed.diseaseName    // "" si no aplica

                DispatchQueue.main.async {
                    // Guardar para la notificación
                    self.lastStatus = status
                    self.lastConfidencePct = confidence
                    self.lastDiseaseName = diseaseName

                    // Texto de UI
                    switch status {
                    case .sano:
                        self.prediction = "🌿 Planta sana (\(Int(confidence))%)"
                    case .sospecha:
                        if diseaseName.isEmpty {
                            self.prediction = "⚠️ Sospecha (\(Int(confidence))%)"
                        } else {
                            self.prediction = "⚠️ Sospecha de \(diseaseName.capitalized) (\(Int(confidence))%)"
                        }
                    case .enfermo:
                        if diseaseName.isEmpty {
                            self.prediction = "🚨 Enfermo (\(Int(confidence))%)"
                        } else {
                            self.prediction = "🚨 \(diseaseName.capitalized) (\(Int(confidence))%)"
                        }
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

// MARK: - Parser de label → (status, diseaseName)
private func parseStatus(from raw: String) -> (status: PlotStatus, diseaseName: String) {
    // Casos esperados:
    // "sana" | "sano"
    // "<enfermedad> sospecha"
    // "<enfermedad> enfermo"
    // También toleramos mayúsculas/espacios extras (ya bajamos a lowercased + trim arriba)
    let parts = raw.split(separator: " ").map { String($0) } // ["roya", "enfermo"] o ["sana"]

    if parts.count == 1 {
        let word = parts[0]
        if word == "sana" || word == "sano" || word == "saludable" || word == "healthy" {
            return (.sano, "")
        }
        // Si el modelo manda solo el nombre de enfermedad sin estado → tratamos por probabilidad (pero aquí no la tenemos).
        // Devolvemos sospecha por default en ese caso aislado.
        return (.sospecha, word)
    } else {
        let disease = parts.dropLast().joined(separator: " ")
        let state = parts.last ?? ""
        switch state {
        case "sospecha", "sospechoso", "suspected":
            return (.sospecha, disease)
        case "enfermo", "enfermedad", "diseased", "sick":
            return (.enfermo, disease)
        case "sano", "sana", "healthy":
            return (.sano, disease)
        default:
            // Estado no reconocido → sospecha
            return (.sospecha, disease)
        }
    }
}

#Preview {
    DetectaView()
        .environmentObject(HistoryStore())
}

// MARK: - Simple Location Manager for capturing current location
class SimpleLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func requestFreshLocation() {
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        print("[LocationManager] Location updated: \(lastLocation?.coordinate.latitude ?? 0), \(lastLocation?.coordinate.longitude ?? 0)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
    }
}
