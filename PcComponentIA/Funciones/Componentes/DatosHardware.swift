//
//  DatosHardware.swift
//  PcComponentIA
//

import Foundation

enum TipoInteraccionComponente: String, Codable {
    case instalar
    case conectar
    case usarIntegrado
    case configurar
}

struct InfoComponente: Codable, Identifiable {

    var id: String {
        nombreImagenSF + String(descripcion.prefix(10))
    }

    let descripcion: String
    let guiaDeUsoOMontaje: String
    let nombreImagenSF: String
    let tipoInteraccion: TipoInteraccionComponente

    var dificultad: Int = 1
    var tiempoEstimadoMin: Int = 5
    var esFavorito: Bool = false

    var tituloGuia: String {
        switch tipoInteraccion {
        case .instalar:
            return L("Cómo instalarlo")

        case .conectar:
            return L("Cómo conectarlo")

        case .usarIntegrado:
            return L("Qué se conecta aquí")

        case .configurar:
            return L("Cómo configurarlo")
        }
    }

    var iconoGuia: String {
        switch tipoInteraccion {
        case .instalar:
            return "wrench.and.screwdriver.fill"

        case .conectar:
            return "cable.connector"

        case .usarIntegrado:
            return "arrow.down.to.line.compact"

        case .configurar:
            return "gearshape.fill"
        }
    }
    var comoConectar: String {
        guiaDeUsoOMontaje
    }
}

final class DatosHardware {

    /// Devuelve las fichas de todos los componentes. Se construyen una sola vez
    /// (la primera vez que se piden) y después se reutilizan.
    static func obtenerDiccionario() -> [String: InfoComponente] {
        diccionario
    }

    private static var diccionario: [String: InfoComponente] { _diccionario.valor }

    private static let _diccionario = PorIdioma<[String: InfoComponente]> {
        crearDiccionario()
    }

