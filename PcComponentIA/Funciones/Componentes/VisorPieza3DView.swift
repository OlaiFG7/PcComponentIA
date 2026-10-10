//
//  VisorPieza3DView.swift
//  PcComponentIA
//
//  Visor 3D de una pieza (modelo USDZ del bundle) con sus conectores:
//  - al abrir, la cámara llega desde lejos y encuadra la pieza entera;
//  - se gira arrastrando y se acerca pellizcando;
//  - al tocar un conector, la cámara se acerca a él y aparece una burbuja con su explicación.
//  La cámara la mueve la app (no los controles automáticos) para poder animar el zoom.
//

import Combine
import RealityKit
import SwiftUI

// MARK: - Datos

/// Conector en 3D. La posición va de 0 a 1 dentro de la caja que envuelve al modelo
/// (x: izquierda→derecha, y: abajo→arriba, z: fondo→frente), así no depende de su escala.
struct Punto3D: Identifiable {
    var id: String { nombre }
    let nombre: String
    let descripcion: String
    let posicion: SIMD3<Float>
    var claveFicha: String? = nil
    /// Dibujo de la forma del conector, para reconocerlo cuando en el modelo no se ve bien.
    var silueta: SiluetaConector? = nil
}

struct ModeloPieza3D {
    /// Nombre del .usdz dentro de la app (sin extensión).
    let archivo: String
    let titulo: String
    let puntos: [Punto3D]
    /// Crédito obligatorio por la licencia CC BY.
    let credito: String
    /// Lado desde el que se miran siempre los conectores (p. ej. el frente de una placa, que es
    /// plana y no tiene nada por detrás). Si es nil, la cámara se coloca según dónde esté el punto.
    var vistaFija: SIMD3<Float>? = nil
}

enum ModelosPiezas3D {
    /// Clave de la ficha → modelo 3D (USDZ de Sketchfab, licencia CC BY 4.0).
    /// Posiciones medidas sobre vistas renderizadas de cada modelo con una cuadrícula 0-1.
    static var todos: [String: ModeloPieza3D] { _todos.valor }
    private static let _todos = PorIdioma<[String: ModeloPieza3D]> {
        [
        "GPU": grafica,
        "Placa_Base": placaBase,
        "Modulo_RAM": ram,
        "M2_SSD_NVMe": m2,
        "Fuente_Alimentacion": fuente,
    ]
    }

    private static func p(_ x: Float, _ y: Float, _ z: Float) -> SIMD3<Float> { SIMD3(x, y, z) }

    static var grafica: ModeloPieza3D { _grafica.valor }

    private static let _grafica = PorIdioma<ModeloPieza3D> {
        ModeloPieza3D(
        archivo: "gpu",
        titulo: L("Tarjeta gráfica"),
        puntos: [
            Punto3D(nombre: L("Conector PCIe x16"),
                    descripcion: L("Los contactos dorados que entran en la ranura PCIe x16 de la placa base."),
                    posicion: p(0.4, 0.65, 0.08), claveFicha: "Ranura_PCIe_x16"),
            Punto3D(nombre: L("Salidas de vídeo"),
                    descripcion: L("HDMI y DisplayPort: el monitor se conecta aquí, no a la placa base."),
                    posicion: p(0.7, 1.0, 0.5), claveFicha: "Puerto_DisplayPort"),
            Punto3D(nombre: L("Soporte metálico"),
                    descripcion: L("Se atornilla a la caja para que la gráfica no se incline ni se mueva."),
                    posicion: p(0.3, 1.0, 0.3)),
            Punto3D(nombre: L("Alimentación 12 pines"),
                    descripcion: L("Recibe corriente extra de la fuente. Sin este cable la gráfica no arranca; debe entrar hasta el fondo."),
                    posicion: p(0.52, 0.405, 0.95), claveFicha: "Conector_12VHPWR"),
            Punto3D(nombre: L("Ventilador"),
                    descripcion: L("Enfría la GPU. Muchos se paran en reposo: es normal."),
                    posicion: p(1.0, 0.2, 0.55)),
        ],
        credito: L("Modelo 3D: «GeForce RTX 3080 Graphics Card» de _surovic_ (Sketchfab, CC BY 4.0)")
    )
    }

