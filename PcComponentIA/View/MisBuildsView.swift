//
//  MisBuildsView.swift
//  PcComponentIA
//

import SwiftUI

struct MisBuildsView: View {

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Paleta Temática Verde de Builds
    
    private let colorBuild = Color(
        red: 0.16,
        green: 0.68,
        blue: 0.33
    )

    private let colorBuildSecundario = Color(
        red: 0.02,
        green: 0.66,
        blue: 0.63
    )

    private let colorPeligro = Color(
        red: 0.92,
        green: 0.24,
        blue: 0.22
    )

    @State private var builds: [Build] = AlmacenBuilds.cargar()

    @State private var mostrarNuevoBuild = false
    @State private var nombreNuevoBuild = ""

    @State private var modoSeleccion = false
    @State private var seleccionados: Set<UUID> = []

    @State private var filtroEtiqueta = "Todas"
    @State private var mostrarConfirmacionEliminar = false

    private let columnas = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var buildsFiltrados: [Build] {
        builds
            .filter { build in
                filtroEtiqueta == "Todas" || build.etiqueta == filtroEtiqueta
            }
            .sorted { $0.fechaCreacion > $1.fechaCreacion }
    }

    private var etiquetasConBuilds: [String] {
        let etiquetas = Set(builds.map(\.etiqueta))
        return ["Todas"] + etiquetas.sorted()
    }

    private var precioTotalBuilds: Double {
        builds.reduce(0) { $0 + $1.precioTotal }
    }

    private var totalComponentes: Int {
        builds.reduce(0) { $0 + $1.componentes.count }
    }

