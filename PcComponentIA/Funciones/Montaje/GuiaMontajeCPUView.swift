//
//  GuiaMontajeCPUView.swift
//  PcComponentIA
//
//  Guía visual para montar el procesador y su disipador: un dibujo animado por paso,
//  adaptado al tipo de socket, y al final se marcan los pasos en el checklist.
//

import SwiftUI

// MARK: - Datos

enum PlataformaCPU: String, CaseIterable, Identifiable {
    case intel, am5, am4

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .intel: "Intel (LGA)"
        case .am5: "AMD AM5"
        case .am4: "AMD AM4"
        }
    }

    /// LGA y AM5 llevan los contactos en la placa y un marco metálico; AM4, solo agujeros.
    var contactosEnPlaca: Bool { self != .am4 }
}

struct PasoGuiaCPU: Identifiable {
    enum Dibujo {
        case preparar, abrir, alinear, soltar, cerrar, pasta, disipador, ventilador, final
    }

    let id: Int
    let dibujo: Dibujo
    let titulo: String
    let texto: String
    var aviso: String? = nil

    static func pasos(para plataforma: PlataformaCPU) -> [PasoGuiaCPU] {
        let abrir: String
        let avisoAbrir: String
        let cerrar: String

        switch plataforma {
        case .intel:
            abrir = L("Empuja la palanca hacia abajo y hacia fuera para soltarla, y levántala del todo. El marco metálico se abre con ella. Deja puesta la tapa de plástico negra: saltará sola al cerrar.")
            avisoAbrir = L("No toques los contactos del socket: se doblan con nada y arreglarlos es muy difícil.")
            cerrar = L("Baja el marco metálico y después la palanca, hasta engancharla bajo su pestaña. Hace falta bastante fuerza y es normal oír un crujido. La tapa de plástico salta sola: guárdala.")
        case .am5:
            abrir = L("Empuja la palanca hacia abajo y hacia fuera, levántala y abre el marco metálico. Deja puesta la tapa de plástico: saltará sola al cerrar.")
            avisoAbrir = L("No toques los contactos del socket: se doblan con nada y arreglarlos es muy difícil.")
            cerrar = L("Baja el marco metálico y después la palanca, hasta engancharla bajo su pestaña. Hace falta bastante fuerza y es normal oír un crujido. La tapa de plástico salta sola: guárdala.")
        case .am4:
            abrir = L("Levanta la palanca del lateral hasta que quede en vertical. Este socket no tiene marco: solo se ven los agujeros.")
            avisoAbrir = L("Coge el procesador por los bordes: los pines de debajo se doblan con facilidad.")
            cerrar = L("Baja la palanca hasta que quede enganchada. Va suave: si se resiste, el procesador no está bien asentado.")
        }

        return [
            PasoGuiaCPU(
                id: 0, dibujo: .preparar,
                titulo: L("Prepara la zona"),
                texto: L("Trabaja con la placa fuera de la caja, apoyada sobre su propia caja de cartón. Toca algo metálico antes de empezar para descargar la electricidad estática."),
                aviso: L("No apoyes la placa sobre la bolsa antiestática: por fuera conduce la electricidad.")
            ),
            PasoGuiaCPU(id: 1, dibujo: .abrir, titulo: L("Abre el socket"), texto: abrir, aviso: avisoAbrir),
            PasoGuiaCPU(
                id: 2, dibujo: .alinear,
                titulo: L("Alinea el triángulo"),
                texto: L("El procesador tiene un triángulo dorado en una esquina, y el socket, una marca igual. Las dos tienen que coincidir: el procesador solo encaja de una forma.")
            ),
            PasoGuiaCPU(
                id: 3, dibujo: .soltar,
                titulo: L("Déjalo caer, sin apretar"),
                texto: L("Baja el procesador recto y suéltalo sobre el socket. Debe quedar plano por su propio peso. Si no asienta, levántalo y vuelve a alinearlo: nunca lo empujes.")
            ),
            PasoGuiaCPU(id: 4, dibujo: .cerrar, titulo: L("Cierra el socket"), texto: cerrar),
            PasoGuiaCPU(
                id: 5, dibujo: .pasta,
                titulo: L("Pasta térmica"),
                texto: L("Mira la base del disipador: si ya trae una capa gris, no pongas más. Si no, pon una gota del tamaño de un guisante en el centro del procesador. El disipador la extiende al apretar."),
                aviso: L("Si el disipador trae un plástico protector en la base, quítalo.")
            ),
            PasoGuiaCPU(
                id: 6, dibujo: .disipador,
                titulo: L("Monta el disipador"),
                texto: L("Colócalo recto sobre el procesador, alineado con sus anclajes. Aprieta los tornillos en cruz y poco a poco: unas vueltas a uno, luego al de la esquina contraria, y así hasta que todos hagan tope."),
                aviso: L("Cada disipador se ancla de una forma. Sigue su manual para elegir las piezas de tu socket.")
            ),
            PasoGuiaCPU(
                id: 7, dibujo: .ventilador,
                titulo: L("Conecta el ventilador"),
                texto: L("Enchufa el cable del ventilador al cabezal CPU_FAN de la placa, cerca del socket. La guía de plástico solo deja ponerlo de una forma. Recoge el cable sobrante para que no roce las aspas.")
            ),
            PasoGuiaCPU(
                id: 8, dibujo: .final,
                titulo: L("Comprobación final"),
                texto: L("El disipador no debe moverse al tocarlo, y el ventilador debe girar libre. Ya puedes marcar estos pasos en tu checklist.")
            ),
        ]
    }
}

