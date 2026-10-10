//
//  HomeView.swift
//  PcComponentIA
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var checklist: GestorChecklist

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass

    @AppStorage("onboardingCompletado")
    private var onboardingCompletado = false

    /// Solo se muestra el número de escaneos: se cuenta sin cargar las fotos.
    @State private var totalEscaneos = 0

    /// Para la transición de zoom de la tarjeta del escáner a la cámara
    @Namespace private var transicionEscaner

    private let diccionarioInformacion = DatosHardware.obtenerDiccionario()

    private var saludo: String {
        let hora = Calendar.current.component(.hour, from: .now)

        switch hora {
        case 6..<13:
            return L("Buenos días")

        case 13..<20:
            return L("Buenas tardes")

        default:
            return L("Buenas noches")
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                fondoAsistente

                ScrollView {
                    VStack(spacing: 22) {
                        header
                            .aparicionEscalonada(indice: 0)

                        scannerCard
                            .aparicionEscalonada(indice: 1)

                        checklistResumen
                            .aparicionEscalonada(indice: 2)

                        accesosRapidos(
                            anchoDisponible: geo.size.width - 40
                        )

                        estadisticas
                            .aparicionEscalonada(indice: 9)
                    }
                    .frame(maxWidth: 900)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .safeAreaPadding(.top, 14)

                ChecklistLateral(gestor: checklist)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .trailing
                    )
                    .padding(.bottom, 28)
                    .safeAreaPadding(.top, 108)
            }
        }
        // En iPad la barra se deja visible: lleva el botón que abre y cierra la barra lateral
        .toolbar(sizeClass == .regular ? .automatic : .hidden, for: .navigationBar)
        .onAppear {
            withAnimation(Animaciones.muelle) {
                totalEscaneos = AlmacenHistorial.contar()
            }
        }
    }

    // MARK: - Fondo

    private var fondoAsistente: some View {
        ZStack {
            fondoBase

            if colorScheme == .dark {
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

                RadialGradient(
                    colors: [
                        .cyan.opacity(0.050),
                        .clear
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 420
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

                LinearGradient(
                    colors: [
                        .white.opacity(0.30),
                        .white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var fondoBase: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
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
        }

        return LinearGradient(
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
    }

    // MARK: - Cabecera

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(saludo.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.4)

                Text("PC Component IA")
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .font(
                        .system(
                            size: 30,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)

                Text("Detecta, aprende y monta tu PC")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                botonIdioma
                botonGuia
                botonTema
            }
        }
    }

    // Cambia el idioma al momento; los nombres van en su propio idioma para reconocerlos siempre
    private var botonIdioma: some View {
        Menu {
            Picker(
                "Idioma",
                selection: Binding(
                    get: { Idioma.codigo },
                    set: { Idioma.cambiar(a: $0) }
                )
            ) {
                ForEach(Idioma.disponibles, id: \.self) { codigo in
                    Text(Idioma.nombre(de: codigo)).tag(codigo)
                }
            }
        } label: {
            // El código del idioma activo, para saber cuál está puesto sin abrir el menú
            Text(Idioma.codigo.uppercased())
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.teal)
                .frame(width: 46, height: 46)
                .homeGlassCircle()
        }
        .accessibilityLabel("Idioma")
        .accessibilityValue(Idioma.nombre(de: Idioma.codigo))
    }

    private var botonGuia: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            onboardingCompletado = false
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 46, height: 46)
                .homeGlassCircle()
        }
        .buttonStyle(HomePressStyle())
        .accessibilityLabel("Ver guía de bienvenida")
    }

    private var botonTema: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                settings.alternarTema()
            }

            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
        } label: {
            Image(
                systemName: colorScheme == .dark
                    ? "sun.max.fill"
                    : "moon.fill"
            )
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(
                colorScheme == .dark
                    ? Color.orange
                    : Color.indigo
            )
            // El sol se transforma en luna (y al revés) en lugar de cambiar de golpe
            .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp)))
            .frame(width: 46, height: 46)
            .homeGlassCircle()
        }
        .buttonStyle(HomePressStyle())
        .accessibilityLabel(
            colorScheme == .dark
                ? L("Cambiar a modo claro")
                : L("Cambiar a modo oscuro")
        )
    }

    // MARK: - Escáner

    private var scannerCard: some View {
        NavigationLink {
            ScannerView()
                .navigationTransition(.zoom(sourceID: "escaner", in: transicionEscaner))
        } label: {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.96),
                            .indigo.opacity(0.88),
                            .purple.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 180, height: 180)
                    .offset(x: 130, y: -74)

                Circle()
                    .fill(.white.opacity(0.07))
                    .frame(width: 120, height: 120)
                    .offset(x: -152, y: 82)

                HStack(spacing: 15) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundStyle(.white)
                        // "Respira" despacio para invitar a pulsar
                        .symbolEffect(.breathe.pulse, options: .repeat(.continuous))
                        .frame(width: 58, height: 58)
                        .background(
                            .white.opacity(0.16),
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
                                .white.opacity(0.32),
                                lineWidth: 1
                            )
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Iniciar escaneo")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Text("Apunta a un componente de PC")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            .white.opacity(0.15),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .stroke(
                                    .white.opacity(0.36),
                                    lineWidth: 1
                                )
                        }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 142)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
                .stroke(
                    .white.opacity(0.32),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .blue.opacity(0.24),
                radius: 16,
                y: 8
            )
            .matchedTransitionSource(id: "escaner", in: transicionEscaner) { origen in
                origen.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .buttonStyle(HomePressStyle())
    }

    // MARK: - Checklist

    private var checklistResumen: some View {
        HStack(spacing: 13) {
            Image(systemName: "checklist")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
                .frame(width: 46, height: 46)
                .background(
                    .green.opacity(0.16),
                    in: Circle()
                )
                .overlay {
                    Circle()
                        .stroke(
                            .green.opacity(0.25),
                            lineWidth: 1
                        )
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(checklist.nombreBuildActiva.map { L("Montaje: \($0)") } ?? L("Montaje de tu PC"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(
                    "\(checklist.completados) de \(checklist.pasosRequeridos) pasos completados"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("\(Int(checklist.progreso * 100))%")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(.green)
                .contentTransition(.numericText(value: checklist.progreso))
                .animation(Animaciones.muelle, value: checklist.progreso)
        }
        .padding(14)
        .homeGlassSurface(
            cornerRadius: 22,
            tint: .green
        )
    }

    // MARK: - Accesos

    private func accesosRapidos(
        anchoDisponible: CGFloat
    ) -> some View {
        let pantallaAncha = anchoDisponible >= 620

        // Modificado a una rejilla dinámica o de 3 columnas en móviles para acomodar el nuevo botón de forma equilibrada
        // Adaptable: en iPad en vertical o a pantalla partida, 2 columnas se estiraban y 6 se apretaban
        let columnas = [
            GridItem(
                .adaptive(minimum: pantallaAncha ? 130 : 150),
                spacing: 10
            )
        ]

        return VStack(alignment: .leading, spacing: 11) {
            Text("Explorar")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            LazyVGrid(columns: columnas, spacing: 10) {
                AccesoRapidoCompacto(
                    icono: "books.vertical.fill",
                    titulo: "Historial",
                    color: Color(
                        red: 0.18,
                        green: 0.48,
                        blue: 0.96
                    ),
                    destino: AnyView(HistorialView())
                )
                .aparicionEscalonada(indice: 3)

                AccesoRapidoCompacto(
                    icono: "character.book.closed.fill",
                    titulo: "Diccionario",
                    color: Color(
                        red: 0.49,
                        green: 0.27,
                        blue: 0.93
                    ),
                    destino: AnyView(
                        DiccionarioView(
                            diccionario: diccionarioInformacion
                        )
                    )
                )
                .aparicionEscalonada(indice: 4)

                AccesoRapidoCompacto(
                    icono: "wrench.and.screwdriver.fill",
                    titulo: "Guías",
                    color: Color(
                        red: 0.10,
                        green: 0.55,
                        blue: 0.90
                    ),
                    destino: AnyView(GuiasMontajeView())
                )
                .aparicionEscalonada(indice: 5)

                AccesoRapidoCompacto(
                    icono: "cube.transparent.fill",
                    titulo: "Piezas 3D",
                    color: Color(
                        red: 0.05,
                        green: 0.62,
                        blue: 0.72
                    ),
                    destino: AnyView(GuiasVisualesView())
                )
                .aparicionEscalonada(indice: 5)

                AccesoRapidoCompacto(
                    icono: "viewfinder",
                    titulo: "Detectables",
                    color: Color(
                        red: 0.02,
                        green: 0.66,
                        blue: 0.63
                    ),
                    destino: AnyView(ComponentesDetectablesView())
                )
                .aparicionEscalonada(indice: 5)

                AccesoRapidoCompacto(
                    icono: "pc",
                    titulo: "Mis Builds",
                    color: Color(
                        red: 0.16,
                        green: 0.68,
                        blue: 0.33
                    ),
                    destino: AnyView(MisBuildsView())
                )
                .aparicionEscalonada(indice: 6)

                AccesoRapidoCompacto(
                    icono: "sparkles",
                    titulo: "Asistente",
                    color: Color(
                        red: 0.88,
                        green: 0.24,
                        blue: 0.62
                    ),
                    destino: AnyView(ChatIAView())
                )
                .aparicionEscalonada(indice: 7)

                AccesoRapidoCompacto(
                    icono: "exclamationmark.triangle.fill",
                    titulo: "Error",
                    color: Color(
                        red: 0.95,
                        green: 0.37,
                        blue: 0.10
                    ),
                    destino: AnyView(DiagnosticoLedView())
                )
                .aparicionEscalonada(indice: 8)
            }
        }
    }

    // MARK: - Estadísticas

    private var estadisticas: some View {
        HStack(spacing: 10) {
            StatCard(
                icono: "checkmark.seal.fill",
                valor: "\(totalEscaneos)",
                etiqueta: "Escaneos",
                color: .green
            )

            StatCard(
                icono: "viewfinder",
                valor: "\(ComponentesDetectables.total)",
                etiqueta: "Detectables",
                color: .cyan
            )

            StatCard(
                icono: "square.grid.2x2.fill",
                valor: "\(diccionarioInformacion.count)",
                etiqueta: "Componentes",
                color: .indigo
            )
        }
    }
}

// MARK: - Acceso rápido

struct AccesoRapidoCompacto: View {

    @Environment(\.colorScheme) private var colorScheme

    let icono: String
    let titulo: String
    let color: Color
    let destino: AnyView

    var body: some View {
        NavigationLink(destination: destino) {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(
                            color.opacity(
                                colorScheme == .dark ? 0.20 : 0.13
                            )
                        )
                        .frame(width: 46, height: 46)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(
                                        colorScheme == .dark ? 0.26 : 0.72
                                    ),
                                    color.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 46, height: 46)

                    Image(systemName: icono)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                        .symbolRenderingMode(.hierarchical)
                }
                .shadow(
                    color: color.opacity(
                        colorScheme == .dark ? 0.14 : 0.10
                    ),
                    radius: 7,
                    y: 3
                )

                Text(titulo.localizado)
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 98)
            .background {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .fill(colorFondo)
            }
            .background {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(
                                colorScheme == .dark ? 0.075 : 0.56
                            ),
                            color.opacity(
                                colorScheme == .dark ? 0.055 : 0.035
                            ),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(
                                colorScheme == .dark ? 0.20 : 0.74
                            ),
                            color.opacity(
                                colorScheme == .dark ? 0.14 : 0.12
                            ),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(
                    colorScheme == .dark ? 0.20 : 0.08
                ),
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(HomePressStyle())
        .accessibilityLabel(titulo.localizado)
    }

    private var colorFondo: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.092,
                green: 0.098,
                blue: 0.120
            )
            .opacity(0.72)
        }

        return Color.white.opacity(0.52)
    }
}
// MARK: - Estadística

