//
//  PitidosDiagnosticoView.swift
//  PcComponentIA
//
//  Modo "Pitidos" del diagnóstico: el usuario reproduce lo que oye (corto/largo)
//  y la app le dice qué significa según la BIOS.
//

import SwiftUI

struct PitidosDiagnosticoView: View {
    /// Se llama al pulsar "Guardar diagnóstico".
    var onGuardar: (CodigoPitidos) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var bios: BIOSPitidos = .desconocida
    @State private var patron: [TipoPitido] = []
    @State private var continuo = false

    private var resultados: [CodigoPitidos] {
        DatosPitidos.buscar(patron, continuo: continuo, bios: bios)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            selectorBIOS
            editorPatron
            resultado
        }
    }

    // MARK: - BIOS

    private var selectorBIOS: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Qué BIOS tiene tu placa?")
                .font(.subheadline.weight(.semibold))
            Picker("BIOS", selection: $bios) {
                ForEach(BIOSPitidos.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Text("Aparece en la primera pantalla al encender o en el manual. Si no lo sabes, se busca en todas.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(fondoTarjeta, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Patrón

    private var editorPatron: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("¿Qué pitidos oyes?")
                .font(.subheadline.weight(.semibold))

            // Representación visual del patrón: · corto, — largo
            HStack(spacing: 8) {
                if patron.isEmpty {
                    Text("Pulsa «Corto» o «Largo» en el orden en que suenan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(patron.enumerated()), id: \.offset) { _, pitido in
                        Capsule()
                            .fill(Color.orange.gradient)
                            .frame(width: pitido == .corto ? 12 : 36, height: 12)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if continuo {
                        Image(systemName: "repeat")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(minHeight: 24)
            .animation(Animaciones.muelle, value: patron)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(descripcionAccesible.localizado)

            HStack(spacing: 10) {
                botonPitido("Corto", tipo: .corto)
                botonPitido("Largo", tipo: .largo)
            }

            HStack {
                Toggle("Se repite sin parar", isOn: $continuo.animation(Animaciones.muelle))
                    .font(.subheadline)
            }

            HStack {
                Button(role: .destructive) {
                    withAnimation(Animaciones.muelle) {
                        _ = patron.popLast()
                    }
                } label: {
                    Label("Borrar último", systemImage: "delete.left")
                }
                .disabled(patron.isEmpty)

                Spacer()

                Button {
                    withAnimation(Animaciones.muelle) {
                        patron.removeAll()
                        continuo = false
                    }
                } label: {
                    Label("Empezar de nuevo", systemImage: "arrow.counterclockwise")
                }
                .disabled(patron.isEmpty && !continuo)
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(fondoTarjeta, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sensoryFeedback(.impact(weight: .light), trigger: patron.count)
    }

    private func botonPitido(_ titulo: String, tipo: TipoPitido) -> some View {
        Button {
            guard patron.count < 12 else { return }
            withAnimation(Animaciones.muelle) {
                patron.append(tipo)
            }
        } label: {
            VStack(spacing: 6) {
                Capsule()
                    .fill(.white)
                    .frame(width: tipo == .corto ? 12 : 34, height: 10)
                Text(titulo.localizado)
                    .font(.subheadline.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(tipo == .corto ? .orange : .indigo)
        .accessibilityLabel("Añadir pitido \(titulo.lowercased())")
    }

    private var descripcionAccesible: String {
        guard !patron.isEmpty else { return L("Sin pitidos todavía") }
        // En el orden en que suenan: "largo, corto, corto"
        return L("Patrón: ") + patron.map { $0 == .corto ? L("corto") : L("largo") }.joined(separator: ", ")
            + (continuo ? L(", repetido") : "")
    }

    // MARK: - Resultado

    @ViewBuilder
    private var resultado: some View {
        if !patron.isEmpty {
            if resultados.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Patrón no reconocido", systemImage: "questionmark.circle")
                        .font(.headline)
                    Text("Comprueba el orden de los pitidos o elige otra BIOS. Cada fabricante puede usar códigos propios: consulta el manual de tu placa.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fondoTarjeta, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ForEach(resultados) { codigo in
                    tarjetaResultado(codigo)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func tarjetaResultado(_ codigo: CodigoPitidos) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(codigo.bios.rawValue.localizado)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.18), in: Capsule())
                Text(codigo.patronTexto.localizado)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Text(codigo.titulo.localizado)
                .font(.headline)
            Text(codigo.descripcion.localizado)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(codigo.pasos.enumerated()), id: \.offset) { indice, paso in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(indice + 1).")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.orange)
                        Text(paso.localizado)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Button {
                onGuardar(codigo)
            } label: {
                Label("Guardar diagnóstico", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
        .padding(16)
        .background(fondoTarjeta, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var fondoTarjeta: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.07 : 0.045)
    }
}
