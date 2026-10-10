//
//  OnboardingView.swift
//  PcComponentIA
//

import SwiftUI

struct PuntoOnboarding: Identifiable {
    var id: String { texto }
    let icono: String
    let texto: String
}

struct PaginaOnboarding: Identifiable {
    let id: Int
    let icono: String
    /// Iconos pequeños que flotan alrededor del principal
    let satelites: [String]
    let color: Color
    let etiqueta: String
    let titulo: String
    let descripcion: String
    /// Tres cosas concretas que se pueden hacer en esa parte de la app
    let puntos: [PuntoOnboarding]

    static var todas: [PaginaOnboarding] {
        [
            PaginaOnboarding(
                id: 0,
                icono: "camera.viewfinder",
                satelites: ["photo.on.rectangle", "cpu", "memorychip"],
                color: Color(red: 0.02, green: 0.66, blue: 0.63),
                etiqueta: L("ESCÁNER INTELIGENTE"),
                titulo: L("Identifica tu hardware"),
                descripcion: L("Apunta la cámara a una pieza y la app te dice qué es, sin conexión."),
                puntos: [
                    PuntoOnboarding(icono: "camera.fill", texto: L("En directo con la cámara o desde una foto de tu galería")),
                    PuntoOnboarding(icono: "hand.tap.fill", texto: L("Toca una pieza detectada para abrir su ficha")),
                    PuntoOnboarding(icono: "clock.arrow.circlepath", texto: L("Tus capturas se guardan en el historial"))
                ]
            ),
            PaginaOnboarding(
                id: 1,
                icono: "character.book.closed.fill",
                satelites: ["cube.transparent", "cable.connector", "magnifyingglass"],
                color: Color(red: 0.49, green: 0.27, blue: 0.93),
                etiqueta: L("DICCIONARIO Y 3D"),
                titulo: L("Aprende mientras montas"),
                descripcion: L("Cada componente, conector y puerto explicado con palabras sencillas."),
                puntos: [
                    PuntoOnboarding(icono: "book.pages.fill", texto: L("Fichas con descripción y guía de montaje")),
                    PuntoOnboarding(icono: "cube.transparent.fill", texto: L("Modelos 3D: toca un conector y la cámara se acerca a él")),
                    PuntoOnboarding(icono: "link", texto: L("Qué se conecta con qué, pieza a pieza"))
                ]
            ),
            PaginaOnboarding(
                id: 2,
                icono: "checklist",
                satelites: ["wrench.and.screwdriver.fill", "bolt.fill", "checkmark.seal.fill"],
                color: Color(red: 0.18, green: 0.48, blue: 0.96),
                etiqueta: L("GUÍA DE MONTAJE"),
                titulo: L("Monta paso a paso"),
                descripcion: L("Una lista clara para instalar cada pieza en el orden correcto."),
                puntos: [
                    PuntoOnboarding(icono: "list.bullet.clipboard.fill", texto: L("Un checklist propio para cada build")),
                    PuntoOnboarding(icono: "checkmark.circle.fill", texto: L("Marca pasos desde el escáner o desde una ficha")),
                    PuntoOnboarding(icono: "power", texto: L("Te avisa de lo esencial antes de encender"))
                ]
            ),
            PaginaOnboarding(
                id: 3,
                icono: "pc",
                satelites: ["eurosign.circle.fill", "bolt.shield.fill", "square.and.arrow.up.fill"],
                color: Color(red: 0.16, green: 0.68, blue: 0.33),
                etiqueta: L("MIS CONFIGURACIONES"),
                titulo: L("Organiza tus builds"),
                descripcion: L("Guarda tus equipos con sus piezas, precios y notas."),
                puntos: [
                    PuntoOnboarding(icono: "checkmark.shield.fill", texto: L("Comprueba si el procesador, la placa y la RAM son compatibles")),
                    PuntoOnboarding(icono: "bolt.fill", texto: L("Calcula el consumo y la fuente recomendada")),
                    PuntoOnboarding(icono: "square.and.arrow.up", texto: L("Comparte la build como texto o imagen"))
                ]
            ),
            PaginaOnboarding(
                id: 4,
                icono: "stethoscope.circle.fill",
                satelites: ["lightbulb.led.fill", "number.square.fill", "speaker.wave.2.fill"],
                color: Color(red: 0.95, green: 0.37, blue: 0.1),
                etiqueta: L("DIAGNÓSTICO DE ARRANQUE"),
                titulo: L("Diagnostica fallos de arranque"),
                descripcion: L("Si tu PC no arranca, la app te ayuda a encontrar el motivo."),
                puntos: [
                    PuntoOnboarding(icono: "lightbulb.led.fill", texto: L("LEDs de la placa: CPU, DRAM, VGA y BOOT")),
                    PuntoOnboarding(icono: "number.square.fill", texto: L("Códigos POST de ASUS, Gigabyte, MSI y ASRock")),
                    PuntoOnboarding(icono: "speaker.wave.2.fill", texto: L("Pitidos de la BIOS (AMI y Award)"))
                ]
            ),
            PaginaOnboarding(
                id: 5,
                icono: "sparkles",
                satelites: ["mic.fill", "globe", "ipad.and.iphone"],
                color: Color(red: 0.88, green: 0.24, blue: 0.62),
                etiqueta: L("ASISTENTE Y MÁS"),
                titulo: L("Consulta al asistente IA"),
                descripcion: L("Pregunta lo que quieras sobre compatibilidad, montaje o averías."),
                puntos: [
                    PuntoOnboarding(icono: "lock.shield.fill", texto: L("Funciona en tu dispositivo: tus preguntas no salen de él")),
                    PuntoOnboarding(icono: "text.bubble.fill", texto: L("Sabe qué build o diagnóstico estás viendo")),
                    PuntoOnboarding(icono: "globe", texto: L("En español e inglés, y también con Siri y Atajos"))
                ]
            )
        ]
    }
}

