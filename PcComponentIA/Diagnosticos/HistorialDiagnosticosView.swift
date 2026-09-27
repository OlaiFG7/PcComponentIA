//
//  HistorialDiagnosticosView.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 17/07/2026.
//

import SwiftUI

struct HistorialDiagnosticosView: View {

    @EnvironmentObject private var gestor: GestorDiagnosticos

    var body: some View {
        Group {
            if gestor.registros.isEmpty {
                ContentUnavailableView(
                    "Sin diagnósticos guardados",
                    systemImage: "stethoscope",
                    description: Text(
                        "Guarda un resultado LED o POST para consultarlo después."
                    )
                )
            } else {
                List {
                    ForEach(gestor.registros) { registro in
                        NavigationLink {
                            DetalleDiagnosticoGuardadoView(
                                registro: registro
                            )
                        } label: {
                            fila(registro)
                        }
                    }
                    .onDelete(perform: gestor.eliminarEn)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Diagnósticos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fila(
        _ registro: RegistroDiagnostico
    ) -> some View {
        HStack(spacing: 12) {
            Image(
                systemName: registro.tipo == .led
                    ? "circle.grid.2x2.fill"
                    : "number.square.fill"
            )
            .foregroundStyle(colorEstado(registro.estado))
            .frame(width: 32, height: 32)
            .background(
                colorEstado(registro.estado).opacity(0.14),
                in: RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(registro.tituloResultado)
                    .font(.headline)

                Text(
                    "\(registro.tipo.rawValue) · \(registro.codigoOIndicador) · \(registro.marcaPlaca)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(registro.fecha, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(registro.estado.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorEstado(registro.estado))
        }
    }

    private func colorEstado(
        _ estado: EstadoRegistroDiagnostico
    ) -> Color {
        switch estado {
        case .pendiente:
            return .orange
        case .enProceso:
            return .blue
        case .resuelto:
            return .green
        }
    }
}
