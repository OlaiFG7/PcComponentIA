//
//  DiccionarioView.swift
//  PcComponentIA
//

import SwiftUI

struct DiccionarioView: View {

    let diccionario: [String: InfoComponente]
    let colorPrincipal: Color
    let colorSecundario: Color

    @Environment(\.colorScheme) private var colorScheme

    @State private var textoBusqueda = ""
    @State private var categoriaSeleccionada: CategoriaDiccionario = .todas

    private let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Inicializador Parametrizado (Por defecto Violeta/Fucsia)
    init(
        diccionario: [String: InfoComponente],
        colorPrincipal: Color = Color(
            red: 0.49,
            green: 0.27,
            blue: 0.93
        ),
        colorSecundario: Color = Color(
            red: 0.88,
            green: 0.24,
            blue: 0.62
        )
    ) {
        self.diccionario = diccionario
        self.colorPrincipal = colorPrincipal
        self.colorSecundario = colorSecundario
    }

    private var componentesFiltrados: [(clave: String, info: InfoComponente)] {
        diccionario
            .map { (clave: $0.key, info: $0.value) }
            .filter { item in
                coincideConBusqueda(item)
                    && coincideConCategoria(item)
            }
            .sorted {
                nombreLegible($0.clave)
                    .localizedCaseInsensitiveCompare(
                        nombreLegible($1.clave)
                    ) == .orderedAscending
            }
    }

    var body: some View {
        ZStack {
            fondoAsistente

            if componentesFiltrados.isEmpty {
                estadoVacio
            } else {
                contenido
            }
        }
        .navigationTitle("Diccionario")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(
            text: $textoBusqueda,
            prompt: "Buscar componente, puerto o conector..."
        )
    }

    // MARK: - Contenido

    private var contenido: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                cabecera

                selectorCategorias

                LazyVGrid(columns: columnas, spacing: 12) {
                    ForEach(componentesFiltrados, id: \.clave) { item in
                        NavigationLink {
                            DetalleComponenteInfoView(
                                nombre: item.clave,
                                info: item.info,
                                colorPrincipal: colorPrincipal,
                                colorSecundario: colorSecundario
                            )
                        } label: {
                            tarjetaComponente(
                                nombre: item.clave,
                                info: item.info
                            )
                        }
                        .buttonStyle(DiccionarioPressStyle())
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                UIImpactFeedbackGenerator(
                                    style: .light
                                )
                                .impactOccurred()
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: 880)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var cabecera: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(colorPrincipal)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: [
                            colorPrincipal.opacity(
                                colorScheme == .dark ? 0.25 : 0.17
                            ),
                            colorSecundario.opacity(
                                colorScheme == .dark ? 0.10 : 0.06
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 17,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 17,
                        style: .continuous
                    )
                    .stroke(
                        colorPrincipal.opacity(0.28),
                        lineWidth: 1
                    )
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Componentes y conexiones")
                    .font(.headline)

                Text(
                    "\(componentesFiltrados.count) elementos disponibles"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .diccionarioGlassSurface(
            cornerRadius: 23,
            tint: colorPrincipal
        )
    }

    // MARK: - Categorías

    private var selectorCategorias: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CategoriaDiccionario.allCases) { categoria in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            categoriaSeleccionada = categoria
                        }

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: categoria.icono)
                                .font(.system(size: 12, weight: .bold))

