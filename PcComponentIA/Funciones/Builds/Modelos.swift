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

        // El borrado por lotes no aplica la regla en cascada: se borran también las piezas
        // para que no queden huérfanas en la base de datos
        try? ctx.delete(model: ComponenteBuildSD.self)
        try? ctx.delete(model: BuildSD.self)
        for b in builds {
            let compSD = b.componentes.enumerated().map { posicion, componente in
                ComponenteBuildSD(
                    id: componente.id,
                    categoria: componente.categoria,
                    nombre: componente.nombre,
                    precio: componente.precio,
                    notas: componente.notas,
                    orden: posicion
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

        // Builds guardadas antes de existir `orden`: todas sus piezas valen 0.
        // Se numeran una vez para que su orden deje de ser aleatorio.
        var numeradas = false
        for item in items where item.componentes.count > 1 && Set(item.componentes.map(\.orden)).count == 1 {
            for (posicion, componente) in item.componentes.enumerated() {
                componente.orden = posicion
            }
            numeradas = true
        }
        if numeradas {
            try? ctx.save()
        }

        return items.map { item in
            Build(
                id: item.id,
                nombre: item.nombre,
                fechaCreacion: item.fechaCreacion,
                componentes: item.componentes.sorted { $0.orden < $1.orden }.map {
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

    /// Crea una build nueva sin reescribir las demás. Devuelve false si no se pudo guardar.
    @discardableResult
    static func crear(_ build: Build, context: ModelContext? = nil) -> Bool {
        actualizar(build, context: context)
    }

    /// Guarda los cambios de UNA build (la crea si no existe) sin tocar las demás:
    /// así no se pisan piezas añadidas desde el escáner o el diccionario.
    @discardableResult
    static func actualizar(_ build: Build, context: ModelContext? = nil) -> Bool {
        guard let ctx = context ?? defaultContext else { return false }
        let id = build.id

        do {
            let buildSD: BuildSD
            if let existente = try ctx.fetch(FetchDescriptor<BuildSD>(predicate: #Predicate { $0.id == id })).first {
                buildSD = existente
            } else {
                buildSD = BuildSD(
                    id: build.id,
                    nombre: build.nombre,
                    fechaCreacion: build.fechaCreacion,
                    componentes: [],
                    etiqueta: build.etiqueta,
                    notas: build.notas,
                    presupuestoObjetivo: build.presupuestoObjetivo
                )
                ctx.insert(buildSD)
            }

            buildSD.nombre = build.nombre
            buildSD.etiqueta = build.etiqueta
            buildSD.notas = build.notas
            buildSD.presupuestoObjetivo = build.presupuestoObjetivo

            // Piezas: se borran las quitadas, se actualizan las que siguen y se añaden las nuevas
            let idsNuevos = Set(build.componentes.map(\.id))
            for viejo in buildSD.componentes where !idsNuevos.contains(viejo.id) {
                ctx.delete(viejo)
            }
            var porId = Dictionary(
                buildSD.componentes.filter { idsNuevos.contains($0.id) }.map { ($0.id, $0) },
                uniquingKeysWith: { primero, _ in primero }
            )
            for (posicion, componente) in build.componentes.enumerated() {
                if let sd = porId[componente.id] {
                    sd.categoria = componente.categoria
                    sd.nombre = componente.nombre
                    sd.precio = componente.precio
                    sd.notas = componente.notas
                    sd.orden = posicion
                } else {
                    let sd = ComponenteBuildSD(
                        id: componente.id,
                        categoria: componente.categoria,
                        nombre: componente.nombre,
                        precio: componente.precio,
                        notas: componente.notas,
                        orden: posicion
                    )
                    buildSD.componentes.append(sd)
                    porId[componente.id] = sd
                }
            }

            try ctx.save()
            return true
        } catch {
            print("No se pudo guardar la build: \(error)")
            ctx.rollback()
            return false
        }
    }

    /// Borra builds concretas (con sus piezas, por la regla en cascada).
    @discardableResult
    static func eliminar(ids: Set<UUID>, context: ModelContext? = nil) -> Bool {
        guard let ctx = context ?? defaultContext, !ids.isEmpty else { return false }
        let lista = Array(ids)
        do {
            for buildSD in try ctx.fetch(FetchDescriptor<BuildSD>(predicate: #Predicate { lista.contains($0.id) })) {
                ctx.delete(buildSD)
            }
            try ctx.save()
            return true
        } catch {
            print("No se pudieron borrar las builds: \(error)")
            ctx.rollback()
            return false
        }
    }

    /// Añade una pieza al final de una build ya guardada (desde el escáner o el diccionario).
    @discardableResult
    static func añadir(_ componente: ComponenteBuild, aBuild idBuild: UUID, context: ModelContext? = nil) -> Bool {
        guard let ctx = context ?? defaultContext,
              let buildSD = try? ctx.fetch(
                FetchDescriptor<BuildSD>(predicate: #Predicate { $0.id == idBuild })
              ).first
        else { return false }

        let siguiente = (buildSD.componentes.map(\.orden).max() ?? -1) + 1
        let nuevo = ComponenteBuildSD(
            id: componente.id,
            categoria: componente.categoria,
            nombre: componente.nombre,
            precio: componente.precio,
            notas: componente.notas,
            orden: siguiente
        )
        buildSD.componentes.append(nuevo)
        do {
            try ctx.save()
            return true
        } catch {
            ctx.rollback()
            return false
        }
    }
}