struct OnboardingView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    @AppStorage("onboardingCompletado")
    private var completado = false

    @State private var paginaActual = 0
    @State private var haloActivo = false

    private let paginas = PaginaOnboarding.todas

    var body: some View {
        ZStack {
            fondoOnboarding

            VStack(spacing: 0) {
                cabecera

                TabView(selection: $paginaActual) {
                    ForEach(
                        Array(paginas.enumerated()),
                        id: \.offset
                    ) { indice, pagina in
                        paginaContenido(
                            pagina,
                            indice: indice
                        )
                        .tag(indice)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pie
            }
            .safeAreaPadding(.top, 14)
        }
        .onAppear {
            guard !reducirMovimiento else {
                return
            }

            withAnimation(
                .easeInOut(duration: 5.5)
                .repeatForever(autoreverses: true)
            ) {
                haloActivo = true
            }
        }
    }

    // MARK: - Cabecera

    private var cabecera: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(
                        Color(
                            red: 0.02,
                            green: 0.66,
                            blue: 0.63
                        )
                    )                    .frame(width: 30, height: 30)
                    .background(
                        Color(
                            red: 0.02,
                            green: 0.66,
                            blue: 0.63
                        )
                        .opacity(
                            colorScheme == .dark ? 0.15 : 0.10
                        ),
                        in: Circle()
                    )

                Text("PcComponentIA")
                    .font(
                        .system(
                            size: 16,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button("Saltar") {
                finalizarOnboarding()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                colorControl,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        Color.primary.opacity(
                            colorScheme == .dark ? 0.13 : 0.09
                        ),
                        lineWidth: 1
                    )
            }
            .buttonStyle(OnboardingPressStyle())
            .accessibilityLabel("Saltar bienvenida")
        }
        .padding(.horizontal, 22)
    }

    // MARK: - Página

    private func paginaContenido(
        _ pagina: PaginaOnboarding,
        indice: Int
    ) -> some View {
        // Con letra grande o en un iPhone pequeño el contenido no cabe: se puede desplazar
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 24) {
                    iconoPrincipal(
                        pagina,
                        indice: indice
                    )

                    VStack(spacing: 12) {
                        etiquetaFuncion(para: pagina)

                        Text(pagina.titulo)
                            .font(
                                .system(
                                    size: 28,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text(pagina.descripcion)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .accessibilityElement(children: .combine)

                    tarjetaPuntos(
                        pagina,
                        indice: indice
                    )
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }

    private func etiquetaFuncion(
        para pagina: PaginaOnboarding
    ) -> some View {
        Text(pagina.etiqueta)
            .font(.caption2.weight(.bold))
            .tracking(0.9)
            .foregroundStyle(pagina.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                pagina.color.opacity(
                    colorScheme == .dark ? 0.15 : 0.10
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        pagina.color.opacity(0.24),
                        lineWidth: 1
                    )
            }
    }

    /// Los tres puntos de la página, que entran uno tras otro al llegar a ella.
    private func tarjetaPuntos(
        _ pagina: PaginaOnboarding,
        indice: Int
    ) -> some View {
        let visible = paginaActual == indice

        return VStack(alignment: .leading, spacing: 14) {
            ForEach(
                Array(pagina.puntos.enumerated()),
                id: \.element.id
            ) { orden, punto in
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: punto.icono)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(pagina.color)
                        .frame(width: 36, height: 36)
                        .background(
                            pagina.color.opacity(
                                colorScheme == .dark ? 0.18 : 0.12
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 11,
                                style: .continuous
                            )
                        )
                        .accessibilityHidden(true)

                    Text(punto.texto)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .opacity(visible || reducirMovimiento ? 1 : 0)
                .offset(y: visible || reducirMovimiento ? 0 : 10)
                .animation(
                    reducirMovimiento
                        ? nil
                        : .spring(response: 0.45, dampingFraction: 0.82)
                            .delay(0.12 + Double(orden) * 0.09),
                    value: visible
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            colorControl,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.13 : 0.09
                ),
                lineWidth: 1
            )
        }
    }

    private func iconoPrincipal(
        _ pagina: PaginaOnboarding,
        indice: Int
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    pagina.color.opacity(
                        colorScheme == .dark ? 0.13 : 0.11
                    )
                )
                .frame(width: 190, height: 190)
                .scaleEffect(
                    !reducirMovimiento
                    && paginaActual == indice
                    && haloActivo
                        ? 1.10
                        : 1
                )
                .blur(radius: 2)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            pagina.color.opacity(
                                colorScheme == .dark ? 0.30 : 0.18
                            ),
                            .blue.opacity(
                                colorScheme == .dark ? 0.08 : 0.04
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 142, height: 142)

            Circle()
                .stroke(
                    pagina.color.opacity(
                        colorScheme == .dark ? 0.55 : 0.38
                    ),
                    lineWidth: 1
                )
                .frame(width: 142, height: 142)

            Circle()
                .stroke(
                    .white.opacity(
                        colorScheme == .dark ? 0.16 : 0.46
                    ),
                    lineWidth: 1
                )
                .frame(width: 128, height: 128)

            Image(systemName: pagina.icono)
                .font(.system(size: 54, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            pagina.color,
                            pagina.color.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .shadow(
                    color: pagina.color.opacity(0.30),
                    radius: 14,
                    y: 6
                )
                .symbolEffect(
                    .bounce,
                    options: .nonRepeating,
                    value: paginaActual == indice
                )

            // Iconos pequeños alrededor, que flotan despacio
            ForEach(
                Array(pagina.satelites.enumerated()),
                id: \.offset
            ) { orden, simbolo in
                let angulo = Angle.degrees(-150 + Double(orden) * 120)
                let flota = !reducirMovimiento && haloActivo && paginaActual == indice

                Image(systemName: simbolo)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(pagina.color)
                    .frame(width: 42, height: 42)
                    .background(colorControl, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(
                                pagina.color.opacity(0.30),
                                lineWidth: 1
                            )
                    }
                    .offset(
                        x: cos(angulo.radians) * 98,
                        y: sin(angulo.radians) * 98 + (flota ? (orden.isMultiple(of: 2) ? -6 : 6) : 0)
                    )
            }
        }
        .frame(width: 240, height: 240)
        .accessibilityHidden(true)
    }

    // MARK: - Pie

    private var pie: some View {
        VStack(spacing: 18) {
            indicadorPaginas

            Text(
                "\(paginaActual + 1) de \(paginas.count)"
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary.opacity(0.85))

            Button {
                siguientePagina()
            } label: {
                HStack(spacing: 9) {
                    Text(
                        paginaActual == paginas.count - 1
                            ? L("Empezar a explorar")
                            : "Continuar"
                    )

                    Image(
                        systemName: paginaActual == paginas.count - 1
                            ? "arrow.right.circle.fill"
                            : "arrow.right"
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .bold
                        )
                    )
                }
                .font(
                    .system(
                        size: 16,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            colorBotonActual,
                            colorBotonActual.opacity(0.73)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(
                            .white.opacity(0.18),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: colorBotonActual.opacity(0.28),
                    radius: 13,
                    y: 7
                )
            }
            .buttonStyle(OnboardingPressStyle())
            .accessibilityLabel(
                paginaActual == paginas.count - 1
                    ? L("Finalizar bienvenida")
                    : L("Ir a la siguiente página")
            )
        }
        .padding(.horizontal, 28)
        .safeAreaPadding(.bottom, 16)
    }

    private var indicadorPaginas: some View {
        HStack(spacing: 8) {
            ForEach(paginas.indices, id: \.self) { indice in
                Capsule()
                    .fill(
                        indice == paginaActual
                            ? colorBotonActual
                            : Color.primary.opacity(
                                colorScheme == .dark ? 0.18 : 0.14
                            )
                    )
                    .frame(
                        width: indice == paginaActual ? 27 : 7,
                        height: 7
                    )
                    .animation(
                        reducirMovimiento
                            ? nil
                            : .spring(
                                response: 0.30,
                                dampingFraction: 0.78
                            ),
                        value: paginaActual
                    )
            }
        }
        .accessibilityLabel(
            "Página \(paginaActual + 1) de \(paginas.count)"
        )
    }

    // MARK: - Acciones

    private func siguientePagina() {
        UIImpactFeedbackGenerator(style: .medium)
            .impactOccurred()

        if paginaActual < paginas.count - 1 {
            withAnimation(
                reducirMovimiento
                    ? .linear(duration: 0.01)
                    : .spring(
                        response: 0.42,
                        dampingFraction: 0.84
                    )
            ) {
                paginaActual += 1
            }
        } else {
            finalizarOnboarding()
        }
    }

    private func finalizarOnboarding() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)

        withAnimation(
            reducirMovimiento
                ? .linear(duration: 0.01)
                : .easeInOut(duration: 0.25)
        ) {
            completado = true
        }
    }

    // MARK: - Colores

    private var colorBotonActual: Color {
        paginas[paginaActual].color
    }

    private var colorControl: Color {
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

    private var fondoOnboarding: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.038,
                            green: 0.040,
                            blue: 0.050
                        ),
                        Color(
                            red: 0.016,
                            green: 0.019,
                            blue: 0.030
                        ),
                        Color(
                            red: 0.004,
                            green: 0.006,
                            blue: 0.011
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorBotonActual.opacity(0.18),
                        .blue.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 540
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.978,
                            green: 0.985,
                            blue: 1.0
                        ),
                        Color(
                            red: 0.944,
                            green: 0.962,
                            blue: 0.990
                        ),
                        Color(
                            red: 0.908,
                            green: 0.929,
                            blue: 0.970
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorBotonActual.opacity(0.16),
                        .cyan.opacity(0.04),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 540
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Pulsación

private struct OnboardingPressStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed ? 0.975 : 1
            )
            .opacity(
                configuration.isPressed ? 0.88 : 1
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
