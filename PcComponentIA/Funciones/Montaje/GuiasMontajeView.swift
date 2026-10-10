//
//  GuiasMontajeView.swift
//  PcComponentIA
//
//  Las guías paso a paso de los puntos más delicados del montaje.
//

import SwiftUI

struct GuiasMontajeView: View {

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("Lo más delicado del montaje, paso a paso y con dibujos."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)

                fila(
                    icono: "cpu.fill",
                    color: .cyan,
                    titulo: L("Procesador y disipador"),
                    detalle: L("Abrir el socket, colocar el procesador, pasta térmica y disipador."),
                    pasos: 9
                ) {
                    GuiaMontajeCPUView()
                }
                .aparicionEscalonada(indice: 0)

                fila(
                    icono: "memorychip.fill",
                    color: Color(red: 0.35, green: 0.62, blue: 1.0),
                    titulo: L("Memoria RAM"),
                    detalle: L("Qué ranuras usar y cómo encajarla sin forzar."),
                    pasos: 5
                ) {
                    GuiaMontajeRAMView()
                }
                .aparicionEscalonada(indice: 1)

                fila(
                    icono: "display",
                    color: Color(red: 0.30, green: 0.82, blue: 0.48),
                    titulo: L("Tarjeta gráfica"),
                    detalle: L("Insertarla, atornillarla, darle corriente y conectar el monitor."),
                    pasos: 6
                ) {
                    GuiaMontajeGPUView()
                }
                .aparicionEscalonada(indice: 2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L("Guías de montaje"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func fila<Destino: View>(
        icono: String,
        color: Color,
        titulo: String,
        detalle: String,
        pasos: Int,
        @ViewBuilder destino: @escaping () -> Destino
    ) -> some View {
        NavigationLink {
            destino()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icono)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 56, height: 56)
                    .background(
                        color.opacity(colorScheme == .dark ? 0.2 : 0.12),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(titulo)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(detalle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    Text(L("\(pasos) pasos"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}
