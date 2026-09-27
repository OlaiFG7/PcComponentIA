//
//  ChatIAView.swift
//  PcComponentIA
//

import SwiftUI

struct ChatIAView: View {

    // Propiedades e inicializador personalizado
    let consultaInicial: String?
    let enviarConsultaInicialAutomaticamente: Bool

    init(
        consultaInicial: String? = nil,
        enviarConsultaInicialAutomaticamente: Bool = false
    ) {
        self.consultaInicial = consultaInicial
        self.enviarConsultaInicialAutomaticamente = enviarConsultaInicialAutomaticamente
    }
    
    @EnvironmentObject private var checklist: GestorChecklist
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var controladorIA = ControladorIA()
    @State private var pregunta = ""
    @State private var mostrarHistorialChats = false
    @State private var mostrarConfirmarBorrado = false

    // Control del envío inicial automatizado
    @State private var consultaInicialEnviada = false
    @FocusState private var campoActivo: Bool

    private let sugerencias = [
        "¿Qué PSU necesito para una RTX 5090?",
        "¿Es compatible mi RAM con esta placa?",
        "Ayúdame a montar el disipador",
        "¿Cómo aplico correctamente la pasta térmica?",
        "¿Qué orden sigo para montar un PC desde cero?",
        "¿Cómo evito el cuello de botella CPU-GPU?"
    ]

    // MARK: - Paleta

    private var colorAsistente: Color {
        Color(
            red: 0.88,
            green: 0.24,
            blue: 0.62
        )
    }

    private var colorAsistenteSecundario: Color {
        Color(
            red: 0.49,
            green: 0.27,
            blue: 0.93
        )
    }

    private var colorPeligro: Color {
        Color(
            red: 0.92,
            green: 0.24,
            blue: 0.22
        )
    }

