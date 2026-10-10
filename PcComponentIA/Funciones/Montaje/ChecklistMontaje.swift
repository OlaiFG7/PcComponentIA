//
//  ChecklistMontaje.swift
//  PcComponentIA
//

import SwiftUI
import Foundation
import Combine

enum EstadoPasoMontaje: String, Codable {
    case pendiente
    case completado
    case noAplica

    var icono: String {
        switch self {
        case .pendiente:
            return "circle"

        case .completado:
            return "checkmark"

        case .noAplica:
            return "minus"
        }
    }

    var color: Color {
        switch self {
        case .pendiente:
            return .secondary

        case .completado:
            return .green

        case .noAplica:
            return .orange
        }
    }
}

struct PasoMontaje: Identifiable, Codable {
    var id = UUID()

    let nombre: String
    let icono: String
    let permiteNoAplica: Bool

    var estado: EstadoPasoMontaje = .pendiente

    var completado: Bool {
        estado == .completado
    }

    var noAplica: Bool {
        estado == .noAplica
    }
}

final class GestorChecklist: ObservableObject {

    @Published var pasos: [PasoMontaje] {
        didSet {
            guardar()
        }
    }

    /// Build cuyo montaje se está siguiendo (nil = checklist general).
    /// Cada build guarda su propio progreso con una clave distinta.
    @Published private(set) var buildActiva: UUID?
    @Published private(set) var nombreBuildActiva: String?

    private static let claveBuildActiva = "checklistBuildActivaPCComponentIA"
    private static let claveNombreBuildActiva = "checklistNombreBuildActivaPCComponentIA"

    private var sufijo: String { buildActiva.map { "_" + $0.uuidString } ?? "" }
    private var claveGuardado: String { "checklistMontajePCComponentIA" + sufijo }
    private var versionClave: String { "checklistMontajeVersionPCComponentIA" + sufijo }
    private let versionActual = 9

    init() {
        let defaults = UserDefaults.standard
        buildActiva = defaults.string(forKey: Self.claveBuildActiva).flatMap(UUID.init(uuidString:))
        nombreBuildActiva = defaults.string(forKey: Self.claveNombreBuildActiva)
        pasos = []
        cargarPasos()
    }

    /// Cambia el checklist que se muestra en toda la app (nil = general).
    func activar(build id: UUID?, nombre: String?) {
        guard id != buildActiva || nombre != nombreBuildActiva else { return }
        buildActiva = id
        nombreBuildActiva = id == nil ? nil : nombre
        let defaults = UserDefaults.standard
        defaults.set(id?.uuidString, forKey: Self.claveBuildActiva)
        defaults.set(nombreBuildActiva, forKey: Self.claveNombreBuildActiva)
        cargarPasos()
    }

    /// Si se borra la build activa, se vuelve al checklist general y se limpia su progreso.
    func buildEliminada(_ id: UUID) {
        UserDefaults.standard.removeObject(forKey: "checklistMontajePCComponentIA_" + id.uuidString)
        UserDefaults.standard.removeObject(forKey: "checklistMontajeVersionPCComponentIA_" + id.uuidString)
        if buildActiva == id {
            activar(build: nil, nombre: nil)
        }
    }

    private func cargarPasos() {
        let pasosBase = Self.pasosIniciales

        let versionGuardada = UserDefaults.standard.integer(
            forKey: versionClave
        )

        if
            versionGuardada == versionActual,
            let datos = UserDefaults.standard.data(
                forKey: claveGuardado
            ),
            let pasosGuardados = try? JSONDecoder().decode(
                [PasoMontaje].self,
                from: datos
            ),
            pasosGuardados.count == pasosBase.count
        {
            pasos = pasosGuardados
        } else {
            // Si los pasos cambiaron en una versión nueva, se conserva el progreso
            // de los pasos que siguen existiendo (se emparejan por nombre)
            let anteriores = UserDefaults.standard.data(forKey: claveGuardado)
                .flatMap { try? JSONDecoder().decode([PasoMontaje].self, from: $0) } ?? []
            let estadoPorNombre = Dictionary(
                anteriores.map { ($0.nombre, $0.estado) },
                uniquingKeysWith: { primero, _ in primero }
            )
            pasos = pasosBase.map { paso in
                var paso = paso
                if let estado = estadoPorNombre[paso.nombre],
                   estado != .noAplica || paso.permiteNoAplica {
                    paso.estado = estado
                }
                return paso
            }
            guardar()
        }
    }

