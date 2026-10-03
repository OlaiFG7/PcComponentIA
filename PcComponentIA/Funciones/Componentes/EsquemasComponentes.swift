//
//  EsquemasComponentes.swift
//  PcComponentIA
//
//  Datos de los esquemas interactivos: un dibujo simplificado del componente con sus
//  conectores. Todas las posiciones van de 0 a 1 respecto al lienzo, así el esquema se
//  adapta a cualquier tamaño de pantalla. Para añadir un componente nuevo basta con
//  añadir una entrada a `EsquemasComponentes.todos`; la vista no hay que tocarla.
//

import SwiftUI

/// Forma decorativa del cuerpo del componente (placa, disipador, ventilador...).
struct FormaEsquema {
    enum Tipo {
        case rectangulo(radio: CGFloat)
        case circulo
        case ventilador  // círculo con aspas que giran
    }

    let tipo: Tipo
    let marco: CGRect
    let color: Color
    var etiqueta: String? = nil
}

/// Conector o zona que se puede pulsar.
struct PuntoEsquema: Identifiable {
    var id: String { nombre }

    let nombre: String
    /// Frase corta que aparece al pulsar (una línea o dos).
    let descripcion: String
    let marco: CGRect
    let color: Color
    /// Ficha del diccionario con la explicación completa (si existe).
    var claveFicha: String? = nil
}

struct EsquemaComponente {
    let titulo: String
    /// Ancho / alto del lienzo.
    let proporcion: CGFloat
    let colorFondo: Color
    let formas: [FormaEsquema]
    let puntos: [PuntoEsquema]
}

enum EsquemasComponentes {

    /// Clave de la ficha del diccionario -> esquema.
    static var todos: [String: EsquemaComponente] { _todos.valor }
    private static let _todos = PorIdioma<[String: EsquemaComponente]> {
        [
        "GPU": grafica,
        "Placa_Base": placaBase,
        "Tarjeta_Sonido": tarjetaSonido,
    ]
    }

    static func esquema(para clave: String) -> EsquemaComponente? {
        todos[clave]
    }

    private static func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    private static let oro = Color(red: 0.86, green: 0.68, blue: 0.25)
    private static let metal = Color(white: 0.62)
    private static let plasticoOscuro = Color(white: 0.16)

    // MARK: - Tarjeta gráfica (vista lateral, soporte a la izquierda)

    static var grafica: EsquemaComponente { _grafica.valor }

