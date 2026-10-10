//
//  GuiasRAMyGPU.swift
//  PcComponentIA
//
//  Guías de montaje de la memoria RAM y de la tarjeta gráfica, con el mismo formato
//  que la del procesador (GuiaPasosView): un dibujo animado por paso.
//

import SwiftUI

// MARK: - Memoria RAM

struct GuiaMontajeRAMView: View {

    private let acento = Color(red: 0.35, green: 0.62, blue: 1.0)

    private var pasos: [PasoGuia] {
        [
            PasoGuia(
                id: 0,
                titulo: L("Elige las ranuras"),
                texto: L("Con dos módulos, usa la segunda y la cuarta ranura contando desde el procesador (A2 y B2). Así trabajan en doble canal. Con cuatro, llénalas todas."),
                aviso: L("El orden puede cambiar en algunas placas: confírmalo en su manual o en la serigrafía.")
            ),
            PasoGuia(
                id: 1,
                titulo: L("Abre las pestañas"),
                texto: L("Empuja hacia fuera las pestañas de los extremos de la ranura. Muchas placas solo tienen una pestaña móvil: el otro extremo es fijo.")
            ),
            PasoGuia(
                id: 2,
                titulo: L("Alinea la muesca"),
                texto: L("El módulo tiene una muesca entre los contactos dorados, y la ranura, un resalte en el mismo sitio. No está en el centro, así que solo entra de una forma."),
                aviso: L("Coge el módulo por los bordes, sin tocar los contactos dorados.")
            ),
            PasoGuia(
                id: 3,
                titulo: L("Presiona hasta oír el clic"),
                texto: L("Apoya el módulo recto y presiona con los pulgares en los dos extremos hasta que las pestañas se cierren solas. Hace falta más fuerza de la que parece."),
                aviso: L("Si un lado no encaja, sácalo y vuelve a empezar: no lo fuerces torcido.")
            ),
            PasoGuia(
                id: 4,
                titulo: L("Comprueba"),
                texto: L("Las pestañas deben estar cerradas y los contactos dorados no deben verse. Cuando arranques, activa el perfil XMP o EXPO en la BIOS para que la memoria vaya a su velocidad.")
            ),
        ]
    }

    var body: some View {
        GuiaPasosView(
            titulo: L("Memoria RAM"),
            pasos: pasos,
            pasosChecklist: ["Instalar módulos de memoria RAM"],
            acento: acento
        ) {
            EmptyView()
        } dibujo: { indice, animado in
            DibujoGuiaView(animado: animado) { ctx, tam, t, segundos in
                DibujosRAM(acento: acento).pintar(ctx, tam: tam, paso: indice, t: t, segundos: segundos)
            }
        }
    }
}

// MARK: - Tarjeta gráfica

struct GuiaMontajeGPUView: View {

    private let acento = Color(red: 0.30, green: 0.82, blue: 0.48)

    private var pasos: [PasoGuia] {
        [
            PasoGuia(
                id: 0,
                titulo: L("Quita las tapas traseras"),
                texto: L("Mira cuántas ranuras ocupa tu gráfica (normalmente dos) y quita de la caja las chapas de esa altura. Guarda los tornillos: los usarás después.")
            ),
            PasoGuia(
                id: 1,
                titulo: L("Abre la pestaña de la ranura"),
                texto: L("Usa la ranura PCIe x16 más cercana al procesador. Al final tiene una pestaña: empújala para abrirla.")
            ),
            PasoGuia(
                id: 2,
                titulo: L("Inserta la gráfica"),
                texto: L("Alinea los contactos dorados con la ranura y el soporte metálico con el hueco trasero. Presiona recta hasta oír el clic de la pestaña."),
                aviso: L("Sujétala por los bordes o por el soporte, no por los ventiladores.")
            ),
            PasoGuia(
                id: 3,
                titulo: L("Atorníllala a la caja"),
                texto: L("Fija el soporte metálico con los tornillos de las chapas. Así el peso no recae solo en la ranura."),
                aviso: L("Si la gráfica es larga y pesada, usa el soporte que suele traer para que no se combe.")
            ),
            PasoGuia(
                id: 4,
                titulo: L("Conecta la alimentación"),
                texto: L("Enchufa los cables PCIe de la fuente (6 + 2 pines) o el de 12 pines, hasta el fondo. Si la gráfica tiene dos conectores, usa a ser posible un cable distinto para cada uno."),
                aviso: L("No uses el cable EPS del procesador: se parece, pero no es compatible.")
            ),
            PasoGuia(
                id: 5,
                titulo: L("El monitor, a la gráfica"),
                texto: L("Conecta el cable del monitor a los puertos de la gráfica, no a los de la placa base. Es el motivo más habitual de que no haya imagen en el primer arranque.")
            ),
        ]
    }