// MARK: - Vista

struct GuiaMontajeCPUView: View {

    @AppStorage("plataformaGuiaCPU")
    private var plataformaGuardada = PlataformaCPU.intel.rawValue

    private let acento = Color.cyan

    private var plataforma: PlataformaCPU {
        PlataformaCPU(rawValue: plataformaGuardada) ?? .intel
    }

    var body: some View {
        let lista = PasoGuiaCPU.pasos(para: plataforma)

        GuiaPasosView(
            titulo: L("Procesador y disipador"),
            pasos: lista.map { PasoGuia(id: $0.id, titulo: $0.titulo, texto: $0.texto, aviso: $0.aviso) },
            pasosChecklist: [
                "Instalar CPU en el socket de la placa base",
                "Comprobar o aplicar pasta térmica",
                "Montar disipador o refrigeración de CPU",
                "Conectar cable CPU_FAN al disipador",
            ],
            acento: acento,
            variante: plataforma.rawValue
        ) {
            Picker(L("Tu plataforma"), selection: $plataformaGuardada) {
                ForEach(PlataformaCPU.allCases) { opcion in
                    Text(opcion.titulo).tag(opcion.rawValue)
                }
            }
            .pickerStyle(.segmented)
        } dibujo: { indice, animado in
            DibujoPasoCPUView(
                dibujo: lista[indice].dibujo,
                plataforma: plataforma,
                animado: animado,
                acento: acento
            )
        }
    }
}

// MARK: - Dibujo animado

/// Vista cenital del socket. Cada paso anima de 0 a 1, se queda un momento al final y repite.
struct DibujoPasoCPUView: View {
    let dibujo: PasoGuiaCPU.Dibujo
    let plataforma: PlataformaCPU
    let animado: Bool
    let acento: Color

    @State private var inicio = Date()

    private let duracion = 2.6
    private let pausa = 1.1