    static var placaBase: ModeloPieza3D { _placaBase.valor }

    private static let _placaBase = PorIdioma<ModeloPieza3D> {
        ModeloPieza3D(
        archivo: "placa_base",
        titulo: L("Placa base ATX"),
        puntos: [
            Punto3D(nombre: L("Socket de la CPU"),
                    descripcion: L("Donde va el procesador. Intel (LGA) y AMD (AM4/AM5) no son compatibles entre sí."),
                    posicion: p(0.55, 0.72, 0.15), claveFicha: "CPU"),
            Punto3D(nombre: L("Ranuras RAM"),
                    descripcion: L("Cuatro ranuras DIMM. Con dos módulos, usa las que indique el manual (suele ser A2 y B2)."),
                    posicion: p(0.82, 0.72, 0.95), claveFicha: "Ranura_RAM"),
            Punto3D(nombre: L("VRM"),
                    descripcion: L("Regulan la corriente de la CPU; van bajo estos disipadores."),
                    posicion: p(0.45, 0.93, 0.55), claveFicha: "VRM"),
            Punto3D(nombre: L("Panel trasero (I/O)"),
                    descripcion: L("Puertos USB, red, audio y vídeo que asoman por detrás de la caja."),
                    posicion: p(0.1, 0.75, 0.8), claveFicha: "Protector_IO"),
            Punto3D(nombre: L("EPS 8 pines (CPU)"),
                    descripcion: L("Alimentación del procesador desde la fuente. Imprescindible."),
                    posicion: p(0.29, 0.97, 0.36), claveFicha: "Conector_EPS_8p", silueta: .pines(columnas: 4, corte: 2)),
            Punto3D(nombre: L("ATX 24 pines"),
                    descripcion: L("Alimentación principal de la placa. El conector más grande de la fuente."),
                    posicion: p(0.97, 0.65, 0.35), claveFicha: "Conector_ATX_24p", silueta: .pines(columnas: 12, corte: 0)),
            Punto3D(nombre: L("M.2"),
                    descripcion: L("Ranura para SSD M.2 NVMe, el almacenamiento más rápido. Se fija con un tornillo."),
                    posicion: p(0.5, 0.47, 0.1), claveFicha: "Ranura_M2", silueta: .ranuraM2),
            Punto3D(nombre: L("PCIe x16"),
                    descripcion: L("Ranura para la tarjeta gráfica. Usa siempre la más cercana a la CPU."),
                    posicion: p(0.5, 0.4, 0.22), claveFicha: "Ranura_PCIe_x16", silueta: .ranura(largo: 1)),
            Punto3D(nombre: L("PCIe x1"),
                    descripcion: L("Ranura corta para tarjetas de red, sonido o capturadoras."),
                    posicion: p(0.25, 0.47, 0.22), claveFicha: "Ranura_PCIe_x1", silueta: .ranura(largo: 0.28)),
            Punto3D(nombre: L("Pila CMOS"),
                    descripcion: L("Pila de botón que guarda la hora y la configuración de la BIOS."),
                    posicion: p(0.41, 0.335, 0.1), claveFicha: "Pila_CMOS"),
            Punto3D(nombre: L("Chipset"),
                    descripcion: L("Gestiona USB, SATA y otras conexiones. Va bajo este disipador plano."),
                    posicion: p(0.78, 0.25, 0.3), claveFicha: "Chipset"),
            Punto3D(nombre: L("Puertos SATA"),
                    descripcion: L("Para discos duros y SSD de 2,5\". Necesitan también cable de corriente."),
                    posicion: p(0.975, 0.27, 0.35), claveFicha: "Puerto_SATA", silueta: .sata(ancho: 0.42)),
            Punto3D(nombre: L("Audio frontal"),
                    descripcion: L("Cabezal para las tomas de auriculares y micrófono del frontal de la caja."),
                    posicion: p(0.23, 0.02, 0.15), claveFicha: "Conector_HD_Audio"),
            Punto3D(nombre: L("USB frontales"),
                    descripcion: L("Cabezales para los USB del frontal de la caja."),
                    posicion: p(0.76, 0.02, 0.15), claveFicha: "Conector_USB_2_0"),
            Punto3D(nombre: L("Panel frontal"),
                    descripcion: L("Pines del botón de encendido, reset y LEDs de la caja."),
                    posicion: p(0.93, 0.02, 0.15), claveFicha: "Panel_Frontal_Pins"),
            Punto3D(nombre: L("CPU_FAN"),
                    descripcion: L("Cabezal de 4 pines para el ventilador del disipador de la CPU."),
                    posicion: p(0.73, 0.92, 0.15), claveFicha: "Conector_FAN", silueta: .cabezal(pines: 4, hueco: nil)),
            Punto3D(nombre: L("SYS_FAN"),
                    descripcion: L("Cabezal de 4 pines para ventiladores de la caja."),
                    posicion: p(0.28, 0.545, 0.15), claveFicha: "Conector_SYS_FAN", silueta: .cabezal(pines: 4, hueco: nil)),
            Punto3D(nombre: L("M.2 (2)"),
                    descripcion: L("Segunda ranura M.2 para otro SSD."),
                    posicion: p(0.6, 0.1, 0.33), claveFicha: "Ranura_M2", silueta: .ranuraM2),
            Punto3D(nombre: L("PCIe x16 (2)"),
                    descripcion: L("Segunda ranura larga. Suele ir más lenta que la primera: úsala para otra tarjeta, no para la gráfica principal."),
                    posicion: p(0.5, 0.2, 0.22), claveFicha: "Ranura_PCIe_x16", silueta: .ranura(largo: 1)),
            Punto3D(nombre: L("USB 3.0 frontal"),
                    descripcion: L("Cabezal de 19 pines para los USB 3.0 del frontal de la caja."),
                    posicion: p(0.965, 0.52, 0.25), claveFicha: "Conector_USB_3_0_Front"),
            Punto3D(nombre: L("RGB 12 V"),
                    descripcion: L("Cabezal de 4 pines para tiras de luz de un solo color. No lo confundas con el ARGB de 5 V, que tiene 3 pines."),
                    posicion: p(0.93, 0.975, 0.15), claveFicha: "Conector_RGB_12V", silueta: .cabezal(pines: 4, hueco: nil)),
            Punto3D(nombre: L("Chip de audio (DAC)"),
                    descripcion: L("Convierte el sonido digital en analógico; de él depende la calidad."),
                    posicion: p(0.12, 0.14, 0.15), claveFicha: "Conector_HD_Audio"),
            Punto3D(nombre: L("Antenas Wi-Fi"),
                    descripcion: L("Conectores dorados donde se enroscan las antenas de Wi-Fi y Bluetooth."),
                    posicion: p(0.02, 0.92, 0.4), claveFicha: "Antena_WiFi"),
        ],
        credito: L("Modelo 3D: «MotherBoard + Components» de Daniel Cardona (Sketchfab, CC BY 4.0)"),
        vistaFija: SIMD3(0, 0, 1)
    )
    }

