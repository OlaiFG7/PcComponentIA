//
//  VisualizadorARView.swift
//  PcComponentIA
//

import SwiftUI

struct VisualizadorARView: View {

    let rectPlaca: CGRect
    let componente: String
    let tamanoContenedor: CGSize
    let onCerrar: () -> Void
    

    @State private var animarPulso = false

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                Color.cyan.opacity(0.62),
                style: StrokeStyle(
                    lineWidth: 1.5,
                    dash: [7, 5]
                )
            )
            .frame(
                width: rectPlaca.width,
                height: rectPlaca.height
            )
            .position(
                x: rectPlaca.midX,
                y: rectPlaca.midY
            )
            .allowsHitTesting(false)

            if let guia = obtenerGuiaParaComponente(componente) {
                let layout = calcularCoordenadasRelativas(
                    en: rectPlaca,
                    para: guia.zona
                )

                Path { path in
                    path.move(
                        to: CGPoint(
                            x: rectPlaca.midX,
                            y: rectPlaca.midY
                        )
                    )

                    path.addLine(
                        to: layout.centro
                    )
                }
                .stroke(
                    guia.color.opacity(0.42),
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [5, 5]
                    )
                )
                .allowsHitTesting(false)

                ZStack {
                    RoundedRectangle(
                        cornerRadius: layout.esRedonda ? 999 : 10,
                        style: .continuous
                    )
                    .stroke(
                        guia.color.opacity(0.92),
                        lineWidth: 2.2
                    )
                    .frame(
                        width: layout.ancho,
                        height: layout.alto
                    )

                    RoundedRectangle(
                        cornerRadius: layout.esRedonda ? 999 : 10,
                        style: .continuous
                    )
                    .fill(guia.color.opacity(0.16))
                    .frame(
                        width: max(1, layout.ancho - 4),
                        height: max(1, layout.alto - 4)
                    )

                    RoundedRectangle(
                        cornerRadius: layout.esRedonda ? 999 : 10,
                        style: .continuous
                    )
                    .stroke(
                        guia.color.opacity(0.55),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: layout.ancho,
                        height: layout.alto
                    )
                    .scaleEffect(animarPulso ? 1.25 : 1)
                    .opacity(animarPulso ? 0 : 1)
                }
                .position(
                    x: layout.centro.x,
                    y: layout.centro.y
                )
                .allowsHitTesting(false)

                cartelaGuia(
                    guia: guia,
                    layout: layout
                )
            }
        }
        .onAppear {
            animarPulso = false

            withAnimation(
                .easeOut(duration: 1.35)
                .repeatForever(autoreverses: false)
            ) {
                animarPulso = true
            }
        }
        .onDisappear {
            animarPulso = false
        }
    }

    private func cartelaGuia(
        guia: DatosGuiaAR,
        layout: LayoutGuia
    ) -> some View {
        let usarLadoIzquierdo =
            layout.centro.x > rectPlaca.midX

        let desplazamientoX: CGFloat =
            usarLadoIzquierdo ? -118 : 118

        let xPropuesto = layout.centro.x + desplazamientoX
        let anchoCartela: CGFloat = 184
        let margenHorizontal: CGFloat = 12

        let xMinimo = (anchoCartela / 2) + margenHorizontal
        let xMaximo = tamanoContenedor.width
            - (anchoCartela / 2)
            - margenHorizontal

        let xSeguro = min(
            max(xMinimo, xPropuesto),
            max(xMinimo, xMaximo)
        )
        let yPropuesto = layout.centro.y - 72
        let ySeguro = max(105, yPropuesto)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: guia.icono)
                    .font(.caption.weight(.bold))

                Text(guia.titulo.uppercased())
                    .font(
                        .system(
                            size: 10,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(guia.color)

            Text(guia.instruccion.localizado)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Text("ZONA APROXIMADA")
                .font(
                    .system(
                        size: 8,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .tracking(0.7)
                .foregroundStyle(.white.opacity(0.56))

            Button {
                onCerrar()
            } label: {
                Label(
                    "Ocultar guía",
                    systemImage: "eye.slash"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    guia.color.opacity(0.32),
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
        .padding(11)
        .frame(width: 184, alignment: .leading)
        .background(
            .black.opacity(0.82),
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                guia.color.opacity(0.62),
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.35),
            radius: 9,
            y: 4
        )
        .position(
            x: xSeguro,
            y: ySeguro
        )
    }

    // MARK: - Guía

    private enum ZonaPlaca {
        case socketCPU
        case ranurasRAM
        case ranuraPCIe
        case puertosSATA
        case puertoM2
    }

    private struct DatosGuiaAR {
        let titulo: String
        let instruccion: String
        let zona: ZonaPlaca
        let color: Color
        let icono: String
    }

    private struct LayoutGuia {
        let centro: CGPoint
        let ancho: CGFloat
        let alto: CGFloat
        let esRedonda: Bool
    }

    private func obtenerGuiaParaComponente(
        _ componente: String
    ) -> DatosGuiaAR? {
        let texto = normalizar(componente)

        if texto.contains("cpu") ||
            texto.contains("procesador") ||
            texto.contains("socket") {
            return DatosGuiaAR(
                titulo: L("Socket de CPU"),
                instruccion: L("Levanta la palanca, alinea el triángulo de la CPU y déjala caer sin presionar."),
                zona: .socketCPU,
                color: .cyan,
                icono: "cpu.fill"
            )
        }

        if texto.contains("ram") ||
            texto.contains("memoria") ||
            texto.contains("modulo") {
            return DatosGuiaAR(
                titulo: L("Ranuras de memoria"),
                instruccion: L("Coloca primero la RAM en A2. Si instalas dos módulos, usa A2 y B2. Confirma las marcas impresas en tu placa."),
                zona: .ranurasRAM,
                color: .green,
                icono: "memorychip.fill"
            )
        }

        if texto.contains("gpu") ||
            texto.contains("grafica") ||
            texto.contains("pcie") {
            return DatosGuiaAR(
                titulo: L("PCIe x16 principal"),
                instruccion: L("Inserta la tarjeta gráfica hasta oír un clic y después fíjala al chasis con sus tornillos."),
                zona: .ranuraPCIe,
                color: .orange,
                icono: "display"
            )
        }

        if texto.contains("m2") ||
            texto.contains("nvme") {
            return DatosGuiaAR(
                titulo: L("Ranura M.2"),
                instruccion: L("Inserta el SSD inclinado unos 30 grados, bájalo con cuidado y usa el tornillo o anclaje."),
                zona: .puertoM2,
                color: .teal,
                icono: "internaldrive.fill"
            )
        }

        if texto.contains("sata") ||
            texto.contains("hdd") ||
            texto.contains("ssd") {
            return DatosGuiaAR(
                titulo: L("Puertos SATA"),
                instruccion: L("Conecta aquí el cable SATA de datos que sale de tu SSD o HDD de 2.5/3.5 pulgadas."),
                zona: .puertosSATA,
                color: .yellow,
                icono: "cable.connector"
            )
        }

        return nil
    }

    private func calcularCoordenadasRelativas(
        en rect: CGRect,
        para zona: ZonaPlaca
    ) -> LayoutGuia {
        switch zona {
        case .socketCPU:
            return LayoutGuia(
                centro: CGPoint(
                    x: rect.minX + rect.width * 0.42,
                    y: rect.minY + rect.height * 0.34
                ),
                ancho: rect.width * 0.27,
                alto: rect.width * 0.27,
                esRedonda: false
            )

        case .ranurasRAM:
            return LayoutGuia(
                centro: CGPoint(
                    x: rect.minX + rect.width * 0.72,
                    y: rect.minY + rect.height * 0.36
                ),
                ancho: rect.width * 0.18,
                alto: rect.height * 0.36,
                esRedonda: false
            )

        case .ranuraPCIe:
            return LayoutGuia(
                centro: CGPoint(
                    x: rect.minX + rect.width * 0.47,
                    y: rect.minY + rect.height * 0.68
                ),
                ancho: rect.width * 0.66,
                alto: max(12, rect.height * 0.08),
                esRedonda: false
            )

        case .puertoM2:
            return LayoutGuia(
                centro: CGPoint(
                    x: rect.minX + rect.width * 0.45,
                    y: rect.minY + rect.height * 0.50
                ),
                ancho: rect.width * 0.36,
                alto: max(11, rect.height * 0.075),
                esRedonda: false
            )

        case .puertosSATA:
            return LayoutGuia(
                centro: CGPoint(
                    x: rect.minX + rect.width * 0.85,
                    y: rect.minY + rect.height * 0.74
                ),
                ancho: rect.width * 0.18,
                alto: rect.width * 0.18,
                esRedonda: true
            )
        }
    }

    private func normalizar(
        _ texto: String
    ) -> String {
        texto
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
