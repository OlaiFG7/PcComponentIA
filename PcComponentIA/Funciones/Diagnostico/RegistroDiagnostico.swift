//
//  RegistroDiagnostico.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 17/07/2026.
//

import Foundation

enum TipoRegistroDiagnostico: String, Codable, CaseIterable, Identifiable {
    case led = "LED"
    case codigoPOST = "Código POST"
    case pitidos = "Pitidos"

    var id: String {
        rawValue
    }

    var icono: String {
        switch self {
        case .led: "circle.grid.2x2.fill"
        case .codigoPOST: "number.square.fill"
        case .pitidos: "speaker.wave.2.fill"
        }
    }
}

enum EstadoRegistroDiagnostico: String, Codable, CaseIterable, Identifiable {
    case pendiente = "Pendiente"
    case enProceso = "En proceso"
    case resuelto = "Resuelto"

    var id: String {
        rawValue
    }
}

struct RegistroDiagnostico: Identifiable, Codable, Equatable {
    var id = UUID()

    var fecha: Date = .now
    var marcaPlaca: String

    var tipo: TipoRegistroDiagnostico
    var codigoOIndicador: String

    var tituloResultado: String
    var resultado: String
    var pasosRecomendados: [String]

    var notaManual: String = ""
    var estado: EstadoRegistroDiagnostico = .pendiente
}
