//
//  GuiaPasosView.swift
//  PcComponentIA
//
//  Formato común de las guías de montaje: un dibujo animado por paso, su explicación,
//  un aviso si hay riesgo y, en el último paso, los pasos del checklist que cubre la guía.
//

import SwiftUI

struct PasoGuia: Identifiable {
    let id: Int
    let titulo: String
    let texto: String
    var aviso: String? = nil
}

struct GuiaPasosView<Cabecera: View, Dibujo: View>: View {

    let titulo: String
    let pasos: [PasoGuia]
    /// Pasos del checklist que cubre la guía (nombres tal como se guardan, en español).
    let pasosChecklist: [String]
    let acento: Color
    /// Cambia cuando el dibujo debe reiniciarse sin cambiar de paso (p. ej. otro tipo de socket).
    var variante: String = ""
    @ViewBuilder let cabecera: () -> Cabecera
    @ViewBuilder let dibujo: (_ indice: Int, _ animado: Bool) -> Dibujo

    @EnvironmentObject private var checklist: GestorChecklist
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    @State private var indice = 0

    var body: some View {
        let actual = min(indice, pasos.count - 1)
        let paso = pasos[actual]

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                cabecera()

                dibujo(actual, !reducirMovimiento)
                    .frame(height: 270)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(red: 0.07, green: 0.09, blue: 0.12),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                    )
                    // Cada paso arranca su animación desde el principio
                    .id("\(paso.id)-\(variante)")
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 10) {
                    Text(L("Paso \(actual + 1) de \(pasos.count)"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(acento)
                        .textCase(.uppercase)

                    Text(paso.titulo)
                        .font(.title2.bold())

                    Text(paso.texto)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let aviso = paso.aviso {
                        Label {
                            Text(aviso)
                                .font(.footnote.weight(.medium))
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundStyle(.orange)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color.orange.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }

                    if actual == pasos.count - 1, !pasosChecklist.isEmpty {
                        marcarEnChecklist
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            controles
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(titulo)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: indice)
    }

    // MARK: Controles

    private var controles: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(pasos.indices, id: \.self) { posicion in
                    Capsule()
                        .fill(posicion == indice ? acento : Color.primary.opacity(0.18))
                        .frame(width: posicion == indice ? 22 : 7, height: 7)
                }
            }
            .animation(reducirMovimiento ? nil : Animaciones.muelle, value: indice)
            .accessibilityHidden(true)

            HStack(spacing: 12) {
                Button {
                    cambiar(a: indice - 1)
                } label: {
                    Label(L("Anterior"), systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(indice == 0)

                Button {
                    cambiar(a: indice + 1)
                } label: {
                    Label(L("Siguiente"), systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(acento)
                .disabled(indice >= pasos.count - 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private func cambiar(a nuevo: Int) {
        guard pasos.indices.contains(nuevo) else { return }
        withAnimation(reducirMovimiento ? nil : Animaciones.muelle) {
            indice = nuevo
        }
    }

    // MARK: Checklist

    private var marcarEnChecklist: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("Marcar en el checklist"))
                .font(.headline)
                .padding(.top, 8)

            ForEach(pasosChecklist, id: \.self) { nombre in
                let hecho = checklist.estaCompletadoPaso(nombre: nombre)

                Button {
                    _ = checklist.alternarPaso(nombre: nombre)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: hecho ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(hecho ? Color.green : Color.secondary)
                            .contentTransition(.symbolEffect(.replace))

                        Text(nombre.localizado)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(hecho ? .isSelected : [])
            }
        }
    }
}