    // El modelo trae varios módulos en cuadrícula: los puntos están sobre el primero
    static var ram: ModeloPieza3D { _ram.valor }
    private static let _ram = PorIdioma<ModeloPieza3D> {
        ModeloPieza3D(
        archivo: "ram",
        titulo: L("Memoria RAM DDR5"),
        puntos: [
            Punto3D(nombre: L("Contactos dorados"),
                    descripcion: L("Entran en la ranura de la placa. La muesca del borde impide ponerlo al revés o en una ranura de otro tipo (DDR4/DDR5)."),
                    posicion: p(0.2, 1.0, 0.25), claveFicha: "Ranura_RAM"),
            Punto3D(nombre: L("Chips de memoria"),
                    descripcion: L("Guardan los datos mientras el equipo está encendido; se borran al apagarlo."),
                    posicion: p(0.1, 1.0, 0.3), claveFicha: "Modulo_RAM"),
        ],
        credito: L("Modelo 3D: «RAM-Hynix553-8a-24GB(DDR5S)» de Apple (Sketchfab, CC BY 4.0)")
    )
    }

    static var m2: ModeloPieza3D { _m2.valor }

    private static let _m2 = PorIdioma<ModeloPieza3D> {
        ModeloPieza3D(
        archivo: "m2",
        titulo: L("SSD M.2"),
        puntos: [
            Punto3D(nombre: L("Contactos M.2"),
                    descripcion: L("Entran inclinados en la ranura M.2 de la placa; luego se baja el SSD y se atornilla."),
                    posicion: p(0.02, 1.0, 0.5), claveFicha: "Ranura_M2"),
            Punto3D(nombre: L("Controlador"),
                    descripcion: L("El «cerebro» del SSD: gestiona dónde se guarda cada dato."),
                    posicion: p(0.17, 1.0, 0.25)),
            Punto3D(nombre: L("Chips de memoria NAND"),
                    descripcion: L("Donde se guardan los archivos; no se borran al apagar."),
                    posicion: p(0.72, 1.0, 0.5), claveFicha: "M2_SSD_NVMe"),
            Punto3D(nombre: L("Muesca del tornillo"),
                    descripcion: L("Aquí va el tornillo (o el clip) que sujeta el SSD a la placa."),
                    posicion: p(0.98, 1.0, 0.5)),
        ],
        credito: L("Modelo 3D: «SSD NoName m.2 256gb» de Хлюпич (Sketchfab, CC BY 4.0)")
    )
    }

