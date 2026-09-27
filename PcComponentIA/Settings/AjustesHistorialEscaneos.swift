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
            return "No eliminar automáticamente"

        case .dias7:
            return "Cada 7 días"

        case .dias30:
            return "Cada 30 días"

        case .dias90:
            return "Cada 90 días"
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

    func aplicarRetencion(a historial: inout [CapturaHistorial]) {
        guard retencion != .nunca else {
            return
        }

        let limite = Calendar.current.date(
            byAdding: .day,
            value: -retencion.rawValue,
            to: Date()
        ) ?? Date()

        let filtrado = historial.filter { captura in
            captura.fecha >= limite
        }

        guard filtrado.count != historial.count else {
            return
        }

        historial = filtrado
        AlmacenHistorial.guardar(historial)
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
                                Text(opcion.etiqueta)
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
                    Text(
                        "Los escaneos más antiguos que el periodo " +
                        "seleccionado se eliminarán automáticamente " +
                        "al abrir el historial."
                    )
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
