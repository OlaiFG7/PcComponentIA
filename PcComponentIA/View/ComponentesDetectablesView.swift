//
//  ComponentesDetectablesView.swift
//  PcComponentIA
//

import SwiftUI

enum ComponentesDetectables {

    static let claves: Set<String> = [
        "Socket_Intel",
        "Socket_AMD",
        "CPU",
        "Ranura_PCIe_x16",
        "Ranura_RAM",
        "Pila_CMOS",
        "Protector_IO",
        "GPU",
        "Modulo_RAM",
        "Fuente_Alimentacion",
        "HDD",
        "SSD_SATA",
        "M2_SSD_NVMe",
        "Ranura_M2",
        "Puerto_SATA",
        "Ventilador_Caja",
        "Disipador_Aire",
        "Radiador",
        "Bloque_refrigeracion_liquida",
        "Conector_ATX_24p",
        "Conector_EPS_8p",
        "Placa_Base",
        "Caja_PC",
        "Puerto_HDMI",
        "Puerto_Ethernet",
        "Puerto_USB_A",
        "Puerto_USB_C",
        "Monitor",
        "Teclado",
        "Raton",
        // Bomba_Liquida y Conector_SYS_FAN se retiraron del detector (modelo 3) por falta de
        // fotos; se explican desde el bloque de líquida y el ventilador de caja (relacionados).
    ]

    static var diccionario: [String: InfoComponente] {
        DatosHardware.obtenerDiccionario().filter { clave, _ in
            claves.contains(clave)
        }
    }

    static var total: Int {
        diccionario.count
    }
}

struct ComponentesDetectablesView: View {

    var body: some View {
        DiccionarioView(
            diccionario: ComponentesDetectables.diccionario,
            colorPrincipal: Color(
                red: 0.02,
                green: 0.66,
                blue: 0.63
            ),
            colorSecundario: Color(
                red: 0.18,
                green: 0.48,
                blue: 0.96
            )
        )
    }
}