                            Text(categoria.titulo)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            categoriaSeleccionada == categoria
                                ? Color.white
                                : Color.primary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(
                                    categoriaSeleccionada == categoria
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [
                                                    categoria.color,
                                                    categoria.color.opacity(0.70)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(
                                            colorFondoChip
                                        )
                                )
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    categoriaSeleccionada == categoria
                                        ? categoria.color.opacity(0.36)
                                        : Color.primary.opacity(0.10),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(DiccionarioPressStyle())
                    .accessibilityLabel(
                        "Mostrar categoría \(categoria.titulo)"
                    )
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Tarjeta

    private func tarjetaComponente(
        nombre: String,
        info: InfoComponente
    ) -> some View {
        let categoria = categoriaPara(
            nombre: nombre,
            icono: info.nombreImagenSF
        )

        return VStack(alignment: .leading, spacing: 11) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            categoria.color.opacity(
                                colorScheme == .dark ? 0.25 : 0.19
                            ),
                            .blue.opacity(
                                colorScheme == .dark ? 0.07 : 0.05
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 78)

                Image(systemName: info.nombreImagenSF)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(categoria.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .stroke(
                    categoria.color.opacity(0.24),
                    lineWidth: 1
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(nombreLegible(nombre))
                    .font(
                        .system(
                            size: 14,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(categoria.titulo.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(categoria.color)
                    .tracking(0.7)

                Text(info.descripcion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .padding(11)
        .frame(
            maxWidth: .infinity,
            minHeight: 191,
            alignment: .topLeading
        )
        .diccionarioGlassSurface(
            cornerRadius: 22,
            tint: categoria.color
        )
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 13) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(colorPrincipal)

            Text("No hay resultados")
                .font(.headline)

            Text(
                "No encontramos componentes para “\(textoBusqueda)”."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button("Limpiar búsqueda") {
                textoBusqueda = ""
                categoriaSeleccionada = .todas
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(colorPrincipal)
            .padding(.top, 2)
        }
        .padding(28)
        .frame(maxWidth: 330)
        .diccionarioGlassSurface(
            cornerRadius: 26,
            tint: colorPrincipal
        )
    }

    // MARK: - Filtro

    private func coincideConBusqueda(
        _ item: (clave: String, info: InfoComponente)
    ) -> Bool {
        let consulta = textoBusqueda.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )

        guard !consulta.isEmpty else {
            return true
        }

        let contenido = [
            item.clave,
            nombreLegible(item.clave),
            item.info.descripcion,
            item.info.comoConectar
        ]
        .joined(separator: " ")
        .folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )

        return contenido.contains(consulta)
    }

    private func coincideConCategoria(
        _ item: (clave: String, info: InfoComponente)
    ) -> Bool {
        guard categoriaSeleccionada != .todas else {
            return true
        }

        return categoriaPara(
            nombre: item.clave,
            icono: item.info.nombreImagenSF
        ) == categoriaSeleccionada
    }

    private func categoriaPara(
        nombre: String,
        icono: String
    ) -> CategoriaDiccionario {
        let texto = (nombre + " " + icono).lowercased()

        if texto.contains("fan") || texto.contains("ventilador") || texto.contains("disip") ||
           texto.contains("refriger") || texto.contains("radiador") || texto.contains("liquida") ||
           texto.contains("bomba") || texto.contains("bloque") || texto.contains("termica") {
            return .refrigeracion
        }

        if texto.contains("atx") || texto.contains("eps") || texto.contains("psu") ||
           texto.contains("fuente") || texto.contains("power") || texto.contains("molex") ||
           texto.contains("12vhpwr") || texto.contains("12v-2x6") || texto.contains("bolt") {
            return .alimentacion
        }

        if texto.contains("hdmi") || texto.contains("displayport") || texto.contains("usb") ||
           texto.contains("audio") || texto.contains("ethernet") || texto.contains("wifi")  || texto.contains("cmos") || texto.contains("panel") || texto.contains("cable") {
            return .conectividad
        }

        if texto.contains("sata") || texto.contains("ssd") || texto.contains("hdd") ||
           texto.contains("disco") || texto.contains("m.2") || texto.contains("nvme") {
            return .almacenamiento
        }

        if texto.contains("cpu") || texto.contains("procesador") || texto.contains("socket") {
            return .procesador
        }

        if texto.contains("ram") || texto.contains("dimm") || texto.contains("memoria") {
            return .memoria
        }

        if texto.contains("gpu") || texto.contains("grafica") || texto.contains("pcie") {
            return .graficos
        }

        return .placaYCaja
    }
    
    private func nombreLegible(_ nombre: String) -> String {
        nombre
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(
                of: "CPU",
                with: "CPU",
                options: .caseInsensitive
            )
            .replacingOccurrences(
                of: "GPU",
                with: "GPU",
                options: .caseInsensitive
            )
    }

    private var colorFondoChip: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.72)
        }

        return Color.white.opacity(0.52)
    }

    // MARK: - Fondo

    private var fondoAsistente: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.038, green: 0.040, blue: 0.048),
                        Color(red: 0.021, green: 0.023, blue: 0.030),
                        Color(red: 0.006, green: 0.007, blue: 0.012)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorPrincipal.opacity(0.13),
                        colorSecundario.opacity(0.045),
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
                        Color(red: 0.975, green: 0.982, blue: 0.995),
                        Color(red: 0.940, green: 0.956, blue: 0.982),
                        Color(red: 0.910, green: 0.930, blue: 0.965)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorPrincipal.opacity(0.14),
                        colorSecundario.opacity(0.040),
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

// MARK: - Categorías

private enum CategoriaDiccionario: String, CaseIterable, Identifiable {
    case todas
    case procesador
    case placaYCaja
    case memoria
    case graficos
    case almacenamiento
    case alimentacion
    case refrigeracion
    case conectividad

    var id: String {
        rawValue
    }

    var titulo: String {
        switch self {
        case .todas: return "Todo"
        case .procesador: return "CPU"
        case .placaYCaja: return "Placa y caja"
        case .memoria: return "Memoria"
        case .graficos: return "Gráficos"
        case .almacenamiento: return "Discos"
        case .alimentacion: return "Energía"
        case .refrigeracion: return "Refrigeración"
        case .conectividad: return "Conexiones"
        }
    }

    var icono: String {
        switch self {
        case .todas: return "square.grid.2x2.fill"
        case .procesador: return "cpu"
        case .placaYCaja: return "rectangle.3.group"
        case .memoria: return "memorychip"
        case .graficos: return "display"
        case .almacenamiento: return "internaldrive"
        case .alimentacion: return "bolt.fill"
        case .refrigeracion: return "fan.fill"
        case .conectividad: return "cable.connector"
        }
    }

    var color: Color {
        switch self {
        case .todas: return .blue
        case .procesador: return .orange
        case .placaYCaja: return .indigo
        case .memoria: return .purple
        case .graficos: return .pink
        case .almacenamiento: return .cyan
        case .alimentacion: return .yellow
        case .refrigeracion: return .teal
        case .conectividad: return .green
        }
    }
}

// MARK: - Detalle

struct DetalleComponenteInfoView: View {

    let nombre: String
    let info: InfoComponente
    let colorPrincipal: Color
    let colorSecundario: Color

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Inicializador del Detalle Reactivo
    init(
        nombre: String,
        info: InfoComponente,
        colorPrincipal: Color = Color(
            red: 0.49,
            green: 0.27,
            blue: 0.93
        ),
        colorSecundario: Color = Color(
            red: 0.88,
            green: 0.24,
            blue: 0.62
        )
    ) {
        self.nombre = nombre
        self.info = info
        self.colorPrincipal = colorPrincipal
        self.colorSecundario = colorSecundario
    }

    private var titulo: String {
        nombre.replacingOccurrences(of: "_", with: " ")
    }

    var body: some View {
        ZStack {
            fondoAsistente

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero

                    fichaDescripcion

                    fichaMontaje

                    if let clave = DatosHardware.clave(de: info, nombre: nombre) {
                        SeccionRelacionados(clave: clave, color: colorPrincipal)
                            .padding(16)
                            .diccionarioGlassSurface(cornerRadius: 24, tint: colorPrincipal)
                    }

                    fichaDificultad
                }
                .frame(maxWidth: 720)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(titulo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorPrincipal.opacity(0.27),
                                colorSecundario.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 106, height: 106)

                Circle()
                    .stroke(
                        colorPrincipal.opacity(0.30),
                        lineWidth: 1
                    )
                    .frame(width: 106, height: 106)

                Image(systemName: info.nombreImagenSF)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(colorPrincipal)
            }

            Text(titulo)
                .font(
                    .system(
                        size: 23,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .multilineTextAlignment(.center)

            Text("Ficha técnica y guía de instalación")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .diccionarioGlassSurface(
            cornerRadius: 28,
            tint: colorPrincipal
        )
    }

    private var fichaDescripcion: some View {
        BloqueDetalleDiccionario(
            icono: "info.circle.fill",
            titulo: "Descripción técnica",
            color: colorPrincipal,
            contenido: info.descripcion
        )
    }

    private var fichaMontaje: some View {
        BloqueDetalleDiccionario(
            icono: "wrench.and.screwdriver.fill",
            titulo: "Cómo instalar o conectar",
            color: .green,
            contenido: info.comoConectar
        )
    }

    private var fichaDificultad: some View {
        HStack(spacing: 12) {
            Image(systemName: "gauge.with.dots.needle.50percent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(colorDificultad)
                .frame(width: 42, height: 42)
                .background(
                    colorDificultad.opacity(0.16),
                    in: RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Nivel de montaje")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(textoDificultad)
                    .font(.headline)
            }

            Spacer(minLength: 0)

            Text("\(info.tiempoEstimadoMin) min")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .diccionarioGlassSurface(
            cornerRadius: 21,
            tint: colorDificultad
        )
    }

    private var textoDificultad: String {
        switch info.dificultad {
        case 1: return "Fácil"
        case 2: return "Intermedio"
        default: return "Avanzado"
        }
    }

    private var colorDificultad: Color {
        switch info.dificultad {
        case 1: return .green
        case 2: return .orange
        default: return .red
        }
    }

    private var fondoAsistente: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.038, green: 0.040, blue: 0.048),
                        Color(red: 0.021, green: 0.023, blue: 0.030),
                        Color(red: 0.006, green: 0.007, blue: 0.012)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorPrincipal.opacity(0.13),
                        colorSecundario.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 520
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.975, green: 0.982, blue: 0.995),
                        Color(red: 0.940, green: 0.956, blue: 0.982),
                        Color(red: 0.910, green: 0.930, blue: 0.965)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorPrincipal.opacity(0.14),
                        colorSecundario.opacity(0.040),
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

// MARK: - Bloque de detalle

private struct BloqueDetalleDiccionario: View {

    let icono: String
    let titulo: String
    let color: Color
    let contenido: String

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 9) {
                Image(systemName: icono)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(
                        color.opacity(0.15),
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                Text(titulo.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.7)
            }

            Text(contenido)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(16)
        .diccionarioGlassSurface(
            cornerRadius: 22,
            tint: color
        )
    }
}

// MARK: - Superficies compartidas

private extension View {

    func diccionarioGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            DiccionarioGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }
}

private struct DiccionarioGlassSurfaceModifier: ViewModifier {

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
                                tint.opacity(0.080),
                                .blue.opacity(0.020),
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

// MARK: - Pulsación

private struct DiccionarioPressStyle: ButtonStyle {

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