    // MARK: - Pasos

    private static var pasosIniciales: [PasoMontaje] {
        [
            PasoMontaje(
                nombre: "Preparar mesa, herramientas y protección antiestática",
                icono: "wrench.and.screwdriver",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Comprobar compatibilidad de CPU, placa base y RAM",
                icono: "checkmark.shield",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar CPU en el socket de la placa base",
                icono: "cpu",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Comprobar o aplicar pasta térmica",
                icono: "drop.fill",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Montar disipador o refrigeración de CPU",
                icono: "fan",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Conectar cable CPU_FAN al disipador",
                icono: "cable.connector",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar módulos de memoria RAM",
                icono: "memorychip",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar SSD M.2 NVMe",
                icono: "internaldrive",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Instalar SSD SATA o disco duro HDD",
                icono: "externaldrive",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar cable SATA de datos",
                icono: "cable.connector",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar alimentación SATA de la fuente",
                icono: "cable.connector.horizontal",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Colocar separadores de placa base en la caja",
                icono: "circle.grid.3x3.fill",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar protector trasero I/O Shield",
                icono: "rectangle.portrait.and.arrow.right",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Montar placa base dentro de la caja",
                icono: "rectangle.3.group",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Atornillar placa base sin forzar el PCB",
                icono: "screwdriver",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar fuente de alimentación PSU",
                icono: "bolt.fill",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Conectar cable ATX de 24 pines",
                icono: "powerplug",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Conectar cable EPS CPU de 8 pines",
                icono: "powerplug.fill",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar tarjeta gráfica dedicada GPU",
                icono: "display",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Atornillar GPU al chasis",
                icono: "screwdriver.fill",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar alimentación PCIe o 12VHPWR a GPU",
                icono: "cable.connector.horizontal",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar Power SW y LEDs del panel frontal",
                icono: "power",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Conectar Reset SW del panel frontal",
                icono: "arrow.counterclockwise",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar USB frontal y audio HD frontal",
                icono: "cable.connector",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Conectar ventiladores extra de la caja a SYS_FAN",
                icono: "fan.fill",
                permiteNoAplica: true
            ),
            PasoMontaje(
                nombre: "Organizar cables y revisar todos los conectores",
                icono: "line.3.crossed.swirl.circle",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Cerrar paneles de la caja",
                icono: "rectangle.split.3x1",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Conectar pantalla, teclado y cable de corriente",
                icono: "display.and.arrow.down",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Encender PC y comprobar POST o BIOS",
                icono: "power.circle.fill",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Verificar temperaturas y ventiladores en BIOS",
                icono: "thermometer.medium",
                permiteNoAplica: false
            ),
            PasoMontaje(
                nombre: "Instalar sistema operativo y controladores",
                icono: "arrow.down.circle.fill",
                permiteNoAplica: false
            )
        ]
    }

    // MARK: - Progreso

    var completados: Int {
        pasos.filter(\.completado).count
    }

    var noAplican: Int {
        pasos.filter(\.noAplica).count
    }

    var pasosRequeridos: Int {
        pasos.filter { !$0.noAplica }.count
    }

    var pendientes: Int {
        pasos.filter {
            $0.estado == .pendiente
        }
        .count
    }

    var progreso: Double {
        guard pasosRequeridos > 0 else {
            return 0
        }

        return Double(completados) / Double(pasosRequeridos)
    }

    var pasosCriticosAntesDeEncender: [PasoMontaje] {
        let nombresCriticos = [
            "Instalar CPU en el socket de la placa base",
            "Comprobar o aplicar pasta térmica",
            "Montar disipador o refrigeración de CPU",
            "Conectar cable CPU_FAN al disipador",
            "Instalar módulos de memoria RAM",
            "Montar placa base dentro de la caja",
            "Instalar fuente de alimentación PSU",
            "Conectar cable ATX de 24 pines",
            "Conectar cable EPS CPU de 8 pines",
            "Conectar Power SW y LEDs del panel frontal",
            "Organizar cables y revisar todos los conectores",
            "Conectar pantalla, teclado y cable de corriente"
        ]

        return pasos.filter {
            nombresCriticos.contains($0.nombre)
        }
    }