    var body: some View {
        GuiaPasosView(
            titulo: L("Tarjeta gráfica"),
            pasos: pasos,
            pasosChecklist: [
                "Instalar tarjeta gráfica dedicada GPU",
                "Atornillar GPU al chasis",
                "Conectar alimentación PCIe o 12VHPWR a GPU",
            ],
            acento: acento
        ) {
            EmptyView()
        } dibujo: { indice, animado in
            DibujoGuiaView(animado: animado) { ctx, tam, t, segundos in
                DibujosGPU(acento: acento).pintar(ctx, tam: tam, paso: indice, t: t, segundos: segundos)
            }
        }
    }
}

// MARK: - Lienzo animado común

/// Anima de 0 a 1, se queda un momento al final y repite. `segundos` es el tiempo total,
/// para los parpadeos que no dependen del ciclo.
struct DibujoGuiaView: View {
    let animado: Bool
    let pintar: (_ ctx: GraphicsContext, _ tam: CGSize, _ t: Double, _ segundos: Double) -> Void

    @State private var inicio = Date()

    private let duracion = 2.6
    private let pausa = 1.1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animado)) { linea in
            let segundos = linea.date.timeIntervalSince(inicio)
            let ciclo = segundos.truncatingRemainder(dividingBy: duracion + pausa)
            let t = animado ? min(ciclo / duracion, 1) : 1

            Canvas { ctx, tam in
                pintar(ctx, tam, t, animado ? segundos : 0)
            }
        }
        .onAppear { inicio = Date() }
    }
}

private func suave(_ t: Double) -> Double {
    let x = min(max(t, 0), 1)
    return x * x * (3 - 2 * x)
}

private let oroGuia = Color(red: 0.90, green: 0.70, blue: 0.24)
private let metalGuia = Color(white: 0.78)
private let placaGuia = Color(red: 0.09, green: 0.17, blue: 0.20)

private func fondoPlaca(_ ctx: GraphicsContext, _ tam: CGSize) {
    let marco = CGRect(x: 10, y: 10, width: tam.width - 20, height: tam.height - 20)
    ctx.fill(Path(roundedRect: marco, cornerRadius: 16), with: .color(placaGuia))
    ctx.stroke(Path(roundedRect: marco, cornerRadius: 16), with: .color(.white.opacity(0.10)), lineWidth: 1)
}

private func visto(_ ctx: GraphicsContext, _ tam: CGSize, aparece: Double) {
    let radio = 24 * suave(aparece)
    let punto = CGPoint(x: tam.width - 52, y: tam.height - 50)
    ctx.fill(Path(ellipseIn: CGRect(x: punto.x - radio, y: punto.y - radio, width: radio * 2, height: radio * 2)), with: .color(.green))
    if aparece > 0.5 {
        var marca = ctx.resolve(Image(systemName: "checkmark"))
        marca.shading = .color(.white)
        ctx.draw(marca, in: CGRect(x: punto.x - 11, y: punto.y - 11, width: 22, height: 22))
    }
}

private func flechaAbajo(_ ctx: GraphicsContext, en punto: CGPoint, color: Color) {
    var flecha = ctx.resolve(Image(systemName: "arrow.down"))
    flecha.shading = .color(color)
    ctx.draw(flecha, in: CGRect(x: punto.x - 10, y: punto.y - 12, width: 20, height: 24))
}

// MARK: - Dibujos de la RAM

private struct DibujosRAM {
    let acento: Color

