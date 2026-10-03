//
//  OnboardingView.swift
//  PcComponentIA
//

import SwiftUI

struct PaginaOnboarding: Identifiable {
    let id = UUID()
    let icono: String
    let color: Color
    let titulo: String
    let descripcion: String
    let detalle: String
}

struct OnboardingView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    @AppStorage("onboardingCompletado")
    private var completado = false

    @State private var paginaActual = 0
    @State private var haloActivo = false

    private let paginas: [PaginaOnboarding] = [
        PaginaOnboarding(
            icono: "camera.viewfinder",
            color: Color(
                red: 0.02,
                green: 0.66,
                blue: 0.63
            ),
            titulo: L("Identifica tu hardware"),
            descripcion: L("""
            Apunta la cámara a un componente y deja que
            la IA te ayude a reconocerlo.
            """),
            detalle: L("""
            Guarda tus capturas detectadas para consultarlas después
            desde el historial de escaneos.
            """)
        ),
        PaginaOnboarding(
            icono: "checklist",
            color: Color(
                red: 0.18,
                green: 0.48,
                blue: 0.96
            ),
            titulo: L("Monta paso a paso"),
            descripcion: L("""
            Sigue una lista clara para instalar los componentes
            de tu PC en el orden correcto.
            """),
            detalle: L("""
            Marca cada paso como completado y detecta rápidamente
            qué pieza, cable o conexión te falta.
            """)
        ),
        PaginaOnboarding(
            icono: "character.book.closed.fill",
            color: Color(
                red: 0.49,
                green: 0.27,
                blue: 0.93
            ),
            titulo: L("Aprende mientras montas"),
            descripcion: L("""
            Consulta el diccionario con explicaciones técnicas
            y guías de conexión de cada componente.
            """),
            detalle: L("""
            Encuentra información sobre sockets, conectores, RAM,
            almacenamiento, refrigeración y mucho más.
            """)
        ),
        PaginaOnboarding(
            icono: "stethoscope.circle.fill",
            color: Color(
                red: 0.95,
                green: 0.37,
                blue: 0.10
            ),
            titulo: L("Diagnostica fallos de arranque"),
            descripcion: L("""
            Consulta LEDs Q-LED, EZ Debug y códigos POST
            mostrados por tu placa base.
            """),
            detalle: L("""
            Revisa los pasos recomendados, guarda el diagnóstico
            y controla si está pendiente, en proceso o resuelto.
            """)
        ),
        PaginaOnboarding(
            icono: "sparkles",
            color: Color(
                red: 0.88,
                green: 0.24,
                blue: 0.62
            ),
            titulo: L("Consulta al asistente IA"),
            descripcion: L("""
            Pregunta sobre compatibilidad, montaje, rendimiento
            o problemas con tus componentes.
            """),
            detalle: L("""
            Desde un diagnóstico, el asistente recibe automáticamente
            el LED o código POST y los pasos que ya has comprobado.
            """)
        ),
        PaginaOnboarding(
            icono: "pc",
            color: Color(
                red: 0.16,
                green: 0.68,
                blue: 0.33
            ),
            titulo: L("Organiza tus builds"),
            descripcion: L("""
            Guarda tus equipos con componentes, precios,
            estado y notas personales.
            """),
            detalle: L("""
            Ten cada configuración reunida en un solo lugar antes
            de comprar, montar, mejorar o reparar tu PC.
            """)
        )
    ]
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
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            iconoPrincipal(
                pagina,
                indice: indice
            )

            Spacer()
                .frame(height: 34)

            VStack(spacing: 12) {
                etiquetaFuncion(
                    para: pagina,
                    indice: indice
                )

                Text(pagina.titulo.localizado)
                    .font(
                        .system(
                            size: 28,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(pagina.descripcion.localizado)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                Text(pagina.detalle.localizado)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 3)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: 560)

            Spacer(minLength: 28)
        }
        .padding(.top, 8)
    }

    private func etiquetaFuncion(
        para pagina: PaginaOnboarding,
        indice: Int
    ) -> some View {
        Text(textoEtiqueta(indice))
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

    private func textoEtiqueta(
        _ indice: Int
    ) -> String {
        switch indice {
        case 0:
            return L("ESCÁNER INTELIGENTE")

        case 1:
            return L("GUÍA DE MONTAJE")

        case 2:
            return L("DICCIONARIO DE HARDWARE")

        case 3:
            return L("DIAGNÓSTICO DE ARRANQUE")

        case 4:
            return L("ASISTENTE TÉCNICO")

        default:
            return L("MIS CONFIGURACIONES")
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
                .frame(width: 210, height: 210)
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
        }
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