    var pendientesCriticosAntesDeEncender: [PasoMontaje] {
        pasosCriticosAntesDeEncender.filter {
            $0.estado != .completado
        }
    }

    var estaListoParaEncender: Bool {
        !pasosCriticosAntesDeEncender.isEmpty &&
        pendientesCriticosAntesDeEncender.isEmpty
    }

    // MARK: - Acciones

    func toggleCompletado(_ paso: PasoMontaje) {
        guard let indice = pasos.firstIndex(
            where: { $0.id == paso.id }
        ) else {
            return
        }

        switch pasos[indice].estado {
        case .pendiente, .noAplica:
            pasos[indice].estado = .completado

        case .completado:
            pasos[indice].estado = .pendiente
        }
    }

    func toggleNoAplica(_ paso: PasoMontaje) {
        guard
            paso.permiteNoAplica,
            let indice = pasos.firstIndex(
                where: { $0.id == paso.id }
            )
        else {
            return
        }

        switch pasos[indice].estado {
        case .pendiente, .completado:
            pasos[indice].estado = .noAplica

        case .noAplica:
            pasos[indice].estado = .pendiente
        }
    }

    func reiniciar() {
        for indice in pasos.indices {
            pasos[indice].estado = .pendiente
        }
    }

    @discardableResult
    func marcarComponenteComoHecho(
        _ nombreComponente: String
    ) -> Bool {
        guard let indice = indicePasoParaComponente(
            nombreComponente
        ) else {
            return false
        }

        pasos[indice].estado = .completado
        return true
    }

    func estaMarcado(_ nombreComponente: String) -> Bool {
        guard let indice = indicePasoParaComponente(
            nombreComponente
        ) else {
            return false
        }

        return pasos[indice].completado
    }

    @discardableResult
    func alternarComponente(_ nombreComponente: String) -> Bool {
        guard let indice = indicePasoParaComponente(
            nombreComponente
        ) else {
            return false
        }

        switch pasos[indice].estado {
        case .completado:
            pasos[indice].estado = .pendiente
            return false

        case .pendiente, .noAplica:
            pasos[indice].estado = .completado
            return true
        }
    }

    func tienePasoAsociado(
        _ nombreComponente: String
    ) -> Bool {
        indicePasoParaComponente(nombreComponente) != nil
    }

    func pasoConNombre(_ nombre: String) -> PasoMontaje? {
        pasos.first { $0.nombre == nombre }
    }

    func estaCompletadoPaso(nombre: String) -> Bool {
        pasoConNombre(nombre)?.completado ?? false
    }

    @discardableResult
    func alternarPaso(nombre: String) -> Bool {
        guard let indice = pasos.firstIndex(where: { $0.nombre == nombre }) else {
            return false
        }

        switch pasos[indice].estado {
        case .completado:
            pasos[indice].estado = .pendiente
            return false

        case .pendiente, .noAplica:
            pasos[indice].estado = .completado
            return true
        }
    }

    // MARK: - Asociación del escáner

