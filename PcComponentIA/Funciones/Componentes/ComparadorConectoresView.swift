//
//  ComparadorConectoresView.swift
//  PcComponentIA
//
//  «¿Cuál es cuál?»: conectores que se confunden, con un dibujo de su forma y el rasgo
//  que los distingue. Los dibujos son vectoriales (sin fotos ni licencias) y también
//  se usan en las burbujas del visor 3D.
//

import SwiftUI

// MARK: - Datos

/// Forma simplificada de un conector, lo justo para reconocerlo.
enum SiluetaConector {
    case hdmi
    case displayPort
    case usbA(rapido: Bool)
    case usbC
    /// Conector de alimentación de dos filas; `corte` es la columna tras la que se separa (0 = entero).
    case pines(columnas: Int, corte: Int)
    /// Cabezal de una fila en la placa; `hueco` es la posición sin pin.
    case cabezal(pines: Int, hueco: Int?)
    /// Ranura de expansión; `largo` de 0 a 1 respecto a una x16.
    case ranura(largo: CGFloat)
    /// Conector SATA en L; `ancho` de 0 a 1.
    case sata(ancho: CGFloat)
    /// Módulo de RAM; `muesca` de 0 a 1 a lo largo de los contactos.
    case modulo(muesca: CGFloat)
    /// SSD M.2; `muescas` de 0 a 1 a lo largo del borde con contactos.
    case m2(muescas: [CGFloat])
    /// Ranura M.2 de la placa, con el hueco del SSD y su tornillo.
    case ranuraM2
    /// Socket del procesador: con contactos en la placa (LGA, AM5) o solo agujeros (AM4).
    case socket(pinesEnPlaca: Bool, alargado: Bool)
    /// Placa base a escala; `ancho` y `alto` de 0 a 1 respecto a una ATX.
    case placa(ancho: CGFloat, alto: CGFloat)
    case molex
}

struct ConectorComparado: Identifiable {
    let id = UUID()
    let nombre: String
    let rasgo: String
    let silueta: SiluetaConector
    var claveFicha: String? = nil
}

struct GrupoComparado: Identifiable {
    let id = UUID()
    let titulo: String
    /// Cómo distinguirlos de un vistazo.
    let truco: String
    /// Riesgo real si se confunden.
    var aviso: String? = nil
    let conectores: [ConectorComparado]
}

