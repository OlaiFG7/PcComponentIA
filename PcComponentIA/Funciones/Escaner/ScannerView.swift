//
//  ScannerView.swift
//  PcComponentIA
//

import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct ScannerView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var checklist: GestorChecklist

    // MARK: - Cámara

    @State private var detecciones: [DeteccionEstable] = []
    @State private var controladorCamara: CameraViewController?
    @State private var imagenCongelada: UIImage?
    @State private var deteccionesCongeladas: [DeteccionEstable] = []

    // MARK: - Componente

    @State private var componenteSeleccionado: String?
    @State private var informacionSeleccionada: InfoComponente?
    @State private var mostrarDetalleCompleto = false
    @State private var mostrarGuiaAR = false
    @State private var mensajeGuiaNoDisponible = false

    // MARK: - Interfaz

    @State private var mostrarGrid = false
    @State private var linternaActiva = false
    @State private var camaraDenegada = false
    /// Se incrementa para recrear la cámara cuando el permiso se concede desde Ajustes
    @State private var intentoCamara = 0
    @State private var capturandoFoto = false
    /// Última pieza reconocida con seguridad; al cambiar, el móvil vibra suavemente
    @State private var piezaFijada = ""

    // MARK: - Foto de la galería
    @State private var fotoElegida: PhotosPickerItem?
    /// La imagen congelada viene de la galería: se muestra entera en vez de recortada
    @State private var imagenDeGaleria = false
    @State private var analizandoFoto = false
    @State private var fotoSinPiezas = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.esRaizDeSeccion) private var esRaizDeSeccion
    @State private var mostrarHistorial = false
    @State private var mostrarSelectorDetectados = false
    @State private var deteccionesSeleccionables: [DeteccionEstable] = []

    // MARK: - Estado

    @State private var estado: EstadoScanner = .analizando
    @State private var mejorEtiqueta = ""
    @State private var confianza: Float = 0
    @State private var pasoMarcadoResumen = false

    // MARK: - Servicios

    @StateObject private var lector = LectorAudio()

    private let informacion = DatosHardware.obtenerDiccionario()

    private static let dispositivoTieneLinterna =
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasTorch ?? false
    private let confianzaMinima: Float = 0.60
    private let maximoCajas = 5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                cameraLayer(size: geo.size)
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height
                    )

                gradientOverlay
                    .allowsHitTesting(false)

                if mostrarGrid && imagenCongelada == nil {
                    scannerGrid
                        .allowsHitTesting(false)
                }

                detectionOverlay(size: geo.size)

                if mostrarGuiaAR,
                   let rectPlaca = rectanguloPlacaBase(
                    en: geo.size
                   ),
                   let componente = componenteSeleccionado {
                    VisualizadorARView(
                        rectPlaca: rectPlaca,
                        componente: componente,
                        tamanoContenedor: geo.size,
                        onCerrar: {
                            withAnimation(
                                .spring(
                                    response: 0.28,
                                    dampingFraction: 0.85
                                )
                            ) {
                                mostrarGuiaAR = false
                            }
                        }
                    )
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.96)
                        )
                    )
                    .zIndex(200)
                }

                ChecklistLateral(gestor: checklist)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )
                    .padding(.bottom, 280)
                    .padding(.top, 120)
                    .padding(.trailing, 4)
            }
            .frame(
                width: geo.size.width,
                height: geo.size.height
            )
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .top) {
            estadoScannerChip
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let nombre = componenteSeleccionado,
                   let info = informacionSeleccionada,
                   !mostrarDetalleCompleto {
                    componentCard(
                        nombre: nombre,
                        info: info
                    )
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
                }

                // Sin permiso de cámara, disparar o encender la linterna no tiene sentido,
                // pero sí se puede analizar una foto de la galería
                if !camaraDenegada || imagenCongelada != nil {
                    bottomControls
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: piezaFijada) { _, nueva in
            !nueva.isEmpty
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !esRaizDeSeccion {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .frame(width: 38, height: 38)
                    }
                    .accessibilityLabel("Cerrar escáner")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    mostrarHistorial = true
                } label: {
                    Image(
                        systemName: "clock.arrow.circlepath"
                    )
                    .font(.body.weight(.bold))
                    .frame(width: 38, height: 38)
                }
                .accessibilityLabel("Ver historial")
            }
        }
        .onDisappear {
            if linternaActiva {
                controladorCamara?.toggleLinterna(
                    activar: false
                )
            }
        }
        // La foto puede elegirse desde los controles o desde el aviso de cámara denegada
        .onChange(of: fotoElegida) { _, item in
            guard let item else { return }
            Task { await analizarFotoDeGaleria(item) }
        }
        .alert("No se ha encontrado ninguna pieza", isPresented: $fotoSinPiezas) {
            // Sin piezas no hay nada que hacer con la foto: se vuelve a la cámara
            Button("Vale", role: .cancel) {
                if imagenDeGaleria {
                    toggleCapture()
                }
            }
        } message: {
            Text("Prueba con una foto más cercana y bien iluminada, donde la pieza se vea entera.")
        }
        .sheet(isPresented: $mostrarHistorial) {
            HistorialView()
        }
        .sheet(isPresented: $mostrarSelectorDetectados) {
            selectorDetectadosSheet
        }
        .sheet(isPresented: $mostrarDetalleCompleto) {
            if let nombre = componenteSeleccionado,
               let info = informacionSeleccionada {
                DetalleComponenteView(
                    nombre: nombre,
                    info: info,
                    lector: lector,
                    onCerrar: {
                        mostrarDetalleCompleto = false
                    }
                )
                .presentationBackground(.clear)
                // Tirador del sistema: indica que la hoja se puede ampliar y VoiceOver lo anuncia
                .presentationDragIndicator(.visible)
                // Media pantalla o completa: con letra grande o en iPad el texto no se corta
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(32)
            }
        }
        .alert(
            "No veo una placa base",
            isPresented: $mensajeGuiaNoDisponible
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(
                "Enfoca a la vez la placa base y el componente para activar la guía visual."
            )
        }
    }

    // MARK: - Cámara

    @ViewBuilder
    private func cameraLayer(
        size: CGSize
    ) -> some View {
        if let foto = imagenCongelada {
            Image(uiImage: foto)
                .resizable()
                .aspectRatio(contentMode: imagenDeGaleria ? .fit : .fill)
                .frame(
                    width: size.width,
                    height: size.height
                )
                .clipped()
        } else {
            CameraView(
                onDetection: procesarDetecciones,
                controladorRef: $controladorCamara,
                onPermisoDenegado: { camaraDenegada = true }
            )
            .id(intentoCamara)
            .frame(
                width: size.width,
                height: size.height
            )
            .clipped()
            .overlay {
                if camaraDenegada {
                    avisoCamaraDenegada
                }
            }
            .onChange(of: scenePhase) { _, fase in
                // Si el usuario vuelve de Ajustes con el permiso ya concedido, se reintenta
                guard fase == .active, camaraDenegada,
                      AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                else { return }
                camaraDenegada = false
                intentoCamara += 1
            }
        }
    }

    /// Sin permiso de cámara el escáner se vería negro: se explica qué pasa y cómo arreglarlo.
    private var avisoCamaraDenegada: some View {
        ContentUnavailableView {
            Label("Sin acceso a la cámara", systemImage: "camera.badge.ellipsis")
        } description: {
            Text("Para reconocer componentes, PcComponentIA necesita la cámara. Actívala en Ajustes > PcComponentIA > Cámara.")
        } actions: {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            // Sin cámara, todavía se puede analizar una foto ya hecha
            PhotosPicker(selection: $fotoElegida, matching: .images) {
                Label("Analizar una foto de la galería", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(.bordered)
        }
        .background(.black)
    }

    // MARK: - Capas visuales

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [
                .black.opacity(0.5),
                .clear,
                .clear,
                .black.opacity(0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var scannerGrid: some View {
        GeometryReader { geometry in
            Path { path in
                let columnas = 3
                let filas = 5
                let ancho = geometry.size.width
                    / CGFloat(columnas)
                let alto = geometry.size.height
                    / CGFloat(filas)

                for columna in 1...columnas {
                    let x = CGFloat(columna) * ancho

                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(
                        to: CGPoint(
                            x: x,
                            y: geometry.size.height
                        )
                    )
                }

                for fila in 1..<filas {
                    let y = CGFloat(fila) * alto

                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(
                        to: CGPoint(
                            x: geometry.size.width,
                            y: y
                        )
                    )
                }
            }
            .stroke(
                .white.opacity(0.3),
                style: StrokeStyle(
                    lineWidth: 0.5,
                    dash: [4, 4]
                )
            )
        }
    }

    // MARK: - Detecciones

    @ViewBuilder
    private func detectionOverlay(
        size: CGSize
    ) -> some View {
        let fuente = imagenCongelada == nil
            ? detecciones
            : deteccionesCongeladas

        let visibles = Array(
            fuente.prefix(maximoCajas)
        )

        ZStack {
            ForEach(visibles.indices, id: \.self) { indice in
                let deteccion = visibles[indice]

                DetectionBox(
                    titulo: nombreLegible(deteccion.label),
                    confianza: deteccion.confidence,
                    rect: transformarRectangulo(
                        deteccion.boundingBox,
                        video: deteccion.tamanoFotograma,
                        en: size
                    ),
                    principal: indice == 0,
                    action: {
                        seleccionarComponente(
                            etiqueta: deteccion.label,
                            confianza: deteccion.confidence
                        )
                    }
                )
                .zIndex(
                    indice == 0
                        ? 100.0
                        : Double(maximoCajas - indice)
                )
                // También se pueden tocar con la imagen congelada o con una foto de la galería:
                // es justo cuando resulta más cómodo abrir la ficha de cada pieza
            }
        }
    }

    // MARK: - Controles inferiores

    private var bottomControls: some View {
        VStack(spacing: 16) {
            if imagenCongelada != nil {
                frozenCaptureActions
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            }

            if detecciones.count > 1 &&
                imagenCongelada == nil {
                Button {
                    deteccionesSeleccionables = detecciones
                    mostrarSelectorDetectados = true
                } label: {
                    Label(
                        "\(detecciones.count) detectados",
                        systemImage: "viewfinder"
                    )
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
            }

            GlassEffectContainer(spacing: 24) {
                HStack(spacing: 24) {
                    // La mayoría de iPads no tienen flash: el botón no haría nada
                    if Self.dispositivoTieneLinterna && !imagenDeGaleria {
                    Button {
                        linternaActiva.toggle()

                        controladorCamara?.toggleLinterna(
                            activar: linternaActiva
                        )
                    } label: {
                        Image(
                            systemName: linternaActiva
                                ? "flashlight.on.fill"
                                : "flashlight.off.fill"
                        )
                        .font(.title3)
                        .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                    .tint(
                        linternaActiva
                            ? .yellow
                            : .primary
                    )
                    .accessibilityLabel("Linterna")
                    .accessibilityValue(linternaActiva ? "Encendida" : "Apagada")
                    .accessibilityAddTraits(.isToggle)
                    }

                    Button {
                        toggleCapture()
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    .white,
                                    lineWidth: 4
                                )
                                .frame(
                                    width: 72,
                                    height: 72
                                )

                            Circle()
                                .fill(
                                    imagenCongelada == nil
                                        ? .white
                                        : .accentColor
                                )
                                .frame(
                                    width: 60,
                                    height: 60
                                )

                            if imagenCongelada != nil {
                                Image(
                                    systemName: "play.fill"
                                )
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        .regular.interactive(),
                        in: .circle
                    )
                    .accessibilityLabel(
                        imagenCongelada == nil
                            ? L("Capturar foto")
                            : L("Reanudar cámara")
                    )

                    if !imagenDeGaleria {
                    Button {
                        withAnimation(
                            .easeInOut(duration: 0.2)
                        ) {
                            mostrarGrid.toggle()
                        }
                    } label: {
                        Image(
                            systemName: mostrarGrid
                                ? "grid.circle.fill"
                                : "grid.circle"
                        )
                        .font(.title3)
                        .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.glass)
                    .clipShape(Circle())
                    .tint(
                        mostrarGrid
                            ? .white
                            : .primary
                    )
                    .accessibilityLabel("Cuadrícula")
                    .accessibilityValue(mostrarGrid ? "Visible" : "Oculta")
                    .accessibilityAddTraits(.isToggle)
                    }

                    botonGaleria
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Analizar una foto ya hecha (galería, captura de un anuncio...) en vez de la cámara.
    private var botonGaleria: some View {
        PhotosPicker(selection: $fotoElegida, matching: .images) {
            Group {
                if analizandoFoto {
                    ProgressView()
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                }
            }
            .font(.title3)
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.glass)
        .clipShape(Circle())
        .disabled(analizandoFoto)
        .accessibilityLabel("Analizar una foto de la galería")
    }

    private func analizarFotoDeGaleria(_ item: PhotosPickerItem) async {
        analizandoFoto = true
        defer {
            analizandoFoto = false
            fotoElegida = nil
        }

        guard let datos = try? await item.loadTransferable(type: Data.self),
              let foto = await Task.detached(priority: .userInitiated, operation: {
                  UIImage(data: datos).flatMap(Self.prepararFoto)
              }).value,
              let cgImage = foto.cgImage
        else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        let encontradas = await DetectionStabilizer.detectar(en: cgImage)

        if linternaActiva {
            linternaActiva = false
            controladorCamara?.toggleLinterna(activar: false)
        }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            imagenDeGaleria = true
            imagenCongelada = foto
            deteccionesCongeladas = Array(encontradas.prefix(maximoCajas))
            estado = .congelado
            if let principal = encontradas.first {
                mejorEtiqueta = nombreLegible(principal.label)
                confianza = principal.confidence
            }
        }

        fotoSinPiezas = encontradas.isEmpty
        UINotificationFeedbackGenerator()
            .notificationOccurred(encontradas.isEmpty ? .warning : .success)
    }

    /// Endereza la foto (las del iPhone suelen venir giradas en sus metadatos) y la reduce
    /// a 1600 px de lado como máximo: el modelo trabaja a 416 px y así se ahorra memoria.
    private nonisolated static func prepararFoto(_ imagen: UIImage) -> UIImage? {
        let ladoMayor = max(imagen.size.width, imagen.size.height)
        guard ladoMayor > 0 else { return nil }
        let escala = min(1, 1600 / ladoMayor)
        let tamano = CGSize(width: imagen.size.width * escala, height: imagen.size.height * escala)

        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            imagen.draw(in: CGRect(origin: .zero, size: tamano))
        }
    }

    private var frozenCaptureActions: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    guardarCapturaEnHistorial()
                } label: {
                    Label(
                        "Guardar",
                        systemImage: "bookmark.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(.accentColor)

                Button(role: .cancel) {
                    toggleCapture()
                } label: {
                    Label(
                        "Descartar",
                        systemImage: "trash"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(.white)
            }
            .controlSize(.large)
        }
    }

    // MARK: - Historial

    private func guardarCapturaEnHistorial() {
        guard let imagen = imagenCongelada else {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.warning)
            return
        }

        let deteccionesAGuardar =
            deteccionesCongeladas.isEmpty
                ? detecciones
                : deteccionesCongeladas

        guard let deteccionPrincipal =
            deteccionesAGuardar.first else {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.warning)
            return
        }

        let imagenConDetecciones = dibujarDetecciones(
            sobre: imagen,
            detecciones: deteccionesAGuardar
        )

        let nombres = deteccionesAGuardar
            .map { nombreLegible($0.label) }
            .joined(separator: " · ")

        let fecha = Date.now
        let confianzaTexto = "\(Int(deteccionPrincipal.confidence * 100))%"

        // Comprimir la foto a JPEG cuesta decenas de milisegundos: se hace fuera del hilo
        // principal y solo la inserción en SwiftData vuelve a él.
        Task {
            let fotoData = await Task.detached(priority: .userInitiated) {
                imagenConDetecciones.jpegData(compressionQuality: 0.94) ?? Data()
            }.value

            AlmacenHistorial.añadir(
                CapturaHistorial(
                    id: UUID(),
                    componente: nombres,
                    fecha: fecha,
                    confianza: confianzaTexto,
                    fotoData: fotoData
                )
            )

            // El historial se abre cuando la captura ya está guardada, para que aparezca en él
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)

            withAnimation(
                .spring(
                    response: 0.3,
                    dampingFraction: 0.82
                )
            ) {
                mostrarHistorial = true
            }
        }
    }

    // MARK: - Selector

    private var selectorDetectadosSheet: some View {
        NavigationStack {
            List(
                deteccionesSeleccionables.indices,
                id: \.self
            ) { indice in
                let deteccion = deteccionesSeleccionables[indice]

                Button {
                    mostrarSelectorDetectados = false

                    seleccionarComponente(
                        etiqueta: deteccion.label,
                        confianza: deteccion.confidence
                    )
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "viewfinder")
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28)

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text(
                                nombreLegible(deteccion.label)
                            )
                            .foregroundStyle(.primary)
                            .font(.body.weight(.medium))

                            Text(
                                L("\(Int(deteccion.confidence * 100))% de confianza")
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(
                            systemName: "chevron.right"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Componentes detectados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        mostrarSelectorDetectados = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Tarjeta de componente

    private func componentCard(
        nombre: String,
        info: InfoComponente
    ) -> some View {
        let tienePaso = checklist.tienePasoAsociado(nombre)

        return VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack(spacing: 12) {
                Image(systemName: info.nombreImagenSF)
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.tint)
                    .frame(width: 48, height: 48)
                    .background(
                        .tint.opacity(0.15),
                        in: RoundedRectangle(
                            cornerRadius: 12
                        )
                    )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(nombre.localizado)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("Componente identificado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if tienePaso {
                    Button {
                        alternarChecklistResumen(
                            nombre: nombre
                        )
                    } label: {
                        Image(
                            systemName: pasoMarcadoResumen
                                ? "checkmark.circle.fill"
                                : "checkmark.circle"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            pasoMarcadoResumen
                                ? Color.white
                                : Color.green
                        )
                        .frame(width: 36, height: 36)
                        .background(
                            pasoMarcadoResumen
                                ? Color.green
                                : Color.green.opacity(0.14),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .stroke(
                                    Color.green.opacity(
                                        pasoMarcadoResumen
                                            ? 0.70
                                            : 0.34
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        pasoMarcadoResumen
                            ? L("Desmarcar del checklist")
                            : L("Marcar como hecho en checklist")
                    )
                } else {
                    HStack(spacing: 4) {
                        Image(
                            systemName: "info.circle.fill"
                        )
                        .font(.caption2)

                        Text("Informativo")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Color.blue.opacity(0.12),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.blue.opacity(0.24),
                                lineWidth: 1
                            )
                    }
                }

                Button {
                    cerrarInformacionComponente()
                } label: {
                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            Text(info.descripcion.localizado)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                if componenteTieneGuiaAR(nombre) {
                    Button {
                        abrirGuiaAR(nombre)
                    } label: {
                        Label(
                            "Ver dónde va",
                            systemImage: "viewfinder.circle.fill"
                        )
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.cyan)
                    .controlSize(.regular)
                }

                Button {
                    mostrarDetalleCompleto = true
                } label: {
                    Label(
                        "Más información",
                        systemImage: "info.circle"
                    )
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .controlSize(.regular)
            }
        }
        .padding(16)
        .glassEffect(
            .regular,
            in: RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
        .onAppear {
            pasoMarcadoResumen = checklist.estaMarcado(
                nombre
            )
        }
    }

    // MARK: - Procesamiento

    private func procesarDetecciones(
        _ nuevasDetecciones: [DeteccionEstable]
    ) {
        guard imagenCongelada == nil else {
            return
        }

        let ordenadas = nuevasDetecciones
            .filter {
                $0.confidence >= confianzaMinima
            }
            .sorted {
                if abs($0.confidence - $1.confidence) < 0.03 {
                    return area(of: $0.boundingBox)
                        > area(of: $1.boundingBox)
                }

                return $0.confidence > $1.confidence
            }

        withAnimation(
            .spring(
                response: 0.18,
                dampingFraction: 0.85
            )
        ) {
            detecciones = Array(
                ordenadas.prefix(maximoCajas)
            )
        }

        guard let principal = ordenadas.first else {
            withAnimation(.easeOut(duration: 0.18)) {
                estado = .analizando
                mejorEtiqueta = ""
                confianza = 0
            }

            return
        }

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.84
            )
        ) {
            estado = .detectado
            mejorEtiqueta = nombreLegible(principal.label)
            confianza = principal.confidence
        }

        // Vibración suave solo cuando se reconoce con seguridad una pieza distinta
        if principal.confidence >= 0.6, principal.label != piezaFijada {
            piezaFijada = principal.label
        }
    }

    // MARK: - Acciones

    private func seleccionarComponente(
        etiqueta: String,
        confianza: Float
    ) {
        let nombre = nombreLegible(etiqueta)

        guard let info = buscarInformacion(
            etiqueta: etiqueta,
            nombreLimpio: nombre
        ) else {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.warning)
            return
        }

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.82
            )
        ) {
            componenteSeleccionado = nombre
            informacionSeleccionada = info
            mejorEtiqueta = nombre
            self.confianza = confianza
            estado = .detectado
            mostrarDetalleCompleto = false
            mostrarGuiaAR = false
        }

        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
    }

    private func cerrarInformacionComponente() {
        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.86
            )
        ) {
            componenteSeleccionado = nil
            informacionSeleccionada = nil
            mostrarDetalleCompleto = false
            mostrarGuiaAR = false
            mensajeGuiaNoDisponible = false
        }
    }

    private func toggleCapture() {
        if imagenCongelada == nil {
            guard !capturandoFoto, let controlador = controladorCamara else { return }
            capturandoFoto = true
            // Las detecciones se fijan al pulsar, para que coincidan con el fotograma
            let deteccionesAlPulsar = detecciones

            Task {
                defer { capturandoFoto = false }
                guard let foto = await controlador.capturarFotoActual(),
                      foto.size.width > 0,
                      foto.size.height > 0 else {
                    return
                }

                withAnimation(
                    .spring(
                        response: 0.34,
                        dampingFraction: 0.86
                    )
                ) {
                    deteccionesCongeladas = deteccionesAlPulsar
                    imagenCongelada = foto
                    estado = .congelado
                }

                UIImpactFeedbackGenerator(style: .medium)
                    .impactOccurred()
            }
        } else {
            withAnimation(
                .spring(
                    response: 0.34,
                    dampingFraction: 0.86
                )
            ) {
                imagenCongelada = nil
                imagenDeGaleria = false
                deteccionesCongeladas = []
                detecciones = []
                deteccionesSeleccionables = []
                componenteSeleccionado = nil
                informacionSeleccionada = nil
                mostrarDetalleCompleto = false
                mostrarGuiaAR = false
                mensajeGuiaNoDisponible = false
                estado = .analizando
                mejorEtiqueta = ""
                confianza = 0
            }
        }
    }

    private func alternarChecklistResumen(
        nombre: String
    ) {
        let marcado = checklist.alternarComponente(nombre)

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.75
            )
        ) {
            pasoMarcadoResumen = marcado
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(
                marcado ? .success : .warning
            )
    }

    // MARK: - Guía AR

    private func abrirGuiaAR(
        _ nombre: String
    ) {
        guard hayPlacaBaseDetectada else {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.warning)

            mensajeGuiaNoDisponible = true
            return
        }

        withAnimation(
            .spring(
                response: 0.34,
                dampingFraction: 0.82
            )
        ) {
            mostrarGuiaAR = true
        }

        UIImpactFeedbackGenerator(style: .medium)
            .impactOccurred()
    }

    private var hayPlacaBaseDetectada: Bool {
        let fuente = imagenCongelada == nil
            ? detecciones
            : deteccionesCongeladas

        return fuente.contains {
            esPlacaBase($0.label)
        }
    }

    private func componenteTieneGuiaAR(
        _ nombre: String
    ) -> Bool {
        let texto = normalizar(nombre)

        return texto.contains("cpu") ||
            texto.contains("procesador") ||
            texto.contains("socket") ||
            texto.contains("ram") ||
            texto.contains("memoria") ||
            texto.contains("modulo") ||
            texto.contains("gpu") ||
            texto.contains("grafica") ||
            texto.contains("pcie") ||
            texto.contains("m2") ||
            texto.contains("nvme") ||
            texto.contains("sata") ||
            texto.contains("hdd") ||
            texto.contains("ssd")
    }

    private func rectanguloPlacaBase(
        en size: CGSize
    ) -> CGRect? {
        let fuente = imagenCongelada == nil
            ? detecciones
            : deteccionesCongeladas

        guard let placa = fuente.first(
            where: { esPlacaBase($0.label) }
        ) else {
            return nil
        }

        return transformarRectangulo(
            placa.boundingBox,
            video: placa.tamanoFotograma,
            en: size
        )
    }

    private func esPlacaBase(
        _ etiqueta: String
    ) -> Bool {
        let texto = normalizar(etiqueta)

        return texto.contains("placabase") ||
            texto.contains("motherboard")
    }

    // MARK: - Estado visual

    private var estadoScannerChip: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForState)
                .foregroundStyle(statusColor)

            Text(statusTitle.localizado)
                .font(.subheadline.weight(.semibold))

            if !statusSubtitle.isEmpty {
                Text("·")
                    .foregroundStyle(.secondary)

                Text(statusSubtitle.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }

    private var iconForState: String {
        switch estado {
        case .analizando:
            return "sparkles"
        case .detectado:
            return "checkmark.circle.fill"
        case .congelado:
            return "pause.circle.fill"
        }
    }

    private var statusColor: Color {
        switch estado {
        case .analizando:
            return .orange
        case .detectado:
            return .green
        case .congelado:
            return .yellow
        }
    }

    private var statusTitle: String {
        switch estado {
        case .analizando:
            return "Analizando"

        case .detectado:
            if componenteSeleccionado != nil ||
                detecciones.count == 1 {
                return L("Componente detectado")
            }

            return L("Componentes detectados")

        case .congelado:
            return L("Imagen congelada")
        }
    }

    private var statusSubtitle: String {
        switch estado {
        case .analizando:
            return L("Buscando componentes")

        case .detectado:
            if componenteSeleccionado != nil {
                return mejorEtiqueta
            }

            if detecciones.count > 1 {
                return L("Toca uno para ver más detalles")
            }

            return mejorEtiqueta

        case .congelado:
            return L("Pulsa guardar o descartar")
        }
    }

    // MARK: - Dibujo de capturas

    private func dibujarDetecciones(
        sobre imagen: UIImage,
        detecciones: [DeteccionEstable]
    ) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = imagen.scale
        rendererFormat.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: imagen.size,
            format: rendererFormat
        )

        return renderer.image { _ in
            imagen.draw(
                in: CGRect(
                    origin: .zero,
                    size: imagen.size
                )
            )

            for (indice, deteccion) in detecciones.enumerated() {
                let rect = rectanguloEnImagen(
                    deteccion.boundingBox,
                    imageSize: imagen.size
                )

                let esPrincipal = indice == 0

                let color = esPrincipal
                    ? UIColor.systemGreen
                    : UIColor.systemBlue

                dibujarCaja(
                    rect,
                    titulo: nombreLegible(deteccion.label),
                    confianza: deteccion.confidence,
                    color: color,
                    esPrincipal: esPrincipal,
                    imageSize: imagen.size
                )
            }
        }
    }

    private func rectanguloEnImagen(
        _ boundingBox: CGRect,
        imageSize: CGSize
    ) -> CGRect {
        CGRect(
            x: boundingBox.minX * imageSize.width,
            y: (1 - boundingBox.maxY) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }

    private func dibujarCaja(
        _ rectOriginal: CGRect,
        titulo: String,
        confianza: Float,
        color: UIColor,
        esPrincipal: Bool,
        imageSize: CGSize
    ) {
        let anchoImagen = imageSize.width
        let altoImagen = imageSize.height
        let grosor: CGFloat = esPrincipal ? 2.0 : 1.5
        let radioCaja: CGFloat = 9
        let tamañoFuente: CGFloat = 9
        let paddingHorizontal: CGFloat = 7
        let paddingVertical: CGFloat = 4
        let separacionEtiqueta: CGFloat = 5
        let tamañoPunto: CGFloat = 5
        let espacioPuntoTexto: CGFloat = 5
        let rect = rectOriginal.integral

        color.withAlphaComponent(
            esPrincipal ? 0.11 : 0.07
        )
        .setFill()

        UIBezierPath(
            roundedRect: rect,
            cornerRadius: radioCaja
        )
        .fill()

        let rutaCaja = UIBezierPath(
            roundedRect: rect,
            cornerRadius: radioCaja
        )

        rutaCaja.lineWidth = grosor

        color.withAlphaComponent(
            esPrincipal ? 0.95 : 0.82
        )
        .setStroke()

        rutaCaja.stroke()

        let porcentaje = Int(confianza * 100)
        let texto = "\(titulo) · \(porcentaje)%"

        let atributos: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(
                ofSize: tamañoFuente,
                weight: .semibold
            ),
            .foregroundColor: UIColor.white
        ]

        let tamañoTexto = (texto as NSString).size(
            withAttributes: atributos
        )

        let anchoEtiqueta = tamañoTexto.width +
            tamañoPunto +
            espacioPuntoTexto +
            (paddingHorizontal * 2)

        let altoEtiqueta = max(
            tamañoTexto.height + (paddingVertical * 2),
            tamañoPunto + (paddingVertical * 2)
        )

        let xEtiqueta = min(
            max(0, rect.minX),
            max(0, anchoImagen - anchoEtiqueta)
        )

        let yEncima = rect.minY -
            altoEtiqueta -
            separacionEtiqueta

        let yEtiqueta: CGFloat

        if yEncima >= 0 {
            yEtiqueta = yEncima
        } else {
            yEtiqueta = min(
                rect.minY + separacionEtiqueta,
                max(0, altoImagen - altoEtiqueta)
            )
        }

        let etiquetaRect = CGRect(
            x: xEtiqueta,
            y: yEtiqueta,
            width: anchoEtiqueta,
            height: altoEtiqueta
        )

        UIColor.black
            .withAlphaComponent(0.72)
            .setFill()

        UIBezierPath(
            roundedRect: etiquetaRect,
            cornerRadius: altoEtiqueta / 2
        )
        .fill()

        let rutaEtiqueta = UIBezierPath(
            roundedRect: etiquetaRect,
            cornerRadius: altoEtiqueta / 2
        )

        rutaEtiqueta.lineWidth = 0.7
        color.withAlphaComponent(0.62).setStroke()
        rutaEtiqueta.stroke()

        let puntoRect = CGRect(
            x: etiquetaRect.minX + paddingHorizontal,
            y: etiquetaRect.midY - (tamañoPunto / 2),
            width: tamañoPunto,
            height: tamañoPunto
        )

        color.setFill()
        UIBezierPath(ovalIn: puntoRect).fill()

        let puntoTexto = CGPoint(
            x: puntoRect.maxX + espacioPuntoTexto,
            y: etiquetaRect.midY - (
                tamañoTexto.height / 2
            )
        )

        (texto as NSString).draw(
            at: puntoTexto,
            withAttributes: atributos
        )
    }

    // MARK: - Datos

    private func buscarInformacion(
        etiqueta: String,
        nombreLimpio: String
    ) -> InfoComponente? {
        let etiquetaNormalizada = normalizar(etiqueta)
        let nombreNormalizado = normalizar(nombreLimpio)

        let alias: [String: String] = [
            "placabase": "Placa_Base",
            "motherboard": "Placa_Base",

            "socketintel": "Socket_Intel",
            "socketamd": "Socket_AMD",
            "socketcpu": "Socket_CPU",

            "cpu": "CPU",
            "procesador": "CPU",
            "cpuintel": "CPU_Intel",
            "cpuamd": "CPU_AMD",

            "ram": "Modulo_RAM",
            "moduloram": "Modulo_RAM",
            "ranuraram": "Ranura_RAM",

            "gpu": "GPU",
            "grafica": "GPU",
            "tarjetagrafica": "GPU",

            "hdd": "HDD",
            "discohdd": "HDD",
            "discoshdd": "HDD",
            "discoduro": "HDD",

            "ssd": "SSD_SATA",
            "discosssd": "SSD_SATA",

            "discom2": "M2_SSD_NVMe",
            "m2": "M2_SSD_NVMe",
            "nvme": "M2_SSD_NVMe",
            "ranuram2": "Ranura_M2",

            "psu": "Fuente_Alimentacion",
            "fuente": "Fuente_Alimentacion",

            "ventilador": "Ventilador_Caja",
            "ventiladorcaja": "Ventilador_Caja",
            "ventiladorcpu": "Ventilador_procesador",

            "disipador": "Disipador_Aire",

            "aio": "Refrigeracion_Liquida_AIO",
            "refrigeracionliquida":
                "Refrigeracion_Liquida_AIO",

            "bombaliquida": "Bomba_Liquida",
            "bloquecpu": "Bloque_refrigeracion_liquida",
            "bloquerefrogeracionliquida":
                "Bloque_refrigeracion_liquida",
            "radiador": "Radiador",

            "ranurapcie": "Ranura_PCIe_x16",
            "puertosata": "Puerto_SATA",
            "puertossata": "Puerto_SATA",
            "conectoratx24p": "Conector_ATX_24p",
            "conectoreps8p": "Conector_EPS_8p",
            "conectorventilador": "Conector_SYS_FAN",
            "pilacmos": "Pila_CMOS",
            "bios": "BIOS_UEFI",
            "uefi": "BIOS_UEFI",

            "reario": "Protector_IO",
            "protectorio": "Protector_IO"
        ]

        if let clave = alias[etiquetaNormalizada],
           let info = informacion[clave] {
            return info
        }

        if let clave = alias[nombreNormalizado],
           let info = informacion[clave] {
            return info
        }

        if let info = informacion[etiqueta] {
            return info
        }

        if let info = informacion[nombreLimpio] {
            return info
        }

        return informacion.first { elemento in
            let clave = normalizar(elemento.key)

            return clave == etiquetaNormalizada ||
                clave == nombreNormalizado
        }?.value
    }

    private func normalizar(
        _ texto: String
    ) -> String {
        texto
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(
                of: "_",
                with: ""
            )
            .replacingOccurrences(
                of: "-",
                with: ""
            )
            .replacingOccurrences(
                of: ".",
                with: ""
            )
            .replacingOccurrences(
                of: " ",
                with: ""
            )
    }

    private func nombreLegible(
        _ nombre: String
    ) -> String {
        nombre
            .replacingOccurrences(
                of: "_",
                with: " "
            )
            .replacingOccurrences(
                of: "M2",
                with: "M.2"
            )
    }

    private func transformarRectangulo(
        _ boundingBox: CGRect,
        video tamanoVideo: CGSize,
        en size: CGSize
    ) -> CGRect {
        // Tamaño real del fotograma: depende de la orientación y de la resolución de la cámara
        let anchoVideo = max(tamanoVideo.width, 1)
        let altoVideo = max(tamanoVideo.height, 1)

        // La cámara llena la pantalla (aspect fill); una foto de la galería se muestra
        // entera (aspect fit) para no recortar piezas. La fórmula sirve para ambos casos.
        let escalaAspectFill = imagenDeGaleria
            ? min(size.width / anchoVideo, size.height / altoVideo)
            : max(size.width / anchoVideo, size.height / altoVideo)

        let anchoEscalado = anchoVideo * escalaAspectFill
        let altoEscalado = altoVideo * escalaAspectFill

        let offsetX = (
            anchoEscalado - size.width
        ) / 2

        let offsetY = (
            altoEscalado - size.height
        ) / 2

        let x = boundingBox.minX * anchoEscalado - offsetX
        let y = (
            1 - boundingBox.maxY
        ) * altoEscalado - offsetY

        let width = boundingBox.width * anchoEscalado
        let height = boundingBox.height * altoEscalado

        return CGRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    private func area(
        of rect: CGRect
    ) -> CGFloat {
        rect.width * rect.height
    }
}

// MARK: - Caja de detección

private struct DetectionBox: View {

    let titulo: String
    let confianza: Float
    let rect: CGRect
    let principal: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    /// Efecto "fijar objetivo": la caja aparece algo más grande y se ajusta al objeto
    @State private var fijado = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .strokeBorder(
                    colorBorde,
                    lineWidth: principal ? 2.5 : 1.5
                )
                .background(
                    colorBorde.opacity(
                        principal ? 0.105 : 0.045
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                )
                .compositingGroup()
                .shadow(
                    color: colorBorde.opacity(
                        principal ? 0.30 : 0.18
                    ),
                    radius: principal ? 5 : 3
                )

                etiquetaCompacta
                    .padding(5)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(fijado || reducirMovimiento ? 1 : 1.18)
        .opacity(fijado ? 1 : 0)
        .frame(
            width: max(rect.width, 42),
            height: max(rect.height, 42)
        )
        .position(
            x: rect.midX,
            y: rect.midY
        )
        // Entre fotogramas la caja se desliza en vez de saltar
        .animation(reducirMovimiento ? nil : .smooth(duration: 0.18), value: rect)
        .onAppear {
            // Con "Reducir movimiento" solo un fundido corto, sin rebote
            withAnimation(
                reducirMovimiento
                    ? .easeOut(duration: 0.15)
                    : .spring(response: 0.32, dampingFraction: 0.7)
            ) {
                fijado = true
            }
        }
        .contentShape(Rectangle())
        .accessibilityLabel(
            "\(titulo), \(Int(confianza * 100)) por ciento de confianza"
        )
    }

    private var etiquetaCompacta: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(colorBorde)
                .frame(width: 5, height: 5)
                .shadow(
                    color: colorBorde.opacity(0.70),
                    radius: 2
                )

            Text(titulo.localizado)
                .font(
                    .system(
                        size: 11,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .lineLimit(1)

            Text("\(Int(confianza * 100))%")
                .font(
                    .system(
                        size: 10,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .stroke(
                            colorBorde.opacity(
                                principal ? 0.58 : 0.35
                            ),
                            lineWidth: 0.8
                        )
                }
        }
        .shadow(
            color: .black.opacity(0.18),
            radius: 4,
            y: 2
        )
    }

    private var colorBorde: Color {
        principal ? .green : .accentColor
    }
}

// MARK: - Estado

private enum EstadoScanner {
    case analizando
    case detectado
    case congelado
}