    private func indicePasoParaComponente(
        _ nombreComponente: String
    ) -> Int? {
        let nombre = normalizar(nombreComponente)

        // "CPU" a secas es la clase que devuelve el detector: no contiene ninguna de las
        // palabras de abajo y, como palabra suelta, coincidiría con "CPU_FAN" o "EPS CPU".
        if nombre == "cpu" {
            return pasos.firstIndex { $0.nombre == "Instalar CPU en el socket de la placa base" }
        }

        let candidatos: [
            (palabras: [String], paso: String)
        ] = [
            (
                palabras: [
                    "cpu intel",
                    "cpu amd",
                    "procesador",
                    "socket intel",
                    "socket amd",
                    "socket cpu"
                ],
                paso: "Instalar CPU en el socket de la placa base"
            ),
            (
                palabras: [
                    "pasta termica"
                ],
                paso: "Comprobar o aplicar pasta térmica"
            ),
            (
                palabras: [
                    "disipador",
                    "disipador aire",
                    "refrigeracion liquida",
                    "refrigeracion liquida aio",
                    "aio",
                    "bomba liquida",
                    "bloque cpu",
                    "radiador"
                ],
                paso: "Montar disipador o refrigeración de CPU"
            ),
            (
                palabras: [
                    "ventilador cpu",
                    "cpu fan",
                    "conector cpu fan"
                ],
                paso: "Conectar cable CPU_FAN al disipador"
            ),
            (
                palabras: [
                    "ram",
                    "modulo ram",
                    "memoria",
                    "ranura ram"
                ],
                paso: "Instalar módulos de memoria RAM"
            ),
            (
                palabras: [
                    "m2 ssd nvme",
                    "ssd nvme",
                    "nvme",
                    "ranura m2"
                ],
                paso: "Instalar SSD M.2 NVMe"
            ),
            (
                palabras: [
                    "ssd sata",
                    "hdd",
                    "disco duro"
                ],
                paso: "Instalar SSD SATA o disco duro HDD"
            ),
            (
                palabras: [
                    "cable datos sata",
                    "cable sata"
                ],
                paso: "Conectar cable SATA de datos"
            ),
            (
                palabras: [
                    "cable alimentacion sata",
                    "alimentacion sata"
                ],
                paso: "Conectar alimentación SATA de la fuente"
            ),
            (
                palabras: [
                    "separadores",
                    "standoffs"
                ],
                paso: "Colocar separadores de placa base en la caja"
            ),
            (
                palabras: [
                    "protector io",
                    "io shield"
                ],
                paso: "Instalar protector trasero I/O Shield"
            ),
            (
                palabras: [
                    "placa base",
                    "motherboard"
                ],
                paso: "Montar placa base dentro de la caja"
            ),
            (
                palabras: [
                    "fuente alimentacion",
                    "fuente",
                    "psu"
                ],
                paso: "Instalar fuente de alimentación PSU"
            ),
            (
                palabras: [
                    "atx 24",
                    "atx24",
                    "conector atx"
                ],
                paso: "Conectar cable ATX de 24 pines"
            ),
            (
                palabras: [
                    "eps",
                    "eps8",
                    "cpu 8 pines"
                ],
                paso: "Conectar cable EPS CPU de 8 pines"
            ),
            (
                palabras: [
                    "gpu",
                    "tarjeta grafica",
                    "grafica",
                    "pcie x16"
                ],
                paso: "Instalar tarjeta gráfica dedicada GPU"
            ),
            (
                palabras: [
                    "pcie gpu",
                    "cable pcie",
                    "12vhpwr",
                    "12v 2x6"
                ],
                paso: "Conectar alimentación PCIe o 12VHPWR a GPU"
            ),
            (
                palabras: [
                    "power sw",
                    "panel frontal",
                    "power led",
                    "hdd led"
                ],
                paso: "Conectar Power SW y LEDs del panel frontal"
            ),
            (
                palabras: [
                    "reset sw"
                ],
                paso: "Conectar Reset SW del panel frontal"
            ),
            (
                palabras: [
                    "usb frontal",
                    "audio hd",
                    "usb c",
                    "usb 3",
                    "usb 2"
                ],
                paso: "Conectar USB frontal y audio HD frontal"
            ),
            (
                palabras: [
                    "ventilador caja",
                    "sys fan",
                    "sysfan",
                    "conector sys fan"
                ],
                paso: "Conectar ventiladores extra de la caja a SYS_FAN"
            ),
            (
                palabras: [
                    "monitor",
                    "teclado",
                    "raton",
                    "cable corriente",
                    "iec"
                ],
                paso: "Conectar pantalla, teclado y cable de corriente"
            ),
            (
                palabras: [
                    "bios",
                    "uefi",
                    "post"
                ],
                paso: "Encender PC y comprobar POST o BIOS"
            )
        ]

        for candidato in candidatos {
            let coincide = candidato.palabras.contains {
                nombre.contains(normalizar($0))
            }

            if coincide {
                return pasos.firstIndex {
                    $0.nombre == candidato.paso
                }
            }
        }

        return nil
    }