    private static let _grafica = PorIdioma<EsquemaComponente> {

        EsquemaComponente(
        titulo: L("Tarjeta gráfica"),
        proporcion: 2.3,
        colorFondo: Color(red: 0.10, green: 0.11, blue: 0.13),
        formas: [
            FormaEsquema(tipo: .rectangulo(radio: 0.01), marco: r(0.02, 0.05, 0.06, 0.78), color: metal,
                         etiqueta: nil),
            FormaEsquema(tipo: .rectangulo(radio: 0.03), marco: r(0.08, 0.12, 0.90, 0.66),
                         color: Color(white: 0.22), etiqueta: nil),
            FormaEsquema(tipo: .ventilador, marco: r(0.20, 0.17, 0.25, 0.56), color: Color(white: 0.30)),
            FormaEsquema(tipo: .ventilador, marco: r(0.52, 0.17, 0.25, 0.56), color: Color(white: 0.30)),
            FormaEsquema(tipo: .rectangulo(radio: 0.005), marco: r(0.08, 0.78, 0.88, 0.05),
                         color: Color(red: 0.08, green: 0.30, blue: 0.20)),
        ],
        puntos: [
            PuntoEsquema(nombre: L("Conector PCIe x16"),
                         descripcion: L("Los contactos dorados que entran en la ranura PCIe x16 de la placa."),
                         marco: r(0.22, 0.83, 0.52, 0.08), color: oro, claveFicha: "Ranura_PCIe_x16"),
            PuntoEsquema(nombre: L("Alimentación PCIe 8 pines"),
                         descripcion: L("Recibe corriente extra de la fuente. Sin este cable la gráfica no arranca."),
                         marco: r(0.80, 0.03, 0.08, 0.10), color: plasticoOscuro, claveFicha: "Cable_PCIe_GPU"),
            PuntoEsquema(nombre: L("12VHPWR / 12V-2x6"),
                         descripcion: L("Conector de 16 pines de las gráficas modernas. Debe entrar hasta el fondo."),
                         marco: r(0.66, 0.03, 0.11, 0.10), color: plasticoOscuro, claveFicha: "Conector_12VHPWR"),
            PuntoEsquema(nombre: L("HDMI"),
                         descripcion: L("Salida de vídeo y audio para monitores y televisores."),
                         marco: r(0.025, 0.14, 0.05, 0.12), color: plasticoOscuro, claveFicha: "Puerto_HDMI"),
            PuntoEsquema(nombre: L("DisplayPort"),
                         descripcion: L("Salida de vídeo habitual en monitores de PC; admite altas tasas de refresco."),
                         marco: r(0.025, 0.30, 0.05, 0.12), color: plasticoOscuro, claveFicha: "Puerto_DisplayPort"),
            PuntoEsquema(nombre: L("DisplayPort (2)"),
                         descripcion: L("Segunda salida para conectar otro monitor."),
                         marco: r(0.025, 0.46, 0.05, 0.12), color: plasticoOscuro, claveFicha: "Puerto_DisplayPort"),
            PuntoEsquema(nombre: L("Soporte metálico"),
                         descripcion: L("Se atornilla a la caja para que la gráfica no se incline ni se mueva."),
                         marco: r(0.02, 0.64, 0.06, 0.16), color: metal),
            PuntoEsquema(nombre: L("Ventiladores"),
                         descripcion: L("Enfrían la GPU. Muchos se paran en reposo: es normal."),
                         marco: r(0.36, 0.40, 0.25, 0.14), color: Color(white: 0.40)),
        ]
    )

    }

    // MARK: - Placa base ATX (vista desde arriba, panel trasero a la izquierda)

    private static let pcb = Color(red: 0.12, green: 0.14, blue: 0.16)
    private static let ranura = Color(white: 0.30)

    static var placaBase: EsquemaComponente { _placaBase.valor }

