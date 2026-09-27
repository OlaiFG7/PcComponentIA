//
//  MigrationManager.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 20/07/2026.
//

import Foundation
import SwiftData

final class MigrationManager {
    static let shared = MigrationManager()

    private let migrationKey = "swiftdata_migration_completed_v1"

    private init() {}

    @MainActor
    func performMigrationIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // 1. Migración de Builds guardadas
        if let datosBuilds = UserDefaults.standard.data(forKey: "misBuildsGuardados"),
           let buildsLegacy = try? JSONDecoder().decode([Build].self, from: datosBuilds) {
            for build in buildsLegacy {
                let compSD = build.componentes.map {
                    ComponenteBuildSD(
                        id: $0.id,
                        categoria: $0.categoria,
                        nombre: $0.nombre,
                        precio: $0.precio,
                        notas: $0.notas
                    )
                }
                let buildSD = BuildSD(
                    id: build.id,
                    nombre: build.nombre,
                    fechaCreacion: build.fechaCreacion,
                    componentes: compSD,
                    etiqueta: build.etiqueta,
                    notas: build.notas,
                    presupuestoObjetivo: build.presupuestoObjetivo
                )
                context.insert(buildSD)
            }
        }

        // 2. Migración de Historial de Diagnósticos
        if let datosDiag = UserDefaults.standard.data(forKey: "historialDiagnosticosPC"),
           let diagLegacy = try? JSONDecoder().decode([RegistroDiagnostico].self, from: datosDiag) {
            for diag in diagLegacy {
                let diagSD = RegistroDiagnosticoSD(
                    id: diag.id,
                    fecha: diag.fecha,
                    marcaPlaca: diag.marcaPlaca,
                    tipoRaw: diag.tipo.rawValue,
                    codigoOIndicador: diag.codigoOIndicador,
                    tituloResultado: diag.tituloResultado,
                    resultado: diag.resultado,
                    pasosRecomendados: diag.pasosRecomendados,
                    notaManual: diag.notaManual,
                    estadoRaw: diag.estado.rawValue
                )
                context.insert(diagSD)
            }
        }

        // 3. Migración de Historial de Capturas de la Cámara
        if let datosHist = UserDefaults.standard.data(forKey: "historialCapturas"),
           let capturasLegacy = try? JSONDecoder().decode([CapturaHistorial].self, from: datosHist) {
            for cap in capturasLegacy {
                let capSD = CapturaHistorialSD(
                    id: cap.id,
                    componente: cap.componente,
                    fecha: cap.fecha,
                    confianza: cap.confianza,
                    fotoData: cap.fotoData
                )
                context.insert(capSD)
            }
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
