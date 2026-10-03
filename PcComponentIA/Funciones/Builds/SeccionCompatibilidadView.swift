//
//  SeccionCompatibilidadView.swift
//  PcComponentIA
//
//  Sección "Compatibilidad y consumo" de la ficha de una build.
//

import SwiftUI

struct SeccionCompatibilidadView: View {
    let build: Build

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let (avisos, consumo) = CompatibilidadBuild.analizar(build)

        VStack(alignment: .leading, spacing: 14) {
            Label("Compatibilidad y consumo", systemImage: "checkmark.shield")
                .font(.headline)

            if consumo.total > 75 {
                barraConsumo(consumo)
            }

            if avisos.isEmpty {
                Text("Añade el procesador, la placa base, la RAM y la fuente con su modelo para comprobar que todo encaja.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(avisos) { aviso in
                        filaAviso(aviso)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(Animaciones.muelle, value: avisos)
            }

            Text("Estimación orientativa a partir de los nombres de las piezas. Consulta siempre la web del fabricante.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04),
            in: RoundedRectangle(cornerRadius: 23, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - Consumo

    private func barraConsumo(_ consumo: EstimacionConsumo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(consumo.total) W")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(consumo.total)))
                Text("consumo estimado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Fuente recomendada")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(consumo.fuenteRecomendada) W")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
            }

            // Reparto del consumo: CPU, GPU y resto del equipo
            GeometryReader { geo in
                let total = max(Double(consumo.total), 1)
                HStack(spacing: 2) {
                    segmento(Double(consumo.cpu ?? 0) / total, ancho: geo.size.width, color: .blue)
                    segmento(Double(consumo.gpu ?? 0) / total, ancho: geo.size.width, color: .green)
                    segmento(Double(consumo.resto) / total, ancho: geo.size.width, color: .gray)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())
            .animation(Animaciones.muelle, value: consumo)

            HStack(spacing: 12) {
                leyenda("CPU", consumo.cpu, .blue)
                leyenda(L("Gráfica"), consumo.gpu, .green)
                leyenda("Resto", consumo.resto, .gray)
            }
            .font(.caption2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L("Consumo estimado \(consumo.total) vatios: procesador \(consumo.cpu.map { "\($0)" } ?? "desconocido"), ")
            + L("gráfica \(consumo.gpu.map { "\($0)" } ?? "desconocida"), resto \(consumo.resto). ")
            + L("Fuente recomendada \(consumo.fuenteRecomendada) vatios.")
        )
    }

    private func segmento(_ fraccion: Double, ancho: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color.gradient)
            .frame(width: max(0, ancho * fraccion - 2))
    }

    private func leyenda(_ texto: String, _ vatios: Int?, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(vatios.map { "\(texto) \($0) W" } ?? "\(texto) ?")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Avisos

    private func filaAviso(_ aviso: AvisoCompatibilidad) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icono(aviso.nivel))
                .font(.body.weight(.semibold))
                .foregroundStyle(color(aviso.nivel))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(aviso.titulo.localizado)
                    .font(.subheadline.weight(.semibold))
                Text(aviso.detalle.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color(aviso.nivel).opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(nombreNivel(aviso.nivel)): \(aviso.titulo). \(aviso.detalle)")
    }

    private func nombreNivel(_ nivel: AvisoCompatibilidad.Nivel) -> String {
        switch nivel {
        case .correcto: L("Correcto")
        case .info: L("Información")
        case .advertencia: L("Advertencia")
        case .error: L("Error")
        }
    }

    private func icono(_ nivel: AvisoCompatibilidad.Nivel) -> String {
        switch nivel {
        case .correcto: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .advertencia: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private func color(_ nivel: AvisoCompatibilidad.Nivel) -> Color {
        switch nivel {
        case .correcto: .green
        case .info: .blue
        case .advertencia: .orange
        case .error: .red
        }
    }
}