    private var degradadoAsistente: LinearGradient {
        LinearGradient(
            colors: [
                colorAsistente,
                colorAsistenteSecundario
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            fondoTema

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if controladorIA.mensajes.isEmpty {
                            estadoVacio
                        }

                        ForEach(controladorIA.mensajes) { mensaje in
                            burbujaMensaje(mensaje)
                                .id(mensaje.id)
                        }

                        if controladorIA.estaPensando {
                            indicadorPensando
                                .id("pensando")
                        }

                        Color.clear
                            .frame(height: 2)
                            .id("final")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    barraDeEntrada
                }
                .onChange(of: controladorIA.mensajes.count) { _, _ in
                    scrollAlFinal(con: proxy, animado: true)
                }
                .onChange(of: controladorIA.estaPensando) { _, pensando in
                    if pensando {
                        scrollAlFinal(con: proxy, animado: true)
                    }
                }
                .onChange(of: controladorIA.conversacionActualID) { _, _ in
                    scrollAlFinal(con: proxy, animado: false)
                }
            }

            ChecklistLateral(gestor: checklist)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .trailing
                )
                .padding(.top, 116)
                .padding(.bottom, 28)
        }
        .task {
            enviarConsultaInicialSiCorresponde()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                encabezadoToolbar
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                botonToolbar(
                    icono: "square.and.pencil",
                    color: colorAsistente,
                    etiqueta: "Nueva conversación"
                ) {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()

                    controladorIA.nuevaConversacion()
                }

                botonToolbar(
                    icono: "line.3.horizontal",
                    color: colorAsistenteSecundario,
                    etiqueta: "Historial de conversaciones"
                ) {
                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()

                    mostrarHistorialChats = true
                }

                botonToolbar(
                    icono: "trash",
                    color: colorPeligro,
                    etiqueta: "Borrar conversación",
                    deshabilitado: controladorIA.mensajes.isEmpty
                ) {
                    mostrarConfirmarBorrado = true
                }
            }
        }
        .sheet(isPresented: $mostrarHistorialChats) {
            HistorialChatsView(
                controladorIA: controladorIA,
                mostrar: $mostrarHistorialChats
            )
        }
        .alert(
            "Borrar esta conversación",
            isPresented: $mostrarConfirmarBorrado
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Borrar", role: .destructive) {
                controladorIA.borrarHistorial()
            }
        } message: {
            Text("Se eliminarán los mensajes de esta conversación.")
        }
    }

    // MARK: - Fondo

    private var fondoTema: some View {
        ZStack {
            fondoBase

            if colorScheme == .dark {
                RadialGradient(
                    colors: [
                        .white.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 460
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        .white.opacity(0.52),
                        .clear
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
                        red: 0.024,
                        green: 0.025,
                        blue: 0.031
                    ),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [
                Color(
                    red: 0.980,
                    green: 0.984,
                    blue: 0.992
                ),
                Color(
                    red: 0.950,
                    green: 0.956,
                    blue: 0.970
                ),
                Color(
                    red: 0.920,
                    green: 0.930,
                    blue: 0.950
                )
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Barra superior

    private var encabezadoToolbar: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(degradadoAsistente)
                    .frame(width: 31, height: 31)
                    .overlay {
                        Circle()
                            .stroke(
                                .white.opacity(0.36),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: colorAsistente.opacity(0.22),
                        radius: 7,
                        y: 3
                    )

                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Asistente IA")
                    .font(
                        .system(
                            size: 15,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text("En el dispositivo")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func botonToolbar(
        icono: String,
        color: Color,
        etiqueta: String,
        deshabilitado: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icono)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    deshabilitado
                        ? Color.secondary.opacity(0.45)
                        : color
                )
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(colorFondoBotonToolbar)
                )
                .overlay {
                    Circle()
                        .stroke(
                            Color.primary.opacity(0.12),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(ChatPressStyle())
        .disabled(deshabilitado)
        .accessibilityLabel(etiqueta)
    }

    private var colorFondoBotonToolbar: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.09)
        }

        return Color.white.opacity(0.72)
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorAsistente.opacity(0.22),
                                colorAsistenteSecundario.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)
                    .overlay {
                        Circle()
                            .stroke(
                                colorAsistente.opacity(0.28),
                                lineWidth: 1
                            )
                    }

                Image(systemName: "sparkles")
                    .font(.system(size: 33, weight: .semibold))
                    .foregroundStyle(degradadoAsistente)
            }

            VStack(spacing: 6) {
                Text("¿En qué te ayudo hoy?")
                    .font(
                        .system(
                            size: 21,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text(
                    "Compatibilidad, rendimiento, presupuestos\ny guías de montaje"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            VStack(spacing: 9) {
                ForEach(sugerencias, id: \.self) { texto in
                    Button {
                        pregunta = texto
                        campoActivo = true

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(colorAsistente)
                                .frame(width: 29, height: 29)
                                .background(
                                    colorAsistente.opacity(
                                        colorScheme == .dark ? 0.18 : 0.12
                                    ),
                                    in: Circle()
                                )

                            Text(texto)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                            Spacer(minLength: 0)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, height: 30)
                                .background(
                                    colorFondoIconoSecundario,
                                    in: Circle()
                                )
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 11)
                        .surfaceChat(
                            cornerRadius: 18,
                            tint: colorAsistente,
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(ChatPressStyle())
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }

    private var colorFondoIconoSecundario: Color {
        if colorScheme == .dark {
            return .white.opacity(0.085)
        }

        return .black.opacity(0.055)
    }

    // MARK: - Mensajes

    private var avatarIA: some View {
        ZStack {
            Circle()
                .fill(degradadoAsistente)
                .frame(width: 28, height: 28)
                .overlay {
                    Circle()
                        .stroke(
                            .white.opacity(0.34),
                            lineWidth: 1
                        )
                }

            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(
            color: colorAsistente.opacity(0.20),
            radius: 5,
            y: 2
        )
    }

    private var indicadorPensando: some View {
        HStack(alignment: .top, spacing: 9) {
            avatarIA

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { indice in
                    Circle()
                        .fill(.secondary.opacity(0.58))
                        .frame(width: 6, height: 6)
                        .scaleEffect(
                            controladorIA.estaPensando
                                ? 1
                                : 0.45
                        )
                        .animation(
                            .easeInOut(duration: 0.58)
                            .repeatForever()
                            .delay(Double(indice) * 0.14),
                            value: controladorIA.estaPensando
                        )
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .surfaceChat(
                cornerRadius: 19,
                tint: colorAsistente,
                colorScheme: colorScheme
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func burbujaMensaje(
        _ mensaje: MensajeChat
    ) -> some View {
        HStack(alignment: .top, spacing: 9) {
            if mensaje.esUsuario {
                Spacer(minLength: 48)
            } else {
                avatarIA
            }

            VStack(
                alignment: mensaje.esUsuario ? .trailing : .leading,
                spacing: 5
            ) {
                Text(mensaje.texto)
                    .font(.system(size: 15))
                    .foregroundStyle(
                        mensaje.esUsuario
                            ? Color.white
                            : Color.primary
                    )
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .background {
                        if mensaje.esUsuario {
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                            .fill(degradadoAsistente)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 20,
                                    style: .continuous
                                )
                                .stroke(
                                    .white.opacity(0.28),
                                    lineWidth: 1
                                )
                            }
                        } else {
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                            .fill(colorFondoMensajeIA)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 20,
                                    style: .continuous
                                )
                                .stroke(
                                    Color.primary.opacity(0.10),
                                    lineWidth: 1
                                )
                            }
                        }
                    }

                Text(mensaje.fecha, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.70))
                    .padding(.horizontal, 6)
            }

            if !mensaje.esUsuario {
                Spacer(minLength: 48)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: mensaje.esUsuario ? .trailing : .leading
        )
    }

    private var colorFondoMensajeIA: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.115,
                green: 0.118,
                blue: 0.140
            )
        }

        return Color.white.opacity(0.86)
    }

    // MARK: - Entrada

    private var barraDeEntrada: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                "Escribe tu pregunta...",
                text: $pregunta,
                axis: .vertical
            )
            .font(.system(size: 15))
            .foregroundStyle(.primary)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
            .lineLimit(1...5)
            .focused($campoActivo)
            .submitLabel(.send)
            .onSubmit {
                enviarPregunta()
            }
            .background(
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .fill(colorFondoEntrada)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    campoActivo
                        ? colorAsistente.opacity(0.68)
                        : Color.primary.opacity(0.12),
                    lineWidth: campoActivo ? 1.5 : 1
                )
            }

            Button {
                enviarPregunta()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        Circle()
                            .fill(colorBotonEnviar)
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                .white.opacity(0.36),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: preguntaLimpia.isEmpty
                            ? .clear
                            : colorAsistente.opacity(0.24),
                        radius: 8,
                        y: 4
                    )
            }
            .buttonStyle(ChatPressStyle())
            .disabled(
                preguntaLimpia.isEmpty ||
                controladorIA.estaPensando
            )
            .accessibilityLabel("Enviar pregunta")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(colorFondoBarraEntrada)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 1)
                }
        }
    }

    private var colorFondoEntrada: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.108,
                green: 0.111,
                blue: 0.130
            )
        }

        return Color.white.opacity(0.88)
    }

    private var colorFondoBarraEntrada: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.045,
                green: 0.047,
                blue: 0.056
            )
            .opacity(0.97)
        }

        return Color.white.opacity(0.93)
    }

    private var preguntaLimpia: String {
        pregunta.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var colorBotonEnviar: LinearGradient {
        if preguntaLimpia.isEmpty || controladorIA.estaPensando {
            return LinearGradient(
                colors: [
                    .gray.opacity(0.38),
                    .gray.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return degradadoAsistente
    }

    // MARK: - Acciones

    private func enviarPregunta() {
        let texto = preguntaLimpia

        guard !texto.isEmpty,
              !controladorIA.estaPensando
        else {
            return
        }

        UIImpactFeedbackGenerator(style: .medium)
            .impactOccurred()

        pregunta = ""
        controladorIA.consultarIA(pregunta: texto)
    }

    private func enviarConsultaInicialSiCorresponde() {
        guard enviarConsultaInicialAutomaticamente,
              !consultaInicialEnviada,
              let consultaInicial else {
            return
        }

        let texto = consultaInicial.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !texto.isEmpty else {
            return
        }

        consultaInicialEnviada = true
        campoActivo = false
        
        controladorIA.nuevaConversacion()
        controladorIA.consultarIA(pregunta: texto)
    }

    private func scrollAlFinal(
        con proxy: ScrollViewProxy,
        animado: Bool
    ) {
        DispatchQueue.main.async {
            if animado {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo("final", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("final", anchor: .bottom)
            }
        }
    }
    
}

// MARK: - Superficies

private extension View {

    func surfaceChat(
        cornerRadius: CGFloat,
        tint: Color,
        colorScheme: ColorScheme
    ) -> some View {
        let forma = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

        return self
            .background {
                forma.fill(
                    colorScheme == .dark
                        ? Color(
                            red: 0.075,
                            green: 0.082,
                            blue: 0.105
                        )
                        .opacity(0.72)
                        : Color.white.opacity(0.52)
                )
            }
            .background {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                tint.opacity(0.075),
                                .white.opacity(0.025),
                                .clear
                            ]
                            : [
                                tint.opacity(0.055),
                                .white.opacity(0.42),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                forma.stroke(
                    LinearGradient(
                        colors: [
                          .white.opacity(
                              colorScheme == .dark ? 0.18 : 0.70
                          ),
                          tint.opacity(
                              colorScheme == .dark ? 0.14 : 0.11
                          ),
                          .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.24)
                    : tint.opacity(0.08),
                radius: 10,
                y: 5
            )
    }
}

// MARK: - Pulsación

private struct ChatPressStyle: ButtonStyle {

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
