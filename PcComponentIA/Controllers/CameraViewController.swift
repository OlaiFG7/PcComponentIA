//
//  CameraViewController.swift
//  PcComponentIA
//

import UIKit
import AVFoundation
import Vision
import CoreML
import SwiftUI

struct DeteccionEstable {
    let label: String
    let confidence: Float
    let boundingBox: CGRect
    /// Tamaño real del fotograma analizado (cambia con la orientación y la resolución).
    /// Sin valor por defecto a propósito: un tamaño supuesto descuadra las cajas en vertical.
    let tamanoFotograma: CGSize
}

// MARK: - Vista de cámara

final class CameraPreviewView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

// MARK: - Controlador

final class CameraViewController:
    NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate {

    // MARK: Cámara

    private let captureSession = AVCaptureSession()

    private let sessionQueue = DispatchQueue(
        label: "pccomponent.camera.session",
        qos: .userInitiated
    )

    private let visionQueue = DispatchQueue(
        label: "pccomponent.camera.vision",
        qos: .userInitiated
    )

    private let imageQueue = DispatchQueue(
        label: "pccomponent.camera.image",
        qos: .userInitiated
    )

    private let videoDataOutput = AVCaptureVideoDataOutput()

    private var backCamera: AVCaptureDevice?
    private weak var previewView: CameraPreviewView?
    private var ultimoPixelBuffer: CVPixelBuffer?
    private let ciContext = CIContext(
        options: [
            .cacheIntermediates: false
        ]
    )

    private var cameraConfigured = false
    private var shouldRunCamera = false
    private var isConfiguringCamera = false

    // MARK: Inferencia y Estabilización

    private let stabilizer = DetectionStabilizer()
    private var isProcessingFrame = false
    private var lastInferenceDate = Date.distantPast
    private var inferenceInterval: TimeInterval = 0.20

    // MARK: Callback

    var onObjectsDetected: (([DeteccionEstable]) -> Void)?

    // MARK: Inicialización

    override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(estadoTermicoCambio),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientacionCambio),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Conexión

    func conectar(a vista: CameraPreviewView) {
        previewView = vista
        vista.previewLayer?.session = captureSession
        vista.previewLayer?.videoGravity = .resizeAspectFill

        actualizarOrientacionCamara()
        solicitarPermisoYPrepararCamara()
    }

    func desconectar() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.shouldRunCamera = false

            // El estabilizador y isProcessingFrame solo se tocan desde la cola de Vision
            self.visionQueue.async {
                self.stabilizer.reset()
                self.isProcessingFrame = false
            }

            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            DispatchQueue.main.async {
                self.previewView = nil
            }
        }
    }

    // MARK: Permisos

    private func solicitarPermisoYPrepararCamara() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            prepararCamara()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] concedido in
                guard concedido else { return }
                self?.prepararCamara()
            }
        case .denied, .restricted:
            print("Permiso de cámara denegado. Actívalo en Ajustes > Privacidad > Cámara.")
        @unknown default:
            break
        }
    }

    // MARK: Configuración

    private func prepararCamara() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.shouldRunCamera = true

            if self.cameraConfigured {
                self.iniciarCamaraEnCola()
                return
            }

            guard !self.isConfiguringCamera else { return }
            self.isConfiguringCamera = true
            self.configurarCamaraEnCola()
            self.isConfiguringCamera = false

            self.iniciarCamaraEnCola()
        }
    }

    private func configurarCamaraEnCola() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Establecer el preset inicial según el estado térmico actual.
        // El modelo reduce cada fotograma a ~416 px, así que 720p basta y ahorra batería y calor.
        captureSession.sessionPreset = Self.preset(para: ProcessInfo.processInfo.thermalState)
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        backCamera = camera

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            guard captureSession.canAddInput(input) else { return }
            captureSession.addInput(input)
            configurarDispositivo(camera)
        } catch {
            return
        }

        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: visionQueue)

        guard captureSession.canAddOutput(videoDataOutput) else { return }
        captureSession.addOutput(videoDataOutput)
        cameraConfigured = true

        DispatchQueue.main.async { [weak self] in
            self?.actualizarOrientacionCamara()
        }
    }

    private func configurarDispositivo(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        } catch {
            print("No se pudo configurar la cámara: \(error.localizedDescription)")
        }
    }

    private func iniciarCamaraEnCola() {
        guard cameraConfigured, shouldRunCamera, !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    // MARK: Rotación universal (Solución iPad/iPhone nativa)

    @objc private func orientacionCambio() {
        actualizarOrientacionCamara()
    }

    private func actualizarOrientacionCamara() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

            let interfaceOrientation = scene.effectiveGeometry.interfaceOrientation
            let angulo: CGFloat

            switch interfaceOrientation {
            case .portrait: angulo = 90
            case .portraitUpsideDown: angulo = 270
            case .landscapeLeft: angulo = 180
            case .landscapeRight: angulo = 0
            default: angulo = 90
            }

            if let previewConnection = self.previewView?.previewLayer?.connection,
               previewConnection.isVideoRotationAngleSupported(angulo) {
                previewConnection.videoRotationAngle = angulo
            }

            self.sessionQueue.async {
                if let outputConnection = self.videoDataOutput.connection(with: .video),
                   outputConnection.isVideoRotationAngleSupported(angulo) {
                    outputConnection.videoRotationAngle = angulo
                }
            }
        }
    }

    // MARK: Vídeo

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        imageQueue.sync { ultimoPixelBuffer = pixelBuffer }

        guard !isProcessingFrame else { return }
        let now = Date()
        guard now.timeIntervalSince(lastInferenceDate) >= inferenceInterval else { return }

        lastInferenceDate = now
        isProcessingFrame = true

        stabilizer.procesar(pixelBuffer: pixelBuffer) { [weak self] resultados in
            guard let self = self else { return }
            self.isProcessingFrame = false

            // SwiftUI solo admite cambios de estado en el hilo principal
            DispatchQueue.main.async {
                self.onObjectsDetected?(resultados)
            }
        }
    }

    // MARK: Linterna

    func toggleLinterna(activar: Bool) {
        sessionQueue.async { [weak self] in
            guard let device = self?.backCamera, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.torchMode = activar ? .on : .off
            } catch {}
        }
    }

    // MARK: Captura

    func capturarFotoActual() -> UIImage {
        let pixelBuffer: CVPixelBuffer? = imageQueue.sync { ultimoPixelBuffer }
        guard let pixelBuffer else { return UIImage() }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = ciContext.createCGImage(
            ciImage,
            from: ciImage.extent
        ) else {
            return UIImage()
        }
        let scale: CGFloat = previewView?.traitCollection.displayScale ?? 1.0

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    // MARK: Temperatura e Intervalos / Resolución Dinámica

    private func configurarPresetDeSesion(para estadoTermico: ProcessInfo.ThermalState) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let targetPreset = Self.preset(para: estadoTermico)

            guard self.captureSession.sessionPreset != targetPreset else { return }

            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(targetPreset) {
                self.captureSession.sessionPreset = targetPreset
                print("Cámara: Reconfigurado sessionPreset a \(targetPreset == .vga640x480 ? "480p" : "720p") debido a estado térmico \(estadoTermico)")
            }
            self.captureSession.commitConfiguration()
        }
    }

    private static func preset(para estadoTermico: ProcessInfo.ThermalState) -> AVCaptureSession.Preset {
        switch estadoTermico {
        case .serious, .critical:
            return .vga640x480
        default:
            return .hd1280x720
        }
    }

    @objc private func estadoTermicoCambio() {
        let estado = ProcessInfo.processInfo.thermalState
        let nuevoIntervalo: TimeInterval

        switch estado {
        case .nominal:
            nuevoIntervalo = 0.20
        case .fair:
            nuevoIntervalo = 0.25
        case .serious:
            nuevoIntervalo = 0.40
        case .critical:
            nuevoIntervalo = 0.75
        @unknown default:
            nuevoIntervalo = 0.25
        }

        visionQueue.async { [weak self] in
            self?.inferenceInterval = nuevoIntervalo
        }
        
        configurarPresetDeSesion(para: estado)
    }
}

// MARK: - Puente SwiftUI

struct CameraView: UIViewRepresentable {
    var onDetection: ([DeteccionEstable]) -> Void
    @Binding var controladorRef: CameraViewController?

    func makeCoordinator() -> CameraViewController {
        let controller = CameraViewController()
        controller.onObjectsDetected = onDetection
        return controller
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        context.coordinator.conectar(a: view)
        DispatchQueue.main.async { controladorRef = context.coordinator }
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        context.coordinator.onObjectsDetected = onDetection
    }

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: CameraViewController) {
        coordinator.desconectar()
    }
}
