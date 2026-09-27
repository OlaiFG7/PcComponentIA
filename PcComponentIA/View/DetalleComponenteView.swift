//
//  DetalleComponenteView.swift
//  PcComponentIA
//

import SwiftUI

struct DetalleComponenteView: View {

    let nombre: String
    let info: InfoComponente
    let lector: LectorAudio
    var onCerrar: (() -> Void)? = nil

    @EnvironmentObject private var checklist: GestorChecklist

    @State private var pasoMarcado = false

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 4)

            cabecera

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    descripcionTecnica

                    Divider()

                    guiaEnsamblaje

                    if let clave = DatosHardware.clave(de: info, nombre: nombre) {
                        SeccionRelacionados(clave: clave, color: .cyan)
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: 600, maxHeight: 420)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
            .stroke(
                Color.primary.opacity(0.15),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.2),
            radius: 20,
            y: 10
        )
        .shadow(
            color: .black.opacity(0.2),
            radius: 20,
            y: 10
        )
    }

    private var cabecera: some View {
        // Comprobamos si el componente actual tiene un paso en el checklist
        let tienePaso = checklist.tienePasoAsociado(nombre)

        return HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(0.2),
                                .blue.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: info.nombreImagenSF)
                    .font(
                        .system(
                            size: 32,
                            weight: .light
                        )
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .cyan,
                                .primary
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("COMPONENTE")
                    .font(
                        .system(
                            size: 10,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundColor(.cyan)
                    .tracking(2)

                Text(nombre.uppercased())
                    .font(
                        .system(
                            size: 22,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                // MARK: - Botón de Checklist vs. Etiqueta Informativa
                if tienePaso {
                    Button {
                        marcarComoHecho()
                    } label: {
                        Image(
                            systemName: pasoMarcado
                                ? "checkmark.circle.fill"
                                : "checkmark.circle"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            pasoMarcado
                                ? Color.white
                                : Color.green
                        )
                        .frame(width: 40, height: 40)
                        .background(
                            pasoMarcado
                                ? Color.green
                                : Color.green.opacity(0.14),
                            in: Circle()
                        )
                        .overlay {
                            Circle()
                                .stroke(
                                    Color.green.opacity(
                                        pasoMarcado ? 0.70 : 0.34
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        pasoMarcado
                            ? "Marcado como hecho en checklist"
                            : "Marcar como hecho en checklist"
                    )
                } else {
                    // Si no influye en el checklist de montaje, mostramos una píldora estética azul
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                        Text("Informativo")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color.blue.opacity(0.24), lineWidth: 1)
                    }
                }

                if let onCerrar {
                    Button {
                        onCerrar()
                    } label: {
                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Color.primary.opacity(0.1),
                                in: Circle()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cerrar detalle")
                }
            }
        }
        .padding(24)
        .background(
            Color.primary.opacity(0.04),
            in: UnevenRoundedRectangle(
                topLeadingRadius: 32,
                topTrailingRadius: 32
            )
        )
        .onAppear {
            // Inicializa el estado del tick basándose en el checklist al cargar la vista
            pasoMarcado = checklist.estaMarcado(nombre)
        }
    }

    private var descripcionTecnica: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.square.fill")
                    .foregroundColor(.cyan)

                Text("DESCRIPCIÓN TÉCNICA")
                    .font(
                        .system(
                            size: 12,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.secondary)
            }

            Text(info.descripcion)
                .font(
                    .system(
                        size: 15,
                        weight: .medium
                    )
                )
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
    }

    private var guiaEnsamblaje: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(
                    systemName: "wrench.and.screwdriver.fill"
                )
                .foregroundColor(.green)

                Text("GUÍA DE ENSAMBLAJE")
                    .font(
                        .system(
                            size: 12,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    lector.leer(
                        texto: info.comoConectar
                    )
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("LEER")
                    }
                    .font(
                        .system(
                            size: 10,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Leer guía de ensamblaje"
                )
            }

            Text(info.comoConectar)
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(16)
                .background {
                    RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                    .fill(Color.primary.opacity(0.05))
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                        .stroke(
                            Color.primary.opacity(0.1),
                            lineWidth: 1
                        )
                    }
                }
        }
    }

    private func marcarComoHecho() {
        // En lugar de forzar siempre a true, alternamos el estado usando el gestor
        let seMarco = checklist.alternarComponente(nombre)

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.75
            )
        ) {
            pasoMarcado = seMarco
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(seMarco ? .success : .warning)
    }
}
