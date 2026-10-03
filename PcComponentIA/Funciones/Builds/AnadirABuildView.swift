//
//  AnadirABuildView.swift
//  PcComponentIA
//
//  Hoja para meter en una build la pieza detectada o consultada, sin escribirla a mano.
//

import SwiftUI

// MARK: - Categoría de build según la pieza

enum CategoriaBuildDePieza {
    /// Categoría de "Mis Builds" que corresponde a una clave del diccionario.
    /// Devuelve nil para lo que no se compra por separado (puertos, ranuras, conectores...).
    static func categoria(paraClave clave: String) -> String? {
        switch clave {
        case "CPU", "CPU_Intel", "CPU_AMD":
            return "CPU"
        case "GPU":
            return "GPU"
        case "Placa_Base":
            return "Placa base"
        case "Modulo_RAM":
            return "RAM"
        case "M2_SSD_NVMe", "M2_SSD_SATA", "SSD_SATA", "HDD":
            return "Almacenamiento"
        case "Fuente_Alimentacion":
            return "Fuente"
        case "Disipador_Aire", "Refrigeracion_Liquida_AIO", "Radiador", "Bloque_refrigeracion_liquida",
             "Bomba_Liquida", "Ventilador_procesador", "Ventilador_Caja", "Pasta_Termica", "Hub_Ventiladores":
            return "Refrigeración"
        case "Caja_PC":
            return "Caja"
        case "Tarjeta_WiFi_Bluetooth", "Tarjeta_Capturadora", "Tarjeta_Sonido", "Hub_RGB_ARGB",
             "Monitor", "Teclado", "Raton", "Altavoces_Auriculares":
            return "Otro"
        default:
            return nil
        }
    }
}

// MARK: - Botón reutilizable

/// Botón "Añadir a una build" que abre la hoja. No aparece si la pieza no se compra por separado.
struct BotonAnadirABuild: View {
    let clave: String
    let nombreLegible: String
    var color: Color = .blue

    @State private var mostrarHoja = false

    var body: some View {
        if let categoria = CategoriaBuildDePieza.categoria(paraClave: clave) {
            Button {
                mostrarHoja = true
            } label: {
                Label("Añadir a una build", systemImage: "plus.rectangle.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(color)
            .sheet(isPresented: $mostrarHoja) {
                AnadirABuildView(nombre: nombreLegible, categoria: categoria)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Hoja

struct AnadirABuildView: View {
    let nombre: String
    let categoria: String

    @Environment(\.dismiss) private var dismiss

    @State private var builds: [Build] = []
    @State private var nombreNuevaBuild = ""
    @State private var anadidaA: UUID?
    @State private var fallo = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nombre.localizado).font(.headline)
                            Text(categoria.localizado).font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: Self.icono(categoria))
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Pieza")
                }

                Section {
                    if builds.isEmpty {
                        Text("Aún no tienes builds. Crea una abajo.")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(builds) { build in
                        Button {
                            anadir(a: build.id)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(build.nombre)
                                        .foregroundStyle(.primary)
                                    Text("\(build.componentes.count) piezas · \(build.etiqueta)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if yaTiene(build) {
                                        Label("Ya tiene \(categoria == "Otro" ? "esta pieza" : "una pieza de \(categoria)")",
                                              systemImage: "exclamationmark.circle")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                                Image(systemName: anadidaA == build.id ? "checkmark.circle.fill" : "plus.circle")
                                    .foregroundStyle(anadidaA == build.id ? .green : .blue)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .disabled(anadidaA != nil)
                    }
                } header: {
                    Text("Elige una build")
                }

                Section {
                    HStack {
                        TextField("Nombre de la build nueva", text: $nombreNuevaBuild)
                            .submitLabel(.done)
                            .onSubmit(crearYAnadir)
                        Button("Crear", action: crearYAnadir)
                            .disabled(nombreLimpio.isEmpty || anadidaA != nil)
                    }
                } header: {
                    Text("O crea una nueva")
                }
            }
            .navigationTitle("Añadir a una build")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                builds = AlmacenBuilds.cargar()
            }
            .sensoryFeedback(.success, trigger: anadidaA) { _, nuevo in nuevo != nil }
            .alert("No se pudo añadir la pieza", isPresented: $fallo) {
                Button("Vale", role: .cancel) {}
            }
        }
    }

    /// La build ya tiene una pieza de esta categoría (o esta misma, si es "Otro").
    private func yaTiene(_ build: Build) -> Bool {
        build.componentes.contains {
            categoria == "Otro" ? $0.nombre == nombre : $0.categoria == categoria
        }
    }

    static func icono(_ categoria: String) -> String {
        switch categoria {
        case "CPU": "cpu"
        case "GPU": "rectangle.on.rectangle"
        case "Placa base": "square.grid.3x3"
        case "RAM": "memorychip"
        case "Almacenamiento": "internaldrive"
        case "Fuente": "bolt.fill"
        case "Refrigeración": "fan"
        case "Caja": "pc"
        default: "puzzlepiece.extension"
        }
    }

    private var nombreLimpio: String {
        nombreNuevaBuild.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func crearYAnadir() {
        guard !nombreLimpio.isEmpty, anadidaA == nil else { return }
        let nueva = Build(nombre: nombreLimpio)
        guard AlmacenBuilds.crear(nueva) else {
            fallo = true
            return
        }
        builds.insert(nueva, at: 0)
        anadir(a: nueva.id)
    }

    private func anadir(a idBuild: UUID) {
        let componente = ComponenteBuild(categoria: categoria, nombre: nombre, precio: "", notas: "")
        guard AlmacenBuilds.añadir(componente, aBuild: idBuild) else {
            fallo = true
            return
        }

        withAnimation(Animaciones.muelle) {
            anadidaA = idBuild
        }

        // Se deja ver la marca un momento antes de cerrar
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            dismiss()
        }
    }
}