    static var fuente: ModeloPieza3D { _fuente.valor }

    private static let _fuente = PorIdioma<ModeloPieza3D> {
        ModeloPieza3D(
        archivo: "fuente",
        titulo: L("Fuente de alimentación"),
        puntos: [
            Punto3D(nombre: L("Interruptor"),
                    descripcion: L("Enciende la fuente. «I» es encendido y «O» apagado: apágala antes de tocar nada dentro."),
                    posicion: p(0.67, 0.5, 1.0)),
            Punto3D(nombre: L("Toma de corriente"),
                    descripcion: L("Aquí va el cable de corriente de la pared (conector IEC)."),
                    posicion: p(0.85, 0.5, 1.0), claveFicha: "Cable_Corriente_IEC"),
            Punto3D(nombre: L("Rejilla de ventilación"),
                    descripcion: L("Por aquí sale el aire caliente. Debe quedar libre por detrás de la caja."),
                    posicion: p(0.3, 0.6, 1.0)),
            Punto3D(nombre: L("Ventilador"),
                    descripcion: L("Enfría la fuente. Si la caja tiene filtro abajo, monta la fuente con el ventilador hacia abajo."),
                    posicion: p(0.5, 1.0, 0.5)),
        ],
        credito: L("Modelo 3D: «M1000 inspired by Corsair HX1000» de Igor.Jop (Sketchfab, CC BY 4.0)")
    )
    }

    static func modelo(para clave: String) -> ModeloPieza3D? {
        guard let modelo = todos[clave],
              Bundle.main.url(forResource: modelo.archivo, withExtension: "usdz") != nil
        else { return nil }
        return modelo
    }
}

// MARK: - Cámara

/// Estado de una cámara que orbita alrededor de un punto.
struct EstadoCamara: Equatable {
    var giro: Float = 0          // alrededor del eje vertical (radianes)
    var inclinacion: Float = 0.35
    var distancia: Float = 2.2
    var objetivo: SIMD3<Float> = .zero

    var posicion: SIMD3<Float> {
        objetivo + distancia * SIMD3(
            sin(giro) * cos(inclinacion),
            sin(inclinacion),
            cos(giro) * cos(inclinacion)
        )
    }

