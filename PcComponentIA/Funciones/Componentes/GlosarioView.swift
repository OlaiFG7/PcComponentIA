//
//  GlosarioView.swift
//  PcComponentIA
//
//  Siglas habituales del hardware, cada una explicada en una frase.
//

import SwiftUI

struct TerminoGlosario: Identifiable {
    var id: String { sigla }
    let sigla: String
    /// Lo que significan las letras (casi siempre en inglés, tal como se conoce).
    let significado: String
    let explicacion: String
}

enum Glosario {
    static var terminos: [TerminoGlosario] {
        [
            TerminoGlosario(sigla: "AIO", significado: "All-In-One", explicacion: L("Refrigeración líquida que viene montada y sellada de fábrica: bloque con bomba, tubos y radiador.")),
            TerminoGlosario(sigla: "ARGB", significado: "Addressable RGB", explicacion: L("Iluminación de 5 V y 3 pines en la que cada LED puede tener un color distinto.")),
            TerminoGlosario(sigla: "ATX", significado: "Advanced Technology eXtended", explicacion: L("Estándar que fija el tamaño de las placas base, las cajas y las fuentes, y sus conectores.")),
            TerminoGlosario(sigla: "BIOS", significado: "Basic Input/Output System", explicacion: L("Programa de la placa base que arranca el equipo antes que el sistema operativo y donde se ajusta el hardware.")),
            TerminoGlosario(sigla: "CMOS", significado: "Complementary Metal-Oxide-Semiconductor", explicacion: L("Memoria que guarda la hora y los ajustes de la BIOS gracias a una pila de botón. «Borrar la CMOS» los restablece.")),
            TerminoGlosario(sigla: "CPU", significado: "Central Processing Unit", explicacion: L("El procesador: hace los cálculos y coordina el resto de piezas.")),
            TerminoGlosario(sigla: "DDR", significado: "Double Data Rate", explicacion: L("Generación de la memoria RAM (DDR4, DDR5). No son compatibles entre sí.")),
            TerminoGlosario(sigla: "DIMM", significado: "Dual In-line Memory Module", explicacion: L("Formato de los módulos de RAM de sobremesa. Los de portátil son SO-DIMM, más cortos.")),
            TerminoGlosario(sigla: "DP", significado: "DisplayPort", explicacion: L("Salida de vídeo habitual en monitores de PC; admite altas resoluciones y tasas de refresco.")),
            TerminoGlosario(sigla: "EPS", significado: "Entry-level Power Supply", explicacion: L("Conector de 8 pines (4 + 4) que alimenta el procesador.")),
            TerminoGlosario(sigla: "EXPO", significado: "Extended Profiles for Overclocking", explicacion: L("Perfil de AMD que pone la RAM a su velocidad anunciada. Equivale al XMP de Intel.")),
            TerminoGlosario(sigla: "GPU", significado: "Graphics Processing Unit", explicacion: L("El chip gráfico. Se usa también para llamar a la tarjeta gráfica entera.")),
            TerminoGlosario(sigla: "HDD", significado: "Hard Disk Drive", explicacion: L("Disco duro mecánico: mucha capacidad a bajo precio, pero más lento que un SSD.")),
            TerminoGlosario(sigla: "iGPU", significado: "Integrated GPU", explicacion: L("Gráficos integrados en el procesador. Permiten tener imagen sin tarjeta gráfica.")),
            TerminoGlosario(sigla: "I/O", significado: "Input/Output", explicacion: L("Entrada y salida. El «panel I/O» es el conjunto de puertos traseros de la placa.")),
            TerminoGlosario(sigla: "LGA", significado: "Land Grid Array", explicacion: L("Socket con los pines en la placa base. Lo usan Intel y AMD AM5.")),
            TerminoGlosario(sigla: "M.2", significado: "M.2", explicacion: L("Formato pequeño y alargado para SSD (y tarjetas Wi-Fi) que se atornilla directamente a la placa.")),
            TerminoGlosario(sigla: "NVMe", significado: "Non-Volatile Memory Express", explicacion: L("Protocolo rápido de los SSD M.2 modernos. Mucho más veloz que SATA.")),
            TerminoGlosario(sigla: "PCIe", significado: "PCI Express", explicacion: L("Conexión de las ranuras de expansión (x1, x4, x16) y de los SSD NVMe.")),
            TerminoGlosario(sigla: "PGA", significado: "Pin Grid Array", explicacion: L("Socket con los pines en el procesador. Lo usa AMD AM4.")),
            TerminoGlosario(sigla: "POST", significado: "Power-On Self-Test", explicacion: L("Comprobación que hace la placa al encender. Si falla, lo indica con LEDs, códigos o pitidos.")),
            TerminoGlosario(sigla: "PSU", significado: "Power Supply Unit", explicacion: L("La fuente de alimentación.")),
            TerminoGlosario(sigla: "PWM", significado: "Pulse-Width Modulation", explicacion: L("Control preciso de la velocidad de un ventilador mediante su cuarto pin.")),
            TerminoGlosario(sigla: "QVL", significado: "Qualified Vendor List", explicacion: L("Lista del fabricante de la placa con las memorias RAM que ha probado y funcionan.")),
            TerminoGlosario(sigla: "RAM", significado: "Random Access Memory", explicacion: L("Memoria de trabajo: guarda lo que el equipo está usando y se borra al apagar.")),
            TerminoGlosario(sigla: "RGB", significado: "Red, Green, Blue", explicacion: L("Iluminación de 12 V y 4 pines en la que toda la tira tiene el mismo color.")),
            TerminoGlosario(sigla: "RPM", significado: "Revoluciones por minuto", explicacion: L("Velocidad de giro de un ventilador o de un disco duro.")),
            TerminoGlosario(sigla: "SATA", significado: "Serial ATA", explicacion: L("Conexión de discos duros y SSD de 2,5 pulgadas. Usa un cable de datos y otro de alimentación.")),
            TerminoGlosario(sigla: "SSD", significado: "Solid State Drive", explicacion: L("Unidad de almacenamiento sin partes móviles: mucho más rápida que un disco duro.")),
            TerminoGlosario(sigla: "TDP", significado: "Thermal Design Power", explicacion: L("Calor, en vatios, que el disipador debe ser capaz de evacuar. Orienta sobre el consumo.")),
            TerminoGlosario(sigla: "TPM", significado: "Trusted Platform Module", explicacion: L("Chip o función de seguridad que exigen algunos sistemas operativos, como Windows 11.")),
            TerminoGlosario(sigla: "UEFI", significado: "Unified Extensible Firmware Interface", explicacion: L("La BIOS moderna: con ratón, discos grandes y arranque seguro.")),
            TerminoGlosario(sigla: "USB", significado: "Universal Serial Bus", explicacion: L("Conexión para periféricos. El conector puede ser tipo A (rectangular) o tipo C (ovalado).")),
            TerminoGlosario(sigla: "VRM", significado: "Voltage Regulator Module", explicacion: L("Circuito de la placa que da al procesador el voltaje exacto que necesita.")),
            TerminoGlosario(sigla: "XMP", significado: "Extreme Memory Profile", explicacion: L("Perfil de Intel que pone la RAM a su velocidad anunciada. Sin activarlo, va más lenta."))
        ]
    }
}

struct GlosarioView: View {

    @State private var busqueda = ""

    private let terminos = Glosario.terminos
    private let acento = Color(red: 0.49, green: 0.27, blue: 0.93)

    private var filtrados: [TerminoGlosario] {
        let consulta = busqueda.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        guard !consulta.isEmpty else { return terminos }
        return terminos.filter {
            [$0.sigla, $0.significado.localizado, $0.explicacion]
                .joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                .contains(consulta)
        }
    }

    var body: some View {
        List {
            ForEach(filtrados) { termino in
                HStack(alignment: .top, spacing: 14) {
                    Text(termino.sigla)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(acento)
                        .frame(minWidth: 58, alignment: .leading)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(termino.significado.localizado)
                            .font(.subheadline.weight(.semibold))
                        Text(termino.explicacion)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
            }
        }
        .overlay {
            if filtrados.isEmpty {
                ContentUnavailableView(L("No hay ninguna sigla que coincida."), systemImage: "textformat.abc")
            }
        }
        .navigationTitle(L("Glosario de siglas"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $busqueda, prompt: L("Buscar sigla o palabra..."))
    }
}
