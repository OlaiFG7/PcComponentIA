//
//  Modelos.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 08/07/2026.
//

//
//  Modelos.swift
//  PcComponentIA
//

import SwiftUI

struct ComponenteBuild: Identifiable, Codable, Equatable {
    var id = UUID()
    var categoria: String
    var nombre: String
    var precio: String
    var notas: String
}

struct Build: Identifiable, Codable, Equatable {
    var id = UUID()
    var nombre: String
    var fechaCreacion: Date = Date()
    var componentes: [ComponenteBuild] = []
    var etiqueta: String = "Sin etiqueta"
    var notas: String = ""
    var presupuestoObjetivo: String = ""

    var precioTotal: Double {
        componentes.compactMap { $0.precio.safeDouble }.reduce(0, +)
    }

    var presupuestoNumerico: Double {
        presupuestoObjetivo.safeDouble ?? 0
    }
}

let etiquetasDisponibles = ["Sin etiqueta", "Gaming", "Oficina", "Streaming", "Edición de vídeo", "En proceso", "Terminado"]
let categoriasDisponibles = ["CPU", "GPU", "Placa base", "RAM", "Almacenamiento", "Fuente", "Refrigeración", "Caja", "Otro"]

func colorEtiqueta(_ etiqueta: String) -> Color {
    switch etiqueta {
    case "Gaming": return .purple
    case "Oficina": return .blue
    case "Streaming": return .red
    case "Edición de vídeo": return .orange
    case "En proceso": return .yellow
    case "Terminado": return .green
    default: return .gray
    }
}

import SwiftData

@MainActor
final class AlmacenBuilds {
    static var defaultContext: ModelContext?

    static func guardar(_ builds: [Build], context: ModelContext? = nil) {
        let ctx = context ?? defaultContext
        guard let ctx else { return }

        try? ctx.delete(model: BuildSD.self)
        for b in builds {
            let compSD = b.componentes.map {
                ComponenteBuildSD(
                    id: $0.id,
                    categoria: $0.categoria,
                    nombre: $0.nombre,
                    precio: $0.precio,
                    notas: $0.notas
                )
            }
            let bSD = BuildSD(
                id: b.id,
                nombre: b.nombre,
                fechaCreacion: b.fechaCreacion,
                componentes: compSD,
                etiqueta: b.etiqueta,
                notas: b.notas,
                presupuestoObjetivo: b.presupuestoObjetivo
            )
            ctx.insert(bSD)
        }
        try? ctx.save()
    }

    static func cargar(context: ModelContext? = nil) -> [Build] {
        let ctx = context ?? defaultContext
        guard let ctx else { return [] }

        let descriptor = FetchDescriptor<BuildSD>(sortBy: [SortDescriptor(\.fechaCreacion, order: .reverse)])
        guard let items = try? ctx.fetch(descriptor) else { return [] }

        return items.map { item in
            Build(
                id: item.id,
                nombre: item.nombre,
                fechaCreacion: item.fechaCreacion,
                componentes: item.componentes.map {
                    ComponenteBuild(
                        id: $0.id,
                        categoria: $0.categoria,
                        nombre: $0.nombre,
                        precio: $0.precio,
                        notas: $0.notas
                    )
                },
                etiqueta: item.etiqueta,
                notas: item.notas,
                presupuestoObjetivo: item.presupuestoObjetivo
            )
        }
    }
}
