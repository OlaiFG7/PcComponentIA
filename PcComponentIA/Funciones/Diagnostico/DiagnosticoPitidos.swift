//
//  DiagnosticoPitidos.swift
//  PcComponentIA
//
//  Códigos de pitidos de la BIOS al arrancar (AMI y Award).
//  Un patrón es una secuencia de pitidos cortos y largos, p. ej. largo-corto-corto.
//  Los fabricantes adaptan estos códigos: el manual de la placa es la referencia final.
//

import Foundation

enum TipoPitido: String, Codable, Hashable {
    case corto, largo

    var simbolo: String { self == .corto ? "·" : "—" }
}

enum BIOSPitidos: String, CaseIterable, Identifiable {
    case ami = "AMI"
    // Phoenix usa grupos de pitidos separados por pausas (p. ej. 1-3-1): no encaja en este
    // selector de cortos/largos, así que no se ofrece para no dar diagnósticos equivocados.
    case award = "Award"
    case desconocida = "No lo sé"

    var id: String { rawValue }
}

struct CodigoPitidos: Identifiable {
    let id = UUID()
    let bios: BIOSPitidos
    let patron: [TipoPitido]
    /// Pitidos que se repiten sin parar (el patrón indica el tipo de pitido).
    var continuo = false
    let titulo: String
    let descripcion: String
    let pasos: [String]

    var patronTexto: String {
        let base = patron.map(\.simbolo).joined(separator: " ")
        return continuo ? base + L(" (repetido)") : base
    }
}

enum DatosPitidos {

    private static let c = TipoPitido.corto
    private static let l = TipoPitido.largo

    private static var pasosMemoria: [String] { _pasosMemoria.valor }

    private static let _pasosMemoria = PorIdioma<[String]> {
        [
        L("Apaga el equipo y desenchufa la fuente."),
        L("Saca la RAM y vuelve a colocarla hasta oír el clic en ambos lados."),
        L("Prueba con un solo módulo en la ranura que indica el manual (normalmente A2)."),
        L("Si tienes otro módulo, pruébalo para descartar uno defectuoso."),
    ]
    }

    private static var pasosVideo: [String] { _pasosVideo.valor }

    private static let _pasosVideo = PorIdioma<[String]> {
        [
        L("Comprueba que la gráfica está bien encajada en la ranura PCIe x16 y atornillada."),
        L("Conecta los cables de alimentación PCIe de la fuente a la gráfica."),
        L("Conecta el monitor a la gráfica, no a la placa base."),
        L("Si el procesador tiene gráficos integrados, prueba sin la gráfica."),
    ]
    }

    static var codigos: [CodigoPitidos] { _codigos.valor }

