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
        persistir()
    }

    func actualizar(_ registro: RegistroDiagnostico) {
        guard let indice = registros.firstIndex(
            where: { $0.id == registro.id }
        ) else {
            return
        }

        registros[indice] = registro
        ordenarYGuardar()
    }

    func eliminar(_ registro: RegistroDiagnostico) {
        registros.removeAll { $0.id == registro.id }
        persistir()
    }

    func eliminarEn(_ offsets: IndexSet) {
        registros.remove(atOffsets: offsets)
        persistir()
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

    private func ordenarYGuardar() {
        registros.sort { $0.fecha > $1.fecha }
        persistir()
    }

    private func persistir() {
        guard let context = modelContext else { return }

        try? context.delete(model: RegistroDiagnosticoSD.self)
        for reg in registros {
            let regSD = RegistroDiagnosticoSD(
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
            context.insert(regSD)
        }
        try? context.save()
    }
}
