//
//  DiagnosticoLedView.swift
//  PcComponentIA
//

import SwiftUI

struct DiagnosticoLedView: View {

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // Módulo independiente de almacenamiento local
    @EnvironmentObject private var gestorDiagnosticos: GestorDiagnosticos
    @EnvironmentObject private var checklist: GestorChecklist

    @State private var modo: ModoDiagnostico = .led
    @State private var ledSeleccionado: String?
    @State private var codigoIntroducido = ""
    @State private var marcaSeleccionada: MarcaPlacaBase = .generico
    @State private var diagnosticoGuardadoSeleccionado: RegistroDiagnostico?
    @FocusState private var campoCodigoActivo: Bool
    
    // Variables para el Asistente IA e Historial
    @State private var mostrarAsistenteDiagnostico = false
    @State private var mostrarHistorialDiagnosticos = false
    @State private var consultaDiagnostico = ""

    // MARK: - Paleta de Colores Coherente y Dinámica

    private var colorAsistente: Color {
        Color(red: 0.88, green: 0.24, blue: 0.62)
    }

    private var colorAsistenteSecundario: Color {
        Color(red: 0.95, green: 0.26, blue: 0.50)
    }

    private var colorDiagnosticoError: Color {
        if modo == .led, let clave = ledSeleccionado {
            return colorFisicoHardware(para: clave)
        }
        return Color(red: 0.95, green: 0.37, blue: 0.10)
    }