    private static let _codigos = PorIdioma<[CodigoPitidos]> {
        [
        // MARK: AMI
        CodigoPitidos(bios: .ami, patron: [c], titulo: L("Arranque normal (o fallo de refresco de memoria)"),
                      descripcion: L("En la mayoría de equipos modernos un pitido corto significa que todo ha ido bien. Si además no hay imagen, la BIOS AMI antigua lo usa para un fallo de refresco de la memoria."),
                      pasos: [L("Si hay imagen y el sistema arranca, no hay que hacer nada.")] + pasosMemoria),
        CodigoPitidos(bios: .ami, patron: [c, c], titulo: L("Error de paridad de memoria"),
                      descripcion: L("La BIOS ha detectado un error al comprobar la memoria RAM."),
                      pasos: pasosMemoria),
        CodigoPitidos(bios: .ami, patron: [c, c, c], titulo: L("Fallo en la memoria base (primeros 64 KB)"),
                      descripcion: L("La primera zona de la RAM no responde. Suele ser un módulo mal colocado o defectuoso."),
                      pasos: pasosMemoria),
        CodigoPitidos(bios: .ami, patron: [c, c, c, c], titulo: L("Fallo del temporizador del sistema"),
                      descripcion: L("Un componente de la placa base no responde. También puede deberse a la RAM."),
                      pasos: pasosMemoria + [L("Si persiste, la placa base puede estar dañada.")]),
        CodigoPitidos(bios: .ami, patron: [c, c, c, c, c], titulo: L("Error del procesador"),
                      descripcion: L("La CPU no responde correctamente."),
                      pasos: [L("Comprueba que el conector EPS de 8 pines (CPU) está conectado."),
                              L("Revisa que el procesador está bien asentado en el socket y la palanca cerrada."),
                              L("Comprueba que la BIOS de la placa es compatible con tu procesador (puede necesitar actualización).")]),
        CodigoPitidos(bios: .ami, patron: [c, c, c, c, c, c], titulo: L("Error del controlador de teclado"),
                      descripcion: L("Fallo en el controlador de teclado de la placa (Gate A20)."),
                      pasos: [L("Desconecta todos los periféricos USB y vuelve a arrancar."),
                              L("Prueba con otro teclado."), L("Si persiste, puede ser la placa base.")]),
        CodigoPitidos(bios: .ami, patron: [c, c, c, c, c, c, c, c], titulo: L("Error de memoria de vídeo"),
                      descripcion: L("La tarjeta gráfica o su memoria no responden."),
                      pasos: pasosVideo),
        CodigoPitidos(bios: .ami, patron: [c, c, c, c, c, c, c, c, c], titulo: L("Error en la memoria de la BIOS"),
                      descripcion: L("La comprobación de la BIOS ha fallado; puede estar corrupta."),
                      pasos: [L("Haz un borrado de CMOS (quita la pila unos minutos o usa el jumper CLR_CMOS)."),
                              L("Si tu placa tiene BIOS Flashback, reinstala la BIOS desde un USB.")]),
        CodigoPitidos(bios: .ami, patron: [l, c, c, c], titulo: L("Fallo de memoria"),
                      descripcion: L("La memoria convencional o extendida ha fallado la prueba."),
                      pasos: pasosMemoria),
        CodigoPitidos(bios: .ami, patron: [l, c, c, c, c, c, c, c, c], titulo: L("Fallo de pantalla"),
                      descripcion: L("No se ha podido inicializar la salida de vídeo."),
                      pasos: pasosVideo),

        // MARK: Award
        CodigoPitidos(bios: .award, patron: [c], titulo: L("Arranque correcto"),
                      descripcion: L("La comprobación inicial (POST) ha terminado sin errores."),
                      pasos: [L("No hay que hacer nada. Si no hay imagen, revisa el cable y la entrada del monitor.")]),
        CodigoPitidos(bios: .award, patron: [c, c], titulo: L("Error de configuración (CMOS)"),
                      descripcion: L("Los ajustes guardados de la BIOS no son válidos."),
                      pasos: [L("Entra en la BIOS (Supr o F2 al arrancar), carga los valores por defecto y guarda."),
                              L("Si se repite cada vez que apagas, cambia la pila CMOS (CR2032).")]),
        CodigoPitidos(bios: .award, patron: [l, c], titulo: L("Error de memoria o de placa base"),
                      descripcion: L("La RAM o la placa base no superan la prueba."),
                      pasos: pasosMemoria),
        CodigoPitidos(bios: .award, patron: [l, c, c], titulo: L("Error de vídeo"),
                      descripcion: L("No se detecta la tarjeta gráfica o su memoria falla."),
                      pasos: pasosVideo),
        CodigoPitidos(bios: .award, patron: [l, c, c, c], titulo: L("Error de vídeo o de teclado"),
                      descripcion: L("Según la placa, indica que no hay gráfica o que falla el controlador de teclado."),
                      pasos: pasosVideo + [L("Desconecta los periféricos USB y prueba de nuevo.")]),
        CodigoPitidos(bios: .award, patron: [l, c, c, c, c, c, c, c, c, c], titulo: L("Error de la BIOS"),
                      descripcion: L("La memoria de la BIOS está dañada."),
                      pasos: [L("Haz un borrado de CMOS."),
                              L("Si tu placa tiene BIOS Flashback o Dual BIOS, recupérala desde ahí.")]),
        CodigoPitidos(bios: .award, patron: [l], continuo: true, titulo: L("No se detecta la memoria"),
                      descripcion: L("Pitidos largos repetidos: la placa no encuentra la RAM."),
                      pasos: pasosMemoria),
        CodigoPitidos(bios: .award, patron: [c], continuo: true, titulo: L("Problema de alimentación"),
                      descripcion: L("Pitidos cortos repetidos: la fuente o la alimentación de la placa fallan."),
                      pasos: [L("Comprueba que el conector ATX de 24 pines y el EPS de 8 pines están bien conectados."),
                              L("Prueba con otra fuente si es posible."),
                              L("Revisa que no haya tornillos sueltos que toquen la placa (cortocircuito).")]),
    ]
    }

    /// Códigos cuyo patrón coincide; con BIOS desconocida se buscan en todas.
    static func buscar(_ patron: [TipoPitido], continuo: Bool, bios: BIOSPitidos) -> [CodigoPitidos] {
        guard !patron.isEmpty else { return [] }
        return codigos.filter { codigo in
            (bios == .desconocida || codigo.bios == bios)
                && codigo.continuo == continuo
                && codigo.patron == patron
        }
    }
}
