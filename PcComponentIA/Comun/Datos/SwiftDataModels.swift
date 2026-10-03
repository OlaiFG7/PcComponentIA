//
//  SwiftDataModels.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 20/07/2026.
//

import Foundation
import SwiftData

// MARK: - Entidades de Builds

@Model
final class BuildSD {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var fechaCreacion: Date
    @Relationship(deleteRule: .cascade, inverse: \ComponenteBuildSD.build) var componentes: [ComponenteBuildSD]
    var etiqueta: String
    var notas: String
    var presupuestoObjetivo: String

    init(
        id: UUID = UUID(),
        nombre: String,
        fechaCreacion: Date = Date(),
        componentes: [ComponenteBuildSD] = [],
        etiqueta: String = "Sin etiqueta",
        notas: String = "",
        presupuestoObjetivo: String = ""
    ) {
        self.id = id
        self.nombre = nombre
        self.fechaCreacion = fechaCreacion
        self.componentes = componentes
        self.etiqueta = etiqueta
        self.notas = notas
        self.presupuestoObjetivo = presupuestoObjetivo
    }

    var precioTotal: Double {
        componentes.compactMap { $0.precioNumerico }.reduce(0, +)
    }

    var presupuestoNumerico: Double {
        Double(presupuestoObjetivo.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
    }
}

@Model
final class ComponenteBuildSD {
    @Attribute(.unique) var id: UUID
    var categoria: String
    var nombre: String
    var precio: String
    var notas: String
    /// Posición dentro de la build: SwiftData no conserva el orden de las relaciones.
    /// Con valor por defecto para que la migración de datos existentes sea automática.
    var orden: Int = 0
    var build: BuildSD?

    init(
        id: UUID = UUID(),
        categoria: String,
        nombre: String,
        precio: String,
        notas: String,
        orden: Int = 0
    ) {
        self.id = id
        self.categoria = categoria
        self.nombre = nombre
        self.precio = precio
        self.notas = notas
        self.orden = orden
    }

    var precioNumerico: Double? {
        precio.safeDouble
    }
}

// MARK: - Entidades de Diagnósticos

@Model
final class RegistroDiagnosticoSD {
    @Attribute(.unique) var id: UUID
    var fecha: Date
    var marcaPlaca: String
    var tipoRaw: String
    var codigoOIndicador: String
    var tituloResultado: String
    var resultado: String
    var pasosRecomendados: [String]
    var notaManual: String
    var estadoRaw: String

    init(
        id: UUID = UUID(),
        fecha: Date = Date(),
        marcaPlaca: String,
        tipoRaw: String,
        codigoOIndicador: String,
        tituloResultado: String,
        resultado: String,
        pasosRecomendados: [String],
        notaManual: String = "",
        estadoRaw: String = "Pendiente"
    ) {
        self.id = id
        self.fecha = fecha
        self.marcaPlaca = marcaPlaca
        self.tipoRaw = tipoRaw
        self.codigoOIndicador = codigoOIndicador
        self.tituloResultado = tituloResultado
        self.resultado = resultado
        self.pasosRecomendados = pasosRecomendados
        self.notaManual = notaManual
        self.estadoRaw = estadoRaw
    }
}

// MARK: - Entidades de Escaneo e Historial Visual

@Model
final class CapturaHistorialSD {
    @Attribute(.unique) var id: UUID
    var componente: String
    var fecha: Date
    var confianza: String
    @Attribute(.externalStorage) var fotoData: Data

    init(
        id: UUID = UUID(),
        componente: String,
        fecha: Date = Date(),
        confianza: String,
        fotoData: Data
    ) {
        self.id = id
        self.componente = componente
        self.fecha = fecha
        self.confianza = confianza
        self.fotoData = fotoData
    }

    var nombreLimpio: String {
        componente.replacingOccurrences(of: "_", with: " ")
    }
}