    private var degradadoAsistente: LinearGradient {
        LinearGradient(
            colors: [colorAsistente, colorAsistenteSecundario],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private enum ModoDiagnostico: String, CaseIterable, Identifiable {
        case led = "Q-LED"
        case codigo = "Código POST"
        case pitidos = "Pitidos"

        var id: String { rawValue }

        var icono: String {
            switch self {
            case .led: return "circle.grid.2x2.fill"
            case .codigo: return "number.square.fill"
            case .pitidos: return "speaker.wave.2.fill"
            }
        }
    }

    private var codigoEncontrado: InfoCodigoPOST? {
        DatosDiagnosticoLED.codigo(
            para: codigoIntroducido,
            marca: marcaSeleccionada
        )
    }

    private var codigoLimpio: String {
        DatosDiagnosticoLED.normalizarCodigo(
            codigoIntroducido
        )
    }

    var body: some View {
        ZStack {
            fondoDiagnostico

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {
                    cabecera
                    selectorModo

                    switch modo {
                    case .led:
                        contenidoQLED
                    case .codigo:
                        contenidoPOST
                    case .pitidos:
                        PitidosDiagnosticoView(onGuardar: guardarDiagnosticoPitidos)
                    }

                    avisoSeguridad
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Diagnóstico de arranque")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $diagnosticoGuardadoSeleccionado) { registro in
            NavigationStack {
                DetalleDiagnosticoGuardadoView(registro: registro)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    mostrarHistorialDiagnosticos = true
                } label: {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(colorDiagnosticoError)
                        .frame(width: 34, height: 34)
                        .background(
                            Color.primary.opacity(colorScheme == .dark ? 0.09 : 0.05),
                            in: Circle()
                        )
                }
                .accessibilityLabel("Ver diagnósticos guardados")
            }
        }
        .sheet(isPresented: $mostrarAsistenteDiagnostico) {
            NavigationStack {
                ChatIAView(
                    consultaInicial: consultaDiagnostico,
                    enviarConsultaInicialAutomaticamente: true
                )
            }
        }
        .sheet(isPresented: $mostrarHistorialDiagnosticos) {
            NavigationStack {
                HistorialDiagnosticosView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cerrar") {
                                mostrarHistorialDiagnosticos = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Cabecera

    private var cabecera: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack(
                alignment: .top,
                spacing: 13
            ) {
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(colorDiagnosticoError == .white ? Color.black : Color.white)
                    .frame(width: 60, height: 60)
                    .background(colorDiagnosticoError, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 19,
                            style: .continuous
                        )
                        .stroke(
                            .white.opacity(0.36),
                            lineWidth: 1
                        )
                    }
                    .shadow(
                        color: colorDiagnosticoError.opacity(0.22),
                        radius: 7,
                        y: 3
                    )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    Text("ASISTENTE DE POST")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)

                    Text("Encuentra el fallo de arranque")
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.primary)

                    Text(
                        "Indica el LED fijo o el código mostrado por tu placa base."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                etiquetaEstado(
                    icono: "cpu.fill",
                    texto: "Placa base",
                    color: colorDiagnosticoError
                )

                etiquetaEstado(
                    icono: "magnifyingglass",
                    texto: "Diagnóstico guiado",
                    color: colorDiagnosticoError
                )
            }
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 24,
            tint: colorDiagnosticoError
        )
    }

    private func etiquetaEstado(
        icono: String,
        texto: String,
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icono)
                .font(.system(size: 10, weight: .bold))

            Text(texto.localizado)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(color == .white ? .primary : color)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            color.opacity(
                colorScheme == .dark ? 0.16 : 0.10
            ),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    color.opacity(0.22),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Selector

    private var selectorModo: some View {
        Picker(
            "Modo de diagnóstico",
            selection: $modo
        ) {
            ForEach(ModoDiagnostico.allCases) { modo in
                Label(modo.rawValue.localizado,
                    systemImage: modo.icono
                )
                .tag(modo)
            }
        }
        .pickerStyle(.segmented)
        .padding(6)
        .diagnosticoSurface(
            cornerRadius: 18,
            tint: colorDiagnosticoError
        )
        .onChange(of: modo) {
            campoCodigoActivo = false
        }
    }

    // MARK: - Q-LED

    private var contenidoQLED: some View {
        VStack(spacing: 18) {
            panelQLED

            if let clave = ledSeleccionado,
               let info = DatosDiagnosticoLED.errores[clave] {
                tarjetaDesgloseError(info: info)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            } else {
                tarjetaQLEDInicial
                    .transition(.opacity)
            }
        }
        .animation(
            .spring(
                response: 0.34,
                dampingFraction: 0.84
            ),
            value: ledSeleccionado
        )
    }

    private var panelQLED: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(spacing: 12) {
                Image(
                    systemName: "circle.grid.2x2.fill"
                )
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(colorDiagnosticoError == .white ? .primary : colorDiagnosticoError)
                .frame(width: 38, height: 38)
                .background(
                    colorDiagnosticoError.opacity(0.13),
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Indicadores Q-LED / EZ Debug")
                        .font(.headline)

                    Text(
                        "Toca el indicador que permanece encendido."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 9) {
                ForEach(
                    DatosDiagnosticoLED.ordenLeds,
                    id: \.self
                ) { clave in
                    if let led = DatosDiagnosticoLED.errores[clave] {
                        botonLED(
                            clave: clave,
                            info: led
                        )
                    }
                }
            }

            Text(
                "Los nombres y colores corresponden al estándar de hardware. Comprueba la serigrafía impresa junto a los LEDs de tu placa."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    private func botonLED(
        clave: String,
        info: InfoLedError
    ) -> some View {
        let seleccionado = ledSeleccionado == clave
        let colorFisico = colorFisicoHardware(para: clave)

        return Button {
            withAnimation(
                .spring(
                    response: 0.30,
                    dampingFraction: 0.72
                )
            ) {
                ledSeleccionado = seleccionado
                    ? nil
                    : clave
            }

            UIImpactFeedbackGenerator(
                style: .medium
            )
            .impactOccurred()
        } label: {
            VStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(
                            seleccionado
                                ? colorFisico
                                : Color.secondary.opacity(0.25)
                        )
                        .frame(width: 23, height: 23)
                        .shadow(
                            color: seleccionado
                                ? colorFisico.opacity(0.82)
                                : .clear,
                            radius: seleccionado ? 11 : 0
                        )

                    Circle()
                        .stroke(
                            .white.opacity(
                                seleccionado ? 0.68 : 0.15
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 23, height: 23)
                }

                Text(clave)
                    .font(
                        .system(
                            size: 11,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        seleccionado ? .primary : .secondary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                seleccionado
                    ? colorFisico.opacity(
                        colorScheme == .dark ? 0.18 : 0.11
                    )
                    : Color.primary.opacity(
                        colorScheme == .dark ? 0.05 : 0.03
                    ),
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    seleccionado
                        ? colorFisico.opacity(0.52)
                        : Color.primary.opacity(
                            colorScheme == .dark ? 0.11 : 0.07
                        ),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(DiagnosticoPressStyle())
        .accessibilityLabel(
            seleccionado
                ? L("Ocultar diagnóstico de \(clave)")
                : L("Diagnosticar LED \(clave)")
        )
    }

    private var tarjetaQLEDInicial: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(colorDiagnosticoError)

            Text("Selecciona el LED activo")
                .font(.headline)

            Text(
                "La placa suele encender estos indicadores durante unos segundos. El importante es el que se queda fijo y detiene el arranque."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 27)
        .padding(.horizontal, 18)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    // MARK: - Código POST

    private var contenidoPOST: some View {
        VStack(spacing: 18) {
            panelCodigoPOST

            if codigoLimpio.isEmpty {
                tarjetaCodigoInicial
            } else if let info = codigoEncontrado {
                tarjetaCodigoEncontrado(info: info)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            } else {
                tarjetaCodigoNoEncontrado
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
            }
        }
        .animation(
            .spring(
                response: 0.34,
                dampingFraction: 0.84
            ),
            value: codigoLimpio
        )
    }

    private var panelCodigoPOST: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(spacing: 12) {
                Image(systemName: "number.square.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(colorDiagnosticoError)
                .frame(width: 38, height: 38)
                .background(
                    colorDiagnosticoError.opacity(0.14),
                    in: RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Display de diagnóstico")
                        .font(.headline)

                    Text(
                        "Introduce el código de dos caracteres que ves en la placa."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            Picker(
                "Marca de la placa",
                selection: $marcaSeleccionada
            ) {
                ForEach(MarcaPlacaBase.allCases) { marca in
                    Text(marca.rawValue.localizado)
                        .tag(marca)
                }
            }
            .pickerStyle(.menu)
            .tint(colorDiagnosticoError == .white ? .primary : colorDiagnosticoError)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.06 : 0.035
                ),
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.11 : 0.07
                    ),
                    lineWidth: 1
                )
            }

            HStack(spacing: 12) {
                TextField(
                    "Ej. A2, C5, D6",
                    text: $codigoIntroducido
                )
                .focused($campoCodigoActivo)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .monospaced
                    )
                )
                .multilineTextAlignment(.center)
                .onChange(of: codigoIntroducido) { _, nuevoValor in
                    let normalizado = nuevoValor
                        .uppercased()
                        .filter { caracter in
                            caracter.isNumber ||
                            caracter.isLetter
                        }

                    let limitado = String(
                        normalizado.prefix(2)
                    )

                    if codigoIntroducido != limitado {
                        codigoIntroducido = limitado
                    }
                }

                Button {
                    codigoIntroducido = ""
                    campoCodigoActivo = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(
                            Color.primary.opacity(
                                colorScheme == .dark
                                    ? 0.10
                                    : 0.06
                            ),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .opacity(codigoIntroducido.isEmpty ? 0 : 1)
                .disabled(codigoIntroducido.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.065 : 0.04
                ),
                in: RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .stroke(
                    campoCodigoActivo
                        ? colorDiagnosticoError.opacity(0.70)
                        : Color.primary.opacity(
                            colorScheme == .dark ? 0.12 : 0.08
                        ),
                    lineWidth: campoCodigoActivo ? 1.5 : 1
                )
            }

            Text(
                "Los códigos POST no están totalmente estandarizados: confirma el resultado con el manual específico de tu placa base."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    private var tarjetaCodigoInicial: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 31, weight: .medium))
                .foregroundStyle(colorDiagnosticoError)

            Text("Introduce el código visible")
                .font(.headline)

            Text(
                "Suele aparecer en una pequeña pantalla de dos dígitos de la placa base, cerca de la zona inferior o del borde derecho."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 27)
        .padding(.horizontal, 18)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    private var tarjetaCodigoNoEncontrado: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack(spacing: 10) {
                Image(
                    systemName: "questionmark.circle.fill"
                )
                .font(.title2)
                .foregroundStyle(colorDiagnosticoError)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Código \(codigoLimpio) no incluido aún")
                        .font(.headline)

                    Text(
                        "No quiero asignarle un significado incorrecto."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Text(
                "Revisa el manual de la placa buscando “Q-Code”, “Debug LED”, “POST Code” o “Dr. Debug”. Si me dices la marca y el modelo de tu placa, podremos ampliar esta tabla con datos exactos."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            
            VStack(spacing: 10) {
                botonConsultarAsistente(
                    titulo: L("Consultar este código al asistente"),
                    color: colorAsistente
                ) {
                    consultarPostConAsistente(info: nil)
                }
                
                botonDobleAccion(
                    titulo: "Guardar diagnóstico",
                    icono: "tray.and.arrow.down.fill",
                    color: .secondary
                ) {
                    guardarDiagnosticoPOST(info: nil)
                }
            }
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    private func tarjetaCodigoEncontrado(
        info: InfoCodigoPOST
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(spacing: 12) {
                Text(info.codigo)
                    .font(
                        .system(
                            size: 27,
                            weight: .black,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(info.categoria.color == .white ? .black : info.categoria.color)
                    .frame(width: 66, height: 54)
                    .background(
                        info.categoria.color.opacity(
                            colorScheme == .dark ? 0.18 : 0.11
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 15,
                            style: .continuous
                        )
                        .stroke(
                            info.categoria.color.opacity(0.40),
                            lineWidth: 1
                        )
                    }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    HStack(spacing: 6) {
                        Image(
                            systemName: info.categoria.icono
                        )
                        .font(.caption.weight(.bold))

                        Text(info.categoria.titulo.localizado)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(info.categoria.color == .white ? .primary : info.categoria.color)

                    Text(info.titulo.localizado)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }

            Text(info.descripcion.localizado)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Divider()
                .overlay(
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.12 : 0.08
                    )
                )

            Text("QUÉ COMPROBAR")
                .font(.caption2.weight(.black))
                .tracking(0.9)
                .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(
                    EnlacesDiagnostico.enlaces(
                        para: info.acciones,
                        categoria: info.categoria
                    )
                ) { enlace in
                    tarjetaAccionDiagnostico(
                        enlace: enlace,
                        color: info.categoria.color
                    )
                }
            }

            HStack(
                alignment: .top,
                spacing: 8
            ) {
                Image(
                    systemName: "info.circle.fill"
                )
                .foregroundStyle(colorDiagnosticoError == .white ? Color.primary : colorDiagnosticoError)
                .padding(.top, 1)

                Text(info.advertencia.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(10)
            .background(
                colorDiagnosticoError.opacity(
                    colorScheme == .dark ? 0.11 : 0.07
                ),
                in: RoundedRectangle(
                    cornerRadius: 13,
                    style: .continuous
                )
            )
            
            VStack(spacing: 10) {
                botonConsultarAsistente(
                    titulo: L("Pedir más ayuda al asistente"),
                    color: colorAsistente
                ) {
                    consultarPostConAsistente(info: info)
                }
                
                botonDobleAccion(
                    titulo: "Guardar diagnóstico",
                    icono: "tray.and.arrow.down.fill",
                    color: info.categoria.color
                ) {
                    guardarDiagnosticoPOST(info: info)
                }
            }
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: info.categoria.color
        )
    }

    // MARK: - Ficha LED

    private func tarjetaDesgloseError(
        info: InfoLedError
    ) -> some View {
        return VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(spacing: 11) {
                Image(
                    systemName: "exclamationmark.triangle.fill"
                )
                .font(.title2)
                .foregroundStyle(colorDiagnosticoError == .white ? .primary : colorDiagnosticoError)
                .frame(width: 40, height: 40)
                .background(
                    colorDiagnosticoError.opacity(
                        colorScheme == .dark ? 0.17 : 0.10
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("INDICADOR ACTIVO")
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)

                    Text(info.nombre.localizado)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }

            Text(info.descripcion.localizado)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            consejoRapido(
                texto: info.consejoRapido,
                color: colorDiagnosticoError
            )

            Divider()
                .overlay(
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.12 : 0.08
                    )
                )

            Text("PASOS RECOMENDADOS")
                .font(.caption2.weight(.black))
                .tracking(0.9)
                .foregroundStyle(.secondary)

            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                ForEach(
                    EnlacesDiagnostico.enlaces(
                        para: info.pasosAComprobar
                    )
                ) { enlace in
                    tarjetaAccionDiagnostico(
                        enlace: enlace,
                        color: colorDiagnosticoError
                    )
                }
            }
            
            if let clave = ledSeleccionado {
                VStack(spacing: 10) {
                    botonConsultarAsistente(
                        titulo: L("Consultar este LED al asistente"),
                        color: colorAsistente
                    ) {
                        consultarLEDConAsistente(
                            clave: clave,
                            info: info
                        )
                    }
                    
                    botonDobleAccion(
                        titulo: "Guardar diagnóstico",
                        icono: "tray.and.arrow.down.fill",
                        color: colorDiagnosticoError
                    ) {
                        guardarDiagnosticoLED(clave: clave, info: info)
                    }
                }
            }
        }
        .padding(16)
        .diagnosticoSurface(
            cornerRadius: 23,
            tint: colorDiagnosticoError
        )
    }

    private func tarjetaAccionDiagnostico(
        enlace: EnlaceDiagnostico,
        color: Color
    ) -> some View {
        let colorSeguro = color == .white ? Color.primary : color
        let pasoCompletado = enlace.pasoChecklist.map {
            checklist.estaCompletadoPaso(nombre: $0)
        } ?? false

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: pasoCompletado ? "checkmark.circle.fill" : "wrench.and.screwdriver.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(pasoCompletado ? Color.green : colorSeguro)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(enlace.titulo.localizado)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let paso = enlace.pasoChecklist {
                        Text(paso.localizado)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if enlace.tieneComponente || enlace.tieneChecklist {
                HStack(spacing: 8) {
                    if let clave = enlace.componenteClave,
                       let info = DatosHardware.obtenerDiccionario()[clave] {
                        NavigationLink {
                            DetalleComponenteInfoView(
                                nombre: clave,
                                info: info,
                                colorPrincipal: colorSeguro,
                                colorSecundario: .green
                            )
                        } label: {
                            etiquetaAccionDiagnostico(
                                icono: "info.circle.fill",
                                texto: "Ficha",
                                color: colorSeguro
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            DetalleComponenteInfoView(
                                nombre: clave,
                                info: info,
                                colorPrincipal: .green,
                                colorSecundario: colorSeguro
                            )
                        } label: {
                            etiquetaAccionDiagnostico(
                                icono: "wrench.and.screwdriver.fill",
                                texto: "Guía",
                                color: .green
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if let paso = enlace.pasoChecklist {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            _ = checklist.alternarPaso(nombre: paso)
                        } label: {
                            etiquetaAccionDiagnostico(
                                icono: pasoCompletado ? "checkmark.circle.fill" : "circle",
                                texto: pasoCompletado ? "Hecho" : "Marcar",
                                color: pasoCompletado ? .green : .orange
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(11)
        .background(
            color.opacity(
                colorScheme == .dark ? 0.10 : 0.055
            ),
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                color.opacity(0.20),
                lineWidth: 1
            )
        }
    }

    private func etiquetaAccionDiagnostico(
        icono: String,
        texto: String,
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icono)
                .font(.caption2.weight(.bold))

            Text(texto.localizado)
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(color == .white ? .primary : color)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            color.opacity(
                colorScheme == .dark ? 0.16 : 0.10
            ),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(color.opacity(0.24), lineWidth: 1)
        }
    }

    private func consejoRapido(
        texto: String,
        color: Color
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 9
        ) {
            Image(
                systemName: "bolt.fill"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(color == .white ? .primary : color)
            .padding(.top, 2)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text("Consejo rápido")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color == .white ? .primary : color)

                Text(texto.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .padding(11)
        .background(
            color.opacity(
                colorScheme == .dark ? 0.12 : 0.075
            ),
            in: RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                color.opacity(0.24),
                lineWidth: 1
            )
        }
    }
    
    // MARK: - Auxiliares de Color de Hardware Físico

    private func colorFisicoHardware(para clave: String) -> Color {
        switch clave.uppercased() {
        case "CPU": return .red
        case "DRAM": return .yellow
        case "VGA": return .white
        case "BOOT": return .green
        default: return Color(red: 0.95, green: 0.37, blue: 0.10)
        }
    }

    private func nombreDelColorLED(_ clave: String) -> String {
        switch clave.uppercased() {
        case "CPU": return "rojo"
        case "DRAM": return "amarillo"
        case "VGA": return "blanco"
        case "BOOT": return "verde"
        default: return L("no especificado")
        }
    }

    // MARK: - Funciones del Asistente y Persistencia Local
    
    private func guardarDiagnosticoLED(
        clave: String,
        info: InfoLedError
    ) {
        let registro = RegistroDiagnostico(
            marcaPlaca: marcaSeleccionada.rawValue,
            tipo: .led,
            codigoOIndicador: clave,
            tituloResultado: info.nombre,
            resultado: info.descripcion,
            pasosRecomendados: info.pasosAComprobar
        )
        
        gestorDiagnosticos.guardar(registro)
        
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
            
        diagnosticoGuardadoSeleccionado = registro
    }

    private func guardarDiagnosticoPOST(
        info: InfoCodigoPOST?
    ) {
        let codigo = codigoLimpio.isEmpty ? L("No indicado") : codigoLimpio

        let titulo: String
        let resultado: String
        let pasos: [String]

        if let info {
            titulo = info.titulo
            resultado = info.descripcion
            pasos = info.acciones
        } else {
            titulo = L("Código sin coincidencia local")
            resultado = L("El código \(codigo) no está incluido en la base local. Consulta el manual específico de la placa base o usa el asistente.")
            pasos = [
                L("Confirmar marca y modelo exacto de placa base"),
                L("Consultar el manual buscando Q-Code, POST Code o Debug LED"),
                L("Anotar los componentes instalados y cualquier cambio reciente")
            ]
        }

        let registro = RegistroDiagnostico(
            marcaPlaca: marcaSeleccionada.rawValue,
            tipo: .codigoPOST,
            codigoOIndicador: codigo,
            tituloResultado: titulo,
            resultado: resultado,
            pasosRecomendados: pasos
        )
        
        gestorDiagnosticos.guardar(registro)
        
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
            
        diagnosticoGuardadoSeleccionado = registro
    }

    private func guardarDiagnosticoPitidos(_ codigo: CodigoPitidos) {
        let registro = RegistroDiagnostico(
            marcaPlaca: L("BIOS \(codigo.bios.rawValue)"),
            tipo: .pitidos,
            codigoOIndicador: codigo.patronTexto,
            tituloResultado: codigo.titulo,
            resultado: codigo.descripcion,
            pasosRecomendados: codigo.pasos
        )

        gestorDiagnosticos.guardar(registro)

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)

        diagnosticoGuardadoSeleccionado = registro
    }
    
    private func descubrirLEDColor(_ clave: String) -> String {
        return nombreDelColorLED(clave)
    }

    private func consultarLEDConAsistente(
        clave: String,
        info: InfoLedError
    ) {
        consultaDiagnostico = """
        Necesito ayuda para diagnosticar un PC que no arranca.

        Tipo de diagnóstico: LED de placa base / Q-LED / EZ Debug.
        Indicador que permanece encendido: \(clave).
        Componente o fase afectada: \(info.nombre).
        Color del LED: \(nombreDelColorLED(clave)).
        Marca de placa seleccionada: \(marcaSeleccionada.rawValue).

        Diagnóstico local:
        \(info.descripcion)

        Consejo rápido:
        \(info.consejoRapido)

        Pasos que recomienda la aplicación:
        \(listaConGuiones(info.pasosAComprobar))

        Indica qué debo comprobar primero, en orden. Diferencia las pruebas que puedo hacer con el PC apagado y desconectado de las que requieren entrar en BIOS o arrancar. Si el significado depende del modelo exacto de placa base, dímelo.
        """

        mostrarAsistenteDiagnostico = true
    }

    private func consultarPostConAsistente(
        info: InfoCodigoPOST?
    ) {
        let codigo = codigoLimpio.isEmpty
            ? L("No indicado")
            : codigoLimpio

        let marca = marcaSeleccionada.rawValue

        if let info {
            consultaDiagnostico = """
            Necesito ayuda para diagnosticar un PC que no arranca.

            Tipo de diagnóstico: Código POST/Q-Code
            Marca de placa seleccionada: \(marca)
            Código mostrado: \(codigo)
            Resultado local: \(info.titulo)
            Categoría probable: \(info.categoria.titulo)

            Descripción:
            \(info.descripcion)

            Pasos recomendados por la aplicación:
            \(listaConGuiones(info.acciones))

            Advertencia:
            \(info.advertencia)

            Indica qué debo comprobar ahora, en orden. No asumas que este código significa lo mismo en todos los modelos: si necesitas el modelo exacto de placa o la versión de BIOS para confirmarlo, indícalo.
            """
        } else {
            consultaDiagnostico = """
            Necesito ayuda para diagnosticar un PC que no arranca.

            Tipo de diagnóstico: Código POST/Q-Code
            Marca de placa seleccionada: \(marca)
            Código mostrado: \(codigo)

            Este código no aparece en la base local de la aplicación. No quiero asignarle un significado incorrecto.

            Indica posibles significados para esta marca, qué comprobaciones seguras debo realizar primero y qué modelo exacto de placa, versión de BIOS u otra información necesitas para confirmarlo con el manual oficial.
            """
        }

        mostrarAsistenteDiagnostico = true
    }

    private func listaConGuiones(
        _ elementos: [String]
    ) -> String {
        elementos
            .map { "- \($0.localizado)" }
            .joined(separator: "\n")
    }

    private func botonConsultarAsistente(
        titulo: String,
        icono: String = "sparkles",
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icono)
                    .font(.system(size: 14, weight: .bold))

                Text(titulo.localizado)
                    .font(.subheadline.weight(.bold))

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(degradadoAsistente, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(
                    cornerRadius: 15,
                    style: .continuous
                )
                .stroke(
                    .white.opacity(0.30),
                    lineWidth: 1
                )
            }
            .shadow(
                color: colorAsistente.opacity(0.25),
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(DiagnosticoPressStyle())
    }
    
    private func botonDobleAccion(
        titulo: String,
        icono: String,
        color: Color,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            HStack(spacing: 9) {
                Image(systemName: icono)
                    .font(.system(size: 13, weight: .semibold))
                Text(titulo.localizado)
                    .font(.footnote.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(color == .white ? .black : (color == .secondary ? .primary : color))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                color == .secondary ? Color.primary.opacity(0.06) : color.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color == .secondary ? Color.primary.opacity(0.10) : color.opacity(0.24), lineWidth: 1)
            }
        }
        .buttonStyle(DiagnosticoPressStyle())
    }

    // MARK: - Seguridad

    private var avisoSeguridad: some View {
        HStack(
            alignment: .top,
            spacing: 9
        ) {
            Image(
                systemName: "hand.raised.fill"
            )
            .font(.caption.weight(.bold))
            .foregroundStyle(colorDiagnosticoError == .white ? Color.primary : colorDiagnosticoError)
            .padding(.top, 2)

            Text(
                "Antes de retirar o instalar CPU, RAM, GPU o cables de alimentación, apaga el equipo, desconecta la fuente y mantén pulsado el botón de encendido unos segundos."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
        .padding(13)
        .diagnosticoSurface(
            cornerRadius: 18,
            tint: colorDiagnosticoError
        )
    }

    // MARK: - Fondo

    private var fondoDiagnostico: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.038, green: 0.040, blue: 0.048),
                        Color(red: 0.018, green: 0.020, blue: 0.027),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorDiagnosticoError.opacity(0.11),
                        colorAsistenteSecundario.opacity(0.035),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.975, green: 0.982, blue: 0.995),
                        Color(red: 0.940, green: 0.956, blue: 0.982),
                        Color(red: 0.910, green: 0.930, blue: 0.965)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        colorDiagnosticoError.opacity(0.13),
                        colorAsistenteSecundario.opacity(0.035),
                        .clear
                    ],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Extensiones Requeridas Locales Obligatorias de Compilación
extension View {
    func diagnosticoSurface(cornerRadius: CGFloat, tint: Color) -> some View {
        modifier(DiagnosticoSurfaceModifier(cornerRadius: cornerRadius, tint: tint))
    }
}

struct DiagnosticoSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background {
                forma.fill(colorScheme == .dark ? Color(red: 0.075, green: 0.082, blue: 0.105).opacity(0.72) : Color.white.opacity(0.52))
            }
            .background {
                forma.fill(LinearGradient(colors: colorScheme == .dark ? [tint.opacity(0.075), .white.opacity(0.025), .clear] : [tint.opacity(0.055), .white.opacity(0.42), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                forma.stroke(LinearGradient(colors: [.white.opacity(colorScheme == .dark ? 0.18 : 0.70), tint.opacity(colorScheme == .dark ? 0.14 : 0.11), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                .allowsHitTesting(false)
            }
            .shadow(color: colorScheme == .dark ? .black.opacity(0.24) : tint.opacity(0.08), radius: 10, y: 5)
    }
}

struct DiagnosticoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
