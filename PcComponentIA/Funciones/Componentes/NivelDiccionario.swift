//
//  NivelDiccionario.swift
//  PcComponentIA
//
//  Nivel de detalle del diccionario: quien empieza ve solo las piezas principales,
//  y quien sabe más puede subirlo para ver conectores, cabezales y componentes internos.
//

import Foundation

enum NivelDiccionario: Int, CaseIterable, Identifiable {
    case basico = 1
    case intermedio
    case experto

    static let claveGuardado = "nivelDiccionario"

    var id: Int { rawValue }

    var titulo: String {
        switch self {
        case .basico: return L("Básico")
        case .intermedio: return L("Intermedio")
        case .experto: return L("Experto")
        }
    }

    var explicacion: String {
        switch self {
        case .basico: return L("Las piezas principales de un PC.")
        case .intermedio: return L("Además, las ranuras, cables y puertos que hacen falta para montarlo.")
        case .experto: return L("Todo: también cabezales, iluminación y componentes internos de la placa.")
        }
    }

    /// Nivel a partir del cual se muestra una ficha.
    static func nivel(de clave: String) -> NivelDiccionario {
        if basicas.contains(clave) { return .basico }
        if expertas.contains(clave) { return .experto }
        return .intermedio
    }

    private static let basicas: Set<String> = [
        "Placa_Base", "CPU", "Pasta_Termica", "Modulo_RAM", "GPU", "M2_SSD_NVMe", "SSD_SATA", "HDD",
        "Fuente_Alimentacion", "Disipador_Aire", "Refrigeracion_Liquida_AIO", "Ventilador_Caja", "Caja_PC",
        "Monitor", "Teclado", "Raton", "Altavoces_Auriculares",
    ]

    private static let expertas: Set<String> = [
        "Socket_Intel", "Socket_AMD", "CPU_Intel", "CPU_AMD", "VRM", "Chipset", "Pila_CMOS",
        "Tarjeta_Capturadora", "Tarjeta_Sonido", "Tarjeta_WiFi_Bluetooth", "Antena_WiFi", "M2_SSD_SATA",
        "Cable_Molex", "Radiador", "Bloque_refrigeracion_liquida", "Bomba_Liquida", "Hub_Ventiladores",
        "Conector_ARGB_5V", "Conector_RGB_12V", "Hub_RGB_ARGB",
    ]
}
