//
//  RaizAppView.swift
//  PcComponentIA
//
//  Pantalla raíz: en iPad (ancho regular) usa barra lateral + contenido;
//  en iPhone o ventanas estrechas, la navegación de siempre desde el inicio.
//

import SwiftUI

enum SeccionApp: String, CaseIterable, Identifiable, Hashable {
    case inicio, escaner, diagnostico, asistente
    case diccionario, detectables
    case builds, historial

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .inicio: "Inicio"
        case .escaner: "Escanear"
        case .diagnostico: "Diagnóstico"
        case .asistente: "Asistente"
        case .diccionario: "Diccionario"
        case .detectables: "Detectables"
        case .builds: "Mis Builds"
        case .historial: "Historial"
        }
    }

    var icono: String {
        switch self {
        case .inicio: "house.fill"
        case .escaner: "camera.viewfinder"
        case .diagnostico: "exclamationmark.triangle.fill"
        case .asistente: "sparkles"
        case .diccionario: "character.book.closed.fill"
        case .detectables: "viewfinder"
        case .builds: "pc"
        case .historial: "books.vertical.fill"
        }
    }

    var color: Color {
        switch self {
        case .inicio: .blue
        case .escaner: .indigo
        case .diagnostico: .orange
        case .asistente: .pink
        case .diccionario: .purple
        case .detectables: .teal
        case .builds: .green
        case .historial: .cyan
        }
    }

    /// Grupos de la barra lateral.
    static let grupos: [(String, [SeccionApp])] = [
        ("Herramientas", [.inicio, .escaner, .diagnostico, .asistente]),
        ("Aprender", [.diccionario, .detectables]),
        ("Lo tuyo", [.builds, .historial]),
    ]

    @MainActor @ViewBuilder
    var vista: some View {
        switch self {
        case .inicio: HomeView()
        // Solo aquí el escáner es la pantalla principal (sin "cerrar"); abierto desde el inicio, sí lo lleva
        case .escaner: ScannerView().environment(\.esRaizDeSeccion, true)
        case .diagnostico: DiagnosticoLedView()
        case .asistente: ChatIAView()
        case .diccionario: DiccionarioView(diccionario: DatosHardware.obtenerDiccionario())
        case .detectables: ComponentesDetectablesView()
        case .builds: MisBuildsView()
        case .historial: HistorialView()
        }
    }
}

struct RaizAppView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    @SceneStorage("seccionSeleccionada") private var seccionGuardada: SeccionApp = .inicio
    @State private var seccion: SeccionApp? = nil
    /// En iPhone, sección abierta por Siri/Atajos encima del inicio
    @State private var destinoCompacto: SeccionApp?
    @ObservedObject private var navegador = NavegadorApp.shared

    var body: some View {
        contenido
            .onChange(of: navegador.seccionSolicitada) { _, solicitada in
                guard let solicitada else { return }
                if sizeClass == .regular {
                    seccion = solicitada
                } else {
                    destinoCompacto = solicitada == .inicio ? nil : solicitada
                }
                navegador.seccionSolicitada = nil
            }
    }

    @ViewBuilder
    private var contenido: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                List(selection: $seccion) {
                    ForEach(SeccionApp.grupos, id: \.0) { grupo, secciones in
                        Section(grupo.localizado) {
                            ForEach(secciones) { seccion in
                                Label {
                                    Text(seccion.titulo.localizado)
                                } icon: {
                                    Image(systemName: seccion.icono)
                                        .foregroundStyle(seccion.color)
                                }
                                .tag(seccion)
                            }
                        }
                    }
                }
                .navigationTitle("PcComponentIA")
                .navigationSplitViewColumnWidth(min: 220, ideal: 250)
            } detail: {
                NavigationStack {
                    (seccion ?? .inicio).vista
                }
                // Al cambiar de sección se empieza desde su pantalla principal
                .id(seccion ?? .inicio)
            }
            .onAppear {
                if seccion == nil { seccion = seccionGuardada }
            }
            .onChange(of: seccion) { _, nueva in
                if let nueva { seccionGuardada = nueva }
            }
        } else {
            NavigationStack {
                HomeView()
                    .navigationDestination(item: $destinoCompacto) { destino in
                        destino.vista
                    }
            }
        }
    }
}

// MARK: - Pantalla principal de sección

private struct EsRaizDeSeccionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// true cuando la vista es la primera de una sección de la barra lateral (iPad):
    /// ahí un botón de "cerrar" no tendría a dónde volver.
    var esRaizDeSeccion: Bool {
        get { self[EsRaizDeSeccionKey.self] }
        set { self[EsRaizDeSeccionKey.self] = newValue }
    }
}
