//
//  AjustesHistorialEscaneos.swift
//  PcComponentIA
//

import SwiftUI
import Combine

enum RetencionEscaneos: Int, CaseIterable, Identifiable {
    case nunca = 0
    case dias7 = 7
    case dias30 = 30
    case dias90 = 90

    var id: Int {
        rawValue
    }

    var etiqueta: String {
        switch self {
        case .nunca:
            return L("No eliminar automáticamente")

        case .dias7:
            return L("Cada 7 días")

        case .dias30:
            return L("Cada 30 días")

        case .dias90:
            return L("Cada 90 días")
        }
    }
}

final class GestorRetencionEscaneos: ObservableObject {

    @Published var retencion: RetencionEscaneos {
        didSet {
            UserDefaults.standard.set(
                retencion.rawValue,
                forKey: "retencionHistorialEscaneos"
            )
        }
    }

    init() {
        let valorGuardado = UserDefaults.standard.integer(
            forKey: "retencionHistorialEscaneos"
        )

        retencion = RetencionEscaneos(rawValue: valorGuardado) ?? .nunca
    }

    /// Borra en la base de datos las capturas más antiguas que el periodo elegido, sin cargarlas
    /// en memoria. Llamar antes de cargar el historial.
    func aplicarRetencionEnAlmacen() {
        guard retencion != .nunca,
              let limite = Calendar.current.date(byAdding: .day, value: -retencion.rawValue, to: Date())
        else {
            return
        }

        AlmacenHistorial.borrarAnteriores(a: limite)
    }
}

struct AjustesHistorialEscaneosView: View {

    @ObservedObject var gestor: GestorRetencionEscaneos
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(RetencionEscaneos.allCases) { opcion in
                        Button {
                            gestor.retencion = opcion
                        } label: {
                            HStack {
                                Text(opcion.etiqueta.localizado)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if gestor.retencion == opcion {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Eliminar escaneos automáticamente")
                } footer: {
                    // Una sola frase para que se pueda traducir entera
                    Text("Los escaneos más antiguos que el periodo seleccionado se eliminarán automáticamente al abrir el historial.")
                }
            }
            .navigationTitle("Borrado automático")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}
