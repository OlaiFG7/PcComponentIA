//
//  DetalleBuildView.swift
//  PcComponentIA
//

import SwiftUI

struct DetalleBuildView: View {

    @Binding var build: Build
    var onEliminar: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var checklist: GestorChecklist

    @State private var mostrarNuevoComponente = false
    @State private var mostrarConfirmarEliminar = false
    @State private var mostrarEditarInformacion = false
    @State private var mostrarConfirmarEliminarComponente = false
    @State private var mostrarAlertaPCIe = false

    @State private var componenteEditando: ComponenteBuild?

    @State private var nombreComponente = ""
    @State private var categoriaComponente = categoriasDisponibles.first ?? "CPU"
    @State private var precioComponente = ""
    @State private var notasComponente = ""

    @State private var nombreComponenteEditando = ""
    @State private var categoriaComponenteEditando = (
        categoriasDisponibles.first ?? "CPU"
    )
    @State private var precioComponenteEditando = ""
    @State private var notasComponenteEditando = ""

    var body: some View {
        ZStack {
            fondoAsistente

            ScrollView {
                VStack(alignment: .leading, spacing: 17) {
                    cabeceraBuild
                    resumenEconomico
                    analisisBuild

                    if !build.componentes.isEmpty {
                        SeccionCompatibilidadView(build: build)
                    }

                    botonMontarEstaBuild

                    if let advertencia = build.advertenciaPCIe {
                        seccionAdvertenciaPCIe(advertencia)
                    }
                    
                    seccionComponentes
                    seccionNotas
                    botonEliminar
                }
                .frame(maxWidth: 860)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(build.nombre.isEmpty ? "Build" : build.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                BotonPreguntarAsistente(contexto: build.contextoChat, estilo: .icono)
            }
            ToolbarItem(placement: .topBarTrailing) {
                MenuCompartirBuild(build: build)
            }
        }
        .onChange(of: build.nombre) { _, nuevo in
            // El panel del checklist muestra el nombre de la build que se está montando
            if checklist.buildActiva == build.id {
                checklist.activar(build: build.id, nombre: nuevo.isEmpty ? L("Mi build") : nuevo)
            }
        }
        .sheet(isPresented: $mostrarEditarInformacion) {
            formularioEditarBuild
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $mostrarNuevoComponente) {
            formularioNuevoComponente
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $componenteEditando) { componente in
            formularioEditarComponente(componente)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            "¿Eliminar este componente?",
            isPresented: $mostrarConfirmarEliminarComponente
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                if let componente = componenteEditando {
                    eliminarComponente(id: componente.id)
                }

                componenteEditando = nil
            }
        } message: {
            Text("El componente se quitará de este build.")
        }
        .alert(
            "¿Eliminar este build?",
            isPresented: $mostrarConfirmarEliminar
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                onEliminar()
                dismiss()
            }
        }
        .alert(
            "Conflicto de Líneas PCIe",
            isPresented: $mostrarAlertaPCIe
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Ojo: si conectas el segundo NVMe en la ranura M2_2, tu puerto SATA_1 quedará desactivado o tu tarjeta gráfica bajará de x16 a x8.")
        }
    }

    // MARK: - Cabecera

    private var cabeceraBuild: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 13) {
                Image(systemName: iconoEtiqueta(build.etiqueta))
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(colorEtiqueta(build.etiqueta))
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [
                                colorEtiqueta(build.etiqueta).opacity(
                                    colorScheme == .dark ? 0.30 : 0.17
                                ),
                                .blue.opacity(
                                    colorScheme == .dark ? 0.09 : 0.05
                                )
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .stroke(
                            colorEtiqueta(build.etiqueta).opacity(0.30),
                            lineWidth: 1
                        )
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("MI CONFIGURACIÓN")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    Text(
                        build.nombre.isEmpty
                            ? L("Build sin nombre")
                            : build.nombre
                    )
                    .font(
                        .system(
                            size: 23,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                etiquetaBuild(
                    titulo: build.etiqueta,
                    color: colorEtiqueta(build.etiqueta),
                    icono: iconoEtiqueta(build.etiqueta)
                )

                etiquetaBuild(
                    titulo: textoCantidadComponentes,
                    color: .blue,
                    icono: "cube.box.fill"
                )

                Spacer(minLength: 0)

                Button {
                    mostrarEditarInformacion = true
                } label: {
                    Label(
                        "Editar build",
                        systemImage: "pencil"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(
                        Color.primary.opacity(
                            colorScheme == .dark ? 0.10 : 0.06
                        ),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                Color.primary.opacity(
                                    colorScheme == .dark ? 0.14 : 0.09
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(BuildDetailPressStyle())
            }

            panelConfiguracion
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 24,
            tint: colorEtiqueta(build.etiqueta)
        )
    }

    private var panelConfiguracion: some View {
        HStack(spacing: 10) {
            datoConfiguracion(
                icono: "tag.fill",
                titulo: "Etiqueta",
                valor: build.etiqueta.isEmpty
                    ? "Sin etiqueta"
                    : build.etiqueta,
                color: colorEtiqueta(build.etiqueta)
            )

            datoConfiguracion(
                icono: "target",
                titulo: "Presupuesto",
                valor: build.presupuestoNumerico > 0
                    ? build.presupuestoNumerico.formatoEuro
                    : "No definido",
                color: build.presupuestoNumerico > 0
                    ? .green
                    : .orange
            )
        }
    }

    private func datoConfiguracion(
        icono: String,
        titulo: String,
        valor: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icono)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    color.opacity(0.14),
                    in: RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(titulo.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(.secondary)

                Text(valor)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            Color.primary.opacity(
                colorScheme == .dark ? 0.055 : 0.035
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
                Color.primary.opacity(
                    colorScheme == .dark ? 0.10 : 0.07
                ),
                lineWidth: 1
            )
        }
    }

    // MARK: - Economía

    private var resumenEconomico: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                etiquetaSeccion(
                    icono: "eurosign.circle.fill",
                    titulo: "Resumen económico",
                    color: .green
                )

                Spacer(minLength: 0)

                Text(build.precioTotal.formatoEuro)
                    .font(
                        .system(
                            size: 22,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(colorTotal)
                    .monospacedDigit()
            }

            Divider()
                .overlay(
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.11 : 0.08
                    )
                )

            if build.presupuestoNumerico > 0 {
                VStack(spacing: 9) {
                    HStack {
                        Text("Presupuesto objetivo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(build.presupuestoNumerico.formatoEuro)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }

                    ProgressView(value: porcentajePresupuesto)
                        .tint(colorTotal)
                        .scaleEffect(y: 1.35)
                        .padding(.vertical, 2)

                    HStack {
                        Text(
                            diferenciaPresupuesto >= 0
                                ? "Margen disponible"
                                : "Presupuesto superado"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                        Spacer()

                        Text(
                            diferenciaPresupuesto
                                .magnitude
                                .formatoEuro
                        )
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(colorTotal)
                        .monospacedDigit()
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "target")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.orange)
                        .frame(width: 38, height: 38)
                        .background(
                            .orange.opacity(0.14),
                            in: RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sin presupuesto definido")
                            .font(.subheadline.weight(.semibold))

                        Text(
                            "Pulsa “Editar build” para definir un límite de gasto."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 23,
            tint: .green
        )
    }

    // MARK: - Estado

    private var analisisBuild: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                etiquetaSeccion(
                    icono: iconoEstadoBuild,
                    titulo: "Estado del build",
                    color: colorEstadoBuild
                )

                Spacer(minLength: 0)

                Text(textoEstadoBuild.localizado)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(colorEstadoBuild)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        colorEstadoBuild.opacity(
                            colorScheme == .dark ? 0.18 : 0.12
                        ),
                        in: Capsule()
                    )
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconoEstadoBuild)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(colorEstadoBuild)
                    .frame(width: 38, height: 38)
                    .background(
                        colorEstadoBuild.opacity(
                            colorScheme == .dark ? 0.18 : 0.12
                        ),
                        in: RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(mensajeEstadoBuild.localizado)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(detalleEstadoBuild.localizado)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)
            }

            if !categoriasEsencialesFaltantes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PIEZAS PRINCIPALES PENDIENTES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 7) {
                        ForEach(
                            categoriasEsencialesFaltantes,
                            id: \.self
                        ) { categoria in
                            HStack(spacing: 5) {
                                Image(
                                    systemName: iconoCategoria(categoria)
                                )
                                .font(
                                    .system(
                                        size: 10,
                                        weight: .bold
                                    )
                                )

                                Text(categoria.localizado)
                                    .font(.caption2.weight(.bold))
                            }
                            .foregroundStyle(
                                colorCategoria(categoria)
                            )
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(
                                colorCategoria(categoria).opacity(
                                    colorScheme == .dark
                                        ? 0.16
                                        : 0.10
                                ),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(
                                        colorCategoria(categoria)
                                            .opacity(0.22),
                                        lineWidth: 1
                                    )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 23,
            tint: colorEstadoBuild
        )
    }

    private func seccionAdvertenciaPCIe(_ advertencia: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(
                    .orange.opacity(colorScheme == .dark ? 0.22 : 0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Advertencia de Carriles PCIe")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(advertencia.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 23,
            tint: .orange
        )
    }

    private var categoriasPrincipales: [String] {
        [
            "CPU",
            "Placa base",
            "RAM",
            "Almacenamiento",
            "Fuente",
            "Caja"
        ]
    }

    private var categoriasPresentes: Set<String> {
        Set(build.componentes.map(\.categoria))
    }

    private var categoriasEsencialesFaltantes: [String] {
        categoriasPrincipales.filter {
            !categoriasPresentes.contains($0)
        }
    }

    private var textoEstadoBuild: String {
        if build.componentes.isEmpty {
            return L("Sin empezar")
        }

        if !categoriasEsencialesFaltantes.isEmpty {
            return L("Faltan piezas")
        }

        if build.presupuestoNumerico > 0 &&
            build.precioTotal > build.presupuestoNumerico {
            return L("Fuera de presupuesto")
        }

        return L("Base completa")
    }

    private var mensajeEstadoBuild: String {
        if build.componentes.isEmpty {
            return L("Empieza añadiendo los componentes de tu PC.")
        }

        if !categoriasEsencialesFaltantes.isEmpty {
            return L("Aún no tienes una configuración base completa.")
        }

        if build.presupuestoNumerico > 0 &&
            build.precioTotal > build.presupuestoNumerico {
            return L("La configuración supera el presupuesto objetivo.")
        }

        return L("Ya tienes los componentes principales del equipo.")
    }

    private var detalleEstadoBuild: String {
        if build.componentes.isEmpty {
            return L("Añade CPU, placa base, RAM, almacenamiento, fuente y caja para comenzar.")
        }

        if !categoriasEsencialesFaltantes.isEmpty {
            // Las categorías se guardan en español: se traducen al juntarlas
            let faltan = categoriasEsencialesFaltantes.map(\.localizado).joined(separator: ", ")
            return L("Pendiente: \(faltan).")
        }

        if build.presupuestoNumerico > 0 &&
            build.precioTotal > build.presupuestoNumerico {
            let exceso = (
                build.precioTotal -
                build.presupuestoNumerico
            )
            .formatoEuro

            return L("Te pasas \(exceso) del límite definido.")
        }

        if build.presupuestoNumerico > 0 {
            return L("Vas dentro del presupuesto y puedes revisar componentes opcionales, como GPU o refrigeración.")
        }

        return L("Añade un presupuesto si quieres controlar el gasto total.")
    }

    private var colorEstadoBuild: Color {
        if build.componentes.isEmpty {
            return .blue
        }

        if !categoriasEsencialesFaltantes.isEmpty {
            return .orange
        }

        if build.presupuestoNumerico > 0 &&
            build.precioTotal > build.presupuestoNumerico {
            return .red
        }

        return .green
    }

    private var iconoEstadoBuild: String {
        if build.componentes.isEmpty {
            return "cube.box"
        }

        if !categoriasEsencialesFaltantes.isEmpty {
            return "exclamationmark.triangle.fill"
        }

        if build.presupuestoNumerico > 0 &&
            build.precioTotal > build.presupuestoNumerico {
            return "eurosign.circle.fill"
        }

        return "checkmark.seal.fill"
    }

    // MARK: - Componentes

    private var seccionComponentes: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                etiquetaSeccion(
                    icono: "cpu.fill",
                    titulo: "Componentes",
                    color: .blue
                )

                Spacer(minLength: 0)

                Button {
                    mostrarNuevoComponente = true
                } label: {
                    Label(
                        "Añadir",
                        systemImage: "plus"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                }
                .buttonStyle(BuildDetailPressStyle())
            }

            if build.componentes.isEmpty {
                estadoComponentesVacio
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(build.componentes) { componente in
                        filaComponente(componente)
                            .contextMenu { menuComponente(componente) }
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
                .animation(Animaciones.muelle, value: build.componentes.map(\.id))
            }
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 23,
            tint: .blue
        )
    }

    private var estadoComponentesVacio: some View {
        VStack(spacing: 9) {
            Image(systemName: "cube.box")
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(.blue)

            Text("Todavía no hay componentes")
                .font(.subheadline.weight(.semibold))

            Text(
                "Añade las piezas de tu configuración para calcular el coste total."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 21)
        .background(
            Color.primary.opacity(
                colorScheme == .dark ? 0.045 : 0.030
            ),
            in: RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
        )
    }

    private func filaComponente(
        _ componente: ComponenteBuild
    ) -> some View {
        Button {
            prepararEdicion(componente)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: iconoCategoria(componente.categoria))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        colorCategoria(componente.categoria)
                    )
                    .frame(width: 42, height: 42)
                    .background(
                        colorCategoria(componente.categoria).opacity(0.14),
                        in: RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(componente.nombre)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 7) {
                        Text(componente.categoria.localizado)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                colorCategoria(componente.categoria),
                                in: Capsule()
                            )

                        if !componente.notas
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty {
                            Text(componente.notas)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 5) {
                    if let precio = precioNumerico(componente.precio) {
                        Text(precio.formatoEuro)
                            .font(
                                .subheadline
                                    .monospacedDigit()
                                    .weight(.bold)
                            )
                            .foregroundStyle(.green)
                    } else {
                        Text("Sin precio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(11)
            .contentShape(Rectangle())
            .background(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.052 : 0.035
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
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.09 : 0.06
                    ),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(BuildDetailPressStyle())
    }

    // MARK: - Notas

    private var seccionNotas: some View {
        VStack(alignment: .leading, spacing: 10) {
            etiquetaSeccion(
                icono: "note.text",
                titulo: "Notas del build",
                color: .orange
            )

            TextEditor(text: $build.notas)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 105)
                .padding(11)
                .background(
                    Color.primary.opacity(
                        colorScheme == .dark ? 0.055 : 0.035
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
                        Color.primary.opacity(
                            colorScheme == .dark ? 0.10 : 0.07
                        ),
                        lineWidth: 1
                    )
                }
        }
        .padding(16)
        .buildDetailGlassSurface(
            cornerRadius: 23,
            tint: .orange
        )
    }

    // MARK: - Eliminar build

    private var botonEliminar: some View {
        Button(role: .destructive) {
            mostrarConfirmarEliminar = true
        } label: {
            Label(
                "Eliminar este build",
                systemImage: "trash"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                .red.opacity(
                    colorScheme == .dark ? 0.12 : 0.08
                ),
                in: RoundedRectangle(
                    cornerRadius: 19,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 19,
                    style: .continuous
                )
                .stroke(
                    .red.opacity(0.24),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(BuildDetailPressStyle())
    }

    // MARK: - Editar build

    private var formularioEditarBuild: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Ej. PC Gaming 1440p",
                        text: $build.nombre
                    )

                    Picker(
                        "Uso principal",
                        selection: $build.etiqueta
                    ) {
                        ForEach(
                            etiquetasDisponibles,
                            id: \.self
                        ) { etiqueta in
                            Label(etiqueta.localizado,
                                systemImage: iconoEtiqueta(etiqueta)
                            )
                            .tag(etiqueta)
                        }
                    }
                } header: {
                    Text("Identidad del build")
                } footer: {
                    Text(
                        "El nombre te ayuda a distinguir esta configuración. La etiqueta define su propósito principal."
                    )
                }

                Section {
                    HStack {
                        Text("Límite de gasto")

                        Spacer()

                        TextField(
                            "No definido",
                            text: $build.presupuestoObjetivo
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 130)

                        Text("€")
                            .foregroundStyle(.secondary)
                    }

                    if build.presupuestoNumerico > 0 {
                        Button(role: .destructive) {
                            build.presupuestoObjetivo = ""
                        } label: {
                            Label(
                                "Quitar presupuesto",
                                systemImage: "xmark.circle"
                            )
                        }
                    }
                } header: {
                    Text("Presupuesto")
                } footer: {
                    Text(
                        "Se compara automáticamente con el coste total de los componentes añadidos."
                    )
                }
            }
            .navigationTitle("Editar build")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        mostrarEditarInformacion = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        mostrarEditarInformacion = false

                        UINotificationFeedbackGenerator()
                            .notificationOccurred(.success)
                    }
                }
            }
        }
    }

    // MARK: - Nuevo componente

    private var formularioNuevoComponente: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Categoría",
                        selection: $categoriaComponente
                    ) {
                        ForEach(
                            categoriasDisponibles,
                            id: \.self
                        ) { categoria in
                            Label(categoria.localizado,
                                systemImage: iconoCategoria(categoria)
                            )
                            .tag(categoria)
                        }
                    }

                    TextField(
                        "Nombre (ej. Ryzen 7 7800X3D)",
                        text: $nombreComponente
                    )

                    HStack {
                        Text("Precio")

                        Spacer()

                        TextField(
                            "0",
                            text: $precioComponente
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)

                        Text("€")
                            .foregroundStyle(.secondary)
                    }

                    TextField(
                        "Notas (opcional)",
                        text: $notasComponente,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text("Componente")
                }
            }
            .navigationTitle("Nuevo componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        limpiarFormularioNuevoComponente()
                        mostrarNuevoComponente = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        añadirComponente()
                    }
                    .disabled(
                        nombreComponente
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }

    // MARK: - Editar componente

    private func formularioEditarComponente(
        _ componente: ComponenteBuild
    ) -> some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Categoría",
                        selection: $categoriaComponenteEditando
                    ) {
                        ForEach(
                            categoriasDisponibles,
                            id: \.self
                        ) { categoria in
                            Label(categoria.localizado,
                                systemImage: iconoCategoria(categoria)
                            )
                            .tag(categoria)
                        }
                    }

                    TextField(
                        "Nombre del componente",
                        text: $nombreComponenteEditando
                    )

                    HStack {
                        Text("Precio")

                        Spacer()

                        TextField(
                            "Sin precio",
                            text: $precioComponenteEditando
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)

                        Text("€")
                            .foregroundStyle(.secondary)
                    }

                    TextField(
                        "Notas (opcional)",
                        text: $notasComponenteEditando,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                } header: {
                    Text("Componente")
                } footer: {
                    Text(
                        "Pulsa Guardar para aplicar los cambios al build."
                    )
                }

                Section {
                    Button(role: .destructive) {
                        mostrarConfirmarEliminarComponente = true
                    } label: {
                        Label(
                            "Eliminar componente",
                            systemImage: "trash"
                        )
                    }
                }
            }
            .navigationTitle("Editar componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        componenteEditando = nil
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardarEdicionComponente(
                            id: componente.id
                        )
                    }
                    .disabled(
                        nombreComponenteEditando
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }

    // MARK: - Datos calculados

    private var diferenciaPresupuesto: Double {
        build.presupuestoNumerico - build.precioTotal
    }

    private var porcentajePresupuesto: Double {
        guard build.presupuestoNumerico > 0 else {
            return 0
        }

        return min(
            build.precioTotal / build.presupuestoNumerico,
            1
        )
    }

    private var colorTotal: Color {
        guard build.presupuestoNumerico > 0 else {
            return .green
        }

        return build.precioTotal > build.presupuestoNumerico
            ? .red
            : .green
    }

    private var textoCantidadComponentes: String {
        build.componentes.count == 1
            ? L("1 componente")
            : L("\(build.componentes.count) componentes")
    }

    // MARK: - Acciones

    private func añadirComponente() {
        let nombre = nombreComponente.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !nombre.isEmpty else {
            return
        }

        let nuevoComponente = ComponenteBuild(
            categoria: categoriaComponente,
            nombre: nombre,
            precio: precioComponente.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            notas: notasComponente.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        )

        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.84
            )
        ) {
            build.componentes.append(nuevoComponente)
        }

        if build.advertenciaPCIe != nil {
            mostrarAlertaPCIe = true
        }

        limpiarFormularioNuevoComponente()
        mostrarNuevoComponente = false

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func prepararEdicion(
        _ componente: ComponenteBuild
    ) {
        nombreComponenteEditando = componente.nombre
        categoriaComponenteEditando = componente.categoria
        precioComponenteEditando = componente.precio
        notasComponenteEditando = componente.notas
        componenteEditando = componente
    }

    private func guardarEdicionComponente(
        id: UUID
    ) {
        guard let indice = build.componentes.firstIndex(
            where: { $0.id == id }
        ) else {
            componenteEditando = nil
            return
        }

        let nombreLimpio = nombreComponenteEditando
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !nombreLimpio.isEmpty else {
            return
        }

        build.componentes[indice] = ComponenteBuild(
            categoria: categoriaComponenteEditando,
            nombre: nombreLimpio,
            precio: precioComponenteEditando
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            notas: notasComponenteEditando
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        )

        if build.advertenciaPCIe != nil {
            mostrarAlertaPCIe = true
        }

        componenteEditando = nil

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func limpiarFormularioNuevoComponente() {
        nombreComponente = ""
        categoriaComponente = categoriasDisponibles.first ?? "CPU"
        precioComponente = ""
        notasComponente = ""
    }

    /// Hace que el checklist de montaje de toda la app siga el progreso de esta build.
    private var botonMontarEstaBuild: some View {
        let activa = checklist.buildActiva == build.id

        return Button {
            withAnimation(Animaciones.muelle) {
                if activa {
                    checklist.activar(build: nil, nombre: nil)
                } else {
                    checklist.activar(build: build.id, nombre: build.nombre.isEmpty ? "Mi build" : build.nombre)
                }
            }
        } label: {
            Label(
                activa ? L("Estás montando esta build") : L("Montar esta build"),
                systemImage: activa ? "checklist.checked" : "checklist"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderedProminent)
        .tint(activa ? .green : .blue)
        // Sin piezas no hay nada que montar (salvo para poder desactivarla)
        .disabled(build.componentes.isEmpty && !activa)
        .sensoryFeedback(.success, trigger: activa)
        .accessibilityHint(
            activa
                ? L("Pulsa para volver al checklist general")
                : L("El checklist de montaje seguirá el progreso de esta build")
        )
    }

    /// Menú al mantener pulsada una pieza: editar, duplicar, reordenar o eliminar.
    @ViewBuilder
    private func menuComponente(_ componente: ComponenteBuild) -> some View {
        let indice = build.componentes.firstIndex { $0.id == componente.id }

        Button {
            prepararEdicion(componente)
        } label: {
            Label("Editar", systemImage: "pencil")
        }

        Button {
            guard let indice else { return }
            var copia = componente
            copia.id = UUID()
            build.componentes.insert(copia, at: indice + 1)
        } label: {
            Label("Duplicar", systemImage: "plus.square.on.square")
        }

        if let indice, indice > 0 {
            Button {
                build.componentes.swapAt(indice, indice - 1)
            } label: {
                Label("Subir", systemImage: "arrow.up")
            }
        }

        if let indice, indice < build.componentes.count - 1 {
            Button {
                build.componentes.swapAt(indice, indice + 1)
            } label: {
                Label("Bajar", systemImage: "arrow.down")
            }
        }

        Divider()

        Button(role: .destructive) {
            eliminarComponente(id: componente.id)
        } label: {
            Label("Eliminar", systemImage: "trash")
        }
    }

    private func eliminarComponente(id: UUID) {
        withAnimation(.easeOut(duration: 0.18)) {
            build.componentes.removeAll {
                $0.id == id
            }
        }

        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
    }

    private func precioNumerico(
        _ precio: String
    ) -> Double? {
        precio.safeDouble
    }

    // MARK: - Estilo

    private func etiquetaBuild(
        titulo: String,
        color: Color,
        icono: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icono)
                .font(.system(size: 10, weight: .bold))

            Text(titulo.localizado)
                .lineLimit(1)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            color.opacity(0.92),
            in: Capsule()
        )
    }

    private func etiquetaSeccion(
        icono: String,
        titulo: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icono)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)

            Text(titulo.localizado)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    private func colorEtiqueta(
        _ etiqueta: String
    ) -> Color {
        switch etiqueta {
        case "Gaming":
            return .purple
        case "Oficina":
            return .blue
        case "Streaming":
            return .red
        case "Edición de vídeo":
            return .orange
        case "En proceso":
            return .yellow
        case "Terminado":
            return .green
        default:
            return .gray
        }
    }

    private func iconoEtiqueta(
        _ etiqueta: String
    ) -> String {
        switch etiqueta {
        case "Gaming":
            return "gamecontroller.fill"
        case "Oficina":
            return "briefcase.fill"
        case "Streaming":
            return "dot.radiowaves.left.and.right"
        case "Edición de vídeo":
            return "film.fill"
        case "En proceso":
            return "hammer.fill"
        case "Terminado":
            return "checkmark.seal.fill"
        default:
            return "pc"
        }
    }

    private func colorCategoria(
        _ categoria: String
    ) -> Color {
        switch categoria {
        case "CPU":
            return .orange
        case "GPU":
            return .purple
        case "Placa base":
            return .blue
        case "RAM":
            return .cyan
        case "Almacenamiento":
            return .green
        case "Fuente":
            return .yellow
        case "Refrigeración":
            return .mint
        case "Caja":
            return .indigo
        default:
            return .gray
        }
    }

    private func iconoCategoria(
        _ categoria: String
    ) -> String {
        switch categoria {
        case "CPU":
            return "cpu.fill"
        case "GPU":
            return "display"
        case "Placa base":
            return "rectangle.3.group.fill"
        case "RAM":
            return "memorychip.fill"
        case "Almacenamiento":
            return "internaldrive.fill"
        case "Fuente":
            return "bolt.fill"
        case "Refrigeración":
            return "fan.fill"
        case "Caja":
            return "shippingbox.fill"
        default:
            return "cube.box.fill"
        }
    }

    // MARK: - Fondo

    private var fondoAsistente: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.038,
                            green: 0.040,
                            blue: 0.048
                        ),
                        Color(
                            red: 0.021,
                            green: 0.023,
                            blue: 0.030
                        ),
                        Color(
                            red: 0.006,
                            green: 0.007,
                            blue: 0.012
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .blue.opacity(0.13),
                        .indigo.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 520
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.975,
                            green: 0.982,
                            blue: 0.995
                        ),
                        Color(
                            red: 0.940,
                            green: 0.956,
                            blue: 0.982
                        ),
                        Color(
                            red: 0.910,
                            green: 0.930,
                            blue: 0.965
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .blue.opacity(0.14),
                        .cyan.opacity(0.040),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}