    private static let _placaBase = PorIdioma<EsquemaComponente> {

        EsquemaComponente(
        titulo: L("Placa base ATX"),
        proporcion: 0.82,
        colorFondo: Color(red: 0.07, green: 0.08, blue: 0.09),
        formas: [
            FormaEsquema(tipo: .rectangulo(radio: 0.015), marco: r(0.02, 0.02, 0.96, 0.96), color: pcb),
        ],
        puntos: [
            PuntoEsquema(nombre: L("Panel trasero (I/O)"),
                         descripcion: L("Puertos USB, red, audio y vídeo que asoman por detrás de la caja."),
                         marco: r(0.03, 0.04, 0.10, 0.30), color: metal, claveFicha: "Protector_IO"),
            PuntoEsquema(nombre: L("VRM"),
                         descripcion: L("Regulan la corriente de la CPU; van cubiertos por disipadores."),
                         marco: r(0.15, 0.04, 0.26, 0.07), color: Color(white: 0.45), claveFicha: "VRM"),
            PuntoEsquema(nombre: L("EPS 8 pines (CPU)"),
                         descripcion: L("Alimentación del procesador desde la fuente. Imprescindible."),
                         marco: r(0.15, 0.13, 0.08, 0.05), color: plasticoOscuro, claveFicha: "Conector_EPS_8p"),
            PuntoEsquema(nombre: L("Socket de la CPU"),
                         descripcion: L("Donde va el procesador. Intel (LGA) y AMD (AM4/AM5) no son compatibles entre sí."),
                         marco: r(0.26, 0.15, 0.22, 0.18), color: metal, claveFicha: "CPU"),
            PuntoEsquema(nombre: L("CPU_FAN"),
                         descripcion: L("Cabezal de 4 pines para el ventilador del disipador de la CPU."),
                         marco: r(0.50, 0.08, 0.05, 0.025), color: plasticoOscuro, claveFicha: "Conector_FAN"),
            PuntoEsquema(nombre: L("Ranuras RAM"),
                         descripcion: L("Cuatro ranuras DIMM. Con dos módulos, usa las que indique el manual (suele ser A2 y B2)."),
                         marco: r(0.58, 0.05, 0.14, 0.40), color: ranura, claveFicha: "Ranura_RAM"),
            PuntoEsquema(nombre: L("ATX 24 pines"),
                         descripcion: L("Alimentación principal de la placa. El conector más grande de la fuente."),
                         marco: r(0.88, 0.14, 0.07, 0.20), color: plasticoOscuro, claveFicha: "Conector_ATX_24p"),
            PuntoEsquema(nombre: L("USB 3.0 frontal"),
                         descripcion: L("Cabezal de 19 pines para los USB 3.0 del frontal de la caja."),
                         marco: r(0.88, 0.38, 0.06, 0.07), color: Color(red: 0.15, green: 0.30, blue: 0.70),
                         claveFicha: "Conector_USB_3_0_Front"),
            PuntoEsquema(nombre: L("M.2 (1)"),
                         descripcion: L("Ranura para SSD M.2 NVMe, el almacenamiento más rápido. Se fija con un tornillo."),
                         marco: r(0.20, 0.40, 0.38, 0.035), color: ranura, claveFicha: "Ranura_M2"),
            PuntoEsquema(nombre: L("PCIe x16"),
                         descripcion: L("Ranura para la tarjeta gráfica. Usa siempre la más cercana a la CPU."),
                         marco: r(0.08, 0.48, 0.64, 0.035), color: ranura, claveFicha: "Ranura_PCIe_x16"),
            PuntoEsquema(nombre: L("PCIe x1"),
                         descripcion: L("Ranura corta para tarjetas de red, sonido o capturadoras."),
                         marco: r(0.08, 0.57, 0.18, 0.03), color: ranura, claveFicha: "Ranura_PCIe_x1"),
            PuntoEsquema(nombre: L("Chipset"),
                         descripcion: L("Gestiona USB, SATA y otras conexiones. Va bajo un disipador plano."),
                         marco: r(0.62, 0.58, 0.16, 0.12), color: Color(white: 0.40), claveFicha: "Chipset"),
            PuntoEsquema(nombre: L("Puertos SATA"),
                         descripcion: L("Para discos duros y SSD de 2,5\". Necesitan también cable de corriente."),
                         marco: r(0.86, 0.56, 0.08, 0.16), color: Color(red: 0.12, green: 0.40, blue: 0.62),
                         claveFicha: "Puerto_SATA"),
            PuntoEsquema(nombre: L("Pila CMOS"),
                         descripcion: L("Pila de botón que guarda la hora y la configuración de la BIOS."),
                         marco: r(0.36, 0.62, 0.08, 0.065), color: Color(white: 0.75), claveFicha: "Pila_CMOS"),
            PuntoEsquema(nombre: L("M.2 (2)"),
                         descripcion: L("Segunda ranura M.2 para otro SSD."),
                         marco: r(0.20, 0.74, 0.38, 0.035), color: ranura, claveFicha: "Ranura_M2"),
            PuntoEsquema(nombre: L("Audio frontal (HD Audio)"),
                         descripcion: L("Cabezal para las tomas de auriculares y micrófono del frontal."),
                         marco: r(0.05, 0.90, 0.07, 0.035), color: plasticoOscuro, claveFicha: "Conector_HD_Audio"),
            PuntoEsquema(nombre: L("ARGB 5 V"),
                         descripcion: L("Cabezal de 3 pines para iluminación direccionable. No lo confundas con RGB 12 V."),
                         marco: r(0.15, 0.90, 0.06, 0.035), color: plasticoOscuro, claveFicha: "Conector_ARGB_5V"),
            PuntoEsquema(nombre: L("SYS_FAN"),
                         descripcion: L("Cabezal de 4 pines para ventiladores de la caja."),
                         marco: r(0.24, 0.90, 0.06, 0.035), color: plasticoOscuro, claveFicha: "Conector_SYS_FAN"),
            PuntoEsquema(nombre: L("USB 2.0 frontal"),
                         descripcion: L("Cabezal de 9 pines para los USB 2.0 del frontal."),
                         marco: r(0.40, 0.90, 0.07, 0.035), color: plasticoOscuro, claveFicha: "Conector_USB_2_0"),
            PuntoEsquema(nombre: L("USB-C frontal"),
                         descripcion: L("Conector para el USB-C del frontal de la caja."),
                         marco: r(0.62, 0.84, 0.06, 0.04), color: plasticoOscuro, claveFicha: "Conector_USB_C_Front"),
            PuntoEsquema(nombre: L("Panel frontal"),
                         descripcion: L("Pines del botón de encendido, reset y LEDs de la caja."),
                         marco: r(0.80, 0.90, 0.12, 0.04), color: plasticoOscuro, claveFicha: "Panel_Frontal_Pins"),
        ]
    )

    }