struct StatCard: View {

    let icono: String
    let valor: String
    let etiqueta: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icono)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 39, height: 39)
                .background(
                    color.opacity(0.15),
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .stroke(
                        color.opacity(0.22),
                        lineWidth: 1
                    )
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(valor)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                    // Los dígitos ruedan al cambiar el número
                    .contentTransition(.numericText())

                Text(etiqueta.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .homeGlassSurface(
            cornerRadius: 19,
            tint: color
        )
    }
}

// MARK: - Cristal sobrio

private extension View {

    func homeGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            HomeGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }

    func homeGlassCircle() -> some View {
        modifier(HomeGlassCircleModifier())
    }
}

private struct HomeGlassSurfaceModifier: ViewModifier {

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
                                tint.opacity(0.075),
                                .blue.opacity(0.020),
                                .clear
                            ]
                            : [
                                tint.opacity(0.070),
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

private struct HomeGlassCircleModifier: ViewModifier {

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                Circle().fill(colorFondo)
            }
            .background {
                Circle().fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                .blue.opacity(0.11),
                                .clear
                            ]
                            : [
                                .blue.opacity(0.08),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                Circle()
                    .stroke(
                        colorScheme == .dark
                            ? .white.opacity(0.16)
                            : .white.opacity(0.68),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.25)
                    : .blue.opacity(0.10),
                radius: 9,
                y: 4
            )
    }

    private var colorFondo: Color {
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
}

// MARK: - Pulsación

private struct HomePressStyle: ButtonStyle {

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