// MARK: - Superficie de cristal

private extension View {

    func buildDetailGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            BuildDetailGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }
}

private struct BuildDetailGlassSurfaceModifier: ViewModifier {

    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        let forma = RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )

        content
            .background {
                forma.fill(
                    colorScheme == .dark
                        ? Color(
                            red: 0.075,
                            green: 0.082,
                            blue: 0.105
                        )
                        .opacity(0.68)
                        : Color.white.opacity(0.50)
                )
            }
            .background {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                tint.opacity(0.075),
                                .blue.opacity(0.020),
                                .clear
                            ]
                            : [
                                tint.opacity(0.070),
                                .blue.opacity(0.025),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                .white.opacity(0.065),
                                .white.opacity(0.010),
                                .clear
                            ]
                            : [
                                .white.opacity(0.42),
                                .white.opacity(0.10),
                                .clear
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
            }
            .overlay {
                forma.stroke(
                    colorScheme == .dark
                        ? .white.opacity(0.15)
                        : .white.opacity(0.66),
                    lineWidth: 1
                )
                .allowsHitTesting(false)
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.28)
                    : tint.opacity(0.09),
                radius: 12,
                y: 6
            )
    }
}

// MARK: - Pulsación

private struct BuildDetailPressStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed ? 0.975 : 1
            )
            .opacity(
                configuration.isPressed ? 0.86 : 1
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
