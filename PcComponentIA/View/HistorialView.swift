//
//  HistorialView.swift
//  PcComponentIA
//

import SwiftUI
import UIKit
import AVFoundation
import Combine
import PDFKit
import SwiftData

// MARK: - Lector de audio

final class LectorAudio: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    @Published var isSpeaking = false

    let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
    }

    deinit {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = nil
    }

    func leer(texto: String) {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = self

        let utterance = AVSpeechUtterance(string: texto)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func detener() {
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.delegate = nil
        isSpeaking = false
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSpeaking = false
            self.synthesizer.delegate = nil
        }
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSpeaking = false
            self.synthesizer.delegate = nil
        }
    }
}

// MARK: - Modelo

struct CapturaHistorial: Identifiable, Codable, Equatable {

    let id: UUID
    let componente: String
    let fecha: Date
    let confianza: String
    let fotoData: Data

    init(
        componente: String,
        fecha: Date,
        confianza: String,
        fotoEquipo: UIImage
    ) {
        self.id = UUID()
        self.componente = componente
        self.fecha = fecha
        self.confianza = confianza
        self.fotoData = fotoEquipo.jpegData(
            compressionQuality: 0.94
        ) ?? Data()
    }

    /// Reconstruye una captura ya guardada sin volver a comprimir la foto.
    init(
        id: UUID,
        componente: String,
        fecha: Date,
        confianza: String,
        fotoData: Data
    ) {
        self.id = id
        self.componente = componente
        self.fecha = fecha
        self.confianza = confianza
        self.fotoData = fotoData
    }

    var fotoEquipo: UIImage {
        UIImage(data: fotoData) ?? UIImage()
    }

    var nombreLimpio: String {
        componente.replacingOccurrences(of: "_", with: " ")
    }

    var confianzaNumerica: Int {
        let digitos = confianza.filter(\.isNumber)
        return Int(digitos) ?? 0
    }

    var colorConfianza: Color {
        switch confianzaNumerica {
        case 85...:
            return .green

        case 65...:
            return .orange

        default:
            return .red
        }
    }
}

// MARK: - Almacenamiento

@MainActor
final class AlmacenHistorial {
    static var defaultContext: ModelContext?

    static func guardar(_ historial: [CapturaHistorial], context: ModelContext? = nil) {
        let ctx = context ?? defaultContext
        guard let ctx else { return }

        try? ctx.delete(model: CapturaHistorialSD.self)
        for cap in historial {
            let capSD = CapturaHistorialSD(
                id: cap.id,
                componente: cap.componente,
                fecha: cap.fecha,
                confianza: cap.confianza,
                fotoData: cap.fotoData
            )
            ctx.insert(capSD)
        }
        try? ctx.save()
    }

    static func cargar(context: ModelContext? = nil) -> [CapturaHistorial] {
        let ctx = context ?? defaultContext
        guard let ctx else { return [] }

        let descriptor = FetchDescriptor<CapturaHistorialSD>(sortBy: [SortDescriptor(\.fecha, order: .reverse)])
        guard let items = try? ctx.fetch(descriptor) else { return [] }

        return items.map { item in
            CapturaHistorial(
                id: item.id,
                componente: item.componente,
                fecha: item.fecha,
                confianza: item.confianza,
                fotoData: item.fotoData
            )
        }
    }

    /// Guarda una captura nueva sin reescribir todo el historial.
    static func añadir(_ captura: CapturaHistorial, context: ModelContext? = nil) {
        let ctx = context ?? defaultContext
        guard let ctx else { return }

        ctx.insert(
            CapturaHistorialSD(
                id: captura.id,
                componente: captura.componente,
                fecha: captura.fecha,
                confianza: captura.confianza,
                fotoData: captura.fotoData
            )
        )
        try? ctx.save()
    }

    static func borrarTodo(context: ModelContext? = nil) {
        let ctx = context ?? defaultContext
        guard let ctx else { return }

        try? ctx.delete(model: CapturaHistorialSD.self)
        try? ctx.save()
    }
}

// MARK: - Compartir

struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Filtros

private enum FiltroHistorial: String, CaseIterable, Identifiable {
    case todos
    case hoy
    case semana
    case altaConfianza

    var id: String {
        rawValue
    }