    func mezclado(hacia otro: EstadoCamara, _ t: Float) -> EstadoCamara {
        EstadoCamara(
            giro: giro + (otro.giro - giro) * t,
            inclinacion: inclinacion + (otro.inclinacion - inclinacion) * t,
            distancia: distancia + (otro.distancia - distancia) * t,
            objetivo: objetivo + (otro.objetivo - objetivo) * t
        )
    }

    func parecido(a otro: EstadoCamara) -> Bool {
        abs(giro - otro.giro) < 0.001 && abs(inclinacion - otro.inclinacion) < 0.001
            && abs(distancia - otro.distancia) < 0.001 && simd_distance(objetivo, otro.objetivo) < 0.001
    }
}

/// Mueve la cámara suavemente hacia su destino (60 fps mientras se mueve).
@MainActor
final class ControladorCamara3D: ObservableObject {
    @Published private(set) var actual = EstadoCamara(giro: 2.4, inclinacion: 0.9, distancia: 6)
    var destino = EstadoCamara()
    var girarSolo = true
    private var bucle: Task<Void, Never>?

    static let campoVisionGrados: Float = 45

    func arrancar() {
        guard bucle == nil else { return }
        bucle = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard let self else { return }
                if self.girarSolo {
                    self.destino.giro += 0.003
                }
                guard !self.actual.parecido(a: self.destino) else { continue }
                self.actual = self.actual.mezclado(hacia: self.destino, 0.09)
            }
        }
    }

    func parar() {
        bucle?.cancel()
        bucle = nil
    }

    /// Proyecta un punto 3D a la pantalla (nil si queda detrás de la cámara).
    func proyectar(_ punto: SIMD3<Float>, en tamano: CGSize) -> CGPoint? {
        let estado = actual
        let delante = simd_normalize(estado.objetivo - estado.posicion)
        let derecha = simd_normalize(simd_cross(delante, SIMD3(0, 1, 0)))
        let arriba = simd_cross(derecha, delante)
        let d = punto - estado.posicion
        let profundidad = simd_dot(d, delante)
        guard profundidad > 0.01, tamano.height > 0 else { return nil }

        let tanMitad = tan(Self.campoVisionGrados * .pi / 360)
        let aspecto = Float(tamano.width / tamano.height)
        let x = simd_dot(d, derecha) / (profundidad * tanMitad * aspecto)
        let y = simd_dot(d, arriba) / (profundidad * tanMitad)
        return CGPoint(
            x: CGFloat((x + 1) / 2) * tamano.width,
            y: CGFloat((1 - y) / 2) * tamano.height
        )
    }
}

// MARK: - Vista

struct VisorPieza3DView: View {
    let modelo: ModeloPieza3D

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @Environment(\.dismiss) private var dismiss

    @StateObject private var camara = ControladorCamara3D()
    @State private var camaraEntidad = PerspectiveCamera()
    @State private var mitadTamano: SIMD3<Float> = SIMD3(0.5, 0.5, 0.5)
    @State private var cargado = false
    @State private var fallo = false
    /// Cambia para volver a crear la escena al reintentar la carga
    @State private var intento = 0
    @State private var seleccionado: Punto3D?
    @State private var inicioArrastre: EstadoCamara?
    @State private var inicioZoom: Float?