    var body: some View {
        ZStack {
            fondoAsistente

            if builds.isEmpty {
                estadoVacio
            } else {
                contenido
            }

            if modoSeleccion {
                VStack {
                    Spacer()
                    barraSeleccion
                }
            }
        }
        .navigationTitle(
            modoSeleccion
                ? "\(seleccionados.count) seleccionados"
                : "Mis Builds"
        )
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            toolbarContenido
        }
        .alert(
            "Nuevo build",
            isPresented: $mostrarNuevoBuild
        ) {
            TextField(
                "Nombre del build",
                text: $nombreNuevoBuild
            )

            Button("Cancelar", role: .cancel) {
                nombreNuevoBuild = ""
            }

            Button("Crear") {
                crearBuild()
            }
        } message: {
            Text(
                "Por ejemplo: Mi PC Gaming, Setup de edición o PC de oficina."
            )
        }
        .alert(
            "¿Eliminar builds seleccionados?",
            isPresented: $mostrarConfirmacionEliminar
        ) {
            Button("Cancelar", role: .cancel) {}

            Button("Eliminar", role: .destructive) {
                eliminarSeleccionados()
            }
        } message: {
            Text(
                "Se eliminarán \(seleccionados.count) builds. Esta acción no se puede deshacer."
            )
        }
    }

    // MARK: - Contenido

    private var contenido: some View {
        let buildsVisibles = buildsFiltrados

        return ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                resumen

                selectorEtiquetas

                HStack {
                    Text(
                        filtroEtiqueta == "Todas"
                            ? "Tus configuraciones"
                            : filtroEtiqueta
                    )
                    .font(.headline)

                    Spacer(minLength: 0)

                    Text("\(buildsVisibles.count)")
                        .font(
                            .caption
                                .monospacedDigit()
                                .weight(.bold)
                        )
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            colorControl,
                            in: Capsule()
                        )
                }

                if buildsVisibles.isEmpty {
                    estadoSinFiltro
                } else {
                    LazyVGrid(
                        columns: columnas,
                        spacing: 12
                    ) {
                        ForEach(buildsVisibles) { build in
                            tarjetaConSeleccion(build)
                        }
                    }
                }
            }
            .frame(maxWidth: 900)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(
                .bottom,
                modoSeleccion ? 112 : 36
            )
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Resumen

    private var resumen: some View {
        HStack(spacing: 10) {
            Image(systemName: "pc")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(colorBuild)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [
                            colorBuild.opacity(0.25),
                            colorBuildSecundario.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
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
                        colorBuild.opacity(0.25),
                        lineWidth: 1
                    )
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Tus equipos y configuraciones")
                    .font(.headline)

                Text(resumenTexto)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .buildGlassSurface(
            cornerRadius: 23,
            tint: colorBuild
        )
    }

    private var resumenTexto: String {
        let textoBuilds = builds.count == 1
            ? "1 build"
            : "\(builds.count) builds"

        let textoPiezas = totalComponentes == 1
            ? "1 pieza"
            : "\(totalComponentes) piezas"

        if precioTotalBuilds > 0 {
            return "\(textoBuilds) · \(textoPiezas) · \(precioTotalBuilds.formatoEuro)"
        }

        return "\(textoBuilds) · \(textoPiezas)"
    }

    // MARK: - Filtros

    private var selectorEtiquetas: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(etiquetasConBuilds, id: \.self) { etiqueta in
                    let color = colorEtiqueta(etiqueta)

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            filtroEtiqueta = etiqueta
                        }

                        UIImpactFeedbackGenerator(style: .light)
                            .impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Image(
                                systemName: iconoEtiqueta(etiqueta)
                            )
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold
                                )
                            )

                            Text(etiqueta)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(
                            filtroEtiqueta == etiqueta
                                ? Color.white
                                : Color.primary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(
                                    filtroEtiqueta == etiqueta
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [
                                                    color,
                                                    color.opacity(0.72)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(colorControl)
                                )
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    filtroEtiqueta == etiqueta
                                        ? color.opacity(0.34)
                                        : Color.primary.opacity(0.09),
                                    lineWidth: 1
                                )
                        }
                    }
                    .buttonStyle(BuildPressStyle())
                    .accessibilityLabel(
                        "Mostrar builds: \(etiqueta)"
                    )
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - Tarjeta

    @ViewBuilder
    private func tarjetaConSeleccion(
        _ build: Build
    ) -> some View {
        let estaSeleccionado = seleccionados.contains(build.id)

        ZStack(alignment: .topTrailing) {
            if modoSeleccion {
                Button {
                    toggleSeleccion(build.id)
                } label: {
                    tarjetaBuild(
                        build,
                        seleccionada: estaSeleccionado
                    )
                }
                .buttonStyle(BuildPressStyle())
            } else {
                NavigationLink {
                    DetalleBuildView(
                        build: bindingPara(build.id),
                        onEliminar: {
                            eliminarBuilds([build.id])
                        }
                    )
                } label: {
                    tarjetaBuild(
                        build,
                        seleccionada: false
                    )
                }
                .buttonStyle(BuildPressStyle())
            }

            if modoSeleccion {
                indicadorSeleccion(
                    estaSeleccionado: estaSeleccionado
                )
                .padding(9)
                .allowsHitTesting(false)
            }
        }
        .onLongPressGesture(
            minimumDuration: 0.42
        ) {
            guard !modoSeleccion else {
                return
            }

            UIImpactFeedbackGenerator(style: .medium)
                .impactOccurred()

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.82
                )
            ) {
                modoSeleccion = true
                seleccionados.insert(build.id)
            }
        }
        .contextMenu {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    modoSeleccion = true
                    seleccionados.insert(build.id)
                }
            } label: {
                Label(
                    "Seleccionar build",
                    systemImage: "checkmark.circle"
                )
            }

            Button(role: .destructive) {
                eliminarBuilds([build.id])
            } label: {
                Label(
                    "Eliminar build",
                    systemImage: "trash"
                )
            }
        }
    }

    private func tarjetaBuild(
        _ build: Build,
        seleccionada: Bool
    ) -> some View {
        let color = colorEtiqueta(build.etiqueta)

        return VStack(alignment: .leading, spacing: 11) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(
                                colorScheme == .dark ? 0.28 : 0.21
                            ),
                            .blue.opacity(
                                colorScheme == .dark ? 0.07 : 0.05
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 78)

                Image(systemName: iconoEtiqueta(build.etiqueta))
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)

                if !modoSeleccion {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(11)
                }
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 17,
                    style: .continuous
                )
                .stroke(
                    color.opacity(0.26),
                    lineWidth: 1
                )
            }

            Text(build.nombre)
                .font(
                    .system(
                        size: 14,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            HStack(spacing: 7) {
                etiquetaBuild(
                    etiqueta: build.etiqueta,
                    color: color
                )

                Spacer(minLength: 0)

                if build.precioTotal > 0 {
                    Text(build.precioTotal.formatoEuro)
                        .font(
                            .caption
                                .monospacedDigit()
                                .weight(.bold)
                        )
                        .foregroundStyle(colorBuild)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 10, weight: .semibold))

                Text(
                    build.componentes.count == 1
                        ? "1 componente"
                        : "\(build.componentes.count) componentes"
                )
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(11)
        .frame(
            maxWidth: .infinity,
            minHeight: 215,
            alignment: .topLeading
        )
        .background {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                seleccionada
                    ? color.opacity(
                        colorScheme == .dark ? 0.19 : 0.13
                    )
                    : colorTarjeta
            )
        }
        .background {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: seleccionada
                        ? [
                            color.opacity(0.14),
                            .clear
                        ]
                        : [
                            color.opacity(
                                colorScheme == .dark ? 0.06 : 0.04
                            ),
                            .clear
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                seleccionada
                    ? color.opacity(0.82)
                    : Color.primary.opacity(
                        colorScheme == .dark ? 0.14 : 0.09
                    ),
                lineWidth: seleccionada ? 2 : 1
            )
        }
        .shadow(
            color: seleccionada
                ? color.opacity(0.24)
                : .black.opacity(
                    colorScheme == .dark ? 0.20 : 0.06
                ),
            radius: seleccionada ? 12 : 8,
            y: 4
        )
        .scaleEffect(seleccionada ? 0.975 : 1)
    }

    private func etiquetaBuild(
        etiqueta: String,
        color: Color
    ) -> some View {
        Text(etiqueta)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                color.opacity(0.92),
                in: Capsule()
            )
    }

    private func indicadorSeleccion(
        estaSeleccionado: Bool
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    estaSeleccionado
                        ? colorBuild
                        : Color.black.opacity(0.52)
                )
                .frame(width: 31, height: 31)

            Image(
                systemName: estaSeleccionado
                    ? "checkmark"
                    : "circle"
            )
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
        }
        .overlay {
            Circle()
                .stroke(
                    .white.opacity(0.26),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Barra selección

    private var barraSeleccion: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    seleccionados.count == 1
                        ? "1 build seleccionado"
                        : "\(seleccionados.count) builds seleccionados"
                )
                .font(.subheadline.weight(.semibold))

                Text("Toca los builds que quieras añadir o quitar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button(role: .destructive) {
                guard !seleccionados.isEmpty else {
                    return
                }

                mostrarConfirmacionEliminar = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(
                        colorPeligro.opacity(
                            seleccionados.isEmpty ? 0.32 : 0.90
                        ),
                        in: Circle()
                    )
            }
            .disabled(seleccionados.isEmpty)
            .buttonStyle(BuildPressStyle())
            .accessibilityLabel("Eliminar builds seleccionados")
        }
        .padding(13)
        .buildGlassSurface(
            cornerRadius: 23,
            tint: colorBuild
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Estados

    private var estadoVacio: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorBuild.opacity(0.26),
                                colorBuildSecundario.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(
                        colorBuild.opacity(0.28),
                        lineWidth: 1
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "pc")
                    .font(.system(size: 39, weight: .semibold))
                    .foregroundStyle(colorBuild)
            }

            VStack(spacing: 6) {
                Text("Aún no tienes builds")
                    .font(.title3.bold())

                Text(
                    "Crea tu primer PC, añade componentes,\nprecios y notas para tenerlo organizado."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            Button {
                mostrarNuevoBuild = true
            } label: {
                Label(
                    "Crear mi primer build",
                    systemImage: "plus"
                )
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 21)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [
                            colorBuild,
                            colorBuildSecundario
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(
                    color: colorBuild.opacity(0.28),
                    radius: 11,
                    y: 5
                )
            }
            .buttonStyle(BuildPressStyle())
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: 360)
        .buildGlassSurface(
            cornerRadius: 28,
            tint: colorBuild
        )
        .padding(20)
    }

    private var estadoSinFiltro: some View {
        VStack(spacing: 11) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 27, weight: .semibold))
                .foregroundStyle(colorBuild)

            Text("No hay builds en esta categoría")
                .font(.headline)

            Button("Mostrar todos") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    filtroEtiqueta = "Todas"
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(colorBuild)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .buildGlassSurface(
            cornerRadius: 23,
            tint: colorBuild
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContenido: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !builds.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        modoSeleccion.toggle()
                        seleccionados.removeAll()
                    }

                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                } label: {
                    Text(
                        modoSeleccion
                            ? "Cancelar"
                            : "Seleccionar"
                    )
                    .font(.subheadline.weight(.semibold))
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                mostrarNuevoBuild = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 38, height: 38)
            }
            .accessibilityLabel("Crear un nuevo build")
        }
    }

    // MARK: - Acciones

    private func crearBuild() {
        let nombre = nombreNuevoBuild
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !nombre.isEmpty else {
            return
        }

        let nuevoBuild = Build(nombre: nombre)

        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.84
            )
        ) {
            builds.insert(nuevoBuild, at: 0)
        }

        AlmacenBuilds.guardar(builds)
        nombreNuevoBuild = ""

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func toggleSeleccion(
        _ id: UUID
    ) {
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()

        withAnimation(.easeOut(duration: 0.16)) {
            if seleccionados.contains(id) {
                seleccionados.remove(id)
            } else {
                seleccionados.insert(id)
            }
        }
    }

    private func eliminarBuilds(
        _ ids: [UUID]
    ) {
        let idsAEliminar = Set(ids)

        withAnimation(.easeOut(duration: 0.20)) {
            builds.removeAll { build in
                idsAEliminar.contains(build.id)
            }

            seleccionados.subtract(idsAEliminar)
        }

        AlmacenBuilds.guardar(builds)
    }

    private func eliminarSeleccionados() {
        let ids = Array(seleccionados)

        eliminarBuilds(ids)

        withAnimation(.easeInOut(duration: 0.18)) {
            modoSeleccion = false
            seleccionados.removeAll()
        }

        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    private func bindingPara(
        _ id: UUID
    ) -> Binding<Build> {
        Binding(
            get: {
                builds.first(
                    where: { $0.id == id }
                ) ?? Build(nombre: "")
            },
            set: { nuevoValor in
                guard let indice = builds.firstIndex(
                    where: { $0.id == id }
                ) else {
                    return
                }

                builds[indice] = nuevoValor
                AlmacenBuilds.guardar(builds)
            }
        )
    }

    // MARK: - Etiquetas

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

        case "Todas":
            return .indigo

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

        case "Todas":
            return "square.grid.2x2.fill"

        default:
            return "pc"
        }
    }

    // MARK: - Colores

    private var colorControl: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.74)
        }

        return Color.white.opacity(0.54)
    }

    private var colorTarjeta: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.68)
        }

        return Color.white.opacity(0.50)
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
                        colorBuild.opacity(0.13),
                        colorBuildSecundario.opacity(0.045),
                        .clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 520
                )

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
                        colorBuild.opacity(0.14),
                        colorBuildSecundario.opacity(0.040),
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

    func buildGlassSurface(
        cornerRadius: CGFloat,
        tint: Color
    ) -> some View {
        modifier(
            BuildGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint
            )
        )
    }
}

private struct BuildGlassSurfaceModifier: ViewModifier {

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
                forma.fill(colorFondo)
            }
            .background {
                forma.fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                tint.opacity(0.080),
                                .blue.opacity(0.020),
                                .clear
                            ]
                            : [
                                tint.opacity(0.075),
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

    private var colorFondo: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.075,
                green: 0.082,
                blue: 0.105
            )
            .opacity(0.68)
        }

        return Color.white.opacity(0.50)
    }
}

// MARK: - Pulsación

private struct BuildPressStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
