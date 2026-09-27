//
//  HistorialChatsView.swift
//  PcComponentIA
//

import SwiftUI

struct HistorialChatsView: View {

    @ObservedObject var controladorIA: ControladorIA
    @Binding var mostrar: Bool

    @Environment(\.colorScheme) private var colorScheme

    @State private var mostrarAjustes = false
    @State private var mostrarConfirmarBorrarTodo = false

    // CAMBIO 1: Estados añadidos para el control de selección múltiple
    @State private var modoSeleccion = false
    @State private var conversacionesSeleccionadas: Set<UUID> = []
    @State private var mostrarConfirmarBorrarSeleccionadas = false

    private var conversacionesOrdenadas: [ConversacionChat] {
        controladorIA.conversaciones.sorted {
            $0.fechaActualizacion > $1.fechaActualizacion
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                fondoAsistente

                Group {
                    if controladorIA.conversaciones.isEmpty {
                        estadoVacio
                    } else {
                        contenido
                    }
                }
            }
            // CAMBIO 2: Título dinámico según la cantidad de salas marcadas
            .navigationTitle(
                modoSeleccion
                    ? "\(conversacionesSeleccionadas.count) seleccionadas"
                    : "Conversaciones"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                // CAMBIO 3: Toolbar con botón condicional de Cancelar / Cerrar
                ToolbarItem(placement: .topBarLeading) {
                    if modoSeleccion {
                        Button("Cancelar") {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                modoSeleccion = false
                                conversacionesSeleccionadas.removeAll()
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                    } else {
                        Button("Cerrar") {
                            mostrar = false
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }

                // ToolbarItemGroup adaptado para ocultar y revelar acciones según el modo
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !modoSeleccion {
                        Button {
                            mostrarAjustes = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("Configurar borrado automático")

                        Button {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()

                            controladorIA.nuevaConversacion()
                            mostrar = false
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel("Nueva conversación")
                    }

                    if !controladorIA.conversaciones.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                modoSeleccion.toggle()

                                if !modoSeleccion {
                                    conversacionesSeleccionadas.removeAll()
                                }
                            }

                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                        } label: {
                            Image(
                                systemName: modoSeleccion
                                    ? "checkmark.circle.fill"
                                    : "checkmark.circle"
                            )
                            .font(.system(size: 16, weight: .semibold))
                        }
                        .accessibilityLabel(
                            modoSeleccion
                                ? "Finalizar selección"
                                : "Seleccionar conversaciones"
                        )
                    }

                    if modoSeleccion {
                        Button(role: .destructive) {
                            mostrarConfirmarBorrarSeleccionadas = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .disabled(conversacionesSeleccionadas.isEmpty)
                        .accessibilityLabel("Eliminar conversaciones seleccionadas")
                    }
                }
            }
            .sheet(isPresented: $mostrarAjustes) {
                AjustesRetencionChatView(
                    controladorIA: controladorIA
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert(
                "¿Eliminar todas las conversaciones?",
                isPresented: $mostrarConfirmarBorrarTodo
            ) {
                Button("Cancelar", role: .cancel) {}

                Button("Eliminar todo", role: .destructive) {
                    controladorIA.borrarTodoElHistorial()

                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.success)
                }
            } message: {
                Text(
                    "Se eliminarán todas las conversaciones guardadas. Esta acción no se puede deshacer."
                )
            }
            // CAMBIO 4: Alerta añadida para confirmar el borrado de la selección
            .alert(
                "¿Eliminar conversaciones seleccionadas?",
                isPresented: $mostrarConfirmarBorrarSeleccionadas
            ) {
                Button("Cancelar", role: .cancel) {}

                Button("Eliminar", role: .destructive) {
                    eliminarConversacionesSeleccionadas()

                    UINotificationFeedbackGenerator()
                        .notificationOccurred(.success)
                }
            } message: {
                Text(
                    "Se eliminarán \(conversacionesSeleccionadas.count) conversaciones. Esta acción no se puede deshacer."
                )
            }
        }
    }

    // MARK: - Contenido

    private var contenido: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                resumen

                Text("Historial")
                    .font(.headline)
                    .foregroundStyle(.primary)

                LazyVStack(spacing: 9) {
                    ForEach(conversacionesOrdenadas) { conversacion in
                        tarjetaConversacion(conversacion)
                    }
                }

                if !modoSeleccion {
                    botonBorrarTodo
                }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var resumen: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [
                            .orange.opacity(
                                colorScheme == .dark ? 0.25 : 0.16
                            ),
                            .red.opacity(
                                colorScheme == .dark ? 0.10 : 0.05
                            )
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
                        .orange.opacity(0.28),
                        lineWidth: 1
                    )
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(
                    controladorIA.conversaciones.count == 1
                        ? "1 conversación guardada"
                        : "\(controladorIA.conversaciones.count) conversaciones guardadas"
                )
                .font(.subheadline.weight(.bold))

                Text(
                    "Selecciona una para continuar donde lo dejaste."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .chatHistoryGlassSurface(
            cornerRadius: 22,
            tint: .orange
        )
    }

    // MARK: - Tarjetas

    // CAMBIO 5: Tarjeta rediseñada para soportar estados de selección y color de acento
    private func tarjetaConversacion(
        _ conversacion: ConversacionChat
    ) -> some View {
        let esActual = conversacion.id == controladorIA.conversacionActualID
        let tituloLimpio = conversacion.titulo.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let estaSeleccionada = conversacionesSeleccionadas.contains(
            conversacion.id
        )

        let colorAcento = Color(
            red: 0.88,
            green: 0.24,
            blue: 0.62
        )

        return Button {
            tocarConversacion(conversacion)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                    .fill(
                        estaSeleccionada
                            ? colorAcento.opacity(
                                colorScheme == .dark ? 0.24 : 0.15
                            )
                            : Color.primary.opacity(
                                colorScheme == .dark ? 0.075 : 0.05
                            )
                    )

                    Image(
                        systemName: modoSeleccion
                            ? (
                                estaSeleccionada
                                    ? "checkmark"
                                    : "circle"
                            )
                            : "message.fill"
                        )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            estaSeleccionada
                                ? Color.white
                                : (
                                    esActual
                                        ? colorAcento
                                        : Color.secondary
                                )
                        )
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        tituloLimpio.isEmpty
                            ? "Nueva conversación"
                            : tituloLimpio
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                    Text(
                        conversacion.fechaActualizacion,
                        format: .dateTime
                            .day()
                            .month(.abbreviated)
                            .year()
                            .hour()
                            .minute()
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if !modoSeleccion {
                    if esActual {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(colorAcento)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(12)
            .background {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    estaSeleccionada
                        ? colorAcento.opacity(
                            colorScheme == .dark ? 0.15 : 0.09
                        )
                        : (
                            esActual
                                ? colorAcento.opacity(
                                    colorScheme == .dark ? 0.10 : 0.06
                                )
                                : Color.primary.opacity(
                                    colorScheme == .dark ? 0.050 : 0.030
                                )
                        )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    estaSeleccionada
                        ? colorAcento.opacity(0.70)
                        : (
                            esActual
                                ? colorAcento.opacity(0.42)
                                : Color.primary.opacity(
                                    colorScheme == .dark ? 0.10 : 0.07
                                )
                        ),
                    lineWidth: estaSeleccionada ? 1.6 : 1
                )
            }
        }
        .buttonStyle(ChatHistoryPressStyle())
        .contextMenu {
            if !modoSeleccion {
                Button(role: .destructive) {
                    controladorIA.eliminarConversacion(conversacion.id)
                } label: {
                    Label(
                        "Eliminar conversación",
                        systemImage: "trash"
                    )
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.42) {
            guard !modoSeleccion else {
                return
            }

            UIImpactFeedbackGenerator(style: .medium)
                .impactOccurred()

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.82
                )
            ) {
                modoSeleccion = true
                conversacionesSeleccionadas.insert(conversacion.id)
            }
        }
    }

    private var botonBorrarTodo: some View {
        Button(role: .destructive) {
            mostrarConfirmarBorrarTodo = true
        } label: {
            Label(
                "Eliminar todas las conversaciones",
                systemImage: "trash"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                .red.opacity(
                    colorScheme == .dark ? 0.12 : 0.08
                ),
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    .red.opacity(0.25),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(ChatHistoryPressStyle())
        .padding(.top, 4)
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .orange.opacity(0.22),
                                .red.opacity(0.07)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(
                        .orange.opacity(0.26),
                        lineWidth: 1
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 6) {
                Text("Aún no hay conversaciones")
                    .font(.title3.bold())

                Text(
                    "Empieza una conversación con el asistente\ny volverá a aparecer guardada aquí."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Button {
                controladorIA.nuevaConversacion()
                mostrar = false
            } label: {
                Label(
                    "Nueva conversación",
                    systemImage: "square.and.pencil"
                )
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [.orange, .red.opacity(0.82)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
            .buttonStyle(ChatHistoryPressStyle())
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: 370)
        .chatHistoryGlassSurface(
            cornerRadius: 27,
            tint: .orange
        )
        .padding(20)
    }

    // CAMBIO 6: Funciones de interacción táctil y borrado múltiple integradas
    private func tocarConversacion(
        _ conversacion: ConversacionChat
    ) {
        if modoSeleccion {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            withAnimation(.easeOut(duration: 0.16)) {
                if conversacionesSeleccionadas.contains(conversacion.id) {
                    conversacionesSeleccionadas.remove(conversacion.id)
                } else {
                    conversacionesSeleccionadas.insert(conversacion.id)
                }
            }

            return
        }

        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()

        controladorIA.seleccionarConversacion(conversacion.id)
        mostrar = false
    }

    private func eliminarConversacionesSeleccionadas() {
        guard !conversacionesSeleccionadas.isEmpty else {
            return
        }

        let ids = conversacionesSeleccionadas

        withAnimation(.easeOut(duration: 0.20)) {
            for id in ids {
                controladorIA.eliminarConversacion(id)
            }

            conversacionesSeleccionadas.removeAll()
            modoSeleccion = false
        }
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
                        .orange.opacity(0.13),
                        .red.opacity(0.035),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 520
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
                        .orange.opacity(0.13),
                        .yellow.opacity(0.045),
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

// MARK: - Retención

struct AjustesRetencionChatView: View {

    @ObservedObject var controladorIA: ControladorIA

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                fondoAjustes

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        explicacion

                        VStack(spacing: 9) {
                            ForEach(RetencionHistorial.allCases) { opcion in
                                filaOpcion(opcion)
                            }
                        }
                    }
                    .frame(maxWidth: 620)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Borrado automático")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private var explicacion: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 48, height: 48)
                .background(
                    .orange.opacity(0.16),
                    in: RoundedRectangle(
                        cornerRadius: 15,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text("Gestiona tu historial")
                    .font(.subheadline.weight(.bold))

                Text(
                    "Las conversaciones antiguas se eliminarán al abrir el asistente."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .chatHistoryGlassSurface(
            cornerRadius: 21,
            tint: .orange
        )
    }

    private func filaOpcion(
        _ opcion: RetencionHistorial
    ) -> some View {
        let estaSeleccionada = controladorIA.retencion == opcion

        return Button {
            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()

            withAnimation(.easeInOut(duration: 0.18)) {
                controladorIA.retencion = opcion
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconoRetencion(opcion))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        estaSeleccionada
                            ? Color.orange
                            : Color.secondary
                    )
                    .frame(width: 40, height: 40)
                    .background(
                        estaSeleccionada
                            ? Color.orange.opacity(
                                colorScheme == .dark ? 0.19 : 0.12
                            )
                            : Color.primary.opacity(
                                colorScheme == .dark ? 0.07 : 0.045
                            ),
                        in: RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                    )

                Text(opcion.etiqueta)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Image(
                    systemName: estaSeleccionada
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    estaSeleccionada
                        ? Color.orange
                        : Color.secondary.opacity(0.55)
                )
            }
            .padding(12)
            .background {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    estaSeleccionada
                        ? Color.orange.opacity(
                            colorScheme == .dark ? 0.12 : 0.075
                        )
                        : Color.primary.opacity(
                            colorScheme == .dark ? 0.050 : 0.030
                        )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    estaSeleccionada
                        ? Color.orange.opacity(0.45)
                        : Color.primary.opacity(
                            colorScheme == .dark ? 0.10 : 0.07
                        ),
                    lineWidth: estaSeleccionada ? 1.4 : 1
                )
            }
        }
        .buttonStyle(ChatHistoryPressStyle())
    }

    private func iconoRetencion(
        _ opcion: RetencionHistorial
    ) -> String {
        switch opcion {
        case .nunca:
            return "infinity"

        case .dias7:
            return "calendar"

        case .dias30:
            return "calendar.badge.clock"

        case .dias90:
            return "clock.arrow.circlepath"
        }
    }

    private var fondoAjustes: some View {
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
                            red: 0.012,
                            green: 0.015,
                            blue: 0.022
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .orange.opacity(0.12),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 440
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
                            red: 0.918,
                            green: 0.937,
                            blue: 0.970
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .orange.opacity(0.12),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 440
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Cristal

private extension View {

    func chatHistoryGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            ChatHistoryGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }
}

private struct ChatHistoryGlassSurfaceModifier: ViewModifier {

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
                forma.fill(
                    colorScheme == .dark
                        ? Color(
                            red: 0.075,
                            green: 0.082,
                            blue: 0.105
                        )
                        .opacity(0.68)
                        : Color.white.opacity(0.50)
                )
            }
            .background {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                tint.opacity(0.08),
                                .clear
                            ]
                            : [
                                tint.opacity(0.065),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                forma.stroke(
                    colorScheme == .dark
                        ? .white.opacity(0.15)
                        : .white.opacity(0.66),
                    lineWidth: 1
                )
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.25)
                    : tint.opacity(0.08),
                radius: 11,
                y: 5
            )
    }
}

private struct ChatHistoryPressStyle: ButtonStyle {

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