    private let diccionario = DatosHardware.obtenerDiccionario()
    private let encuadreInicial = EstadoCamara()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.16), Color(white: 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                escena
                    .id(intento)
                    .gesture(gestoGirar.simultaneously(with: gestoZoom))
                    .onTapGesture { deseleccionar() }

                if cargado {
                    ForEach(modelo.puntos) { punto in
                        if let posicion = camara.proyectar(mundo(punto), en: geo.size) {
                            marcador(punto)
                                .position(posicion)
                        }
                    }
                }

                if !cargado && !fallo {
                    ProgressView("Cargando modelo 3D…")
                        .tint(.white)
                        .foregroundStyle(.white)
                }

                if fallo {
                    ContentUnavailableView {
                        Label("No se pudo cargar el modelo", systemImage: "cube.transparent")
                    } description: {
                        Text("Prueba a cerrar y abrir de nuevo.")
                    } actions: {
                        Button("Reintentar") {
                            fallo = false
                            intento += 1
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 10) {
                    if let punto = seleccionado {
                        burbujaDetalle(punto)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if cargado {
                        tiraConectores
                    }
                    Text(modelo.credito.localizado)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .animation(Animaciones.muelle, value: seleccionado?.id)
            }
        }
        .navigationTitle(modelo.titulo.localizado)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cerrar") { dismiss() }
            }
            if seleccionado != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        deseleccionar()
                    } label: {
                        Label("Ver pieza entera", systemImage: "arrow.down.right.and.arrow.up.left")
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: seleccionado?.id)
        .onDisappear { camara.parar() }
    }

    // MARK: Escena RealityKit

    private var escena: some View {
        RealityView { contenido in
            contenido.camera = .virtual

            camaraEntidad.camera.fieldOfViewInDegrees = ControladorCamara3D.campoVisionGrados
            camaraEntidad.camera.fieldOfViewOrientation = .vertical
            contenido.add(camaraEntidad)

            let luz = DirectionalLight()
            luz.light.intensity = 3000
            luz.look(at: .zero, from: SIMD3(1.5, 3, 2), relativeTo: nil)
            contenido.add(luz)

            let relleno = PointLight()
            relleno.light.intensity = 8000
            relleno.position = SIMD3(-2, 1, -1.5)
            contenido.add(relleno)

            do {
                let pieza = try await Entity(named: modelo.archivo)
                // Se escala a 1 m de lado mayor y se centra en el origen
                let limites = pieza.visualBounds(relativeTo: nil)
                let mayor = max(limites.extents.x, limites.extents.y, limites.extents.z)
                let escala = mayor > 0 ? 1 / mayor : 1
                pieza.scale *= escala
                pieza.position -= limites.center * escala
                contenido.add(pieza)

                mitadTamano = limites.extents * escala / 2
                cargado = true
                camara.destino = encuadreInicial
                camara.girarSolo = !reducirMovimiento
                if reducirMovimiento {
                    // Sin vuelo de entrada: se coloca directamente
                    camara.destino = encuadreInicial
                }
                camara.arrancar()
            } catch {
                fallo = true
            }
        } update: { _ in
            let estado = camara.actual
            camaraEntidad.look(at: estado.objetivo, from: estado.posicion, relativeTo: nil)
        }
        .accessibilityLabel("Modelo 3D de \(modelo.titulo). Usa la lista de conectores para explorarlo.")
    }

    /// Posición en el mundo de un conector (sus coordenadas van de 0 a 1 dentro del modelo).
    private func mundo(_ punto: Punto3D) -> SIMD3<Float> {
        (punto.posicion * 2 - 1) * mitadTamano
    }

    // MARK: Gestos

    private var gestoGirar: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { valor in
                camara.girarSolo = false
                let base = inicioArrastre ?? camara.destino
                if inicioArrastre == nil { inicioArrastre = base }
                camara.destino.giro = base.giro - Float(valor.translation.width) * 0.008
                camara.destino.inclinacion = min(1.3, max(-1.3, base.inclinacion + Float(valor.translation.height) * 0.006))
            }
            .onEnded { _ in inicioArrastre = nil }
    }

    private var gestoZoom: some Gesture {
        MagnifyGesture()
            .onChanged { valor in
                camara.girarSolo = false
                let base = inicioZoom ?? camara.destino.distancia
                if inicioZoom == nil { inicioZoom = base }
                camara.destino.distancia = min(5, max(0.35, base / Float(valor.magnification)))
            }
            .onEnded { _ in inicioZoom = nil }
    }

    // MARK: Conectores

    private func marcador(_ punto: Punto3D) -> some View {
        let activo = seleccionado?.id == punto.id
        // Con muchos conectores los nombres se pisan: solo lo lleva el elegido (el resto, en la tira)
        let conNombre = activo || modelo.puntos.count <= 8

        return Button {
            seleccionar(punto)
        } label: {
            // El círculo va centrado justo sobre el conector; el nombre cuelga a su derecha
            // sin desplazarlo.
            Circle()
                .fill(activo ? Color.cyan : Color.white)
                .frame(width: 10, height: 10)
                .overlay {
                    if !reducirMovimiento {
                        Circle()
                            .stroke(activo ? Color.cyan : Color.white, lineWidth: 1.5)
                            .phaseAnimator([false, true]) { anillo, expandido in
                                anillo.scaleEffect(expandido ? 2.6 : 1).opacity(expandido ? 0 : 0.9)
                            } animation: { expandido in
                                expandido ? .easeOut(duration: 1.4) : .linear(duration: 0)
                            }
                    }
                }
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
                .overlay(alignment: .leading) {
                    if conNombre {
                        Text(punto.nombre.localizado)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
                            .environment(\.colorScheme, .dark)
                            .fixedSize()
                            .offset(x: 28)
                            .allowsHitTesting(false)
                    }
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(activo ? 1.12 : 1)
        .animation(Animaciones.muelle, value: activo)
        .accessibilityLabel(punto.nombre.localizado)
        .accessibilityHint(punto.descripcion.localizado)
        .accessibilityAddTraits(activo ? .isSelected : [])
    }

    /// Todos los conectores en una fila: en piezas con muchos puntos los marcadores se pisan,
    /// y así también se pueden recorrer con VoiceOver.
    private var tiraConectores: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(modelo.puntos) { punto in
                        let activo = seleccionado?.id == punto.id
                        Button {
                            seleccionar(punto)
                        } label: {
                            Text(punto.nombre.localizado)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(activo ? Color.black : Color.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    activo ? AnyShapeStyle(Color.cyan) : AnyShapeStyle(.ultraThinMaterial),
                                    in: Capsule()
                                )
                                // Zona táctil de 44 pt aunque la cápsula sea más baja
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(punto.id)
                        .accessibilityHint(punto.descripcion.localizado)
                        .accessibilityAddTraits(activo ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 16)
            }
            .onChange(of: seleccionado?.id) { _, nuevo in
                guard let nuevo else { return }
                withAnimation(Animaciones.muelle) {
                    proxy.scrollTo(nuevo, anchor: .center)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func seleccionar(_ punto: Punto3D) {
        seleccionado = punto
        camara.girarSolo = false
        // La cámara se acerca al conector, mirándolo desde fuera de la pieza
        let destinoPunto = mundo(punto)
        var nuevo = camara.destino
        nuevo.objetivo = destinoPunto
        nuevo.distancia = 0.55
        let horizontal = SIMD2(destinoPunto.x, destinoPunto.z)
        if let vista = modelo.vistaFija {
            nuevo.giro = atan2(vista.x, vista.z)
            nuevo.inclinacion = 0.25
        } else {
            if simd_length(horizontal) > 0.05 {
                nuevo.giro = atan2(destinoPunto.x, destinoPunto.z)
            }
            nuevo.inclinacion = destinoPunto.y > 0 ? 0.6 : 0.2
        }
        camara.destino = nuevo
    }

    private func deseleccionar() {
        guard seleccionado != nil else { return }
        seleccionado = nil
        var vuelta = encuadreInicial
        vuelta.giro = camara.destino.giro
        camara.destino = vuelta
    }

    private func burbujaDetalle(_ punto: Punto3D) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(punto.nombre.localizado)
                        .font(.headline)
                    Text(punto.descripcion.localizado)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                // Cómo es el conector, por si en el modelo queda tapado o se ve pequeño
                if let silueta = punto.silueta {
                    SiluetaConectorView(silueta: silueta, acento: .cyan)
                        .frame(width: 116, height: 64)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                }
            }
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
        .frame(maxWidth: 520, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