    private func normalizar(_ texto: String) -> String {
        texto
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    // MARK: - Persistencia

    private func guardar() {
        guard let datos = try? JSONEncoder().encode(pasos) else {
            return
        }

        UserDefaults.standard.set(
            datos,
            forKey: claveGuardado
        )

        UserDefaults.standard.set(
            versionActual,
            forKey: versionClave
        )
    }
}

struct ChecklistLateral: View {

    enum FiltroChecklist: String, CaseIterable, Identifiable {
        case pendientes
        case noAplica
        case completados

        var id: String {
            rawValue
        }

        var titulo: String {
            switch self {
            case .pendientes:
                return "Pendientes"

            case .noAplica:
                return L("No aplica")

            case .completados:
                return "Hechos"
            }
        }

        var icono: String {
            switch self {
            case .pendientes:
                return "circle"

            case .noAplica:
                return "minus.circle"

            case .completados:
                return "checkmark"
            }
        }
    }

    @ObservedObject var gestor: GestorChecklist

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion)
    private var reducirMovimiento

    @State private var expandido = false
    @State private var filtro: FiltroChecklist = .pendientes

    private var pasosFiltrados: [PasoMontaje] {
        switch filtro {
        case .pendientes:
            return gestor.pasos.filter {
                $0.estado == .pendiente
            }

        case .noAplica:
            return gestor.pasos.filter {
                $0.estado == .noAplica
            }

        case .completados:
            return gestor.pasos.filter {
                $0.estado == .completado
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            if expandido {
                panel
                    .transition(
                        .move(edge: .trailing)
                            .combined(with: .opacity)
                    )
            }

            pestana
        }
        .animation(
            reducirMovimiento
                ? .linear(duration: 0.01)
                : .spring(
                    response: 0.32,
                    dampingFraction: 0.86
                ),
            value: expandido
        )
    }

    private var pestana: some View {
        Button {
            withAnimation(
                reducirMovimiento
                    ? .linear(duration: 0.01)
                    : .spring(
                        response: 0.32,
                        dampingFraction: 0.86
                    )
            ) {
                expandido.toggle()
            }

            UIImpactFeedbackGenerator(style: .light)
                .impactOccurred()
        } label: {
            VStack(spacing: 7) {
                Image(
                    systemName: expandido
                        ? "chevron.right"
                        : "checklist"
                )
                .font(.system(size: 17, weight: .bold))

                if !expandido {
                    Text(
                        "\(gestor.completados)/\(gestor.pasosRequeridos)"
                    )
                    .font(
                        .caption2
                            .monospacedDigit()
                            .weight(.bold)
                    )
                }
            }
            .foregroundStyle(.white)
            .frame(
                width: 52,
                height: expandido ? 72 : 94
            )
            .background(
                LinearGradient(
                    colors: [
                        .green,
                        .mint.opacity(0.82),
                        .teal.opacity(0.74)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: expandido ? 0 : 18,
                    topTrailingRadius: expandido ? 0 : 18
                )
                .stroke(
                    .white.opacity(0.40),
                    lineWidth: 1
                )
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: expandido ? 0 : 18,
                    topTrailingRadius: expandido ? 0 : 18
                )
            )
            .shadow(
                color: .green.opacity(0.25),
                radius: 13,
                y: 7
            )
        }
        .buttonStyle(ChecklistPressStyle())
        .accessibilityLabel(
            expandido
                ? "Cerrar checklist de montaje"
                : "Abrir checklist de montaje"
        )
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 13) {
            cabecera

            avisoAntesDeEncender

            selectorFiltro

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    if pasosFiltrados.isEmpty {
                        estadoSinPasos
                    } else {
                        ForEach(pasosFiltrados) { paso in
                            fila(paso)
                        }
                    }
                }
                // Damos un poco de respiro al final de la lista
                .padding(.bottom, 10)
            }
            .scrollIndicators(.visible)
            // SOLUCIÓN: Eliminamos el maxHeight: 220.
            // Al añadir esto, el ScrollView empuja y rellena todo el espacio
            // disponible hasta el límite de 470 del VStack principal.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(14)
        .frame(width: 344)
        // Mantenemos el límite máximo del panel entero
        .frame(maxHeight: 470, alignment: .top)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
        )
        .background {
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .fill(colorFondoPanel)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(
                            colorScheme == .dark
                                ? 0.075
                                : 0.22
                        ),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .stroke(
                colorScheme == .dark
                    ? .white.opacity(0.17)
                    : .white.opacity(0.72),
                lineWidth: 1
            )
            .allowsHitTesting(false)
        }
        .shadow(
            color: .black.opacity(
                colorScheme == .dark ? 0.35 : 0.15
            ),
            radius: 20,
            y: 10
        )
    }
    private var colorFondoPanel: Color {
        if colorScheme == .dark {
            return Color(
                red: 0.030,
                green: 0.060,
                blue: 0.115
            )
            .opacity(0.90)
        }

        return Color.white.opacity(0.78)
    }

    private var cabecera: some View {
        HStack(alignment: .center, spacing: 11) {
            ZStack {
                Circle()
                    .stroke(
                        .green.opacity(0.20),
                        lineWidth: 7
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: gestor.progreso
                    )
                    .stroke(
                        LinearGradient(
                            colors: [
                                .green,
                                .mint
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 7,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        reducirMovimiento
                            ? .linear(duration: 0.01)
                            : .easeInOut(duration: 0.35),
                        value: gestor.progreso
                    )

                Text("\(Int(gestor.progreso * 100))")
                    .font(
                        .caption
                            .monospacedDigit()
                            .weight(.bold)
                    )
                    .foregroundStyle(.green)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(gestor.nombreBuildActiva.map { "Montaje: \($0)" } ?? "Montaje de tu PC")
                    .font(.headline)
                    .lineLimit(1)

                Text(resumenProgreso.localizado)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        gestor.reiniciar()
                        filtro = .pendientes
                    }

                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                } label: {
                    Label(
                        "Reiniciar checklist",
                        systemImage: "arrow.counterclockwise"
                    )
                }

                if gestor.buildActiva != nil {
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            gestor.activar(build: nil, nombre: nil)
                        }
                    } label: {
                        Label("Volver al checklist general", systemImage: "list.bullet.clipboard")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 37, height: 37)
                    .background(
                        colorFondoControl,
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                Color.primary.opacity(0.10),
                                lineWidth: 1
                            )
                    }
            }
            .accessibilityLabel(
                "Más acciones del checklist"
            )
        }
    }

    private var resumenProgreso: String {
        if gestor.noAplican > 0 {
            return L("\(gestor.completados) hechos · \(gestor.noAplican) no aplican")
        }

        return L("\(gestor.completados) de \(gestor.pasosRequeridos) completados")
    }

    private var avisoAntesDeEncender: some View {
        let pendientes = gestor.pendientesCriticosAntesDeEncender
        let listo = gestor.estaListoParaEncender

        return HStack(alignment: .top, spacing: 10) {
            Image(
                systemName: listo
                    ? "checkmark.shield.fill"
                    : "exclamationmark.triangle.fill"
            )
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(
                listo ? Color.green : Color.orange
            )
            .frame(width: 30, height: 30)
            .background(
                (listo ? Color.green : Color.orange)
                    .opacity(colorScheme == .dark ? 0.18 : 0.12),
                in: Circle()
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(
                    listo
                        ? "Listo para encender"
                        : "Revisa antes de encender"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)

                Text(
                    listo
                        ? "Las conexiones esenciales están completadas."
                        : resumenPendientesCriticos(pendientes)
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            (listo ? Color.green : Color.orange)
                .opacity(colorScheme == .dark ? 0.13 : 0.09),
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
                (listo ? Color.green : Color.orange)
                    .opacity(0.30),
                lineWidth: 1
            )
        }
    }

    private func resumenPendientesCriticos(
        _ pendientes: [PasoMontaje]
    ) -> String {
        let nombres = pendientes.prefix(2).map {
            nombreCortoPasoCritico($0.nombre)
        }

        guard !nombres.isEmpty else {
            return L("Completa las conexiones esenciales antes de iniciar.")
        }

        let texto = nombres.joined(separator: " · ")

        if pendientes.count > 2 {
            return L("\(texto) y \(pendientes.count - 2) más")
        }

        return texto
    }

    private func nombreCortoPasoCritico(
        _ nombre: String
    ) -> String {
        switch nombre {
        case "Instalar CPU en el socket de la placa base":
            return "CPU"
        case "Comprobar o aplicar pasta térmica":
            return L("Pasta térmica")
        case "Montar disipador o refrigeración de CPU":
            return "Disipador"
        case "Conectar cable CPU_FAN al disipador":
            return "CPU_FAN"
        case "Instalar módulos de memoria RAM":
            return "RAM"
        case "Montar placa base dentro de la caja":
            return L("Placa base")
        case "Instalar fuente de alimentación PSU":
            return "Fuente"
        case "Conectar cable ATX de 24 pines":
            return L("ATX 24 pines")
        case "Conectar cable EPS CPU de 8 pines":
            return L("EPS CPU")
        case "Conectar Power SW y LEDs del panel frontal":
            return L("Panel frontal")
        case "Organizar cables y revisar todos los conectores":
            return L("Revisión de cables")
        case "Conectar pantalla, teclado y cable de corriente":
            return L("Pantalla y corriente")
        default:
            return nombre
        }
    }

    private var colorFondoControl: Color {
        if colorScheme == .dark {
            return .white.opacity(0.08)
        }

        return .black.opacity(0.055)
    }

    private var selectorFiltro: some View {
        HStack(spacing: 5) {
            ForEach(FiltroChecklist.allCases) { opcion in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        filtro = opcion
                    }

                    UIImpactFeedbackGenerator(style: .light)
                        .impactOccurred()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: opcion.icono)
                            .font(
                                .system(
                                    size: 10,
                                    weight: .bold
                                )
                            )

                        Text(opcion.titulo.localizado)
                            .font(
                                .caption.weight(.semibold)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(
                        filtro == opcion
                            ? Color.white
                            : Color.secondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(
                                filtro == opcion
                                    ? AnyShapeStyle(
                                        colorFiltroSeleccionado(
                                            opcion
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                            )
                    }
                }
                .buttonStyle(ChecklistPressStyle())
                .accessibilityLabel(
                    "Mostrar pasos: \(opcion.titulo)"
                )
            }
        }
        .padding(4)
        .background(
            colorFondoControl,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    Color.primary.opacity(0.08),
                    lineWidth: 1
                )
        }
    }

    private func colorFiltroSeleccionado(
        _ filtro: FiltroChecklist
    ) -> LinearGradient {
        switch filtro {
        case .pendientes:
            return LinearGradient(
                colors: [
                    .blue,
                    .cyan.opacity(0.80)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .noAplica:
            return LinearGradient(
                colors: [
                    .orange,
                    .red.opacity(0.75)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

        case .completados:
            return LinearGradient(
                colors: [
                    .green,
                    .mint.opacity(0.82)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private func fila(
        _ paso: PasoMontaje
    ) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Button {
                withAnimation(.easeOut(duration: 0.16)) {
                    gestor.toggleCompletado(paso)
                }

                UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred()
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    indicadorEstado(paso)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(paso.nombre.localizado)
                            .font(
                                .subheadline.weight(.medium)
                            )
                            .foregroundStyle(
                                colorTexto(paso)
                            )
                            .strikethrough(
                                paso.noAplica,
                                color: .orange.opacity(0.82)
                            )
                            .multilineTextAlignment(.leading)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        if paso.noAplica {
                            Text("No va en este montaje")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 48,
                    alignment: .leading
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(ChecklistPressStyle())
            .accessibilityLabel(
                paso.completado
                    ? "Marcar como pendiente: \(paso.nombre)"
                    : "Marcar como completado: \(paso.nombre)"
            )

            if paso.permiteNoAplica {
                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        gestor.toggleNoAplica(paso)
                    }

                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                } label: {
                    Image(
                        systemName: paso.noAplica
                            ? "minus.circle.fill"
                            : "minus.circle"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        paso.noAplica
                            ? Color.orange
                            : Color.secondary.opacity(0.75)
                    )
                    .frame(width: 36, height: 38)
                    .background(
                        Circle()
                            .fill(
                                paso.noAplica
                                    ? Color.orange.opacity(0.15)
                                    : colorFondoControl
                            )
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                paso.noAplica
                                    ? Color.orange.opacity(0.30)
                                    : Color.primary.opacity(0.08),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(ChecklistPressStyle())
                .accessibilityLabel(
                    paso.noAplica
                        ? "Volver a incluir: \(paso.nombre)"
                        : "Este componente no va en mi PC: \(paso.nombre)"
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
            .fill(fondoFila(paso))
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 17,
                style: .continuous
            )
            .stroke(
                bordeFila(paso),
                lineWidth: 1
            )
            .allowsHitTesting(false)
        }
    }

    private func indicadorEstado(
        _ paso: PasoMontaje
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    colorFondoIndicador(paso)
                )
                .frame(width: 36, height: 36)

            if paso.estado == .pendiente {
                Image(systemName: paso.icono)
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: paso.estado.icono)
                    .font(
                        .system(
                            size: 15,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
            }
        }
        .overlay {
            Circle()
                .stroke(
                    paso.estado == .pendiente
                        ? Color.primary.opacity(0.09)
                        : paso.estado.color.opacity(0.35),
                    lineWidth: 1
                )
        }
    }

    private var estadoSinPasos: some View {
        VStack(spacing: 9) {
            Image(systemName: iconoSinPasos)
                .font(
                    .system(
                        size: 26,
                        weight: .semibold
                    )
                )
                .foregroundStyle(colorSinPasos)

            Text(mensajeSinPasos.localizado)
                .font(.subheadline.weight(.semibold))

            Text(mensajeSecundarioSinPasos.localizado)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 12)
        .background(
            Color.primary.opacity(0.045),
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
                Color.primary.opacity(0.08),
                lineWidth: 1
            )
        }
    }

    private var mensajeSinPasos: String {
        switch filtro {
        case .pendientes:
            return L("No quedan pasos pendientes")

        case .noAplica:
            return L("No has excluido ningún componente")

        case .completados:
            return L("Aún no has completado pasos")
        }
    }

    private var mensajeSecundarioSinPasos: String {
        switch filtro {
        case .pendientes:
            return L("Todos los pasos requeridos están listos.")

        case .noAplica:
            return L("Pulsa menos en un paso opcional si no vas a hacerlo.")

        case .completados:
            return L("Marca un paso como terminado para verlo aquí.")
        }
    }

    private var iconoSinPasos: String {
        switch filtro {
        case .pendientes:
            return "checkmark.seal.fill"

        case .noAplica:
            return "minus.circle.fill"

        case .completados:
            return "checkmark.circle"
        }
    }

    private var colorSinPasos: Color {
        switch filtro {
        case .pendientes:
            return .green

        case .noAplica:
            return .orange

        case .completados:
            return .blue
        }
    }

    private func fondoFila(
        _ paso: PasoMontaje
    ) -> Color {
        switch paso.estado {
        case .pendiente:
            if colorScheme == .dark {
                return .white.opacity(0.055)
            }

            return .white.opacity(0.38)

        case .completado:
            return .green.opacity(
                colorScheme == .dark ? 0.16 : 0.12
            )

        case .noAplica:
            return .orange.opacity(
                colorScheme == .dark ? 0.14 : 0.10
            )
        }
    }

    private func bordeFila(
        _ paso: PasoMontaje
    ) -> Color {
        switch paso.estado {
        case .pendiente:
            return Color.primary.opacity(0.09)

        case .completado:
            return .green.opacity(0.28)

        case .noAplica:
            return .orange.opacity(0.28)
        }
    }

    private func colorFondoIndicador(
        _ paso: PasoMontaje
    ) -> Color {
        switch paso.estado {
        case .pendiente:
            return colorFondoControl

        case .completado:
            return .green

        case .noAplica:
            return .orange
        }
    }

    private func colorTexto(
        _ paso: PasoMontaje
    ) -> Color {
        switch paso.estado {
        case .pendiente, .completado:
            return .primary

        case .noAplica:
            return .secondary
        }
    }
}

private struct ChecklistPressStyle: ButtonStyle {

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
