//
//  BotonPreguntarAsistente.swift
//  PcComponentIA
//
//  Abre el asistente sabiendo ya de qué se habla (una build, una pieza...).
//

import SwiftUI

struct BotonPreguntarAsistente: View {
    let contexto: ContextoChat
    var estilo: Estilo = .ancho

    enum Estilo { case ancho, icono }

    @State private var mostrar = false

    var body: some View {
        Button {
            mostrar = true
        } label: {
            switch estilo {
            case .ancho:
                Label("Preguntar al asistente", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            case .icono:
                Image(systemName: "sparkles")
            }
        }
        .modifier(EstiloBoton(estilo: estilo))
        .accessibilityLabel("Preguntar al asistente sobre \(contexto.titulo)")
        .sheet(isPresented: $mostrar) {
            NavigationStack {
                ChatIAView(contexto: contexto)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cerrar") { mostrar = false }
                        }
                    }
            }
        }
    }

    private struct EstiloBoton: ViewModifier {
        let estilo: Estilo
        func body(content: Content) -> some View {
            if estilo == .ancho {
                content.buttonStyle(.bordered).tint(.pink)
            } else {
                content
            }
        }
    }
}

// MARK: - Contextos

extension Build {
    var contextoChat: ContextoChat {
        var lineas = [L("Build del usuario: «\(nombre.isEmpty ? "sin nombre" : nombre)» (\(etiqueta)).")]
        if componentes.isEmpty {
            lineas.append(L("Todavía no tiene piezas."))
        } else {
            lineas.append("Piezas:")
            lineas += componentes.map { componente in
                let precio = componente.precio.safeDouble.map { L(" (\($0.formatoEuro))") } ?? ""
                return L("- \(componente.categoria.localizado): \(componente.nombre)\(precio)")
            }
            lineas.append(L("Total: \(precioTotal.formatoEuro)."))
        }
        if presupuestoNumerico > 0 {
            lineas.append(L("Presupuesto: \(presupuestoNumerico.formatoEuro)."))
        }

        let (avisos, consumo) = CompatibilidadBuild.analizar(self)
        if consumo.total > 75 {
            lineas.append(L("Consumo estimado por la app: \(consumo.total) W; fuente recomendada \(consumo.fuenteRecomendada) W."))
        }
        let problemas = avisos.filter { $0.nivel >= .advertencia }
        if !problemas.isEmpty {
            lineas.append(L("Avisos de compatibilidad detectados: ") + problemas.map(\.titulo).joined(separator: "; ") + ".")
        }
        return ContextoChat(titulo: nombre.isEmpty ? L("tu build") : nombre, texto: lineas.joined(separator: "\n"))
    }
}

extension InfoComponente {
    func contextoChat(nombre: String) -> ContextoChat {
        ContextoChat(
            titulo: nombre,
            texto: """
            El usuario está consultando la pieza «\(nombre)».
            Descripción de la app: \(descripcion)
            Guía de montaje de la app: \(guiaDeUsoOMontaje)
            """
        )
    }
}