    func pintar(_ ctx: GraphicsContext, tam: CGSize, paso: Int, t: Double, segundos: Double) {
        fondoPlaca(ctx, tam)

        guard paso > 0 else {
            ranurasDesdeArriba(ctx, tam, segundos: segundos)
            return
        }

        // Vista de lado: la ranura abajo y el módulo encima
        let ancho = min(tam.width * 0.74, 300)
        let ranura = CGRect(x: tam.width / 2 - ancho / 2, y: tam.height * 0.70, width: ancho, height: 16)
        let muesca = ranura.minX + ancho * 0.56
        let arriba = ranura.minY - 122, asentado = ranura.minY - 74

        switch paso {
        case 1:
            ranuraDeLado(ctx, ranura, muesca: muesca, abierta: suave(t))

        case 2:
            ranuraDeLado(ctx, ranura, muesca: muesca, abierta: 1)
            let desvio = 34 * (1 - suave(t))
            modulo(ctx, ranura, muesca: muesca, y: arriba, desvio: desvio)
            // La muesca y el resalte, marcados
            let pulso = 7 + 4 * (0.5 + 0.5 * sin(segundos * 5))
            anillo(ctx, CGPoint(x: muesca + desvio, y: arriba + 74), pulso)
            anillo(ctx, CGPoint(x: muesca, y: ranura.minY), pulso)

        case 3:
            let bajada = suave(t / 0.7)
            // Las pestañas se cierran solas cuando el módulo llega al fondo
            ranuraDeLado(ctx, ranura, muesca: muesca, abierta: 1 - suave((t - 0.7) / 0.3))
            modulo(ctx, ranura, muesca: muesca, y: arriba + (asentado - arriba) * bajada, desvio: 0)
            if t < 0.7 {
                flechaAbajo(ctx, en: CGPoint(x: ranura.minX + 26, y: arriba - 22 + 10 * bajada), color: acento)
                flechaAbajo(ctx, en: CGPoint(x: ranura.maxX - 26, y: arriba - 22 + 10 * bajada), color: acento)
            } else {
                ctx.draw(
                    Text("clic").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(acento),
                    at: CGPoint(x: ranura.midX, y: arriba - 26)
                )
            }

        default:
            ranuraDeLado(ctx, ranura, muesca: muesca, abierta: 0)
            modulo(ctx, ranura, muesca: muesca, y: asentado, desvio: 0)
            visto(ctx, tam, aparece: t * 1.6)
        }
    }

    private func anillo(_ ctx: GraphicsContext, _ punto: CGPoint, _ radio: CGFloat) {
        let circulo = CGRect(x: punto.x - radio, y: punto.y - radio, width: radio * 2, height: radio * 2)
        ctx.stroke(Path(ellipseIn: circulo), with: .color(acento), lineWidth: 2.5)
    }

    /// Las cuatro ranuras vistas desde arriba, con las dos que hay que usar marcadas.
    private func ranurasDesdeArriba(_ ctx: GraphicsContext, _ tam: CGSize, segundos: Double) {
        let alto = tam.height * 0.62
        let y = tam.height / 2 - alto / 2
        // El procesador, como referencia de por dónde se empieza a contar
        let lado = min(tam.height * 0.34, 90)
        let socket = CGRect(x: tam.width * 0.14, y: tam.height / 2 - lado / 2, width: lado, height: lado)
        ctx.fill(Path(roundedRect: socket, cornerRadius: 6), with: .color(Color(white: 0.20)))
        ctx.stroke(Path(roundedRect: socket, cornerRadius: 6), with: .color(metalGuia), lineWidth: 3)
        ctx.draw(
            Text("CPU").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Color.white.opacity(0.7)),
            at: CGPoint(x: socket.midX, y: socket.midY)
        )