enum ComparadorConectores {
    static var grupos: [GrupoComparado] {
        [
            GrupoComparado(
                titulo: L("HDMI o DisplayPort"),
                truco: L("Mira las esquinas: HDMI tiene las dos de abajo recortadas; DisplayPort, solo una."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: "HDMI", rasgo: L("Dos esquinas recortadas. Es el de las teles y casi todos los monitores."), silueta: .hdmi, claveFicha: "Puerto_HDMI"),
                    ConectorComparado(nombre: "DisplayPort", rasgo: L("Una sola esquina recortada. Muchos cables llevan un botón para soltarlos."), silueta: .displayPort, claveFicha: "Puerto_DisplayPort")
                ]
            ),
            GrupoComparado(
                titulo: L("USB-A y USB-C"),
                truco: L("En los USB-A, el color de la lengüeta de dentro suele indicar la velocidad."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: "USB-A 2.0", rasgo: L("Rectangular, con la lengüeta negra o blanca. Para teclado y ratón."), silueta: .usbA(rapido: false), claveFicha: "Puerto_USB_A"),
                    ConectorComparado(nombre: "USB-A 3.x", rasgo: L("Igual, pero con la lengüeta azul (a veces roja o turquesa). Más rápido."), silueta: .usbA(rapido: true), claveFicha: "Puerto_USB_A"),
                    ConectorComparado(nombre: "USB-C", rasgo: L("Pequeño, ovalado y entra en las dos posiciones."), silueta: .usbC, claveFicha: "Puerto_USB_C")
                ]
            ),
            GrupoComparado(
                titulo: L("EPS de la CPU o PCIe de la gráfica"),
                truco: L("Los dos tienen 8 pines y se parecen mucho. Fíjate en cómo se parte el conector y en lo que pone el cable."),
                aviso: L("No son intercambiables: no los fuerces. Enchufar uno en el lugar del otro puede dañar la placa o la gráfica."),
                conectores: [
                    ConectorComparado(nombre: L("EPS 8 pines (CPU)"), rasgo: L("Se separa en 4 + 4. El cable suele poner «CPU». Va arriba a la izquierda de la placa."), silueta: .pines(columnas: 4, corte: 2), claveFicha: "Conector_EPS_8p"),
                    ConectorComparado(nombre: L("PCIe 8 pines"), rasgo: L("Se separa en 6 + 2. El cable suele poner «PCI-E» o «VGA». Va a la gráfica."), silueta: .pines(columnas: 4, corte: 3), claveFicha: "Cable_PCIe_GPU")
                ]
            ),
            GrupoComparado(
                titulo: L("RGB de 12 V o ARGB de 5 V"),
                truco: L("Cuenta los pines del cabezal de la placa."),
                aviso: L("Nunca conectes una tira ARGB de 5 V a un cabezal RGB de 12 V: se quema."),
                conectores: [
                    ConectorComparado(nombre: L("RGB 12 V"), rasgo: L("Cuatro pines seguidos. Toda la tira se ilumina del mismo color."), silueta: .cabezal(pines: 4, hueco: nil), claveFicha: "Conector_RGB_12V"),
                    ConectorComparado(nombre: L("ARGB 5 V"), rasgo: L("Tres pines y un hueco entre ellos. Cada LED puede tener un color distinto."), silueta: .cabezal(pines: 4, hueco: 2), claveFicha: "Conector_ARGB_5V")
                ]
            ),
            GrupoComparado(
                titulo: L("Ranuras PCIe"),
                truco: L("Se distinguen por la longitud. Una tarjeta corta también funciona en una ranura más larga."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: "PCIe x1", rasgo: L("La más corta, de unos 2,5 cm. Tarjetas de red, sonido o capturadoras."), silueta: .ranura(largo: 0.28), claveFicha: "Ranura_PCIe_x1"),
                    ConectorComparado(nombre: "PCIe x4", rasgo: L("Algo menos de 4 cm. SSD en tarjeta y adaptadores."), silueta: .ranura(largo: 0.44), claveFicha: nil),
                    ConectorComparado(nombre: "PCIe x16", rasgo: L("La más larga, de unos 9 cm. Para la tarjeta gráfica."), silueta: .ranura(largo: 1), claveFicha: "Ranura_PCIe_x16")
                ]
            ),
            GrupoComparado(
                titulo: L("SATA de datos o de alimentación"),
                truco: L("Los dos tienen forma de L; el de alimentación es el doble de ancho."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: L("SATA de datos"), rasgo: L("Estrecho, 7 contactos. Va del disco a la placa base."), silueta: .sata(ancho: 0.42), claveFicha: "Cable_Datos_SATA"),
                    ConectorComparado(nombre: L("SATA de alimentación"), rasgo: L("Ancho, 15 contactos. Viene de la fuente."), silueta: .sata(ancho: 0.9), claveFicha: "Cable_Alimentacion_SATA")
                ]
            ),
            GrupoComparado(
                titulo: L("DDR4 o DDR5"),
                truco: L("Miden lo mismo, pero la muesca de los contactos está en otro sitio, así que no entran en la ranura equivocada."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: "DDR4", rasgo: L("Muesca algo desplazada del centro. Mira también la etiqueta del módulo."), silueta: .modulo(muesca: 0.56), claveFicha: "Modulo_RAM"),
                    ConectorComparado(nombre: "DDR5", rasgo: L("Muesca casi en el centro. No vale para placas DDR4."), silueta: .modulo(muesca: 0.51), claveFicha: "Modulo_RAM")
                ]
            ),
            GrupoComparado(
                titulo: L("M.2: la ranura y los dos tipos de SSD"),
                truco: L("La ranura es pequeña y va tumbada sobre la placa. En el SSD, mira las muescas del borde con contactos dorados."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: L("Ranura M.2"), rasgo: L("El SSD entra inclinado por un extremo y se atornilla por el otro."), silueta: .ranuraM2, claveFicha: "Ranura_M2"),
                    ConectorComparado(nombre: "M.2 NVMe", rasgo: L("Una muesca (llave M). Es el más rápido."), silueta: .m2(muescas: [0.72]), claveFicha: "M2_SSD_NVMe"),
                    ConectorComparado(nombre: "M.2 SATA", rasgo: L("Dos muescas (llaves B y M). Solo funciona en ranuras M.2 que admitan SATA."), silueta: .m2(muescas: [0.28, 0.72]), claveFicha: "M2_SSD_SATA")
                ]
            ),
            GrupoComparado(
                titulo: L("Sockets de Intel y AMD"),
                truco: L("El socket de la placa y el del procesador tienen que ser exactamente el mismo: ni siquiera dos LGA distintos son compatibles entre sí."),
                aviso: L("El nombre del socket (LGA1700, AM5…) viene en la caja de la placa y en la del procesador. Compruébalo antes de comprar."),
                conectores: [
                    ConectorComparado(nombre: "LGA1151", rasgo: L("Intel Core de 6.ª a 9.ª generación. Las de 8.ª y 9.ª necesitan una placa de la serie 300."), silueta: .socket(pinesEnPlaca: true, alargado: false), claveFicha: "Socket_Intel"),
                    ConectorComparado(nombre: "LGA1200", rasgo: L("Intel Core de 10.ª y 11.ª generación."), silueta: .socket(pinesEnPlaca: true, alargado: false), claveFicha: "Socket_Intel"),
                    ConectorComparado(nombre: "LGA1700", rasgo: L("Intel Core de 12.ª a 14.ª generación. Es más alargado y usa otro anclaje de disipador."), silueta: .socket(pinesEnPlaca: true, alargado: true), claveFicha: "Socket_Intel"),
                    ConectorComparado(nombre: "LGA1851", rasgo: L("Intel Core Ultra serie 200. Mismo anclaje de disipador que LGA1700."), silueta: .socket(pinesEnPlaca: true, alargado: true), claveFicha: "Socket_Intel"),
                    ConectorComparado(nombre: "AM4", rasgo: L("AMD Ryzen 1000 a 5000. Los pines van en el procesador y el socket solo tiene agujeros."), silueta: .socket(pinesEnPlaca: false, alargado: false), claveFicha: "Socket_AMD"),
                    ConectorComparado(nombre: "AM5", rasgo: L("AMD Ryzen 7000 en adelante. Pines en la placa, como en Intel. Solo admite DDR5."), silueta: .socket(pinesEnPlaca: true, alargado: false), claveFicha: "Socket_AMD")
                ]
            ),
            GrupoComparado(
                titulo: L("Tamaños de placa base"),
                truco: L("Una placa pequeña cabe en una caja grande, pero no al revés. La línea de puntos es el tamaño ATX."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: "ATX", rasgo: L("30,5 × 24,4 cm. La más habitual; hasta 7 ranuras de expansión."), silueta: .placa(ancho: 1, alto: 1), claveFicha: "Placa_Base"),
                    ConectorComparado(nombre: "Micro-ATX", rasgo: L("24,4 × 24,4 cm. Más corta; hasta 4 ranuras de expansión."), silueta: .placa(ancho: 1, alto: 0.8), claveFicha: "Placa_Base"),
                    ConectorComparado(nombre: "Mini-ITX", rasgo: L("17 × 17 cm. Para equipos compactos: una ranura de expansión y dos de RAM."), silueta: .placa(ancho: 0.7, alto: 0.56), claveFicha: "Placa_Base")
                ]
            ),
            GrupoComparado(
                titulo: L("Ventiladores de 3 y 4 pines"),
                truco: L("Un ventilador de 3 pines funciona en un cabezal de 4, y al revés: la guía de plástico solo deja ponerlo de una forma."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: L("3 pines (DC)"), rasgo: L("La placa regula la velocidad cambiando el voltaje. Es menos preciso."), silueta: .cabezal(pines: 3, hueco: nil), claveFicha: "Ventilador_Caja"),
                    ConectorComparado(nombre: L("4 pines (PWM)"), rasgo: L("El cuarto pin controla la velocidad con precisión. Es lo habitual hoy."), silueta: .cabezal(pines: 4, hueco: nil), claveFicha: "Conector_FAN"),
                    ConectorComparado(nombre: "CPU_FAN · SYS_FAN · AIO_PUMP", rasgo: L("Mismo conector, distinto uso: el disipador va en CPU_FAN; los ventiladores de la caja, en SYS_FAN; la bomba de una líquida, en AIO_PUMP."), silueta: .cabezal(pines: 4, hueco: nil), claveFicha: "Conector_SYS_FAN")
                ]
            ),
            GrupoComparado(
                titulo: L("Cables de la fuente"),
                truco: L("Cada cable solo entra en su sitio y en una posición. Si no entra con una presión suave, no es el suyo."),
                aviso: nil,
                conectores: [
                    ConectorComparado(nombre: L("ATX 24 pines"), rasgo: L("El más grande. Alimenta la placa base."), silueta: .pines(columnas: 12, corte: 0), claveFicha: "Conector_ATX_24p"),
                    ConectorComparado(nombre: L("EPS 8 pines (CPU)"), rasgo: L("Se separa en 4 + 4. Alimenta el procesador."), silueta: .pines(columnas: 4, corte: 2), claveFicha: "Conector_EPS_8p"),
                    ConectorComparado(nombre: L("PCIe 8 pines"), rasgo: L("Se separa en 6 + 2. Alimenta la tarjeta gráfica."), silueta: .pines(columnas: 4, corte: 3), claveFicha: "Cable_PCIe_GPU"),
                    ConectorComparado(nombre: "12VHPWR / 12V-2x6", rasgo: L("Compacto, de 12 pines más 4 pequeños. En gráficas modernas; debe entrar hasta el fondo."), silueta: .pines(columnas: 6, corte: 0), claveFicha: "Conector_12VHPWR"),
                    ConectorComparado(nombre: L("SATA de alimentación"), rasgo: L("Plano y en forma de L. Para discos duros y SSD de 2,5 pulgadas."), silueta: .sata(ancho: 0.9), claveFicha: "Cable_Alimentacion_SATA"),
                    ConectorComparado(nombre: "Molex", rasgo: L("Cuatro pines gruesos. Es antiguo, pero aún lo usan algunos ventiladores y accesorios."), silueta: .molex, claveFicha: "Cable_Molex")
                ]
            )
        ]
    }
}

