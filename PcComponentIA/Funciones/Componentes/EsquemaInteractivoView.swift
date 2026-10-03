//
//  EsquemaInteractivoView.swift
//  PcComponentIA
//
//  Dibujo interactivo de un componente con sus conectores (datos en EsquemasComponentes).
//  Se pulsa un conector para ver qué es y abrir su ficha.
//

import SwiftUI

struct EsquemaInteractivoView: View {
    let esquema: EsquemaComponente

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Environment(\.dismiss) private var dismiss

    @State private var seleccionado: PuntoEsquema?
    @State private var visible = false

    private let diccionario = DatosHardware.obtenerDiccionario()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Toca un conector para ver qué es y cómo se conecta.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                lienzo

                if let punto = seleccionado {
                    tarjetaDetalle(punto)
                        .id(punto.id)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                listaConectores
            }
            .frame(maxWidth: 760)
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(esquema.titulo.localizado)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cerrar") { dismiss() }
            }
        }
        .sensoryFeedback(.selection, trigger: seleccionado?.id)
        .onAppear {
            withAnimation(reducirMovimiento ? .easeOut(duration: 0.2) : Animaciones.muelle) {
                visible = true
            }
        }
    }

    // MARK: - Lienzo

    private var lienzo: some View {
        GeometryReader { geo in
            let tamano = geo.size

            ZStack(alignment: .topLeading) {
                ForEach(Array(esquema.formas.enumerated()), id: \.offset) { _, forma in
                    vistaForma(forma, en: tamano)
                }

                ForEach(Array(esquema.puntos.enumerated()), id: \.element.id) { indice, punto in
                    vistaPunto(punto, indice: indice, en: tamano)
                }
            }
        }
        .aspectRatio(esquema.proporcion, contentMode: .fit)
        .background(esquema.colorFondo, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        // Cada conector del dibujo es un botón accesible; las formas decorativas se ocultan
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Esquema de \(esquema.titulo) con \(esquema.puntos.count) conectores")
    }

    @ViewBuilder
    private func vistaForma(_ forma: FormaEsquema, en tamano: CGSize) -> some View {
        let marco = escalar(forma.marco, a: tamano)

        Group {
            switch forma.tipo {
            case .rectangulo(let radio):
                RoundedRectangle(cornerRadius: radio * tamano.width, style: .continuous)
                    .fill(forma.color)
            case .circulo:
                Circle().fill(forma.color)
            case .ventilador:
                Ventilador(color: forma.color, girar: !reducirMovimiento)
            }
        }
        .frame(width: marco.width, height: marco.height)
        .overlay {
            if let etiqueta = forma.etiqueta {
                Text(etiqueta.localizado)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .offset(x: marco.minX, y: marco.minY)
        .accessibilityHidden(true)
    }

    private func vistaPunto(_ punto: PuntoEsquema, indice: Int, en tamano: CGSize) -> some View {
        let marco = escalar(punto.marco, a: tamano)
        let activo = seleccionado?.id == punto.id
        // Zona táctil mínima de 30 pt aunque el conector dibujado sea pequeño
        let anchoToque = max(marco.width, 30)
        let altoToque = max(marco.height, 30)

        return Button {
            withAnimation(Animaciones.muelle) {
                seleccionado = activo ? nil : punto
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(punto.color)
                    .frame(width: marco.width, height: marco.height)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            // Borde claro: los conectores de plástico negro casi no se veían sobre el fondo oscuro
                            .stroke(activo ? Color.white : Color.white.opacity(0.55), lineWidth: activo ? 2 : 1)
                    }
                    .shadow(color: activo ? .cyan.opacity(0.9) : .clear, radius: 6)

                PuntoPulsante(activo: activo, animar: !reducirMovimiento)
            }
            .frame(width: anchoToque, height: altoToque)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(punto.nombre.localizado)
        .accessibilityHint(punto.descripcion.localizado)
        .accessibilityAddTraits(activo ? .isSelected : [])
        .scaleEffect(visible ? 1 : 0.4)
        .opacity(visible ? 1 : 0)
        .animation(
            reducirMovimiento ? nil : Animaciones.muelle.delay(Double(indice) * 0.035),
            value: visible
        )
        .offset(
            x: marco.midX - anchoToque / 2,
            y: marco.midY - altoToque / 2
        )
        .zIndex(activo ? 10 : 1)
    }

    private func escalar(_ rect: CGRect, a tamano: CGSize) -> CGRect {
        CGRect(
            x: rect.minX * tamano.width,
            y: rect.minY * tamano.height,
            width: rect.width * tamano.width,
            height: rect.height * tamano.height
        )
    }

    // MARK: - Detalle del conector

    private func tarjetaDetalle(_ punto: PuntoEsquema) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(punto.color)
                    .frame(width: 18, height: 18)
                    .overlay { RoundedRectangle(cornerRadius: 4).stroke(.primary.opacity(0.2)) }
                Text(punto.nombre.localizado)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(Animaciones.muelle) { seleccionado = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Cerrar detalle del conector")
            }

            Text(punto.descripcion.localizado)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            if let clave = punto.claveFicha, let info = diccionario[clave] {
                NavigationLink {
                    DetalleComponenteInfoView(nombre: clave, info: info)
                } label: {
                    Label("Ver ficha completa", systemImage: "book.pages")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Lista accesible

    private var listaConectores: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Conectores")
                .font(.title3.bold())

            FlowLayout(spacing: 8) {
                ForEach(esquema.puntos) { punto in
                    let activo = seleccionado?.id == punto.id
                    Button {
                        withAnimation(Animaciones.muelle) {
                            seleccionado = activo ? nil : punto
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(punto.color).frame(width: 8, height: 8)
                            Text(punto.nombre.localizado)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            activo ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(punto.descripcion.localizado)
                    .accessibilityAddTraits(activo ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - Piezas animadas

/// Anillo que late sobre cada conector para invitar a tocarlo.
private struct PuntoPulsante: View {
    let activo: Bool
    let animar: Bool

    var body: some View {
        Circle()
            .fill(activo ? Color.cyan : Color.white)
            .frame(width: 7, height: 7)
            .overlay {
                if animar {
                    Circle()
                        .stroke(activo ? Color.cyan : Color.white.opacity(0.8), lineWidth: 1.5)
                        .phaseAnimator([false, true]) { anillo, expandido in
                            anillo
                                .scaleEffect(expandido ? 2.6 : 1)
                                .opacity(expandido ? 0 : 0.9)
                        } animation: { expandido in
                            expandido ? .easeOut(duration: 1.4) : .linear(duration: 0)
                        }
                }
            }
            .allowsHitTesting(false)
    }
}

/// Ventilador con aspas que giran despacio.
private struct Ventilador: View {
    let color: Color
    let girar: Bool

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)

            if girar {
                // 30 imágenes por segundo bastan para un giro lento y gastan la mitad de batería
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { contexto in
                    aspas(angulo: .degrees(contexto.date.timeIntervalSinceReferenceDate * 120))
                }
            } else {
                aspas(angulo: .zero)
            }

            Circle()
                .fill(Color(white: 0.12))
                .scaleEffect(0.28)
        }
    }

    private func aspas(angulo: Angle) -> some View {
        ZStack {
            ForEach(0..<7) { i in
                Capsule()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 8, height: 30)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(i) / 7 * 360))
            }
        }
        .rotationEffect(angulo)
        .scaleEffect(0.9)
    }
}

// MARK: - Botón "Ver conectores"

/// Abre el esquema si el componente tiene uno; si no, no ocupa sitio.
struct BotonVerConectores: View {
    let clave: String
    var color: Color = .cyan

    @State private var mostrar = false

    var body: some View {
        // Si hay modelo 3D se usa; si no, el esquema 2D
        let modelo3D = ModelosPiezas3D.modelo(para: clave)
        let esquema = EsquemasComponentes.esquema(para: clave)

        if modelo3D != nil || esquema != nil {
            Button {
                mostrar = true
            } label: {
                Label(
                    modelo3D != nil ? L("Ver en 3D") : L("Ver conectores"),
                    systemImage: modelo3D != nil ? "cube.transparent" : "point.3.connected.trianglepath.dotted"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(color)
            .sheet(isPresented: $mostrar) {
                NavigationStack {
                    if let modelo3D {
                        VisorPieza3DView(modelo: modelo3D)
                    } else if let esquema {
                        EsquemaInteractivoView(esquema: esquema)
                    }
                }
            }
        }
    }
}
