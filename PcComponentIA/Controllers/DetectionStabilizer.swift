//
//  DetectionStabilizer.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 19/07/2026.
//

import Foundation
import Vision
import CoreML

final class DetectionStabilizer {
    
    // Stable detections structure for smoothing state
    private struct StableDetection {
        var label: String
        var confidence: Float
        var boundingBox: CGRect
        var stableFrames: Int
        var missedFrames: Int
        var lastSeen: Date
    }
    
    /// Modelo compartido: se carga una sola vez, la primera vez que se procesa un
    /// fotograma (en la cola de Vision, no en el hilo principal), y se reutiliza
    /// cada vez que se vuelve a abrir el escáner.
    private static let modeloCompartido: VNCoreMLModel? = {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine

        do {
            let modelContainer = try PcComponentDetector3(configuration: configuration)
            return try VNCoreMLModel(for: modelContainer.model)
        } catch {
            print("Error cargando el modelo Core ML en DetectionStabilizer: " + error.localizedDescription)
            return nil
        }
    }()

    private var visionModel: VNCoreMLModel? { Self.modeloCompartido }
    private var stableDetections: [StableDetection] = []
    
    // Configurable thresholds for testing
    let minimumConfidence: Float = 0.55
    let displayConfidence: Float = 0.60
    let iouMatchThreshold: CGFloat = 0.25
    let smoothingFactor: CGFloat = 0.28
    let maximumMissedFrames = 8
    let maximumDetections = 5
    
    /// Executes the Vision model inference and runs the stabilization algorithm on the resulting observations.
    /// This method is independent of camera hardware and can be easily unit tested.
    func procesar(pixelBuffer: CVPixelBuffer, completion: @escaping ([DeteccionEstable]) -> Void) {
        guard let visionModel = visionModel else {
            completion([])
            return
        }

        let tamanoFotograma = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )

        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else {
                completion([])
                return
            }
            
            guard error == nil, let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            let validResults = results
                .filter { ($0.labels.first?.confidence ?? 0) >= self.minimumConfidence }
                .sorted { ($0.labels.first?.confidence ?? 0) > ($1.labels.first?.confidence ?? 0) }
            
            self.fusionarDetecciones(Array(validResults.prefix(self.maximumDetections)))
            let resultados = self.obtenerDeteccionesEstables(tamanoFotograma: tamanoFotograma)
            completion(resultados)
        }
        
        request.imageCropAndScaleOption = .scaleFill
        
        do {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )
            try handler.perform([request])
        } catch {
            completion([])
        }
    }
    
    private func fusionarDetecciones(_ detections: [VNRecognizedObjectObservation]) {
        let now = Date()
        var usedStableIndexes = Set<Int>()
        var updated: [StableDetection] = []

        for detection in detections {
            guard let label = detection.labels.first else { continue }

            let matchIndex = stableDetections.indices.first { index in
                guard !usedStableIndexes.contains(index) else { return false }
                let stable = stableDetections[index]
                let iouVal = iou(stable.boundingBox, detection.boundingBox)
                let distCentro = distanciaEntreCentros(stable.boundingBox, detection.boundingBox)
                return stable.label == label.identifier && (iouVal >= iouMatchThreshold || distCentro < 0.15)
            }

            if let index = matchIndex {
                usedStableIndexes.insert(index)
                var stable = stableDetections[index]
                stable.boundingBox = interpolarAdaptativo(desde: stable.boundingBox, hasta: detection.boundingBox)
                stable.confidence = stable.confidence * 0.72 + label.confidence * 0.28
                stable.stableFrames += 1
                stable.missedFrames = 0
                stable.lastSeen = now
                updated.append(stable)
            } else {
                updated.append(StableDetection(
                    label: label.identifier,
                    confidence: label.confidence,
                    boundingBox: detection.boundingBox,
                    stableFrames: 1,
                    missedFrames: 0,
                    lastSeen: now
                ))
            }
        }

        for (index, stable) in stableDetections.enumerated() where !usedStableIndexes.contains(index) {
            var old = stable
            old.missedFrames += 1
            if old.missedFrames <= maximumMissedFrames {
                updated.append(old)
            }
        }

        stableDetections = Array(updated.sorted { left, right in
            let scoreLeft = left.confidence + Float(left.stableFrames) * 0.02
            let scoreRight = right.confidence + Float(right.stableFrames) * 0.02
            return scoreLeft > scoreRight
        }.prefix(maximumDetections))
    }

    private func obtenerDeteccionesEstables(tamanoFotograma: CGSize) -> [DeteccionEstable] {
        let visibles = stableDetections.filter {
            $0.confidence >= displayConfidence && $0.stableFrames >= 2 && $0.missedFrames <= 2
        }.sorted { left, right in
            (left.confidence + Float(left.stableFrames) * 0.02) > (right.confidence + Float(right.stableFrames) * 0.02)
        }

        return visibles.map {
            DeteccionEstable(label: $0.label, confidence: $0.confidence, boundingBox: $0.boundingBox,
                             tamanoFotograma: tamanoFotograma)
        }
    }

    // MARK: - Geometría y Suavizado Adaptativo

    private func interpolarAdaptativo(desde old: CGRect, hasta new: CGRect) -> CGRect {
        let centerOld = CGPoint(x: old.midX, y: old.midY)
        let centerNew = CGPoint(x: new.midX, y: new.midY)

        let dx = centerNew.x - centerOld.x
        let dy = centerNew.y - centerOld.y
        let distancia = sqrt(dx * dx + dy * dy)

        // Zona muerta: Ignorar micro-vibraciones del sensor/mano inferior al 0.3%
        let deadzone: CGFloat = 0.003
        if distancia < deadzone && abs(old.width - new.width) < deadzone && abs(old.height - new.height) < deadzone {
            return old
        }

        // Adaptar el factor de suavizado según la velocidad del movimiento
        // Movimiento lento -> alpha bajo (0.18) para máxima estabilidad y cero temblor
        // Movimiento rápido -> alpha alto (0.70) para evitar retraso visual al mover la cámara
        let minAlpha: CGFloat = 0.18
        let maxAlpha: CGFloat = 0.70
        let factorVelocidad = min(max((distancia - deadzone) / 0.10, 0.0), 1.0)
        let alphaAdaptativo = minAlpha + (maxAlpha - minAlpha) * factorVelocidad

        return CGRect(
            x: old.origin.x + (new.origin.x - old.origin.x) * alphaAdaptativo,
            y: old.origin.y + (new.origin.y - old.origin.y) * alphaAdaptativo,
            width: old.size.width + (new.size.width - old.size.width) * alphaAdaptativo,
            height: old.size.height + (new.size.height - old.size.height) * alphaAdaptativo
        )
    }

    private func distanciaEntreCentros(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let dx = a.midX - b.midX
        let dy = a.midY - b.midY
        return sqrt(dx * dx + dy * dy)
    }

    private func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    /// Clear stabilization history (e.g. when session restarts)
    func reset() {
        stableDetections = []
    }
}