        let nombres = ["A1", "A2", "B1", "B2"]
        let inicio = socket.maxX + tam.width * 0.10
        let paso = min((tam.width - 30 - inicio) / 4, 46)
        let parpadeo = 0.55 + 0.45 * sin(segundos * 3.2)
        for (i, nombre) in nombres.enumerated() {
            let usar = i == 1 || i == 3
            let ranura = CGRect(x: inicio + CGFloat(i) * paso, y: y, width: 14, height: alto)
            ctx.fill(Path(roundedRect: ranura, cornerRadius: 4), with: .color(usar ? acento.opacity(0.35 + 0.45 * parpadeo) : Color(white: 0.16)))
            ctx.stroke(
                Path(roundedRect: ranura, cornerRadius: 4),
                with: .color(usar ? acento : Color.white.opacity(0.35)),
                lineWidth: usar ? 2.5 : 1.5
            )
            ctx.draw(
                Text(nombre)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(usar ? acento : Color.white.opacity(0.55)),
                at: CGPoint(x: ranura.midX, y: ranura.maxY + 14)
            )
        }
    }

    private func ranuraDeLado(_ ctx: GraphicsContext, _ ranura: CGRect, muesca: CGFloat, abierta: Double) {
        ctx.fill(Path(roundedRect: ranura, cornerRadius: 4), with: .color(Color(white: 0.16)))
        ctx.stroke(Path(roundedRect: ranura, cornerRadius: 4), with: .color(.white.opacity(0.4)), lineWidth: 1.5)
        // Resalte que encaja con la muesca del módulo
        ctx.fill(Path(CGRect(x: muesca - 4, y: ranura.minY - 5, width: 8, height: 9)), with: .color(acento))

        // Pestañas: giran hacia fuera sobre su base
        for (base, sentido) in [(CGPoint(x: ranura.minX - 3, y: ranura.maxY), -1.0), (CGPoint(x: ranura.maxX + 3, y: ranura.maxY), 1.0)] {
            let angulo = abierta * 38 * .pi / 180 * sentido
            let punta = CGPoint(x: base.x + CGFloat(sin(angulo)) * 46, y: base.y - CGFloat(cos(angulo)) * 46)
            var pestana = Path()
            pestana.move(to: base)
            pestana.addLine(to: punta)
            ctx.stroke(pestana, with: .color(Color(white: 0.88)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
        }
    }

    private func modulo(_ ctx: GraphicsContext, _ ranura: CGRect, muesca: CGFloat, y: CGFloat, desvio: CGFloat) {
        let cuerpo = CGRect(x: ranura.minX + 12 + desvio, y: y, width: ranura.width - 24, height: 74)
        ctx.fill(Path(roundedRect: cuerpo, cornerRadius: 4), with: .color(Color(red: 0.12, green: 0.34, blue: 0.24)))
        ctx.stroke(Path(roundedRect: cuerpo, cornerRadius: 4), with: .color(.white.opacity(0.35)), lineWidth: 1.5)
        // Chips
        let chips = 6
        let hueco = (cuerpo.width - 24) / CGFloat(chips)
        for i in 0..<chips {
            let chip = CGRect(x: cuerpo.minX + 12 + CGFloat(i) * hueco + 3, y: cuerpo.minY + 12, width: hueco - 6, height: 34)
            ctx.fill(Path(roundedRect: chip, cornerRadius: 2), with: .color(Color(white: 0.10)))
        }
        // Contactos dorados, partidos por la muesca
        let xm = muesca + desvio
        ctx.fill(Path(CGRect(x: cuerpo.minX + 4, y: cuerpo.maxY - 10, width: xm - cuerpo.minX - 9, height: 8)), with: .color(oroGuia))
        ctx.fill(Path(CGRect(x: xm + 5, y: cuerpo.maxY - 10, width: cuerpo.maxX - xm - 9, height: 8)), with: .color(oroGuia))
        ctx.fill(Path(CGRect(x: xm - 5, y: cuerpo.maxY - 12, width: 10, height: 13)), with: .color(placaGuia))
    }
}

// MARK: - Dibujos de la gráfica

private struct DibujosGPU {
    let acento: Color

    func pintar(_ ctx: GraphicsContext, tam: CGSize, paso: Int, t: Double, segundos: Double) {
        guard paso < 5 else {
            puertosTraseros(ctx, tam, t: t, segundos: segundos)
            return
        }

        fondoPlaca(ctx, tam)

        // Vista de lado: la trasera de la caja a la izquierda y la ranura abajo
        let trasera = CGRect(x: 22, y: 26, width: 16, height: tam.height - 52)
        let ranura = CGRect(x: 62, y: tam.height * 0.74, width: tam.width * 0.56, height: 14)
        let tarjeta = CGRect(x: 44, y: ranura.minY - 96, width: tam.width * 0.70, height: 92)

        switch paso {
        case 0:
            traseraCaja(ctx, trasera, ranura, quitadas: suave(t))
            ranuraPCIe(ctx, ranura, abierta: 0)

        case 1:
            traseraCaja(ctx, trasera, ranura, quitadas: 1)
            ranuraPCIe(ctx, ranura, abierta: suave(t))

        case 2:
            traseraCaja(ctx, trasera, ranura, quitadas: 1)
            let bajada = suave(t / 0.75)
            ranuraPCIe(ctx, ranura, abierta: 1 - suave((t - 0.75) / 0.25))
            grafica(ctx, tarjeta.offsetBy(dx: 0, dy: -64 * (1 - bajada)), tornillos: 0)
            if t < 0.75 {
                flechaAbajo(ctx, en: CGPoint(x: tarjeta.maxX + 22, y: tarjeta.midY - 44 + 16 * bajada), color: acento)
            }

        case 3:
            traseraCaja(ctx, trasera, ranura, quitadas: 1)
            ranuraPCIe(ctx, ranura, abierta: 0)
            grafica(ctx, tarjeta, tornillos: t < 0.5 ? 1 : 2, giro: segundos * 6)

        default:
            traseraCaja(ctx, trasera, ranura, quitadas: 1)
            ranuraPCIe(ctx, ranura, abierta: 0)
            grafica(ctx, tarjeta, tornillos: 2)
            // Cable de la fuente hasta el conector de arriba de la gráfica
            let conector = CGPoint(x: tarjeta.maxX - 54, y: tarjeta.minY - 8)
            var cable = Path()
            cable.move(to: CGPoint(x: tam.width - 12, y: 34))
            cable.addCurve(
                to: conector,
                control1: CGPoint(x: tam.width - 70, y: 30),
                control2: CGPoint(x: conector.x, y: conector.y - 50)
            )
            ctx.stroke(
                cable.trimmedPath(from: 0, to: CGFloat(max(suave(t), 0.001))),
                with: .color(oroGuia),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
        }
    }

    /// Chapa trasera de la caja, con las tapas de cada ranura; las dos de la gráfica se retiran.
    private func traseraCaja(_ ctx: GraphicsContext, _ trasera: CGRect, _ ranura: CGRect, quitadas: Double) {
        ctx.fill(Path(roundedRect: trasera, cornerRadius: 3), with: .color(Color(white: 0.30)))
        let alto: CGFloat = 26
        for i in 0..<5 {
            let y = ranura.minY - 96 + CGFloat(i - 1) * (alto + 6)
            guard y > trasera.minY, y + alto < trasera.maxY else { continue }
            let esDeLaGrafica = i == 1 || i == 2
            var capa = ctx
            var tapa = CGRect(x: trasera.minX + 2, y: y, width: trasera.width - 4, height: alto)
            if esDeLaGrafica {
                capa.opacity = 1 - quitadas
                tapa = tapa.offsetBy(dx: -22 * CGFloat(quitadas), dy: 0)
            }
            capa.fill(Path(roundedRect: tapa, cornerRadius: 2), with: .color(esDeLaGrafica ? acento : metalGuia))
        }
    }

    private func ranuraPCIe(_ ctx: GraphicsContext, _ ranura: CGRect, abierta: Double) {
        ctx.fill(Path(roundedRect: ranura, cornerRadius: 3), with: .color(Color(white: 0.16)))
        ctx.stroke(Path(roundedRect: ranura, cornerRadius: 3), with: .color(.white.opacity(0.4)), lineWidth: 1.5)
        // Pestaña del final de la ranura
        let base = CGPoint(x: ranura.maxX + 4, y: ranura.maxY)
        let angulo = abierta * 48 * .pi / 180
        let punta = CGPoint(x: base.x + CGFloat(sin(angulo)) * 26, y: base.y - CGFloat(cos(angulo)) * 26)
        var pestana = Path()
        pestana.move(to: base)
        pestana.addLine(to: punta)
        ctx.stroke(pestana, with: .color(acento), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    }

    private func grafica(_ ctx: GraphicsContext, _ tarjeta: CGRect, tornillos: Int, giro: Double = 0) {
        // Soporte metálico, pegado a la trasera de la caja
        let soporte = CGRect(x: tarjeta.minX - 6, y: tarjeta.minY - 14, width: 7, height: tarjeta.height + 18)
        ctx.fill(Path(roundedRect: soporte, cornerRadius: 2), with: .color(metalGuia))

        ctx.fill(Path(roundedRect: tarjeta, cornerRadius: 8), with: .color(Color(white: 0.17)))
        ctx.stroke(Path(roundedRect: tarjeta, cornerRadius: 8), with: .color(Color(white: 0.55)), lineWidth: 2)

        // Ventiladores
        let radio = tarjeta.height * 0.36
        for centroX in [tarjeta.minX + tarjeta.width * 0.30, tarjeta.minX + tarjeta.width * 0.70] {
            let centro = CGPoint(x: centroX, y: tarjeta.midY - 4)
            let circulo = CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2)
            ctx.stroke(Path(ellipseIn: circulo), with: .color(Color(white: 0.5)), lineWidth: 2)
            ctx.fill(Path(ellipseIn: circulo.insetBy(dx: radio * 0.72, dy: radio * 0.72)), with: .color(Color(white: 0.5)))
        }

        // Conector de alimentación, arriba
        let conector = CGRect(x: tarjeta.maxX - 70, y: tarjeta.minY - 8, width: 32, height: 9)
        ctx.fill(Path(roundedRect: conector, cornerRadius: 2), with: .color(Color(white: 0.75)))

        // Contactos dorados, abajo
        let contactos = CGRect(x: tarjeta.minX + 20, y: tarjeta.maxY, width: tarjeta.width * 0.72, height: 9)
        ctx.fill(Path(contactos), with: .color(oroGuia))

        // Tornillos del soporte
        for i in 0..<tornillos {
            let centro = CGPoint(x: soporte.midX, y: soporte.minY + 8 + CGFloat(i) * 30)
            let tornillo = CGRect(x: centro.x - 8, y: centro.y - 8, width: 16, height: 16)
            ctx.fill(Path(ellipseIn: tornillo), with: .color(acento))
            // La ranura de la cabeza, girando mientras se aprieta
            let ultimo = i == tornillos - 1
            let angulo = ultimo ? giro : 0.6
            var cabeza = Path()
            cabeza.move(to: CGPoint(x: centro.x - CGFloat(cos(angulo)) * 5, y: centro.y - CGFloat(sin(angulo)) * 5))
            cabeza.addLine(to: CGPoint(x: centro.x + CGFloat(cos(angulo)) * 5, y: centro.y + CGFloat(sin(angulo)) * 5))
            ctx.stroke(cabeza, with: .color(.black.opacity(0.7)), lineWidth: 2)
        }
    }

    /// Trasera del PC: arriba los puertos de la placa (no) y abajo los de la gráfica (sí).
    private func puertosTraseros(_ ctx: GraphicsContext, _ tam: CGSize, t: Double, segundos: Double) {
        let chapa = CGRect(x: tam.width * 0.30, y: 16, width: tam.width * 0.40, height: tam.height - 32)
        ctx.fill(Path(roundedRect: chapa, cornerRadius: 10), with: .color(Color(white: 0.26)))

        // Puertos de la placa base
        let placa = CGRect(x: chapa.minX + 14, y: chapa.minY + 16, width: chapa.width - 28, height: 76)
        ctx.fill(Path(roundedRect: placa, cornerRadius: 6), with: .color(Color(white: 0.14)))
        for i in 0..<2 {
            let puerto = CGRect(x: placa.minX + 12, y: placa.minY + 14 + CGFloat(i) * 28, width: placa.width - 24, height: 16)
            ctx.fill(Path(roundedRect: puerto, cornerRadius: 3), with: .color(Color(white: 0.40)))
        }
        var no = ctx.resolve(Image(systemName: "xmark.circle.fill"))
        no.shading = .color(.red)
        ctx.draw(no, in: CGRect(x: placa.maxX - 16, y: placa.minY - 12, width: 28, height: 28))

        // Puertos de la gráfica
        let grafica = CGRect(x: chapa.minX + 14, y: chapa.maxY - 86, width: chapa.width - 28, height: 66)
        ctx.fill(Path(roundedRect: grafica, cornerRadius: 6), with: .color(Color(white: 0.14)))
        ctx.stroke(Path(roundedRect: grafica, cornerRadius: 6), with: .color(acento.opacity(0.5 + 0.5 * sin(segundos * 3.2))), lineWidth: 3)
        let destino = CGRect(x: grafica.minX + 12, y: grafica.minY + 12, width: grafica.width - 24, height: 16)
        for i in 0..<2 {
            ctx.fill(Path(roundedRect: destino.offsetBy(dx: 0, dy: CGFloat(i) * 26), cornerRadius: 3), with: .color(acento))
        }

        // El cable del monitor, que llega desde la izquierda
        let avance = suave(t)
        let punta = CGPoint(x: destino.minX - 150 * (1 - avance) - 6, y: destino.midY)
        var cable = Path()
        cable.move(to: CGPoint(x: 0, y: punta.y + 26))
        cable.addQuadCurve(to: CGPoint(x: punta.x - 22, y: punta.y), control: CGPoint(x: punta.x - 70, y: punta.y + 30))
        ctx.stroke(cable, with: .color(Color(white: 0.7)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        ctx.fill(Path(roundedRect: CGRect(x: punta.x - 24, y: punta.y - 9, width: 26, height: 18), cornerRadius: 3), with: .color(Color(white: 0.85)))

        if avance > 0.95 {
            visto(ctx, tam, aparece: 1)
        }
    }
}