    // MARK: - Tarjeta de sonido PCIe (vista lateral)

    static var tarjetaSonido: EsquemaComponente { _tarjetaSonido.valor }

    private static let _tarjetaSonido = PorIdioma<EsquemaComponente> {

        EsquemaComponente(
        titulo: L("Tarjeta de sonido"),
        proporcion: 2.0,
        colorFondo: Color(red: 0.10, green: 0.11, blue: 0.13),
        formas: [
            FormaEsquema(tipo: .rectangulo(radio: 0.01), marco: r(0.03, 0.05, 0.07, 0.80), color: metal),
            FormaEsquema(tipo: .rectangulo(radio: 0.02), marco: r(0.10, 0.15, 0.84, 0.62),
                         color: Color(red: 0.08, green: 0.25, blue: 0.18)),
            FormaEsquema(tipo: .rectangulo(radio: 0.01), marco: r(0.40, 0.25, 0.22, 0.30),
                         color: Color(white: 0.20), etiqueta: L("DAC")),
        ],
        puntos: [
            PuntoEsquema(nombre: L("Salida de altavoces"),
                         descripcion: L("Toma de 3,5 mm (verde) para altavoces o auriculares."),
                         marco: r(0.045, 0.12, 0.045, 0.12), color: Color.green, claveFicha: "Altavoces_Auriculares"),
            PuntoEsquema(nombre: L("Entrada de micrófono"),
                         descripcion: L("Toma de 3,5 mm (rosa) para el micrófono."),
                         marco: r(0.045, 0.30, 0.045, 0.12), color: Color.pink),
            PuntoEsquema(nombre: L("Salida óptica"),
                         descripcion: L("Audio digital (S/PDIF) para barras de sonido o amplificadores."),
                         marco: r(0.045, 0.48, 0.045, 0.12), color: plasticoOscuro),
            PuntoEsquema(nombre: L("Conector PCIe x1"),
                         descripcion: L("Entra en una ranura PCIe x1 (también vale una x16 libre)."),
                         marco: r(0.14, 0.77, 0.16, 0.08), color: oro, claveFicha: "Ranura_PCIe_x1"),
            PuntoEsquema(nombre: L("Audio frontal"),
                         descripcion: L("Cabezal para llevar el sonido a las tomas del frontal de la caja."),
                         marco: r(0.80, 0.20, 0.08, 0.08), color: plasticoOscuro, claveFicha: "Conector_HD_Audio"),
            PuntoEsquema(nombre: L("Chip de audio (DAC)"),
                         descripcion: L("Convierte el sonido digital en analógico; de él depende la calidad."),
                         marco: r(0.40, 0.25, 0.22, 0.30), color: Color(white: 0.28), claveFicha: "Tarjeta_Sonido"),
        ]
    )

    }
}
