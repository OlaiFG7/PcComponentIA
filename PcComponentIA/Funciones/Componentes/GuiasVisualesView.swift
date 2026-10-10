//
//  GuiasVisualesView.swift
//  PcComponentIA
//
//  Apartado propio para lo que se aprende mirando: los modelos 3D y el comparador
//  de conectores parecidos.
//

import SwiftUI

struct GuiasVisualesView: View {

    @Environment(\.colorScheme) private var colorScheme

    /// Clave de la pieza cuyo modelo 3D está abierto.
    @State private var piezaAbierta: PiezaConModelo?

    private struct PiezaConModelo: Identifiable {
        let id: String
        let icono: String
        let color: Color
    }

    private let piezas: [PiezaConModelo] = [
        PiezaConModelo(id: "Placa_Base", icono: "cpu", color: .purple),
        PiezaConModelo(id: "GPU", icono: "display", color: .green),
        PiezaConModelo(id: "Modulo_RAM", icono: "memorychip", color: .blue),
        PiezaConModelo(id: "M2_SSD_NVMe", icono: "internaldrive", color: .orange),
        PiezaConModelo(id: "Fuente_Alimentacion", icono: "powerplug.fill", color: .red),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                seccion(
                    titulo: L("Modelos 3D"),
                    detalle: L("Gira la pieza y toca un conector para verlo de cerca.")
                ) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Array(piezas.enumerated()), id: \.element.id) { indice, pieza in
                            if let modelo = ModelosPiezas3D.modelo(para: pieza.id) {
                                tarjetaModelo(pieza, modelo: modelo)
                                    .aparicionEscalonada(indice: indice)
                            }
                        }
                    }
                }

                seccion(
                    titulo: L("Para no confundirte"),
                    detalle: L("Conectores que se parecen y cómo distinguirlos de un vistazo.")
                ) {
                    VStack(spacing: 10) {
                        fila(
                            icono: "arrow.left.arrow.right.square.fill",
                            color: .indigo,
                            titulo: L("¿Cuál es cuál?"),
                            detalle: L("Distingue conectores parecidos: HDMI y DisplayPort, EPS y PCIe, RGB y ARGB…")
                        ) {
                            ComparadorConectoresView()
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L("Piezas en 3D"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $piezaAbierta) { pieza in
            NavigationStack {
                if let modelo = ModelosPiezas3D.modelo(para: pieza.id) {
                    VisorPieza3DView(modelo: modelo)
                }
            }
        }
    }

    private func seccion<Contenido: View>(
        titulo: String,
        detalle: String,
        @ViewBuilder contenido: () -> Contenido
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(titulo)
                    .font(.title3.bold())
                Text(detalle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            contenido()
        }
    }

    private func tarjetaModelo(_ pieza: PiezaConModelo, modelo: ModeloPieza3D) -> some View {
        Button {
            piezaAbierta = pieza
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: pieza.icono)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(pieza.color)
                    .frame(width: 48, height: 48)
                    .background(
                        pieza.color.opacity(colorScheme == .dark ? 0.2 : 0.12),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(modelo.titulo)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Label(L("\(modelo.puntos.count) conectores"), systemImage: "cube.transparent")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func fila<Destino: View>(
        icono: String,
        color: Color,
        titulo: String,
        detalle: String,
        @ViewBuilder destino: @escaping () -> Destino
    ) -> some View {
        NavigationLink {
            destino()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icono)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(
                        color.opacity(colorScheme == .dark ? 0.2 : 0.12),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(titulo)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(detalle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
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