    var titulo: String {
        switch self {
        case .todos:
            return "Todo"

        case .hoy:
            return "Hoy"

        case .semana:
            return "7 días"

        case .altaConfianza:
            return "Alta precisión"
        }
    }

    var icono: String {
        switch self {
        case .todos:
            return "square.grid.2x2.fill"

        case .hoy:
            return "calendar"

        case .semana:
            return "calendar.badge.clock"

        case .altaConfianza:
            return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .todos:
            return .blue

        case .hoy:
            return .cyan

        case .semana:
            return .indigo

        case .altaConfianza:
            return .green
        }
    }
}

// MARK: - Historial

struct HistorialView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var historial: [CapturaHistorial] = []

    @StateObject private var gestorRetencion = GestorRetencionEscaneos()

    @State private var textoBusqueda = ""
    @State private var filtro: FiltroHistorial = .todos

    @State private var pdfURL: URL?
    @State private var mostrarShare = false

    @State private var modoSeleccion = false
    @State private var seleccionados: Set<UUID> = []

    @State private var mostrarAjustesRetencion = false
    @State private var mostrarConfirmacionEliminarTodo = false
    @State private var mostrarConfirmacionEliminarSeleccion = false

    @State private var fotoAmpliada: CapturaHistorial?
    
    @EnvironmentObject private var checklist: GestorChecklist

    private let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var historialFiltrado: [CapturaHistorial] {
        historial
            .filter(coincideConFiltro)
            .filter(coincideConBusqueda)
            .sorted { $0.fecha > $1.fecha }
    }

    private var elementosParaExportar: [CapturaHistorial] {
        if modoSeleccion, !seleccionados.isEmpty {
            return historial.filter {
                seleccionados.contains($0.id)
            }
        }

        return historialFiltrado
    }

    private var totalHoy: Int {
        historial.filter {
            Calendar.current.isDateInToday($0.fecha)
        }
        .count
    }

    private var confianzaMedia: Int {
        guard !historial.isEmpty else {
            return 0
        }

        let total = historial.reduce(0) {
            $0 + $1.confianzaNumerica
        }

        return total / historial.count
    }

    var body: some View {
        ZStack {
            fondoAsistente

            if historial.isEmpty {
                estadoVacio
            } else {
                contenido
            }
            
            // MARK: - Checklist Lateral
            ChecklistLateral(gestor: checklist)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .trailing
                )
                // Ajusta los paddings según necesites para que no tape otros elementos
                .padding(.bottom, 28)
                .safeAreaPadding(.top, 108)
        }
        .navigationTitle(
            modoSeleccion
                ? "\(seleccionados.count) seleccionados"
                : "Historial"
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(
            text: $textoBusqueda,
            prompt: "Buscar componente escaneado..."
        )
        .toolbar {
            toolbarContenido
        }
        .sheet(isPresented: $mostrarShare) {
            if let pdfURL {
                ShareSheet(items: [pdfURL])
            }
        }
        .sheet(isPresented: $mostrarAjustesRetencion) {
            AjustesHistorialEscaneosView(
                gestor: gestorRetencion
            )
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(item: $fotoAmpliada) { registro in
            FotoAmpliadaView(registro: registro) {
                fotoAmpliada = nil
            }
        }
        .alert(
            "¿Eliminar todos los escaneos?",
            isPresented: $mostrarConfirmacionEliminarTodo
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar todo", role: .destructive) {
                eliminarTodo()
            }
        } message: {
            Text(
                "Se eliminarán \(historial.count) escaneos guardados. Esta acción no se puede deshacer."
            )
        }
        .alert(
            "¿Eliminar escaneos seleccionados?",
            isPresented: $mostrarConfirmacionEliminarSeleccion
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                eliminarSeleccionados()
            }
        } message: {
            Text(
                "Se eliminarán \(seleccionados.count) escaneos seleccionados."
            )
        }
        .onAppear {
            historial = AlmacenHistorial.cargar()
            aplicarRetencion()
        }
    }

    // MARK: - Contenido

    private var contenido: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                resumen

                selectorFiltros

                HStack {
                    Text(
                        textoSeccionResultados
                    )
                    .font(.headline)

                    Spacer(minLength: 0)

                    Text(
                        "\(historialFiltrado.count)"
                    )
                    .font(
                        .caption
                        .monospacedDigit()
                        .weight(.bold)
                    )
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        colorControl,
                        in: Capsule()
                    )
                }

                if historialFiltrado.isEmpty {
                    estadoSinResultados
                } else {
                    LazyVGrid(
                        columns: columnas,
                        spacing: 12
                    ) {
                        ForEach(historialFiltrado) { registro in
                            tarjeta(registro)
                        }
                    }
                }
            }
            .frame(maxWidth: 900)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 36)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var resumen: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [
                            .cyan.opacity(0.24),
                            .blue.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .stroke(
                        .cyan.opacity(0.25),
                        lineWidth: 1
                    )
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Tus componentes detectados")
                    .font(.headline)

                Text(
                    resumenTexto
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .historialGlassSurface(
            cornerRadius: 23,
            tint: .cyan
        )
    }

    private var resumenTexto: String {
        if historial.count == 1 {
            return "1 escaneo guardado · \(confianzaMedia)% de confianza"
        }

        return "\(historial.count) escaneos · \(totalHoy) hoy · \(confianzaMedia)% de confianza"
    }

    private var selectorFiltros: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(FiltroHistorial.allCases) { opcion in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            filtro = opcion
                        }

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: opcion.icono)
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .bold
                                    )
                                )

                            Text(opcion.titulo)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            filtro == opcion
                                ? Color.white
                                : Color.primary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(
                                    filtro == opcion
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [
                                                    opcion.color,
                                                    opcion.color.opacity(0.72)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(
                                            colorControl
                                        )
                                )
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    filtro == opcion
                                        ? opcion.color.opacity(0.32)
                                        : Color.primary.opacity(0.09),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(HistorialPressStyle())
                    .accessibilityLabel(
                        "Mostrar escaneos: \(opcion.titulo)"
                    )
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Tarjeta

    private func tarjeta(
        _ registro: CapturaHistorial
    ) -> some View {
        let estaSeleccionado = seleccionados.contains(registro.id)

        return VStack(alignment: .leading, spacing: 10) {
            // La foto abre la vista ampliada o selecciona en modo selección
            imagenRegistro(
                registro,
                estaSeleccionado: estaSeleccionado
            )
            .onTapGesture {
                tocarRegistro(registro)
            }

            // El texto inferior te da feedback legible
            VStack(alignment: .leading, spacing: 5) {
                Text(registro.nombreLimpio)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))

                    Text(
                        registro.fecha.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )
                    .lineLimit(1)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 201, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    estaSeleccionado
                        ? Color.accentColor.opacity(
                            colorScheme == .dark ? 0.24 : 0.16
                        )
                        : colorTarjeta
                )
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: estaSeleccionado
                            ? [
                                Color.accentColor.opacity(0.20),
                                .clear
                            ]
                            : [
                                .blue.opacity(colorScheme == .dark ? 0.06 : 0.04),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    estaSeleccionado
                        ? Color.accentColor.opacity(0.86)
                        : Color.primary.opacity(
                            colorScheme == .dark ? 0.14 : 0.09
                        ),
                    lineWidth: estaSeleccionado ? 2 : 1
                )
        }
        .shadow(
            color: estaSeleccionado
                ? Color.accentColor.opacity(0.20)
                : .black.opacity(colorScheme == .dark ? 0.20 : 0.06),
            radius: estaSeleccionado ? 11 : 8,
            y: 4
        )
        .scaleEffect(estaSeleccionado ? 0.975 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onLongPressGesture(minimumDuration: 0.42) {
            entrarEnModoSeleccion(con: registro)
        }
        .contextMenu {
            Button {
                entrarEnModoSeleccion(con: registro)
            } label: {
                Label(
                    "Seleccionar",
                    systemImage: "checkmark.circle"
                )
            }

            Button {
                fotoAmpliada = registro
            } label: {
                Label(
                    "Ver fotografía",
                    systemImage: "arrow.up.left.and.arrow.down.right"
                )
            }

            Button {
                compartirRegistro(registro)
            } label: {
                Label(
                    "Compartir imagen",
                    systemImage: "square.and.arrow.up"
                )
            }

            Divider()

            Button(role: .destructive) {
                eliminar(registro)
            } label: {
                Label(
                    "Eliminar escaneo",
                    systemImage: "trash"
                )
            }
        }
        .accessibilityLabel(
            "\(registro.nombreLimpio), confianza \(registro.confianza)"
        )
    }

    private func imagenRegistro(
        _ registro: CapturaHistorial,
        estaSeleccionado: Bool
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: registro.fotoEquipo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 132)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            .clear,
                            .black.opacity(0.32)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )

            if modoSeleccion {
                ZStack {
                    Circle()
                        .fill(
                            estaSeleccionado
                                ? Color.accentColor
                                : Color.black.opacity(0.48)
                        )
                        .frame(width: 32, height: 32)

                    Circle()
                        .stroke(
                            .white.opacity(estaSeleccionado ? 0.35 : 0.75),
                            lineWidth: 1.5
                        )
                        .frame(width: 32, height: 32)

                    Image(
                        systemName: estaSeleccionado
                            ? "checkmark"
                            : "circle"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                }
                .padding(9)
            } else {
                VStack(alignment: .trailing, spacing: 7) {
                    etiquetaConfianza(registro)

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 27, height: 27)
                        .background(.black.opacity(0.42), in: Circle())
                }
                .padding(8)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    .white.opacity(colorScheme == .dark ? 0.13 : 0.34),
                    lineWidth: 1
                )
        }
    }

    private func etiquetaConfianza(
        _ registro: CapturaHistorial
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 9, weight: .bold))

            Text(registro.confianza)
                .font(
                    .caption2
                    .monospacedDigit()
                    .weight(.bold)
                )
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            registro.colorConfianza.opacity(0.92),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    .white.opacity(0.28),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Estados vacíos

    private var estadoVacio: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.cyan)

            Text("Todavía no hay escaneos")
                .font(.headline)

            Text(
                "Cuando detectes un componente con la cámara, aparecerá guardado aquí."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(28)
        .frame(maxWidth: 340)
        .historialGlassSurface(
            cornerRadius: 26,
            tint: .cyan
        )
        .padding(20)
    }

    private var estadoSinResultados: some View {
        VStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.cyan)

            Text("No hay coincidencias")
                .font(.headline)

            Text(
                "Prueba con otra búsqueda o cambia el filtro."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button("Restablecer filtros") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    textoBusqueda = ""
                    filtro = .todos
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.cyan)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 35)
        .historialGlassSurface(
            cornerRadius: 23,
            tint: .cyan
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContenido: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !historial.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        modoSeleccion.toggle()

                        if !modoSeleccion {
                            seleccionados.removeAll()
                        }
                    }

                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 5) {
                        Image(
                            systemName: modoSeleccion
                                ? "xmark"
                                : "checkmark.circle"
                        )

                        Text(modoSeleccion ? "Cancelar" : "Seleccionar")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .accessibilityLabel(
                    modoSeleccion
                        ? "Cancelar selección"
                        : "Seleccionar varias fotos"
                )
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 5) {
                Button {
                    mostrarAjustesRetencion = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .frame(width: 38, height: 38)
                }
                .accessibilityLabel("Ajustes de retención del historial")

                if !historial.isEmpty {
                    Button {
                        exportarPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 38, height: 38)
                    }
                    .disabled(
                        modoSeleccion
                            && seleccionados.isEmpty
                    )
                    .accessibilityLabel("Exportar historial a PDF")

                    Button(role: .destructive) {
                        if modoSeleccion {
                            mostrarConfirmacionEliminarSeleccion = true
                        } else {
                            mostrarConfirmacionEliminarTodo = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 38, height: 38)
                    }
                    .disabled(
                        modoSeleccion
                            && seleccionados.isEmpty
                    )
                    .accessibilityLabel(
                        modoSeleccion
                            ? "Eliminar escaneos seleccionados"
                            : "Eliminar todo el historial"
                    )
                }
            }
        }
    }

    // MARK: - Filtros

    private func coincideConFiltro(
        _ registro: CapturaHistorial
    ) -> Bool {
        let calendario = Calendar.current

        switch filtro {
        case .todos:
            return true

        case .hoy:
            return calendario.isDateInToday(registro.fecha)

        case .semana:
            guard let haceSieteDias = calendario.date(
                byAdding: .day,
                value: -7,
                to: .now
            ) else {
                return true
            }

            return registro.fecha >= haceSieteDias

        case .altaConfianza:
            return registro.confianzaNumerica >= 85
        }
    }

    private func coincideConBusqueda(
        _ registro: CapturaHistorial
    ) -> Bool {
        guard !textoBusqueda.isEmpty else {
            return true
        }

        return registro.nombreLimpio.localizedCaseInsensitiveContains(
            textoBusqueda
        )
    }

    private var textoSeccionResultados: String {
        if textoBusqueda.isEmpty, filtro == .todos {
            return "Escaneos recientes"
        }

        return "Resultados"
    }

    // MARK: - Acciones

    
    private func entrarEnModoSeleccion(
        con registro: CapturaHistorial
    ) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            modoSeleccion = true
            seleccionados.insert(registro.id)
        }
    }

    private func tocarRegistro(
        _ registro: CapturaHistorial
    ) {
        guard modoSeleccion else {
            fotoAmpliada = registro
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.easeOut(duration: 0.16)) {
            if seleccionados.contains(registro.id) {
                seleccionados.remove(registro.id)
            } else {
                seleccionados.insert(registro.id)
            }
        }
    }

    private func eliminar(
        _ registro: CapturaHistorial
    ) {
        withAnimation(.easeOut(duration: 0.20)) {
            historial.removeAll {
                $0.id == registro.id
            }

            seleccionados.remove(registro.id)
            AlmacenHistorial.guardar(historial)
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func eliminarSeleccionados() {
        guard !seleccionados.isEmpty else {
            return
        }

        withAnimation(.easeOut(duration: 0.20)) {
            historial.removeAll {
                seleccionados.contains($0.id)
            }

            seleccionados.removeAll()
            modoSeleccion = false
            AlmacenHistorial.guardar(historial)
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func eliminarTodo() {
        withAnimation(.easeOut(duration: 0.20)) {
            historial.removeAll()
            seleccionados.removeAll()
            modoSeleccion = false
            AlmacenHistorial.borrarTodo()
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func exportarPDF() {
        guard !elementosParaExportar.isEmpty else {
            return
        }

        pdfURL = generarPDF(items: elementosParaExportar)
        mostrarShare = pdfURL != nil

        UIImpactFeedbackGenerator(style: .medium)
            .impactOccurred()
    }

    private func compartirRegistro(
        _ registro: CapturaHistorial
    ) {
        fotoAmpliada = registro
    }

    private func aplicarRetencion() {
        // Si la retención borra algo, el propio gestor lo guarda. Aquí solo se ordena para mostrar.
        gestorRetencion.aplicarRetencion(a: &historial)
        historial.sort {
            $0.fecha > $1.fecha
        }
    }

    // MARK: - PDF

    private func generarPDF(
        items: [CapturaHistorial]
    ) -> URL? {
        let metadatos: [CFString: Any] = [
            kCGPDFContextCreator: "PcComponentIA",
            kCGPDFContextTitle: "Informe de escaneos",
            kCGPDFContextAuthor: "PcComponentIA"
        ]

        let formato = UIGraphicsPDFRendererFormat()
        formato.documentInfo = metadatos as [String: Any]

        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: 595.2,
            height: 841.8
        )

        let renderer = UIGraphicsPDFRenderer(
            bounds: pageRect,
            format: formato
        )

        let fechaArchivo = Date()
            .formatted(
                .dateTime
                    .year()
                    .month()
                    .day()
                    .hour()
                    .minute()
            )
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")

        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "Informe_Escaneos_\(fechaArchivo).pdf"
            )

        do {
            try renderer.writePDF(to: url) { context in
                let margen: CGFloat = 42
                let anchoContenido = pageRect.width - (margen * 2)

                var y: CGFloat = margen

                func dibujarCabecera(
                    numeroPagina: Int
                ) {
                    context.beginPage()

                    let barra = CGRect(
                        x: 0,
                        y: 0,
                        width: pageRect.width,
                        height: 92
                    )

                    UIColor(
                        red: 0.05,
                        green: 0.08,
                        blue: 0.15,
                        alpha: 1
                    )
                    .setFill()

                    context.cgContext.fill(barra)

                    let titulo = "Informe de escaneos"
                    let subtitulo = "PcComponentIA · \(items.count) elementos"

                    titulo.draw(
                        at: CGPoint(x: margen, y: 28),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 22,
                                weight: .bold
                            ),
                            .foregroundColor: UIColor.white
                        ]
                    )

                    subtitulo.draw(
                        at: CGPoint(x: margen, y: 58),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 11,
                                weight: .regular
                            ),
                            .foregroundColor: UIColor(
                                white: 0.82,
                                alpha: 1
                            )
                        ]
                    )

                    let pagina = "Página \(numeroPagina)"

                    pagina.draw(
                        at: CGPoint(
                            x: pageRect.width - margen - 58,
                            y: 58
                        ),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 10,
                                weight: .medium
                            ),
                            .foregroundColor: UIColor(
                                white: 0.82,
                                alpha: 1
                            )
                        ]
                    )

                    y = 116
                }

                var pagina = 1
                dibujarCabecera(numeroPagina: pagina)

                for registro in items {
                    let alturaFila: CGFloat = 112

                    if y + alturaFila > pageRect.height - 48 {
                        pagina += 1
                        dibujarCabecera(numeroPagina: pagina)
                    }

                    let fondoFila = CGRect(
                        x: margen,
                        y: y,
                        width: anchoContenido,
                        height: alturaFila - 10
                    )

                    UIColor(
                        red: 0.96,
                        green: 0.97,
                        blue: 0.99,
                        alpha: 1
                    )
                    .setFill()

                    UIBezierPath(
                        roundedRect: fondoFila,
                        cornerRadius: 13
                    )
                    .fill()

                    let imagenRect = CGRect(
                        x: margen + 10,
                        y: y + 10,
                        width: 104,
                        height: 82
                    )

                    registro.fotoEquipo.draw(in: imagenRect)

                    let xTexto = imagenRect.maxX + 16
                    let anchoTexto = anchoContenido - 144

                    let titulo = registro.nombreLimpio
                    let detalle = "Confianza: \(registro.confianza)"
                    let fecha = registro.fecha.formatted(
                        date: .long,
                        time: .shortened
                    )

                    titulo.draw(
                        in: CGRect(
                            x: xTexto,
                            y: y + 15,
                            width: anchoTexto,
                            height: 23
                        ),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 15,
                                weight: .bold
                            ),
                            .foregroundColor: UIColor.black
                        ]
                    )

                    detalle.draw(
                        in: CGRect(
                            x: xTexto,
                            y: y + 45,
                            width: anchoTexto,
                            height: 18
                        ),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 12,
                                weight: .semibold
                            ),
                            .foregroundColor: UIColor(
                                red: 0.10,
                                green: 0.46,
                                blue: 0.25,
                                alpha: 1
                            )
                        ]
                    )

                    fecha.draw(
                        in: CGRect(
                            x: xTexto,
                            y: y + 67,
                            width: anchoTexto,
                            height: 18
                        ),
                        withAttributes: [
                            .font: UIFont.systemFont(
                                ofSize: 11,
                                weight: .regular
                            ),
                            .foregroundColor: UIColor.darkGray
                        ]
                    )

                    y += alturaFila
                }
            }

            return url
        } catch {
            return nil
        }
    }

    // MARK: - Colores

    private var colorControl: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.74)
        }

        return Color.white.opacity(0.54)
    }

    private var colorTarjeta: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.68)
        }

        return Color.white.opacity(0.50)
    }

    // MARK: - Fondo

    private var fondoAsistente: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.038,
                            green: 0.040,
                            blue: 0.048
                        ),
                        Color(
                            red: 0.021,
                            green: 0.023,
                            blue: 0.030
                        ),
                        Color(
                            red: 0.006,
                            green: 0.007,
                            blue: 0.012
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .blue.opacity(0.13),
                        .indigo.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 520
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.975,
                            green: 0.982,
                            blue: 0.995
                        ),
                        Color(
                            red: 0.940,
                            green: 0.956,
                            blue: 0.982
                        ),
                        Color(
                            red: 0.910,
                            green: 0.930,
                            blue: 0.965
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .blue.opacity(0.14),
                        .cyan.opacity(0.040),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Visor de fotografía

struct FotoAmpliadaView: View {

    let registro: CapturaHistorial
    var onCerrar: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reducirMovimiento

    @State private var escala: CGFloat = 1
    @State private var ultimaEscala: CGFloat = 1

    @State private var offset: CGSize = .zero
    @State private var ultimoOffset: CGSize = .zero

    @State private var mostrarShare = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: registro.fotoEquipo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(escala)
                    .offset(offset)
                    .gesture(gestoZoom)
                    .simultaneousGesture(gestoArrastre)
                    .onTapGesture(count: 2) {
                        alternarZoom()
                    }

                VStack(spacing: 0) {
                    cabecera(
                        safeAreaTop: geometry.safeAreaInsets.top
                    )

                    Spacer()

                    pie(
                        safeAreaBottom: geometry.safeAreaInsets.bottom
                    )
                }
            }
        }
        .sheet(isPresented: $mostrarShare) {
            ShareSheet(items: [registro.fotoEquipo])
        }
        .statusBar(hidden: true)
    }

    private func cabecera(
        safeAreaTop: CGFloat
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                onCerrar()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.13), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                .white.opacity(0.20),
                                lineWidth: 1
                            )
                    }
            }
            .buttonStyle(HistorialPressStyle())
            .accessibilityLabel("Cerrar fotografía")

            Spacer(minLength: 0)

            VStack(spacing: 3) {
                Text(registro.nombreLimpio.uppercased())
                    .font(
                        .caption
                        .weight(.bold)
                    )
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)

                Text(
                    registro.fecha.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.63))
            }
            .frame(maxWidth: 210)

            Spacer(minLength: 0)

            Button {
                mostrarShare = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.13), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                .white.opacity(0.20),
                                lineWidth: 1
                            )
                    }
            }
            .buttonStyle(HistorialPressStyle())
            .accessibilityLabel("Compartir fotografía")
        }
        .padding(.horizontal, 16)
        .padding(.top, safeAreaTop + 12)
    }

    private func pie(
        safeAreaBottom: CGFloat
    ) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold))

                Text("CONFIANZA \(registro.confianza)")
                    .font(
                        .caption
                        .monospacedDigit()
                        .weight(.bold)
                    )
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                registro.colorConfianza.opacity(0.92),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        .white.opacity(0.26),
                        lineWidth: 1
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, safeAreaBottom + 20)
    }

    private var gestoZoom: some Gesture {
        MagnificationGesture()
            .onChanged { valor in
                escala = max(
                    1,
                    min(4, ultimaEscala * valor)
                )
            }
            .onEnded { _ in
                ultimaEscala = escala

                if escala <= 1 {
                    withAnimation(
                        reducirMovimiento
                            ? .linear(duration: 0.01)
                            : .spring(
                                response: 0.28,
                                dampingFraction: 0.82
                            )
                    ) {
                        escala = 1
                        ultimaEscala = 1
                        offset = .zero
                        ultimoOffset = .zero
                    }
                }
            }
    }

    private var gestoArrastre: some Gesture {
        DragGesture()
            .onChanged { valor in
                guard escala > 1 else {
                    return
                }

                offset = CGSize(
                    width: ultimoOffset.width
                        + valor.translation.width,
                    height: ultimoOffset.height
                        + valor.translation.height
                )
            }
            .onEnded { _ in
                ultimoOffset = offset
            }
    }

    private func alternarZoom() {
        withAnimation(
            reducirMovimiento
                ? .linear(duration: 0.01)
                : .spring(
                    response: 0.32,
                    dampingFraction: 0.80
                )
        ) {
            if escala > 1 {
                escala = 1
                ultimaEscala = 1
                offset = .zero
                ultimoOffset = .zero
            } else {
                escala = 2.5
                ultimaEscala = 2.5
            }
        }
    }
}

// MARK: - Estilos compartidos

private extension View {

    func historialGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            HistorialGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }
}

private struct HistorialGlassSurfaceModifier: ViewModifier {

    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

        content
            .background {
                forma.fill(colorFondo)
            }
            .background {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                tint.opacity(0.08),
                                .blue.opacity(0.02),
                                .clear
                            ]
                            : [
                                tint.opacity(0.075),
                                .blue.opacity(0.025),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                .white.opacity(0.065),
                                .white.opacity(0.010),
                                .clear
                            ]
                            : [
                                .white.opacity(0.42),
                                .white.opacity(0.10),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
            }
            .overlay {
                forma.stroke(
                    colorScheme == .dark
                        ? .white.opacity(0.15)
                        : .white.opacity(0.66),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.28)
                    : tint.opacity(0.09),
                radius: 12,
                y: 6
            )
    }

    private var colorFondo: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.68)
        }

        return Color.white.opacity(0.50)
    }
}

private struct HistorialPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
