//
//  AlmacenDiagnosticos.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 17/07/2026.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

@MainActor
final class GestorDiagnosticos: ObservableObject {

    @Published private(set) var registros: [RegistroDiagnostico] = []
    private var modelContext: ModelContext?

    init(context: ModelContext? = nil) {
        self.modelContext = context
        if context != nil {
            cargar()
        }
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
        cargar()
    }

    func guardar(_ registro: RegistroDiagnostico) {
        registros.insert(registro, at: 0)
        guard let context = modelContext else { return }
        context.insert(Self.aSwiftData(registro))
        guardarContexto()
    }

    func actualizar(_ registro: RegistroDiagnostico) {
        guard let indice = registros.firstIndex(
            where: { $0.id == registro.id }
        ) else {
            return
        }

        registros[indice] = registro
        registros.sort { $0.fecha > $1.fecha }

        // Solo se modifica el registro afectado, no se reescribe todo el historial
        guard let context = modelContext else { return }
        let id = registro.id
        if let existente = try? context.fetch(
            FetchDescriptor<RegistroDiagnosticoSD>(predicate: #Predicate { $0.id == id })
        ).first {
            existente.fecha = registro.fecha
            existente.marcaPlaca = registro.marcaPlaca
            existente.tipoRaw = registro.tipo.rawValue
            existente.codigoOIndicador = registro.codigoOIndicador
            existente.tituloResultado = registro.tituloResultado
            existente.resultado = registro.resultado
            existente.pasosRecomendados = registro.pasosRecomendados
            existente.notaManual = registro.notaManual
            existente.estadoRaw = registro.estado.rawValue
        } else {
            context.insert(Self.aSwiftData(registro))
        }
        guardarContexto()
    }

    func eliminar(_ registro: RegistroDiagnostico) {
        registros.removeAll { $0.id == registro.id }
        borrarDeLaBase([registro.id])
    }

    func eliminarEn(_ offsets: IndexSet) {
        let ids = offsets.map { registros[$0].id }
        registros.remove(atOffsets: offsets)
        borrarDeLaBase(ids)
    }

    func cargar() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<RegistroDiagnosticoSD>(sortBy: [SortDescriptor(\.fecha, order: .reverse)])
        guard let items = try? context.fetch(descriptor) else {
            registros = []
            return
        }

        registros = items.map { item in
            RegistroDiagnostico(
                id: item.id,
                fecha: item.fecha,
                marcaPlaca: item.marcaPlaca,
                tipo: TipoRegistroDiagnostico(rawValue: item.tipoRaw) ?? .led,
                codigoOIndicador: item.codigoOIndicador,
                tituloResultado: item.tituloResultado,
                resultado: item.resultado,
                pasosRecomendados: item.pasosRecomendados,
                notaManual: item.notaManual,
                estado: EstadoRegistroDiagnostico(rawValue: item.estadoRaw) ?? .pendiente
            )
        }
    }

    private func borrarDeLaBase(_ ids: [UUID]) {
        guard let context = modelContext, !ids.isEmpty else { return }
        do {
            try context.delete(
                model: RegistroDiagnosticoSD.self,
                where: #Predicate { ids.contains($0.id) }
            )
            try context.save()
        } catch {
            // Si no se pudo borrar, la lista vuelve a mostrar lo que hay realmente guardado
            print("No se pudo borrar el diagnóstico: \(error)")
            context.rollback()
            cargar()
        }
    }

    private func guardarContexto() {
        do {
            try modelContext?.save()
        } catch {
            print("No se pudo guardar el diagnóstico: \(error)")
        }
    }

    private static func aSwiftData(_ reg: RegistroDiagnostico) -> RegistroDiagnosticoSD {
        RegistroDiagnosticoSD(
            id: reg.id,
            fecha: reg.fecha,
            marcaPlaca: reg.marcaPlaca,
            tipoRaw: reg.tipo.rawValue,
            codigoOIndicador: reg.codigoOIndicador,
            tituloResultado: reg.tituloResultado,
            resultado: reg.resultado,
            pasosRecomendados: reg.pasosRecomendados,
            notaManual: reg.notaManual,
            estadoRaw: reg.estado.rawValue
        )
    }
}
