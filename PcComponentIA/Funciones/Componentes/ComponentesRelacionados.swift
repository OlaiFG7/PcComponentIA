//
//  ComponentesRelacionados.swift
//  PcComponentIA
//

import Foundation

extension DatosHardware {

    /// Piezas relacionadas con cada componente: dónde se conecta, qué lleva dentro o qué
    /// necesita para funcionar. Sirve sobre todo para explicar piezas que la cámara no puede
    /// detectar por sí solas (p. ej. el conector SYS_FAN o la bomba de una AIO) a través de
    /// la pieza visible con la que se conectan.
    static let relacionados: [String: [String]] = [
        // Refrigeración
        "Ventilador_Caja": ["Conector_SYS_FAN", "Hub_Ventiladores", "Conector_ARGB_5V"],
        "Disipador_Aire": ["Ventilador_procesador", "Conector_FAN", "Pasta_Termica", "CPU"],
        "Bloque_refrigeracion_liquida": ["Bomba_Liquida", "Radiador", "Refrigeracion_Liquida_AIO", "Pasta_Termica"],
        "Radiador": ["Bloque_refrigeracion_liquida", "Bomba_Liquida", "Ventilador_Caja"],
        "Bomba_Liquida": ["Bloque_refrigeracion_liquida", "Radiador", "Refrigeracion_Liquida_AIO"],
        "Conector_SYS_FAN": ["Ventilador_Caja", "Hub_Ventiladores"],

        // Procesador y placa
        "Socket_CPU": ["CPU", "Socket_Intel", "Socket_AMD", "Pasta_Termica", "Disipador_Aire"],
        "CPU": ["Socket_CPU", "Pasta_Termica", "Conector_EPS_8p"],
        "Socket_Intel": ["CPU_Intel", "Pasta_Termica", "Disipador_Aire"],
        "Socket_AMD": ["CPU_AMD", "Pasta_Termica", "Disipador_Aire"],
        "Placa_Base": ["Separadores_Placa_Base", "Protector_IO", "Panel_Frontal_Pins", "Pila_CMOS", "Chipset", "VRM"],
        "Pila_CMOS": ["BIOS_UEFI"],
        "Protector_IO": ["Placa_Base", "Puerto_USB_A", "Puerto_Ethernet", "Puerto_HDMI"],

        // Memoria y expansión
        "Ranura_RAM": ["Modulo_RAM"],
        "Modulo_RAM": ["Ranura_RAM"],
        "Ranura_PCIe_x16": ["GPU", "Ranura_PCIe_x1"],
        "GPU": ["Ranura_PCIe_x16", "Cable_PCIe_GPU", "Conector_12VHPWR", "Puerto_HDMI", "Puerto_DisplayPort"],

        // Almacenamiento
        "Ranura_M2": ["M2_SSD_NVMe", "M2_SSD_SATA"],
        "M2_SSD_NVMe": ["Ranura_M2"],
        "Puerto_SATA": ["Cable_Datos_SATA", "SSD_SATA", "HDD"],
        "SSD_SATA": ["Puerto_SATA", "Cable_Datos_SATA", "Cable_Alimentacion_SATA"],
        "HDD": ["Puerto_SATA", "Cable_Datos_SATA", "Cable_Alimentacion_SATA"],

        // Alimentación
        "Fuente_Alimentacion": ["Conector_ATX_24p", "Conector_EPS_8p", "Cable_PCIe_GPU", "Conector_12VHPWR",
                                "Cable_Alimentacion_SATA", "Cable_Corriente_IEC"],
        "Conector_ATX_24p": ["Fuente_Alimentacion"],
        "Conector_EPS_8p": ["Fuente_Alimentacion", "CPU"],

        // Caja y puertos
        "Caja_PC": ["Panel_Frontal_Pins", "Conector_USB_3_0_Front", "Conector_HD_Audio", "Ventilador_Caja",
                    "Separadores_Placa_Base"],
        "Puerto_USB_A": ["Conector_USB_2_0", "Conector_USB_3_0_Front"],
        "Puerto_USB_C": ["Conector_USB_C_Front"],
        "Puerto_Ethernet": ["Tarjeta_WiFi_Bluetooth"],
        "Puerto_HDMI": ["Puerto_DisplayPort", "GPU", "Monitor"],
    ]

    /// Clave del diccionario que corresponde a una ficha. Las vistas a veces solo tienen el
    /// nombre legible ("M.2 SSD NVMe", "Ventilador Caja"): se compara sin espacios, guiones
    /// bajos ni puntos y en minúsculas. No se usa `info.id`, que puede repetirse entre fichas
    /// (p. ej. CPU y CPU_Intel).
    static func clave(de info: InfoComponente, nombre: String) -> String? {
        func normalizar(_ texto: String) -> String {
            texto.lowercased().filter { $0.isLetter || $0.isNumber }
        }
        let buscado = normalizar(nombre)
        return obtenerDiccionario().keys.first { normalizar($0) == buscado }
    }
}