    private let oro = Color(red: 0.90, green: 0.70, blue: 0.24)
    private let metal = Color(white: 0.78)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animado)) { linea in
            let segundos = linea.date.timeIntervalSince(inicio)
            let ciclo = segundos.truncatingRemainder(dividingBy: duracion + pausa)
            let t = animado ? min(ciclo / duracion, 1) : 1

            Canvas { ctx, tam in
                pintar(ctx, tam: tam, t: t, segundos: animado ? segundos : 0)
            }
        }
        .onAppear { inicio = Date() }
    }

    private func suave(_ t: Double) -> Double {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    // MARK: Escena

    private func pintar(_ ctx: GraphicsContext, tam: CGSize, t: Double, segundos: Double) {
        let lado = min(tam.width, tam.height) * 0.42
        let centro = CGPoint(x: tam.width / 2, y: tam.height / 2)
        let socket = CGRect(x: centro.x - lado / 2, y: centro.y - lado / 2, width: lado, height: lado)

        placa(ctx, tam: tam, socket: socket, conCaja: dibujo == .preparar)

        switch dibujo {
        case .preparar:
            base(ctx, socket, contactos: true)
            cierre(ctx, socket, abierto: 0)
            // Recordatorio de la estática, que parpadea despacio
            var rayo = ctx.resolve(Image(systemName: "bolt.slash.fill"))
            rayo.shading = .color(oro.opacity(0.55 + 0.45 * sin(segundos * 2.4)))
            ctx.draw(rayo, in: CGRect(x: tam.width - 62, y: 22, width: 26, height: 30))

        case .abrir:
            base(ctx, socket, contactos: true)
            cierre(ctx, socket, abierto: suave(t))

        case .alinear:
            base(ctx, socket, contactos: true)
            cierre(ctx, socket, abierto: 1)
            let lejos = lado * 0.46 * (1 - 0.62 * suave(t))
            let pulso = 7 + 5 * (0.5 + 0.5 * sin(segundos * 5))
            anillo(ctx, en: marcaSocket(socket), radio: pulso)
            let chip = procesador(ctx, socket, desplazado: CGSize(width: lejos, height: -lejos), escala: 1.1, alfa: 0.96)
            anillo(ctx, en: CGPoint(x: chip.minX + 9, y: chip.maxY - 9), radio: pulso)

        case .soltar:
            base(ctx, socket, contactos: true)
            cierre(ctx, socket, abierto: 1)
            let caida = suave(t)
            // Sombra que se cierra bajo el procesador mientras baja
            let sombra = socket.insetBy(dx: lado * 0.07 - 10 * (1 - caida), dy: lado * 0.07 - 10 * (1 - caida))
            ctx.fill(Path(roundedRect: sombra, cornerRadius: 7), with: .color(.black.opacity(0.35 * (1 - caida))))
            procesador(ctx, socket, desplazado: .zero, escala: 1.26 - 0.26 * caida, alfa: 0.75 + 0.25 * caida)
            if t < 0.85 {
                var flecha = ctx.resolve(Image(systemName: "arrow.down"))
                flecha.shading = .color(acento)
                ctx.draw(flecha, in: CGRect(x: socket.maxX + 30, y: socket.midY - 28 + 20 * caida, width: 20, height: 24))
            }

        case .cerrar:
            base(ctx, socket, contactos: false)
            procesador(ctx, socket)
            cierre(ctx, socket, abierto: 1 - suave(t))

        case .pasta:
            base(ctx, socket, contactos: false)
            procesador(ctx, socket)
            cierre(ctx, socket, abierto: 0)
            gota(ctx, socket, tamano: suave(t * 1.4))

        case .disipador:
            base(ctx, socket, contactos: false)
            procesador(ctx, socket)
            cierre(ctx, socket, abierto: 0)
            gota(ctx, socket, tamano: 1)
            let bajada = suave(t / 0.4)
            // Tras posarse, los tornillos se aprietan en cruz: 1 y 2 en diagonal, luego 3 y 4
            let apretados = t < 0.4 ? 0 : min(Int((t - 0.4) / 0.6 * 4) + 1, 4)
            disipador(ctx, socket, escala: 1.28 - 0.28 * bajada, alfa: 0.2 + 0.8 * bajada, giro: 0, apretados: apretados, numerados: true)

        case .ventilador:
            base(ctx, socket, contactos: false)
            cierre(ctx, socket, abierto: 0)
            disipador(ctx, socket, escala: 1, alfa: 1, giro: segundos * 1.6, apretados: 4, numerados: false)
            cable(ctx, socket, tam: tam, tramo: suave(t))

        case .final:
            base(ctx, socket, contactos: false)
            cierre(ctx, socket, abierto: 0)
            disipador(ctx, socket, escala: 1, alfa: 1, giro: segundos * 1.6, apretados: 4, numerados: false)
            cable(ctx, socket, tam: tam, tramo: 1)
            let aparece = suave(t * 1.6)
            let radio = 24 * aparece
            let punto = CGPoint(x: tam.width - 52, y: tam.height - 50)
            ctx.fill(Path(ellipseIn: CGRect(x: punto.x - radio, y: punto.y - radio, width: radio * 2, height: radio * 2)), with: .color(.green))
            if aparece > 0.5 {
                var visto = ctx.resolve(Image(systemName: "checkmark"))
                visto.shading = .color(.white)
                ctx.draw(visto, in: CGRect(x: punto.x - 11, y: punto.y - 11, width: 22, height: 22))
            }
        }
    }

    // MARK: Piezas

    private func placa(_ ctx: GraphicsContext, tam: CGSize, socket: CGRect, conCaja: Bool) {
        if conCaja {
            // La caja de cartón sobre la que se apoya la placa
            let caja = CGRect(x: 6, y: 6, width: tam.width - 12, height: tam.height - 12)
            ctx.fill(Path(roundedRect: caja, cornerRadius: 20), with: .color(Color(red: 0.62, green: 0.47, blue: 0.30)))
        }
        let margen: CGFloat = conCaja ? 26 : 10
        let marco = CGRect(x: margen, y: margen, width: tam.width - margen * 2, height: tam.height - margen * 2)
        ctx.fill(Path(roundedRect: marco, cornerRadius: 16), with: .color(Color(red: 0.09, green: 0.17, blue: 0.20)))
        ctx.stroke(Path(roundedRect: marco, cornerRadius: 16), with: .color(.white.opacity(0.10)), lineWidth: 1)

        // Agujeros de anclaje del disipador, alrededor del socket
        for esquina in anclajes(socket) {
            let agujero = CGRect(x: esquina.x - 5, y: esquina.y - 5, width: 10, height: 10)
            ctx.stroke(Path(ellipseIn: agujero), with: .color(.white.opacity(0.35)), lineWidth: 1.5)
        }
    }

    private func anclajes(_ socket: CGRect) -> [CGPoint] {
        let zona = socket.insetBy(dx: -socket.width * 0.27, dy: -socket.width * 0.27)
        return [
            CGPoint(x: zona.minX, y: zona.minY), CGPoint(x: zona.maxX, y: zona.maxY),
            CGPoint(x: zona.maxX, y: zona.minY), CGPoint(x: zona.minX, y: zona.maxY),
        ]
    }

    private func marcaSocket(_ socket: CGRect) -> CGPoint {
        CGPoint(x: socket.minX - 9, y: socket.maxY + 9)
    }

    /// Cuerpo del socket, con sus contactos (LGA, AM5) o agujeros (AM4) si no hay procesador.
    private func base(_ ctx: GraphicsContext, _ socket: CGRect, contactos: Bool) {
        ctx.fill(Path(roundedRect: socket, cornerRadius: 7), with: .color(Color(white: 0.15)))
        ctx.stroke(Path(roundedRect: socket, cornerRadius: 7), with: .color(.white.opacity(0.35)), lineWidth: 1.5)

        if contactos {
            let n = 8
            let zona = socket.insetBy(dx: 12, dy: 12)
            for fila in 0..<n {
                for columna in 0..<n {
                    let punto = CGRect(
                        x: zona.minX + zona.width * CGFloat(columna) / CGFloat(n - 1) - 2,
                        y: zona.minY + zona.height * CGFloat(fila) / CGFloat(n - 1) - 2,
                        width: 4,
                        height: 4
                    )
                    if plataforma.contactosEnPlaca {
                        ctx.fill(Path(ellipseIn: punto), with: .color(oro))
                    } else {
                        ctx.stroke(Path(ellipseIn: punto), with: .color(.white.opacity(0.55)), lineWidth: 1)
                    }
                }
            }
        }

        // Marca de orientación del socket: el triángulo de la esquina
        let m = marcaSocket(socket)
        var triangulo = Path()
        triangulo.move(to: CGPoint(x: m.x - 6, y: m.y + 6))
        triangulo.addLine(to: CGPoint(x: m.x + 6, y: m.y + 6))
        triangulo.addLine(to: CGPoint(x: m.x - 6, y: m.y - 6))
        triangulo.closeSubpath()
        ctx.fill(triangulo, with: .color(oro))
    }

    /// Marco metálico (si lo hay) y palanca. `abierto` va de 0 (cerrado) a 1 (abierto del todo).
    private func cierre(_ ctx: GraphicsContext, _ socket: CGRect, abierto: Double) {
        if plataforma.contactosEnPlaca {
            // El marco gira sobre su borde superior: al abrirse se ve cada vez más estrecho
            var capa = ctx
            capa.opacity = 1 - 0.35 * abierto
            let alto = (socket.height + 12) * (1 - 0.86 * abierto)
            let marco = CGRect(x: socket.minX - 6, y: socket.minY - 6 - CGFloat(abierto) * 12, width: socket.width + 12, height: max(alto, 6))
            capa.stroke(Path(roundedRect: marco, cornerRadius: 9), with: .color(metal), lineWidth: 5)
        }

        // Palanca: gira hacia fuera sobre su extremo inferior
        let eje = CGPoint(x: socket.maxX + 16, y: socket.maxY + 4)
        let largo = socket.height
        let angulo = abierto * 62 * .pi / 180
        let punta = CGPoint(x: eje.x + CGFloat(sin(angulo)) * largo, y: eje.y - CGFloat(cos(angulo)) * largo)
        var palanca = Path()
        palanca.move(to: eje)
        palanca.addLine(to: punta)
        ctx.stroke(palanca, with: .color(metal), style: StrokeStyle(lineWidth: 4, lineCap: .round))
        ctx.fill(Path(ellipseIn: CGRect(x: punta.x - 6, y: punta.y - 6, width: 12, height: 12)), with: .color(acento))
    }

    /// Dibuja el procesador y devuelve el rectángulo que ocupa.
    @discardableResult
    private func procesador(
        _ ctx: GraphicsContext,
        _ socket: CGRect,
        desplazado: CGSize = .zero,
        escala: CGFloat = 1,
        alfa: Double = 1
    ) -> CGRect {
        let ladoChip = socket.width * 0.86 * escala
        let chip = CGRect(
            x: socket.midX - ladoChip / 2 + desplazado.width,
            y: socket.midY - ladoChip / 2 + desplazado.height,
            width: ladoChip,
            height: ladoChip
        )
        var capa = ctx
        capa.opacity = alfa
        capa.fill(Path(roundedRect: chip, cornerRadius: 6), with: .color(Color(red: 0.16, green: 0.36, blue: 0.24)))
        let tapa = chip.insetBy(dx: ladoChip * 0.12, dy: ladoChip * 0.12)
        capa.fill(
            Path(roundedRect: tapa, cornerRadius: 8),
            with: .linearGradient(
                Gradient(colors: [Color(white: 0.90), Color(white: 0.62)]),
                startPoint: CGPoint(x: tapa.minX, y: tapa.minY),
                endPoint: CGPoint(x: tapa.maxX, y: tapa.maxY)
            )
        )
        capa.draw(
            Text("CPU").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color(white: 0.35)),
            at: CGPoint(x: chip.midX, y: chip.midY)
        )
        // Triángulo dorado de orientación
        var triangulo = Path()
        triangulo.move(to: CGPoint(x: chip.minX + 3, y: chip.maxY - 3))
        triangulo.addLine(to: CGPoint(x: chip.minX + 15, y: chip.maxY - 3))
        triangulo.addLine(to: CGPoint(x: chip.minX + 3, y: chip.maxY - 15))
        triangulo.closeSubpath()
        capa.fill(triangulo, with: .color(oro))
        return chip
    }

    private func anillo(_ ctx: GraphicsContext, en punto: CGPoint, radio: CGFloat) {
        let circulo = CGRect(x: punto.x - radio, y: punto.y - radio, width: radio * 2, height: radio * 2)
        ctx.stroke(Path(ellipseIn: circulo), with: .color(acento), lineWidth: 2.5)
    }

    private func gota(_ ctx: GraphicsContext, _ socket: CGRect, tamano: Double) {
        let radio = socket.width * 0.085 * CGFloat(tamano)
        guard radio > 0.5 else { return }
        let circulo = CGRect(x: socket.midX - radio, y: socket.midY - radio, width: radio * 2, height: radio * 2)
        ctx.fill(Path(ellipseIn: circulo), with: .color(Color(white: 0.96)))
        ctx.stroke(Path(ellipseIn: circulo), with: .color(Color(white: 0.55)), lineWidth: 1.5)
    }

    private func disipador(
        _ ctx: GraphicsContext,
        _ socket: CGRect,
        escala: CGFloat,
        alfa: Double,
        giro: Double,
        apretados: Int,
        numerados: Bool
    ) {
        var capa = ctx
        capa.opacity = alfa
        let centro = CGPoint(x: socket.midX, y: socket.midY)
        let radio = socket.width * 0.74 * escala
        let esquinas = anclajes(socket).map {
            CGPoint(x: centro.x + ($0.x - centro.x) * escala, y: centro.y + ($0.y - centro.y) * escala)
        }

        // Brazos del anclaje, hacia los cuatro tornillos
        for esquina in esquinas {
            var brazo = Path()
            brazo.move(to: centro)
            brazo.addLine(to: esquina)
            capa.stroke(brazo, with: .color(Color(white: 0.45)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        }

        let cuerpo = CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)
        capa.fill(Path(ellipseIn: cuerpo), with: .color(Color(white: 0.20)))
        capa.stroke(Path(ellipseIn: cuerpo), with: .color(Color(white: 0.55)), lineWidth: 3)

        // Aspas
        for aspa in 0..<7 {
            let angulo = giro + Double(aspa) * 2 * .pi / 7
            var forma = Path()
            forma.move(to: CGPoint(x: centro.x + CGFloat(cos(angulo)) * radio * 0.24, y: centro.y + CGFloat(sin(angulo)) * radio * 0.24))
            forma.addQuadCurve(
                to: CGPoint(x: centro.x + CGFloat(cos(angulo + 0.75)) * radio * 0.88, y: centro.y + CGFloat(sin(angulo + 0.75)) * radio * 0.88),
                control: CGPoint(x: centro.x + CGFloat(cos(angulo + 0.15)) * radio * 0.80, y: centro.y + CGFloat(sin(angulo + 0.15)) * radio * 0.80)
            )
            forma.addQuadCurve(
                to: CGPoint(x: centro.x + CGFloat(cos(angulo + 0.5)) * radio * 0.24, y: centro.y + CGFloat(sin(angulo + 0.5)) * radio * 0.24),
                control: CGPoint(x: centro.x + CGFloat(cos(angulo + 0.8)) * radio * 0.55, y: centro.y + CGFloat(sin(angulo + 0.8)) * radio * 0.55)
            )
            forma.closeSubpath()
            capa.fill(forma, with: .color(Color(white: 0.42)))
        }
        let eje = CGRect(x: centro.x - radio * 0.22, y: centro.y - radio * 0.22, width: radio * 0.44, height: radio * 0.44)
        capa.fill(Path(ellipseIn: eje), with: .color(Color(white: 0.12)))
        capa.stroke(Path(ellipseIn: eje), with: .color(Color(white: 0.55)), lineWidth: 1.5)

        // Tornillos, en el orden en que se aprietan
        for (orden, esquina) in esquinas.enumerated() {
            let apretado = orden < apretados
            let tornillo = CGRect(x: esquina.x - 10, y: esquina.y - 10, width: 20, height: 20)
            capa.fill(Path(ellipseIn: tornillo), with: .color(apretado ? acento : Color(white: 0.70)))
            capa.stroke(Path(ellipseIn: tornillo), with: .color(.black.opacity(0.4)), lineWidth: 1)
            if numerados {
                capa.draw(
                    Text("\(orden + 1)").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color.black),
                    at: esquina
                )
            }
        }
    }

    /// Cabezal CPU_FAN y el cable que llega a él desde el ventilador.
    private func cable(_ ctx: GraphicsContext, _ socket: CGRect, tam: CGSize, tramo: Double) {
        let cabezal = CGRect(x: tam.width - 96, y: 26, width: 58, height: 18)
        ctx.fill(Path(roundedRect: cabezal, cornerRadius: 4), with: .color(Color(white: 0.88)))
        for pin in 0..<4 {
            let punto = CGRect(x: cabezal.minX + 8 + CGFloat(pin) * 13, y: cabezal.midY - 3, width: 6, height: 6)
            ctx.fill(Path(ellipseIn: punto), with: .color(oro))
        }
        ctx.draw(
            Text("CPU_FAN").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Color.white.opacity(0.85)),
            at: CGPoint(x: cabezal.midX, y: cabezal.maxY + 11)
        )

        let radio = socket.width * 0.74
        let salida = CGPoint(x: socket.midX + radio * 0.72, y: socket.midY - radio * 0.69)
        var ruta = Path()
        ruta.move(to: salida)
        ruta.addCurve(
            to: CGPoint(x: cabezal.midX, y: cabezal.maxY),
            control1: CGPoint(x: salida.x + 36, y: salida.y - 6),
            control2: CGPoint(x: cabezal.midX, y: cabezal.maxY + 46)
        )
        ctx.stroke(
            ruta.trimmedPath(from: 0, to: CGFloat(max(tramo, 0.001))),
            with: .color(oro),
            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
        )
    }
}