// MARK: - Vista

struct ComparadorConectoresView: View {

    @Environment(\.colorScheme) private var colorScheme

    private let grupos = ComparadorConectores.grupos
    private let diccionario = DatosHardware.obtenerDiccionario()
    private let acento = Color(red: 0.49, green: 0.27, blue: 0.93)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                Text(L("Conectores que se parecen y cómo distinguirlos de un vistazo."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(grupos) { grupo in
                    tarjeta(grupo)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L("¿Cuál es cuál?"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func tarjeta(_ grupo: GrupoComparado) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(grupo.titulo)
                    .font(.title3.bold())
                Text(grupo.truco)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Lado a lado si caben; uno debajo de otro con letra grande o en pantallas estrechas
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .top)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(grupo.conectores) { conector in
                    celda(conector)
                }
            }

            if let aviso = grupo.aviso {
                Label {
                    Text(aviso)
                        .font(.footnote.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .foregroundStyle(.orange)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.orange.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
        }
        .padding(18)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    @ViewBuilder
    private func celda(_ conector: ConectorComparado) -> some View {
        if let clave = conector.claveFicha, let info = diccionario[clave] {
            NavigationLink {
                DetalleComponenteInfoView(nombre: clave, info: info)
            } label: {
                contenidoCelda(conector, conFicha: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(L("Ver ficha"))
        } else {
            contenidoCelda(conector, conFicha: false)
        }
    }

    private func contenidoCelda(_ conector: ConectorComparado, conFicha: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            SiluetaConectorView(silueta: conector.silueta, acento: acento)
                .frame(height: 86)
                .frame(maxWidth: .infinity)
                .background(
                    acento.opacity(colorScheme == .dark ? 0.14 : 0.07),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text(conector.nombre)
                    .font(.subheadline.bold())
                if conFicha {
                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                }
            }

            Text(conector.rasgo)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Dibujo

struct SiluetaConectorView: View {
    let silueta: SiluetaConector
    let acento: Color

    var body: some View {
        Canvas { ctx, tam in
            let linea = GraphicsContext.Shading.color(.primary)
            let relleno = GraphicsContext.Shading.color(.primary.opacity(0.14))
            let oro = GraphicsContext.Shading.color(Color(red: 0.85, green: 0.66, blue: 0.22))
            let trazo = StrokeStyle(lineWidth: 2.5, lineJoin: .round)
            let discontinuo = StrokeStyle(lineWidth: 1.5, dash: [4, 3])
            let cx = tam.width / 2, cy = tam.height / 2

            switch silueta {
            case .hdmi, .displayPort:
                let w = min(tam.width * 0.62, 120), h = w * 0.36
                let x0 = cx - w / 2, x1 = cx + w / 2, y0 = cy - h / 2, y1 = cy + h / 2
                var p = Path()
                if case .hdmi = silueta {
                    p.move(to: CGPoint(x: x0, y: y0))
                    p.addLine(to: CGPoint(x: x1, y: y0))
                    p.addLine(to: CGPoint(x: x1, y: y0 + h * 0.5))
                    p.addLine(to: CGPoint(x: x1 - w * 0.13, y: y1))
                    p.addLine(to: CGPoint(x: x0 + w * 0.13, y: y1))
                    p.addLine(to: CGPoint(x: x0, y: y0 + h * 0.5))
                } else {
                    p.move(to: CGPoint(x: x0, y: y0))
                    p.addLine(to: CGPoint(x: x1, y: y0))
                    p.addLine(to: CGPoint(x: x1, y: y1))
                    p.addLine(to: CGPoint(x: x0 + w * 0.16, y: y1))
                    p.addLine(to: CGPoint(x: x0, y: y1 - h * 0.42))
                }
                p.closeSubpath()
                ctx.fill(p, with: relleno)
                ctx.stroke(p, with: linea, style: trazo)
                let barra = CGRect(x: cx - w * 0.3, y: cy - h * 0.1, width: w * 0.6, height: h * 0.2)
                ctx.fill(Path(roundedRect: barra, cornerRadius: 2), with: oro)

            case .usbA(let rapido):
                let w = min(tam.width * 0.5, 96), h = w * 0.42
                let marco = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: marco, cornerRadius: 3), with: relleno)
                ctx.stroke(Path(roundedRect: marco, cornerRadius: 3), with: linea, style: trazo)
                let lengueta = CGRect(x: marco.minX + 6, y: marco.minY + 6, width: w - 12, height: h * 0.36)
                ctx.fill(
                    Path(roundedRect: lengueta, cornerRadius: 2),
                    with: .color(rapido ? Color(red: 0.10, green: 0.45, blue: 0.95) : Color.primary.opacity(0.75))
                )

            case .usbC:
                let w = min(tam.width * 0.4, 78), h = w * 0.34
                let marco = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: marco, cornerRadius: h / 2), with: relleno)
                ctx.stroke(Path(roundedRect: marco, cornerRadius: h / 2), with: linea, style: trazo)
                let centro = CGRect(x: cx - w * 0.3, y: cy - h * 0.1, width: w * 0.6, height: h * 0.2)
                ctx.fill(Path(roundedRect: centro, cornerRadius: h * 0.1), with: oro)

            case .pines(let columnas, let corte):
                let separacion: CGFloat = corte > 0 ? 12 : 0
                let hueco: CGFloat = columnas > 6 ? 2 : 4
                // Con muchas columnas (ATX de 24) los pines se encogen para caber
                let lado = min(17, (tam.width * 0.9 - separacion) / CGFloat(columnas) - hueco)
                let ancho = CGFloat(columnas) * lado + CGFloat(columnas - 1) * hueco + separacion
                var x = cx - ancho / 2
                for columna in 0..<columnas {
                    for fila in 0..<2 {
                        let pin = CGRect(
                            x: x,
                            y: cy - lado - hueco / 2 + CGFloat(fila) * (lado + hueco),
                            width: lado,
                            height: lado
                        )
                        // Alterna pin cuadrado y pin redondeado, como en los conectores reales
                        let radio: CGFloat = (columna + fila).isMultiple(of: 2) ? 2 : lado * 0.35
                        ctx.fill(Path(roundedRect: pin, cornerRadius: radio), with: relleno)
                        ctx.stroke(Path(roundedRect: pin, cornerRadius: radio), with: linea, style: StrokeStyle(lineWidth: lado < 12 ? 1.5 : 2.5))
                    }
                    x += lado + hueco + (columna + 1 == corte ? separacion : 0)
                }

            case .cabezal(let pines, let hueco):
                let paso: CGFloat = 22, radio: CGFloat = 6
                let inicio = cx - CGFloat(pines - 1) * paso / 2
                let base = CGRect(x: inicio - 14, y: cy - 13, width: CGFloat(pines - 1) * paso + 28, height: 26)
                ctx.fill(Path(roundedRect: base, cornerRadius: 5), with: relleno)
                ctx.stroke(Path(roundedRect: base, cornerRadius: 5), with: linea, style: trazo)
                for i in 0..<pines {
                    let circulo = Path(ellipseIn: CGRect(
                        x: inicio + CGFloat(i) * paso - radio,
                        y: cy - radio,
                        width: radio * 2,
                        height: radio * 2
                    ))
                    if i + 1 == hueco {
                        ctx.stroke(circulo, with: .color(.primary.opacity(0.3)), style: discontinuo)
                    } else {
                        ctx.fill(circulo, with: oro)
                    }
                }

            case .ranura(let largo):
                let total = min(tam.width * 0.82, 170)
                let w = total * largo, h: CGFloat = 16
                let marco = CGRect(x: cx - total / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: marco, cornerRadius: 3), with: relleno)
                ctx.stroke(Path(roundedRect: marco, cornerRadius: 3), with: linea, style: trazo)
                let contactos = CGRect(x: marco.minX + 5, y: cy - 2, width: max(w - 10, 2), height: 4)
                ctx.fill(Path(roundedRect: contactos, cornerRadius: 2), with: oro)

            case .sata(let ancho):
                let total = min(tam.width * 0.7, 140)
                let w = total * ancho, grosor: CGFloat = 12, alto: CGFloat = 30
                let x0 = cx - w / 2, y0 = cy - alto / 2
                var p = Path()
                p.move(to: CGPoint(x: x0, y: y0))
                p.addLine(to: CGPoint(x: x0 + grosor, y: y0))
                p.addLine(to: CGPoint(x: x0 + grosor, y: y0 + alto - grosor))
                p.addLine(to: CGPoint(x: x0 + w, y: y0 + alto - grosor))
                p.addLine(to: CGPoint(x: x0 + w, y: y0 + alto))
                p.addLine(to: CGPoint(x: x0, y: y0 + alto))
                p.closeSubpath()
                ctx.fill(p, with: relleno)
                ctx.stroke(p, with: linea, style: trazo)

            case .modulo(let muesca):
                let w = min(tam.width * 0.84, 170), h: CGFloat = 40
                let placa = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: placa, cornerRadius: 3), with: relleno)
                ctx.stroke(Path(roundedRect: placa, cornerRadius: 3), with: linea, style: trazo)
                let xm = placa.minX + w * muesca
                ctx.fill(Path(CGRect(x: placa.minX + 4, y: placa.maxY - 9, width: xm - placa.minX - 8, height: 6)), with: oro)
                ctx.fill(Path(CGRect(x: xm + 4, y: placa.maxY - 9, width: placa.maxX - xm - 8, height: 6)), with: oro)
                // La muesca, en color para que se vea la diferencia
                ctx.fill(Path(CGRect(x: xm - 3, y: placa.maxY - 12, width: 6, height: 14)), with: .color(acento))
                // Referencia del centro del módulo
                var eje = Path()
                eje.move(to: CGPoint(x: cx, y: placa.minY + 5))
                eje.addLine(to: CGPoint(x: cx, y: placa.maxY - 14))
                ctx.stroke(eje, with: .color(.primary.opacity(0.3)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            case .m2(let muescas):
                let w = min(tam.width * 0.8, 160), h: CGFloat = 34
                let placa = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: placa, cornerRadius: 3), with: relleno)
                ctx.stroke(Path(roundedRect: placa, cornerRadius: 3), with: linea, style: trazo)
                ctx.fill(Path(CGRect(x: placa.minX + 2, y: placa.minY + 3, width: 9, height: h - 6)), with: oro)
                for muesca in muescas {
                    let corte = CGRect(x: placa.minX - 2, y: placa.minY + h * muesca - 3, width: 15, height: 6)
                    ctx.fill(Path(corte), with: .color(acento))
                }

            case .ranuraM2:
                let w = min(tam.width * 0.8, 160), h: CGFloat = 34
                let x0 = cx - w / 2
                // La ranura: pequeña, en un extremo
                let ranura = CGRect(x: x0, y: cy - h / 2 - 3, width: 20, height: h + 6)
                ctx.fill(Path(roundedRect: ranura, cornerRadius: 3), with: relleno)
                ctx.stroke(Path(roundedRect: ranura, cornerRadius: 3), with: linea, style: trazo)
                ctx.fill(Path(CGRect(x: x0 + 12, y: cy - h / 2 + 3, width: 4, height: h - 6)), with: oro)
                // Dónde queda el SSD, en línea discontinua
                let ssd = CGRect(x: x0 + 20, y: cy - h / 2, width: w - 32, height: h)
                ctx.stroke(Path(roundedRect: ssd, cornerRadius: 3), with: .color(.primary.opacity(0.4)), style: discontinuo)
                // El tornillo del otro extremo
                let tornillo = Path(ellipseIn: CGRect(x: x0 + w - 14, y: cy - 7, width: 14, height: 14))
                ctx.fill(tornillo, with: .color(acento))

            case .socket(let pinesEnPlaca, let alargado):
                let h = min(tam.height * 0.74, 64), w = alargado ? h * 0.84 : h
                let marco = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
                ctx.fill(Path(roundedRect: marco, cornerRadius: 4), with: relleno)
                ctx.stroke(Path(roundedRect: marco, cornerRadius: 4), with: linea, style: trazo)
                // Contactos (dorados) o agujeros (huecos), en rejilla
                let columnas = alargado ? 5 : 6, filas = 6
                let pasoX = (w - 14) / CGFloat(columnas - 1), pasoY = (h - 14) / CGFloat(filas - 1)
                for fila in 0..<filas {
                    for columna in 0..<columnas {
                        let punto = CGRect(
                            x: marco.minX + 7 + CGFloat(columna) * pasoX - 2,
                            y: marco.minY + 7 + CGFloat(fila) * pasoY - 2,
                            width: 4,
                            height: 4
                        )
                        if pinesEnPlaca {
                            ctx.fill(Path(ellipseIn: punto), with: oro)
                        } else {
                            ctx.stroke(Path(ellipseIn: punto), with: linea, lineWidth: 1)
                        }
                    }
                }
                // Palanca de retención
                var palanca = Path()
                palanca.move(to: CGPoint(x: marco.maxX + 7, y: marco.minY + 4))
                palanca.addLine(to: CGPoint(x: marco.maxX + 7, y: marco.maxY - 6))
                palanca.addLine(to: CGPoint(x: marco.maxX + 15, y: marco.maxY - 6))
                ctx.stroke(palanca, with: .color(acento), style: trazo)

            case .placa(let ancho, let alto):
                let altoATX = min(tam.height * 0.82, 72), anchoATX = altoATX * 0.8
                let referencia = CGRect(x: cx - anchoATX / 2, y: cy - altoATX / 2, width: anchoATX, height: altoATX)
                ctx.stroke(Path(roundedRect: referencia, cornerRadius: 3), with: .color(.primary.opacity(0.35)), style: discontinuo)
                // Todas comparten la esquina superior izquierda, como en la caja
                let placa = CGRect(x: referencia.minX, y: referencia.minY, width: anchoATX * ancho, height: altoATX * alto)
                ctx.fill(Path(roundedRect: placa, cornerRadius: 3), with: .color(acento.opacity(0.28)))
                ctx.stroke(Path(roundedRect: placa, cornerRadius: 3), with: linea, style: trazo)
                let zocalo = CGRect(x: placa.minX + placa.width * 0.36, y: placa.minY + placa.height * 0.14, width: 11, height: 11)
                ctx.stroke(Path(zocalo), with: linea, lineWidth: 1.5)

            case .molex:
                let w = min(tam.width * 0.56, 104), h: CGFloat = 30
                let x0 = cx - w / 2, x1 = cx + w / 2, y0 = cy - h / 2, y1 = cy + h / 2
                var carcasa = Path()
                carcasa.move(to: CGPoint(x: x0 + 9, y: y0))
                carcasa.addLine(to: CGPoint(x: x1 - 9, y: y0))
                carcasa.addLine(to: CGPoint(x: x1, y: y0 + 9))
                carcasa.addLine(to: CGPoint(x: x1, y: y1))
                carcasa.addLine(to: CGPoint(x: x0, y: y1))
                carcasa.addLine(to: CGPoint(x: x0, y: y0 + 9))
                carcasa.closeSubpath()
                ctx.fill(carcasa, with: relleno)
                ctx.stroke(carcasa, with: linea, style: trazo)
                for i in 0..<4 {
                    let pin = CGRect(x: x0 + w * (0.2 + 0.2 * CGFloat(i)) - 6, y: cy - 4, width: 12, height: 12)
                    ctx.fill(Path(ellipseIn: pin), with: oro)
                }
            }
        }
    }
}