    private static func crearDiccionario() -> [String: InfoComponente] {
        [

            // MARK: - Placa base y procesador

            "Placa_Base": InfoComponente(
                descripcion: L("La placa base o motherboard es el circuito principal del PC. Conecta CPU, RAM, almacenamiento, tarjetas de expansión, alimentación y puertos externos."),
                guiaDeUsoOMontaje: L("Compruebe que el formato de la placa —ATX, microATX o Mini-ITX— es compatible con la caja. Coloque separadores solo donde coincidan con sus agujeros. Instale el protector I/O si no está integrado, baje la placa sin arrastrarla y fíjela con tornillos sin apretar en exceso."),
                nombreImagenSF: "rectangle.3.group",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 15
            ),

            "Socket_Intel": InfoComponente(
                descripcion: L("Zócalo LGA integrado en la placa base para procesadores Intel compatibles. En estos sockets, los contactos delicados están en la placa y el procesador tiene superficies de contacto planas."),
                guiaDeUsoOMontaje: L("El socket no se instala ni se conecta: ya forma parte de la placa base. Para colocar una CPU compatible, abra la palanca y la tapa de retención, alinee el triángulo de la CPU con la marca del socket y déjela asentarse sin presionar. Cierre la tapa y baje la palanca. No toque ni doble los contactos."),
                nombreImagenSF: "cpu",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Socket_CPU": InfoComponente(
                descripcion: L("Zócalo de la placa base donde va el procesador. Intel usa sockets LGA, con los contactos en la placa; AMD usa AM4, con pines en la CPU, o AM5, con contactos en la placa. Una CPU solo encaja en el socket de su misma familia."),
                guiaDeUsoOMontaje: L("El socket no se instala: forma parte de la placa base. Levante la palanca, alinee el triángulo de la CPU con la marca del socket y déjela caer sin presionar. Baje la palanca para fijarla. No toque ni doble los pines o contactos."),
                nombreImagenSF: "cpu",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Socket_AMD": InfoComponente(
                descripcion: L("Zócalo integrado en la placa base para procesadores AMD compatibles. AM4 usa pines en el procesador, mientras que AM5 tiene contactos en la placa base."),
                guiaDeUsoOMontaje: L("El socket no se instala ni se conecta: forma parte de la placa base. Levante la palanca, alinee el triángulo dorado de la CPU con la marca del socket y déjela caer sin fuerza. Baje la palanca para fijarla. En AM4, proteja los pines de la CPU; en AM5, no toque los contactos del socket."),
                nombreImagenSF: "cpu.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "CPU": InfoComponente(
                descripcion: L("Procesador o CPU. Es el chip que ejecuta las instrucciones de los programas y coordina el resto de componentes. Se monta en el socket de la placa base, que debe ser del mismo fabricante (Intel o AMD) y generación."),
                guiaDeUsoOMontaje: L("Compruebe que la CPU y el socket de la placa son compatibles y que la BIOS la admite. Sujétela por los bordes, alinee el triángulo o las muescas con la marca del socket y déjela asentarse sin hacer fuerza. Cierre el mecanismo de retención. Aplique pasta térmica si el disipador no la trae y monte una refrigeración compatible."),
                nombreImagenSF: "cpu",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            "CPU_Intel": InfoComponente(
                descripcion: L("Procesador Intel Core. Ejecuta instrucciones, coordina tareas del sistema y contiene núcleos, caché y controlador de memoria integrado."),
                guiaDeUsoOMontaje: L("Instale la CPU solo en una placa con socket Intel y BIOS compatibles. Sujétela por los bordes, alinee sus muescas y el triángulo con el socket, y déjela asentarse sin fuerza. Cierre el mecanismo de retención. Aplique pasta térmica solo si el disipador no la trae preaplicada y monte una refrigeración compatible."),
                nombreImagenSF: "cpu",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            "CPU_AMD": InfoComponente(
                descripcion: L("Procesador AMD Ryzen. Gestiona el procesamiento general del PC, la memoria y líneas PCIe para gráficos y almacenamiento."),
                guiaDeUsoOMontaje: L("Instale la CPU únicamente en una placa y socket AMD compatibles. Sujétela por los bordes, alinee el triángulo dorado con la marca del socket y déjela asentarse sin fuerza. Cierre la palanca. En AM4, no doble los pines de la CPU; en AM5, no toque los contactos del socket. Termine instalando un disipador compatible."),
                nombreImagenSF: "cpu",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            "Pasta_Termica": InfoComponente(
                descripcion: L("Compuesto que mejora la transferencia de calor entre el procesador y la base del disipador. Es necesaria salvo que el disipador incluya pasta preaplicada."),
                guiaDeUsoOMontaje: L("Con el equipo apagado, limpie los restos antiguos con alcohol isopropílico y una toallita sin pelusa. Aplique una gota centrada, aproximadamente del tamaño de un guisante. Coloque el disipador recto y apriete su anclaje; la presión repartirá la pasta. No la extienda con el dedo."),
                nombreImagenSF: "drop.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "VRM": InfoComponente(
                descripcion: L("El VRM, o módulo regulador de voltaje, está integrado en la placa base y transforma la energía de la fuente en voltajes estables para la CPU."),
                guiaDeUsoOMontaje: L("El VRM no se instala ni se conecta por separado. Para que funcione, conecte el cable EPS o CPU de la fuente al conector de alimentación de CPU de la placa. Mantenga despejada esta zona y compruebe que el disipador de CPU no presiona sus disipadores metálicos."),
                nombreImagenSF: "bolt.shield.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 2
            ),

            "Chipset": InfoComponente(
                descripcion: L("El chipset es un controlador integrado en la placa base que gestiona puertos USB, SATA, líneas PCIe adicionales y otras funciones de entrada y salida."),
                guiaDeUsoOMontaje: L("El chipset no se instala ni se conecta por separado. Funciona automáticamente al conectar dispositivos compatibles a la placa. Consulte el manual: algunas ranuras M.2 pueden compartir líneas con puertos SATA o PCIe y desactivar determinadas conexiones."),
                nombreImagenSF: "cpu.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "BIOS_UEFI": InfoComponente(
                descripcion: L("La BIOS o UEFI es el firmware de la placa base. Inicializa el hardware antes del sistema operativo y permite configurar memoria, ventiladores, almacenamiento y orden de arranque."),
                guiaDeUsoOMontaje: L("No se instala físicamente. Tras el primer encendido, entre normalmente con Supr o F2. Compruebe que detecta CPU, RAM y unidades, revise temperaturas y active XMP, EXPO o DOCP solo si el sistema es estable. Actualice la BIOS únicamente con el archivo exacto del fabricante y sin interrumpir la alimentación."),
                nombreImagenSF: "gearshape.2.fill",
                tipoInteraccion: .configurar,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Pila_CMOS": InfoComponente(
                descripcion: L("Batería CR2032 que mantiene el reloj y parte de la configuración de BIOS o UEFI cuando el PC está apagado y desconectado."),
                guiaDeUsoOMontaje: L("Para sustituirla o reiniciar la configuración, desconecte la corriente, mantenga pulsado el botón de encendido unos segundos y retire la pila con cuidado. Coloque una CR2032 nueva con el símbolo positivo hacia arriba. Para restaurar ajustes, espere al menos 30 segundos antes de volver a instalarla."),
                nombreImagenSF: "battery.100percent",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            // MARK: - Memoria

            "Ranura_RAM": InfoComponente(
                descripcion: L("Ranura DIMM integrada en la placa base para módulos de memoria DDR4 o DDR5. La muesca física impide insertar una generación incompatible."),
                guiaDeUsoOMontaje: L("La ranura no se instala: se utiliza para colocar RAM. Abra los seguros laterales, alinee la muesca del módulo con la guía de la ranura y presione de forma uniforme hasta que los seguros encajen. Para dos módulos, consulte el manual; normalmente se usan A2 y B2."),
                nombreImagenSF: "memorychip",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 5
            ),

            "Modulo_RAM": InfoComponente(
                descripcion: L("Módulo de memoria DDR4 o DDR5. Guarda temporalmente datos e instrucciones que la CPU necesita de forma inmediata."),
                guiaDeUsoOMontaje: L("Instale módulos de la misma generación admitida por la placa base. Abra los seguros de la ranura, alinee la muesca y presione recto hasta que encajen. Para usar doble canal, coloque el kit en las ranuras indicadas por el manual, normalmente A2 y B2."),
                nombreImagenSF: "memorychip.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 5
            ),

            // MARK: - Expansión y gráficos

            "Ranura_PCIe_x16": InfoComponente(
                descripcion: L("Ranura PCI Express x16 integrada en la placa base. Normalmente se usa para instalar la tarjeta gráfica principal y suele ser la más cercana al procesador."),
                guiaDeUsoOMontaje: L("La ranura no se instala: se usa para montar una tarjeta de expansión. Abra su pestaña de bloqueo, alinee la GPU con la ranura y los huecos traseros de la caja, presione hasta que cierre el seguro y atornille la tarjeta al chasis. Conecte después la alimentación de la GPU si la requiere."),
                nombreImagenSF: "rectangle.3.group.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            "Ranura_PCIe_x1": InfoComponente(
                descripcion: L("Ranura PCI Express x1 integrada en la placa base para tarjetas de expansión como Wi‑Fi, sonido, capturadoras o puertos USB adicionales."),
                guiaDeUsoOMontaje: L("La ranura no se instala: se utiliza para montar una tarjeta de expansión compatible. Retire la cubierta trasera necesaria de la caja, inserte la tarjeta recta, fíjela con un tornillo al chasis e instale los controladores del fabricante si el sistema operativo no la reconoce."),
                nombreImagenSF: "rectangle.grid.1x2",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 5
            ),

            "GPU": InfoComponente(
                descripcion: L("Tarjeta gráfica dedicada o GPU. Procesa gráficos, vídeo, renderizado 3D y tareas de computación paralela. Se instala principalmente en una ranura PCIe x16."),
                guiaDeUsoOMontaje: L("Retire las cubiertas PCIe necesarias de la caja, abra el seguro de la ranura PCIe x16 e inserte la GPU hasta que quede bloqueada. Atornille el soporte metálico de la tarjeta al chasis. Conecte después sus cables PCIe de 6+2 pines o el cable 12VHPWR o 12V-2x6 que indique el fabricante."),
                nombreImagenSF: "display",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Cable_PCIe_GPU": InfoComponente(
                descripcion: L("Cable de alimentación PCIe de 6+2 pines para tarjetas gráficas. No es el mismo cable que el EPS de CPU, aunque ambos puedan tener ocho pines."),
                guiaDeUsoOMontaje: L("Use únicamente cables marcados como PCI-E o VGA y que procedan de la misma fuente modular. Inserte el conector de 6+2 pines en la GPU hasta que bloquee. Para tarjetas con varios conectores, siga las indicaciones de la GPU y fuente; no mezcle cables de fuentes diferentes."),
                nombreImagenSF: "bolt.horizontal.circle.fill",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 4
            ),

            "Conector_12VHPWR": InfoComponente(
                descripcion: L("Conector de alimentación de alta potencia para GPUs modernas, también evolucionado como 12V-2x6. Puede sustituir varios conectores PCIe de ocho pines."),
                guiaDeUsoOMontaje: L("Inserte el conector completamente hasta que no quede hueco visible y el cierre esté asegurado. No doble el cable cerca del conector: deje varios centímetros rectos antes de curvarlo. Siempre que sea posible, use un cable nativo y compatible con la fuente."),
                nombreImagenSF: "bolt.fill",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 4
            ),

            "Tarjeta_WiFi_Bluetooth": InfoComponente(
                descripcion: L("Tarjeta de expansión inalámbrica que añade Wi‑Fi y Bluetooth a un PC que no los incorpora en la placa base."),
                guiaDeUsoOMontaje: L("Instálela en una ranura PCIe x1 libre y fíjela al chasis. Conecte las antenas a los conectores dorados del panel trasero. Instale después los controladores del fabricante o del chipset inalámbrico."),
                nombreImagenSF: "wifi",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 6
            ),

            "Tarjeta_Capturadora": InfoComponente(
                descripcion: L("Tarjeta de expansión que recibe una señal de vídeo externa, por ejemplo de una consola, cámara u otro PC, para grabarla o transmitirla."),
                guiaDeUsoOMontaje: L("Instálela en una ranura PCIe compatible y fíjela al chasis. Conecte la fuente de vídeo a su entrada HDMI o SDI según el modelo. Instale el software y controladores recomendados por el fabricante."),
                nombreImagenSF: "video.fill",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            "Tarjeta_Sonido": InfoComponente(
                descripcion: L("Tarjeta de expansión dedicada para entradas y salidas de audio. Puede ampliar conectividad, amplificación o calidad frente al audio integrado."),
                guiaDeUsoOMontaje: L("Instálela en una ranura PCIe x1 libre, fíjela a la caja e instale su controlador. Conecte altavoces, auriculares o micrófono en los puertos indicados por el fabricante."),
                nombreImagenSF: "speaker.wave.3.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 6
            ),

            // MARK: - Almacenamiento

            "Ranura_M2": InfoComponente(
                descripcion: L("Conector M.2 integrado en la placa base para SSD compactos. Dependiendo de la placa y la ranura, puede admitir unidades NVMe, SATA o ambas."),
                guiaDeUsoOMontaje: L("La ranura no se instala: se utiliza para montar un SSD M.2 compatible. Retire el disipador si existe, ajuste el separador a la longitud de la unidad —habitualmente 2280—, inserte el SSD en ángulo y bájelo sin forzarlo. Fíjelo con el tornillo o cierre y vuelva a colocar el disipador tras retirar el plástico del pad térmico."),
                nombreImagenSF: "internaldrive",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 6
            ),

            "M2_SSD_NVMe": InfoComponente(
                descripcion: L("SSD NVMe en formato M.2. Usa líneas PCIe y ofrece baja latencia y altas velocidades de transferencia; es habitual para el sistema operativo."),
                guiaDeUsoOMontaje: L("Localice una ranura M.2 compatible con NVMe. Inserte la unidad con un ángulo aproximado de 30 grados, bájela hasta el separador y fíjela sin forzar el tornillo. Instale el disipador M.2 si la placa o la unidad lo recomienda."),
                nombreImagenSF: "internaldrive.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 6
            ),

            "M2_SSD_SATA": InfoComponente(
                descripcion: L("SSD M.2 con interfaz SATA. Tiene forma parecida a un NVMe, pero utiliza protocolo SATA y necesita una ranura que admita expresamente SATA."),
                guiaDeUsoOMontaje: L("Consulte el manual: no todas las ranuras M.2 aceptan unidades SATA. Insértela y fíjela igual que un SSD NVMe. En algunas placas, usar esta unidad desactiva uno o varios puertos SATA."),
                nombreImagenSF: "internaldrive",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 6
            ),

            "Puerto_SATA": InfoComponente(
                descripcion: L("Puerto SATA de datos integrado en la placa base. Se utiliza para conectar SSD SATA, discos duros y algunas unidades ópticas."),
                guiaDeUsoOMontaje: L("El puerto SATA no se instala: conecte aquí un extremo del cable de datos SATA. Alinee la muesca en forma de L sin forzar y conecte el otro extremo a la unidad. La unidad necesita además un cable de alimentación SATA desde la fuente."),
                nombreImagenSF: "cable.connector",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Cable_Datos_SATA": InfoComponente(
                descripcion: L("Cable de datos SATA de siete pines. Transporta información entre un SSD SATA o HDD y uno de los puertos SATA de la placa base."),
                guiaDeUsoOMontaje: L("Conecte un extremo a un puerto SATA de la placa y el otro a la unidad. La forma de L evita una orientación incorrecta. No confunda este cable fino con el conector ancho de alimentación SATA."),
                nombreImagenSF: "cable.connector",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Cable_Alimentacion_SATA": InfoComponente(
                descripcion: L("Conector de alimentación SATA de 15 pines procedente de la fuente. Aporta energía a SSD SATA, HDD, hubs de ventiladores y otros accesorios compatibles."),
                guiaDeUsoOMontaje: L("Alinee la muesca en forma de L y conecte el extremo ancho a la unidad o accesorio. No use fuerza si no entra; revise la orientación. En una fuente modular, utilice solo el cable SATA original de esa misma fuente."),
                nombreImagenSF: "powerplug",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "HDD": InfoComponente(
                descripcion: L("Disco duro mecánico de 3.5 pulgadas. Ofrece gran capacidad a bajo coste, pero es más lento y sensible a golpes que un SSD."),
                guiaDeUsoOMontaje: L("Fíjelo en una bahía de 3.5 pulgadas con tornillos o bandeja sin herramientas. Conecte un cable SATA de datos a la placa y un cable SATA de alimentación desde la fuente. Evite golpes mientras esté funcionando."),
                nombreImagenSF: "externaldrive",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 6
            ),

            "SSD_SATA": InfoComponente(
                descripcion: L("Unidad SSD de 2.5 pulgadas con interfaz SATA. No tiene piezas móviles y ofrece una respuesta mucho más rápida que un HDD."),
                guiaDeUsoOMontaje: L("Móntela en una bahía de 2.5 pulgadas o soporte adecuado. Conecte un cable SATA de datos a la placa base y un cable SATA de alimentación desde la fuente."),
                nombreImagenSF: "internaldrive.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 5
            ),

            // MARK: - Alimentación

            "Fuente_Alimentacion": InfoComponente(
                descripcion: L("La fuente de alimentación o PSU convierte la corriente alterna de la red en corriente continua estable para placa, CPU, GPU, almacenamiento y accesorios."),
                guiaDeUsoOMontaje: L("Compruebe que la potencia y conectores cubren todos los componentes. Colóquela en la caja con el ventilador hacia el filtro inferior si hay ventilación bajo la caja; si no, siga el manual del chasis. Fíjela con cuatro tornillos y conecte primero ATX de 24 pines, EPS de CPU, GPU y almacenamiento."),
                nombreImagenSF: "powercord",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 12
            ),

            "Conector_ATX_24p": InfoComponente(
                descripcion: L("Conector principal de alimentación de 24 pines integrado en la placa base. Recibe energía de la fuente para la placa, memoria, controladores y ranuras."),
                guiaDeUsoOMontaje: L("El conector ya está integrado en la placa. Conecte aquí el cable ATX de 24 pines de la fuente. Alinee la pestaña del cable con el cierre del conector y presione uniformemente hasta que el clip quede bloqueado. No lo confunda con el cable EPS de CPU."),
                nombreImagenSF: "powerplug",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Conector_EPS_8p": InfoComponente(
                descripcion: L("Conector de alimentación EPS12V de 8 pines o 4+4 integrado en la placa base. Alimenta el circuito de regulación de voltaje de la CPU."),
                guiaDeUsoOMontaje: L("El conector ya está integrado en la placa, normalmente cerca de la esquina superior izquierda. Conecte aquí el cable marcado CPU o EPS de la fuente; no use un cable PCI-E de GPU aunque parezca similar. Alinee las formas y el clip antes de presionar."),
                nombreImagenSF: "powerplug.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 5
            ),

            "Cable_Molex": InfoComponente(
                descripcion: L("Conector periférico Molex de cuatro pines presente en fuentes y accesorios antiguos o en algunos hubs y controladores RGB."),
                guiaDeUsoOMontaje: L("Úselo únicamente si el accesorio lo exige. Alinee cuidadosamente la forma del conector y no fuerce los pines. Para SSD, HDD y accesorios modernos, utilice preferentemente alimentación SATA."),
                nombreImagenSF: "cable.connector.horizontal",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Cable_Corriente_IEC": InfoComponente(
                descripcion: L("Cable externo de corriente que conecta la fuente de alimentación con una toma eléctrica de pared o regleta protegida."),
                guiaDeUsoOMontaje: L("Conecte el extremo IEC a la fuente y el enchufe a una toma con tierra. Mantenga el interruptor trasero de la PSU apagado durante el montaje. Enciéndalo únicamente después de revisar todas las conexiones internas."),
                nombreImagenSF: "powercord.fill",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            // MARK: - Refrigeración

            "Disipador_Aire": InfoComponente(
                descripcion: L("Refrigeración por aire formada por base, heatpipes, aletas y uno o varios ventiladores. Disipa el calor de la CPU hacia el flujo de aire de la caja."),
                guiaDeUsoOMontaje: L("Instale el backplate y anclajes compatibles con su socket. Aplique pasta térmica si no viene preaplicada. Coloque el disipador y apriete los tornillos alternando en cruz. Conecte el ventilador principal al cabezal CPU_FAN."),
                nombreImagenSF: "fan.fill",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 12
            ),

            "Refrigeracion_Liquida_AIO": InfoComponente(
                descripcion: L("Sistema de refrigeración líquida cerrada con bloque-bomba, tubos, radiador y ventiladores. Traslada el calor de la CPU al radiador."),
                guiaDeUsoOMontaje: L("Monte primero el radiador y sus ventiladores en una posición compatible con la caja. Instale el bloque sobre la CPU con pasta térmica. Conecte la bomba a AIO_PUMP o al cabezal indicado por el fabricante y los ventiladores a CPU_FAN o a un hub."),
                nombreImagenSF: "drop.circle.fill",
                tipoInteraccion: .instalar,
                dificultad: 3,
                tiempoEstimadoMin: 25
            ),

            "Radiador": InfoComponente(
                descripcion: L("Intercambiador de calor de la refrigeración líquida. Disipa el calor del líquido refrigerante hacia el aire exterior mediante ventiladores."),
                guiaDeUsoOMontaje: L("Móntelo en el panel superior, frontal o lateral de la caja asegurándose de que los ventiladores empujen el aire a través de sus aletas."),
                nombreImagenSF: "wind",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Bloque_refrigeracion_liquida": InfoComponente(
                descripcion: L("Parte de la refrigeración líquida que hace contacto directo con el procesador para transferir su calor al líquido refrigerante."),
                guiaDeUsoOMontaje: L("Aplique pasta térmica en la CPU, coloque el bloque centrando los tornillos y apriételos en cruz alternando esquinas."),
                nombreImagenSF: "cpu.fill",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 10
            ),

            "Bomba_Liquida": InfoComponente(
                descripcion: L("Motor encargado de hacer circular el líquido refrigerante por todo el circuito cerrado (AIO) o personalizado."),
                guiaDeUsoOMontaje: L("Suele estar integrada en el bloque de la CPU o en el radiador. Conecte su cable de alimentación al cabezal AIO_PUMP o W_PUMP de la placa base."),
                nombreImagenSF: "drop.circle.fill",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 5
            ),

            "Ventilador_procesador": InfoComponente(
                descripcion: L("Ventilador del disipador de CPU. Dirige aire a través de las aletas y debe ser supervisado por la placa base."),
                guiaDeUsoOMontaje: L("Fíjelo al disipador según su sistema de clips o tornillos. Oriéntelo para dirigir el aire hacia la parte trasera o superior de extracción de la caja. Conecte su cable de 3 o 4 pines al cabezal CPU_FAN."),
                nombreImagenSF: "fan.oscillation",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Ventilador_Caja": InfoComponente(
                descripcion: L("Ventilador de chasis que mueve aire por la caja. Los frontales o inferiores suelen introducir aire, mientras que traseros y superiores suelen expulsarlo."),
                guiaDeUsoOMontaje: L("Atornille el ventilador respetando la dirección de flujo indicada por las flechas de su marco. Conecte un ventilador PWM o DC a SYS_FAN, CHA_FAN o a un hub. No conecte demasiados ventiladores a un solo cabezal sin conocer su límite de corriente."),
                nombreImagenSF: "fan.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 5
            ),

            "Conector_FAN": InfoComponente(
                descripcion: L("Cabezal de 3 o 4 pines integrado en la placa base para el ventilador principal del disipador de CPU. Permite a la BIOS supervisar y regular su velocidad."),
                guiaDeUsoOMontaje: L("El cabezal no se instala: conecte aquí el cable del ventilador del disipador. Alinee la guía plástica del conector y presiónelo suavemente. No deje CPU_FAN vacío salvo que el manual de la placa o de la refrigeración indique otra configuración."),
                nombreImagenSF: "powercord",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 2
            ),

            "Conector_SYS_FAN": InfoComponente(
                descripcion: L("Cabezal SYS_FAN o CHA_FAN integrado en la placa base para ventiladores de caja. Puede ajustar la velocidad según la temperatura configurada."),
                guiaDeUsoOMontaje: L("El cabezal no se instala: conecte aquí un ventilador de caja o el cable de señal de un hub. Para varios ventiladores, use un repartidor o hub alimentado y respete el límite de corriente indicado por el fabricante de la placa."),
                nombreImagenSF: "powercord",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 2
            ),

            "Hub_Ventiladores": InfoComponente(
                descripcion: L("Concentrador que permite alimentar y controlar varios ventiladores desde un solo cabezal de la placa o mediante alimentación SATA."),
                guiaDeUsoOMontaje: L("Fije el hub con adhesivo o tornillos. Conecte su alimentación SATA si la necesita, conecte su cable de señal a SYS_FAN y después enchufe los ventiladores al hub. Normalmente solo uno de sus puertos transmite RPM a la placa."),
                nombreImagenSF: "point.3.connected.trianglepath.dotted",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 7
            ),

            // MARK: - Caja y panel frontal

            "Caja_PC": InfoComponente(
                descripcion: L("La caja o chasis aloja, protege y organiza los componentes. Determina compatibilidad de placa, longitud de GPU, altura de disipador y posiciones de radiador."),
                guiaDeUsoOMontaje: L("Antes de montar, retire ambos paneles, compruebe los separadores, prepare cables del frontal y confirme el flujo de aire. Instale normalmente fuente y placa base antes de organizar el cableado."),
                nombreImagenSF: "cube.box.fill",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 10
            ),

            "Separadores_Placa_Base": InfoComponente(
                descripcion: L("Los separadores o standoffs son piezas metálicas que elevan la placa base y evitan que sus soldaduras contacten directamente con el chasis."),
                guiaDeUsoOMontaje: L("Coloque separadores únicamente donde la placa tenga agujeros de montaje. No deje separadores extra bajo zonas sin agujero, ya que pueden provocar un cortocircuito. Después coloque la placa y atorníllela sin exceso de fuerza."),
                nombreImagenSF: "circle.grid.3x3.fill",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 5
            ),

            "Protector_IO": InfoComponente(
                descripcion: L("Marco trasero de puertos de la placa base, también llamado I/O shield. Algunas placas lo incluyen integrado y otras requieren montarlo por separado."),
                guiaDeUsoOMontaje: L("Si es independiente, presiónelo desde dentro de la caja hasta que encaje en el hueco trasero. Antes de montar la placa, compruebe que ninguna pestaña metálica bloquea puertos USB, red o vídeo."),
                nombreImagenSF: "rectangle.portrait.and.arrow.right",
                tipoInteraccion: .instalar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Panel_Frontal_Pins": InfoComponente(
                descripcion: L("Cabecera F_PANEL o JFP1 integrada en la placa base para los cables del botón de encendido, reset y LEDs del frontal de la caja."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte aquí los cables finos que salen de la caja. Siga el diagrama exacto del manual de la placa. Power SW y Reset SW no tienen polaridad; Power LED y HDD LED sí la tienen. Si un LED no luce, apague el PC y gire su conector."),
                nombreImagenSF: "slider.vertical.3",
                tipoInteraccion: .usarIntegrado,
                dificultad: 3,
                tiempoEstimadoMin: 15
            ),

            "Cable_Power_SW": InfoComponente(
                descripcion: L("Cable del botón de encendido de la caja. Al pulsarlo, cierra momentáneamente el circuito que ordena a la placa iniciar o apagar el sistema."),
                guiaDeUsoOMontaje: L("Conéctelo al par de pines PWR_SW o POWER SW del cabezal F_PANEL. La polaridad no importa. Consulte el esquema de su placa base para identificar la posición exacta."),
                nombreImagenSF: "power",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 2
            ),

            "Cable_Reset_SW": InfoComponente(
                descripcion: L("Cable del botón de reinicio de la caja. Es opcional y permite reiniciar el ordenador mediante un contacto momentáneo."),
                guiaDeUsoOMontaje: L("Conéctelo al par de pines RESET SW o RST_SW del F_PANEL. La polaridad no importa. Si su caja no incluye botón de reinicio, este cable no se utiliza."),
                nombreImagenSF: "arrow.counterclockwise",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 2
            ),

            "Cable_Power_LED": InfoComponente(
                descripcion: L("Cable del LED de encendido de la caja. Indica visualmente que el ordenador está encendido o en espera, según el chasis."),
                guiaDeUsoOMontaje: L("Conecte los terminales PLED+ y PLED- a los pines de Power LED del F_PANEL respetando la polaridad. Si no se ilumina tras encender el equipo, apáguelo e invierta el conector."),
                nombreImagenSF: "lightbulb.fill",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 2
            ),

            "Cable_HDD_LED": InfoComponente(
                descripcion: L("Cable del LED de actividad de almacenamiento de la caja. Parpadea cuando hay acceso a una unidad SATA o NVMe."),
                guiaDeUsoOMontaje: L("Conecte HDD LED+ y HDD LED- a los pines correspondientes del F_PANEL respetando la polaridad. Si no se ilumina, apague el sistema e invierta el conector."),
                nombreImagenSF: "externaldrive.fill",
                tipoInteraccion: .conectar,
                dificultad: 2,
                tiempoEstimadoMin: 2
            ),

            // MARK: - USB, audio y conectividad

            "Conector_USB_2_0": InfoComponente(
                descripcion: L("Cabecera USB 2.0 interna integrada en la placa base. Puede servir a puertos frontales, controladores RGB, AIO y otros accesorios."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte aquí el cable USB 2.0 interno del accesorio o de la caja. Alinee el hueco del conector con el pin ausente de la cabecera y no fuerce el cable."),
                nombreImagenSF: "cable.connector",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Conector_USB_3_0_Front": InfoComponente(
                descripcion: L("Cabecera USB 3.x interna de 19 o 20 pines integrada en la placa base para los puertos USB-A frontales de la caja."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte aquí el cable USB frontal ancho de la caja. Alinee la guía y presiónelo recto; evite doblar los pines. Es aconsejable conectarlo antes de cerrar el cableado trasero."),
                nombreImagenSF: "cable.connector.horizontal",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 4
            ),

            "Conector_USB_C_Front": InfoComponente(
                descripcion: L("Cabecera interna Type-E integrada en algunas placas para el puerto USB-C frontal de la caja."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte aquí el cable USB-C frontal de la caja si ambos son compatibles. Inserte el conector siguiendo su guía sin torcerlo. Si la placa no dispone de esta cabecera, el USB-C frontal puede quedar sin uso o requerir una tarjeta adaptadora."),
                nombreImagenSF: "cable.connector.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 4
            ),

            "Conector_HD_Audio": InfoComponente(
                descripcion: L("Cabecera interna de audio integrada en la placa base para los conectores de auriculares y micrófono del frontal de la caja."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte aquí el bloque etiquetado HD AUDIO de la caja. Alinee el hueco con el pin ausente. Use HD AUDIO; no conecte AC'97 salvo que un hardware antiguo lo requiera."),
                nombreImagenSF: "headphones",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Puerto_Ethernet": InfoComponente(
                descripcion: L("Puerto de red RJ45 de la placa base o tarjeta de red. Permite una conexión por cable estable a un router, switch o punto de acceso."),
                guiaDeUsoOMontaje: L("El puerto ya está integrado. Conecte un cable Ethernet RJ45 hasta que la pestaña haga clic y conecte el otro extremo al router o switch. Los LED del puerto suelen indicar enlace y actividad."),
                nombreImagenSF: "network",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Antena_WiFi": InfoComponente(
                descripcion: L("Antenas externas de una placa base o tarjeta Wi‑Fi. Mejoran cobertura y velocidad de Wi‑Fi y Bluetooth."),
                guiaDeUsoOMontaje: L("Enrosque las antenas en los conectores traseros dorados sin forzar. Colóquelas separadas y, si usan una base con cable, sitúelas fuera de la caja para mejorar la recepción."),
                nombreImagenSF: "antenna.radiowaves.left.and.right",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 2
            ),

            // MARK: - Iluminación

            "Conector_ARGB_5V": InfoComponente(
                descripcion: L("Cabecera ARGB direccionable de 5 V y tres pines integrada en la placa base. Permite controlar LEDs individuales en accesorios compatibles."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte únicamente accesorios ARGB de 5 V y tres pines. Alinee la flecha o marca de 5V del cable con el pin de 5V. Nunca conecte aquí un accesorio RGB de 12 V y cuatro pines."),
                nombreImagenSF: "sparkles",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 3
            ),

            "Conector_RGB_12V": InfoComponente(
                descripcion: L("Cabecera RGB analógica de 12 V y cuatro pines integrada en la placa base. Todos los LEDs conectados muestran el mismo color al mismo tiempo."),
                guiaDeUsoOMontaje: L("La cabecera no se instala: conecte únicamente accesorios RGB de 12 V y cuatro pines, alineando la marca de 12V. No conecte un accesorio ARGB de 5 V y tres pines: son eléctricamente incompatibles y puede dañarse la iluminación."),
                nombreImagenSF: "paintpalette.fill",
                tipoInteraccion: .usarIntegrado,
                dificultad: 2,
                tiempoEstimadoMin: 3
            ),

            "Hub_RGB_ARGB": InfoComponente(
                descripcion: L("Controlador o concentrador para varios dispositivos RGB o ARGB. Algunos se alimentan mediante SATA y se sincronizan con una cabecera de la placa."),
                guiaDeUsoOMontaje: L("Fije el hub, conecte su alimentación SATA si la requiere y conecte ventiladores o tiras compatibles. Conecte su cable de sincronización a la cabecera correcta: ARGB de 5 V o RGB de 12 V. Nunca intercambie ambos tipos."),
                nombreImagenSF: "lightstrip.2.fill",
                tipoInteraccion: .instalar,
                dificultad: 2,
                tiempoEstimadoMin: 8
            ),

            // MARK: - Puertos y periféricos

            "Puerto_USB_A": InfoComponente(
                descripcion: L("Puerto USB de tipo A, rectangular. Está en el panel trasero de la placa base y en el frontal de la caja. Sirve para teclado, ratón, memorias y otros periféricos. Si su interior es azul o rojo suele ser USB 3.x (más rápido)."),
                guiaDeUsoOMontaje: L("El puerto ya está integrado. Conecte el cable con la cara correcta hacia arriba, sin forzar: USB-A solo entra en una posición. Use los puertos USB 3.x para discos externos y los USB 2.0 para teclado y ratón."),
                nombreImagenSF: "cable.connector",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Puerto_USB_C": InfoComponente(
                descripcion: L("Puerto USB de tipo C, pequeño, ovalado y reversible. Según el equipo puede transmitir datos, vídeo (DisplayPort Alt Mode o Thunderbolt) y carga."),
                guiaDeUsoOMontaje: L("El puerto ya está integrado. El conector entra en cualquier orientación. Consulte el manual de la placa para saber si ese puerto admite vídeo o carga rápida, ya que no todos los USB-C tienen las mismas funciones."),
                nombreImagenSF: "cable.connector.horizontal",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Puerto_HDMI": InfoComponente(
                descripcion: L("Puerto de vídeo digital HDMI. Puede estar en la tarjeta gráfica o en la placa base cuando la CPU dispone de gráficos integrados."),
                guiaDeUsoOMontaje: L("El puerto ya está integrado. Conecte el cable HDMI a la GPU dedicada si el PC tiene una. Use el puerto de la placa base únicamente si utiliza gráficos integrados. Seleccione después la entrada HDMI correcta en el monitor."),
                nombreImagenSF: "rectangle.on.rectangle",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Puerto_DisplayPort": InfoComponente(
                descripcion: L("Puerto de vídeo digital DisplayPort, frecuente en tarjetas gráficas y monitores de alta resolución o alta frecuencia de actualización."),
                guiaDeUsoOMontaje: L("El puerto ya está integrado. Conecte el cable DisplayPort a la tarjeta gráfica y al monitor. Algunos conectores incluyen pestaña de bloqueo; presiónela antes de retirar el cable. Configure después resolución y frecuencia de actualización desde el sistema operativo."),
                nombreImagenSF: "display",
                tipoInteraccion: .usarIntegrado,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Monitor": InfoComponente(
                descripcion: L("Pantalla externa que muestra la salida de vídeo del ordenador. Puede usar HDMI, DisplayPort o USB-C según sus conexiones."),
                guiaDeUsoOMontaje: L("Conecte el cable de vídeo a la GPU dedicada si existe y después al monitor. Conecte también la alimentación del monitor y seleccione la entrada correcta desde su menú. Configure resolución y frecuencia de actualización desde el sistema operativo."),
                nombreImagenSF: "display.2",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 3
            ),

            "Teclado": InfoComponente(
                descripcion: L("Periférico de entrada para escribir y controlar el ordenador. Puede conectarse por USB, Bluetooth o receptor inalámbrico."),
                guiaDeUsoOMontaje: L("Conecte el cable USB o receptor inalámbrico a un puerto disponible. Para Bluetooth, active el modo de emparejamiento y selecciónelo desde los ajustes del sistema."),
                nombreImagenSF: "keyboard",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Raton": InfoComponente(
                descripcion: L("Periférico apuntador para controlar el cursor. Puede usar USB, receptor inalámbrico o Bluetooth."),
                guiaDeUsoOMontaje: L("Conecte el cable o receptor USB a un puerto disponible. Si usa Bluetooth, active el modo de emparejamiento y selecciónelo desde el sistema operativo. Ajuste sensibilidad y botones desde el software del fabricante si lo necesita."),
                nombreImagenSF: "computermouse",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 1
            ),

            "Altavoces_Auriculares": InfoComponente(
                descripcion: L("Dispositivos de salida de audio. Pueden conectarse al panel trasero, al frontal de la caja, por USB o de forma inalámbrica."),
                guiaDeUsoOMontaje: L("Conecte auriculares o altavoces analógicos al puerto de salida de audio verde o al conector frontal. Para dispositivos USB o Bluetooth, selecciónelos como salida de sonido desde los ajustes del sistema."),
                nombreImagenSF: "speaker.wave.2.fill",
                tipoInteraccion: .conectar,
                dificultad: 1,
                tiempoEstimadoMin: 2
            ),
        ]
    }

    static func socketDetectadoInfo(
        _ etiquetaSocket: String
    ) -> String {
        let etiqueta = etiquetaSocket.lowercased()

        if etiqueta.contains("intel") {
            return "Intel"
        }

        if etiqueta.contains("amd") {
            return "AMD"
        }

        return "Desconocido"
    }
}
