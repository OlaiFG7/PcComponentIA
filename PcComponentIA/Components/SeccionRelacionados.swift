//
//  SeccionRelacionados.swift
//  PcComponentIA
//

import SwiftUI

/// Lista desplegable de las piezas relacionadas con un componente.
/// Cada pieza se abre en el sitio (sin navegar), así funciona también dentro de la tarjeta
/// flotante del escáner.
struct SeccionRelacionados: View {

    let clave: String
    var color: Color = .orange

    @State private var abierta: String?

    private var relacionados: [(clave: String, info: InfoComponente)] {
        let diccionario = DatosHardware.obtenerDiccionario()
        return (DatosHardware.relacionados[clave] ?? []).compactMap { clave in
            diccionario[clave].map { (clave, $0) }
        }
    }

    var body: some View {
        if !relacionados.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundColor(color)

                    Text("SE CONECTA CON / RELACIONADO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }

                ForEach(relacionados, id: \.clave) { item in
                    fila(item.clave, item.info)
                }
            }
        }
    }

    private func fila(_ clave: String, _ info: InfoComponente) -> some View {
        let estaAbierta = abierta == clave

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    abierta = estaAbierta ? nil : clave
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: info.nombreImagenSF)
                        .foregroundColor(color)
                        .frame(width: 24)

                    Text(clave.replacingOccurrences(of: "_", with: " "))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(estaAbierta ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(estaAbierta ? "Ocultar explicación" : "Mostrar explicación")

            if estaAbierta {
                VStack(alignment: .leading, spacing: 6) {
                    Text(info.descripcion)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Text(info.comoConectar)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .lineSpacing(3)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
