//
//  DiagnosticoLED.swift
//  PcComponentIA
//

import Foundation
import SwiftUI

struct InfoLedError: Identifiable {

    let id = UUID()
    let nombre: String
    let color: Color
    let descripcion: String
    let pasosAComprobar: [String]
    let consejoRapido: String
}

struct InfoCodigoPOST: Identifiable {

    let id = UUID()
    let codigo: String
    let titulo: String
    let categoria: CategoriaCodigoPOST
    let descripcion: String
    let acciones: [String]
    let advertencia: String

    enum CategoriaCodigoPOST {
        case cpu
        case memoria
        case grafica
        case almacenamiento
        case arranque
        case configuracion
        case chipset
        case perifericos
        case placa
        case desconocido

        var color: Color {
            switch self {
            case .cpu:
                return .red
            case .memoria:
                return .yellow
            case .grafica:
                return .purple
            case .almacenamiento:
                return .teal
            case .arranque:
                return .green
            case .configuracion:
                return .blue
            case .chipset:
                return .orange
            case .perifericos:
                return .pink
            case .placa:
                return .indigo
            case .desconocido:
                return .gray
            }
        }

        var icono: String {
            switch self {
            case .cpu:
                return "cpu.fill"
            case .memoria:
                return "memorychip.fill"
            case .grafica:
                return "display"
            case .almacenamiento:
                return "internaldrive.fill"
            case .arranque:
                return "play.circle.fill"
            case .configuracion:
                return "gearshape.fill"
            case .chipset:
                return "square.grid.3x3.fill"
            case .perifericos:
                return "keyboard"
            case .placa:
                return "circuitboard.fill"
            case .desconocido:
                return "questionmark.circle.fill"
            }
        }

        var titulo: String {
            switch self {
            case .cpu:
                return L("Procesador")
            case .memoria:
                return L("Memoria RAM")
            case .grafica:
                return L("Vídeo / GPU")
            case .almacenamiento:
                return L("Almacenamiento")
            case .arranque:
                return L("Arranque")
            case .configuracion:
                return L("Configuración")
            case .chipset:
                return L("Chipset")
            case .perifericos:
                return L("Periféricos")
            case .placa:
                return L("Placa base")
            case .desconocido:
                return L("Sin identificar")
            }
        }
    }
}

enum MarcaPlacaBase: String, CaseIterable, Identifiable {

    case generico = "Genérico"
    case asus = "ASUS"
    case msi = "MSI"
    case gigabyte = "Gigabyte"
    case asrock = "ASRock"

    var id: String {
        rawValue
    }
}

enum DatosDiagnosticoLED {

    static let ordenLeds = [
        "CPU",
        "DRAM",
        "VGA",
        "BOOT"
    ]

    // MARK: - LEDs

    static var errores: [String: InfoLedError] { _errores.valor }

    private static let _errores = PorIdioma<[String: InfoLedError]> {
        [
        "CPU": InfoLedError(
            nombre: L("Fallo de CPU"),
            color: .red,
            descripcion: L("La placa base no puede detectar o inicializar correctamente el procesador. Revisa la colocación de la CPU, el socket y la alimentación EPS de la placa."),
            pasosAComprobar: [
                "Instalar CPU en el socket de la placa base",
                "Conectar cable EPS CPU de 8 pines",
                "Montar disipador o refrigeración de CPU",
                "Comprobar compatibilidad y actualización de BIOS"
            ],
            consejoRapido: L("Apaga la fuente, desconecta el equipo y revisa el socket con buena luz antes de volver a montar la CPU.")
        ),

        "DRAM": InfoLedError(
            nombre: L("Fallo de memoria RAM"),
            color: .yellow,
            descripcion: L("La placa no puede inicializar la memoria. Un módulo puede estar mal encajado, en una ranura no recomendada o no ser compatible con la configuración actual."),
            pasosAComprobar: [
                "Instalar módulos de memoria RAM",
                "Probar un único módulo de RAM",
                "Usar primero la ranura A2 indicada por el manual",
                "Comprobar compatibilidad de CPU, placa base y RAM"
            ],
            consejoRapido: L("Retira la RAM y prueba un módulo cada vez en A2. Empuja hasta que las pestañas laterales queden cerradas.")
        ),

        "VGA": InfoLedError(
            nombre: L("Fallo de vídeo o GPU"),
            color: .purple,
            descripcion: L("La placa base no detecta una salida de vídeo válida. Puede ocurrir si la tarjeta gráfica no está bien insertada, no recibe alimentación o el monitor está conectado al puerto equivocado."),
            pasosAComprobar: [
                "Instalar tarjeta gráfica dedicada GPU",
                "Conectar alimentación PCIe o 12VHPWR a GPU",
                "Comprobar que la GPU encaja en PCIe x16",
                "Conectar pantalla, teclado y cable de corriente"
            ],
            consejoRapido: L("Si tienes GPU dedicada, conecta el monitor a la GPU y no a los puertos de vídeo de la placa base.")
        ),

        "BOOT": InfoLedError(
            nombre: L("No se encuentra dispositivo de arranque"),
            color: .green,
            descripcion: L("El hardware base ha superado las comprobaciones principales, pero no se detecta un sistema operativo o una unidad válida configurada para iniciar el equipo."),
            pasosAComprobar: [
                "Instalar SSD M.2 NVMe",
                "Instalar SSD SATA o disco duro HDD",
                "Comprobar orden de arranque en BIOS",
                "Instalar sistema operativo y controladores"
            ],
            consejoRapido: L("Entra en BIOS y confirma que el SSD aparece detectado antes de intentar instalar o arrancar el sistema operativo.")
        )
    ]
    }

    // MARK: - ASUS Q-Code

    static var codigosASUS: [InfoCodigoPOST] { _codigosASUS.valor }

    private static let _codigosASUS = PorIdioma<[InfoCodigoPOST]> {
        [
        codigo(
            "00",
            "CPU no detectada o fallo crítico",
            .cpu,
            "La placa no puede iniciar el procesador o ha detectado un problema crítico de CPU, socket o alimentación.",
            [
                "Revisar el cable EPS CPU de 8 pines",
                "Comprobar la orientación de la CPU",
                "Inspeccionar pines del socket o de la CPU",
                "Realizar Clear CMOS"
            ],
            "En algunas placas el 00 también puede aparecer tras un fallo de POST; confirma el manual del modelo."
        ),

        codigo(
            "10-14",
            "Inicialización temprana de CPU",
            .cpu,
            "El firmware está inicializando el procesador antes de comenzar la detección de memoria.",
            [
                "Esperar unos segundos si el código avanza",
                "Revisar compatibilidad de CPU y BIOS",
                "Comprobar alimentación EPS de CPU"
            ],
            "Es una fase de arranque; solo trátala como error si queda fija."
        ),

        codigo(
            "53",
            "Memoria no detectada",
            .memoria,
            "La RAM no se detecta o no puede inicializarse con la configuración actual.",
            [
                "Probar un único módulo de RAM en A2",
                "Volver a insertar CPU y RAM",
                "Desactivar XMP o EXPO tras Clear CMOS",
                "Comprobar QVL y versión de BIOS"
            ],
            "ASUS agrupa 53 y 55 como incidencias habituales de memoria."
        ),

        codigo(
            "55",
            "No hay memoria instalada",
            .memoria,
            "La placa no detecta un módulo de RAM funcional.",
            [
                "Reinstalar la RAM hasta cerrar las pestañas",
                "Probar cada módulo por separado en A2",
                "Limpiar contactos y comprobar ranuras",
                "Revisar CPU y pines si persiste"
            ],
            "Verifica el manual: A2 suele ser la ranura recomendada para un único módulo."
        ),

        codigo(
            "62-64",
            "Inicialización de chipset",
            .chipset,
            "El firmware está configurando el PCH o chipset y sus recursos internos.",
            [
                "Realizar Clear CMOS",
                "Desconectar periféricos USB no esenciales",
                "Restablecer ajustes de overclock",
                "Actualizar BIOS si el equipo es nuevo"
            ],
            "Puede ser una fase normal si el código continúa avanzando."
        ),

        codigo(
            "76-77",
            "Inicialización PCH DXE",
            .chipset,
            "El chipset entra en la fase DXE de inicialización de dispositivos y recursos.",
            [
                "Esperar unos segundos",
                "Desconectar dispositivos USB y PCIe adicionales",
                "Realizar Clear CMOS",
                "Comprobar el manual del modelo"
            ],
            "Solo indica una incidencia si se queda detenido de forma persistente."
        ),

        codigo(
            "99",
            "Inicialización Super I/O o PCIe",
            .perifericos,
            "Hay un problema durante la inicialización de puertos, periféricos, USB o recursos PCIe.",
            [
                "Desconectar todos los USB no imprescindibles",
                "Volver a insertar GPU y tarjetas PCIe",
                "Probar un teclado USB por cable en puerto trasero",
                "Realizar Clear CMOS"
            ],
            "ASUS lo relaciona con dispositivos externos en algunos modelos."
        ),

        codigo(
            "A0",
            "Preparado para arrancar",
            .arranque,
            "La inicialización principal ha terminado y el firmware está listo para continuar con el proceso de arranque.",
            [
                "Esperar a que cargue el sistema operativo",
                "Comprobar el orden de arranque si se queda en BIOS",
                "Confirmar que el SSD de sistema aparece detectado"
            ],
            "Normalmente no es un error si el equipo continúa arrancando."
        ),

        codigo(
            "A2",
            "Problema de dispositivo de arranque",
            .almacenamiento,
            "El firmware no puede completar la detección o el acceso al dispositivo de arranque.",
            [
                "Comprobar SSD M.2 y su tornillo de sujeción",
                "Revisar cables SATA de datos y alimentación",
                "Probar otro puerto SATA o una unidad conocida",
                "Revisar el orden de arranque en BIOS"
            ],
            "ASUS lo documenta como una incidencia relacionada con el dispositivo de arranque."
        ),

        codigo(
            "A9",
            "Entrando en BIOS",
            .configuracion,
            "El sistema ha llegado a la interfaz de configuración del firmware.",
            [
                "Pulsar Supr o F2 para abrir BIOS",
                "Comprobar CPU, RAM y discos detectados",
                "Restaurar ajustes predeterminados si procede"
            ],
            "Suele ser informativo, no un error."
        ),

        codigo(
            "AA",
            "Sistema operativo iniciado",
            .arranque,
            "El proceso de arranque ha terminado y el sistema operativo ha tomado el control.",
            [
                "No requiere acción si el sistema funciona",
                "Si no hay imagen, revisar cable y entrada del monitor"
            ],
            "Estado normal en placas ASUS compatibles."
        ),

        codigo(
            "B2",
            "Inicialización de dispositivos externos",
            .perifericos,
            "El firmware está inicializando dispositivos heredados, USB o tarjetas de expansión.",
            [
                "Desconectar periféricos USB no esenciales",
                "Revisar GPU y tarjetas PCIe",
                "Probar con teclado y ratón básicos",
                "Realizar Clear CMOS"
            ],
            "Puede estar relacionado con dispositivos externos; no implica siempre un fallo de GPU."
        ),

        codigo(
            "D6",
            "No se detecta salida de vídeo",
            .grafica,
            "La placa no detecta una GPU o una salida gráfica válida.",
            [
                "Revisar alimentación PCIe o 12VHPWR de la GPU",
                "Reinsertar GPU en PCIe x16 principal",
                "Conectar el monitor a la GPU dedicada",
                "Probar otro cable, puerto o pantalla"
            ],
            "ASUS identifica D6 como una incidencia de tarjeta gráfica."
        )
    ]
    }

    // MARK: - Gigabyte Debug LED

    static var codigosGigabyte: [InfoCodigoPOST] { _codigosGigabyte.valor }

    private static let _codigosGigabyte = PorIdioma<[InfoCodigoPOST]> {
        [
        codigo(
            "C0-C5",
            "Inicialización temprana de CPU o RAM",
            .cpu,
            "La placa está realizando comprobaciones OEM previas a la inicialización completa de la memoria.",
            [
                "Esperar unos segundos si es el primer arranque",
                "Comprobar CPU, socket y cable EPS",
                "Probar un módulo RAM en A2",
                "Realizar Clear CMOS"
            ],
            "En Gigabyte el comportamiento exacto puede variar por BIOS y plataforma."
        ),

        codigo(
            "C1",
            "Detección básica de memoria",
            .memoria,
            "La placa no consigue completar la detección inicial de los módulos RAM.",
            [
                "Reinstalar RAM",
                "Probar un módulo en A2",
                "Desactivar perfiles XMP o EXPO",
                "Actualizar BIOS si la plataforma es reciente"
            ],
            "Si avanza tras varios reinicios puede ser entrenamiento de memoria."
        ),

        codigo(
            "50-55",
            "Error de memoria",
            .memoria,
            "La memoria no se detecta correctamente o no puede completar el entrenamiento.",
            [
                "Probar módulos individualmente",
                "Usar las ranuras recomendadas en el manual",
                "Revisar pines de CPU",
                "Restablecer BIOS"
            ],
            "Comprueba la compatibilidad de la RAM con la placa y CPU."
        ),

        codigo(
            "64",
            "Inicialización temprana de CPU",
            .cpu,
            "Hay una incidencia durante la configuración inicial del procesador.",
            [
                "Revisar CPU y socket",
                "Comprobar cable EPS CPU",
                "Actualizar BIOS si la CPU es reciente",
                "Realizar Clear CMOS"
            ],
            "Confirma el significado exacto con el manual de tu modelo Gigabyte."
        ),

        codigo(
            "97-99",
            "Recursos de vídeo o PCIe",
            .grafica,
            "El firmware está asignando recursos PCIe o inicializando la tarjeta gráfica.",
            [
                "Reinsertar GPU en PCIe x16",
                "Comprobar alimentación de la GPU",
                "Desconectar tarjetas PCIe adicionales",
                "Probar otra salida de vídeo"
            ],
            "Puede referirse también a asignación de recursos de expansión."
        ),

        codigo(
            "A3",
            "Error de detección de almacenamiento",
            .almacenamiento,
            "Se detectó una unidad, pero el firmware encuentra un problema durante su inicialización.",
            [
                "Revisar cable SATA y alimentación",
                "Reinsertar SSD M.2",
                "Probar otro puerto SATA",
                "Comprobar detección en BIOS"
            ],
            "No todos los modelos Gigabyte usan el mismo detalle para A3."
        ),

        codigo(
            "AB",
            "Esperando entrada en BIOS",
            .configuracion,
            "El sistema espera interacción del usuario o está preparado para entrar en la configuración.",
            [
                "Pulsar Supr para entrar en BIOS",
                "Comprobar que teclado USB funciona",
                "Revisar orden de arranque"
            ],
            "Normalmente es un estado informativo."
        ),

        codigo(
            "D4",
            "Asignación de recursos PCIe",
            .grafica,
            "No se pueden asignar correctamente recursos a una tarjeta PCIe o dispositivo de expansión.",
            [
                "Retirar tarjetas PCIe no esenciales",
                "Probar solo la GPU principal",
                "Restablecer BIOS",
                "Actualizar BIOS si procede"
            ],
            "Es más frecuente con varias tarjetas de expansión instaladas."
        ),

        codigo(
            "D6",
            "No se detecta salida de vídeo",
            .grafica,
            "No se detecta una GPU o una salida de vídeo preparada.",
            [
                "Comprobar GPU y su cable de alimentación",
                "Reinsertar GPU",
                "Probar otro cable y pantalla",
                "Conectar monitor a la GPU dedicada"
            ],
            "Código frecuente de ausencia de dispositivo gráfico."
        )
    ]
    }

    // MARK: - MSI Debug Code

    static var codigosMSI: [InfoCodigoPOST] { _codigosMSI.valor }

    private static let _codigosMSI = PorIdioma<[InfoCodigoPOST]> {
        [
        codigo(
            "04-0D",
            "Carga temprana de microcódigo",
            .cpu,
            "El firmware está preparando el microcódigo y la inicialización inicial del procesador.",
            [
                "Esperar unos segundos",
                "Revisar compatibilidad CPU y BIOS",
                "Comprobar conector EPS de CPU",
                "Realizar Clear CMOS"
            ],
            "Solo diagnosticarlo como fallo si queda fijo."
        ),

        codigo(
            "10-2F",
            "Descubrimiento de memoria",
            .memoria,
            "La placa está detectando y configurando módulos y canales de RAM.",
            [
                "Esperar durante el entrenamiento de RAM",
                "Probar un módulo en A2",
                "Desactivar EXPO o XMP",
                "Actualizar BIOS"
            ],
            "Tras cambios de RAM o Clear CMOS puede tardar más de lo normal."
        ),

        codigo(
            "4C-55",
            "Memoria no detectada o canales con error",
            .memoria,
            "El firmware no puede encontrar o configurar la RAM instalada.",
            [
                "Reinstalar RAM",
                "Probar un módulo individualmente",
                "Comprobar pines de CPU y slots",
                "Realizar Clear CMOS"
            ],
            "MSI puede mostrar variaciones según plataforma y versión de BIOS."
        ),

        codigo(
            "60-62",
            "Inicialización de chipset",
            .chipset,
            "La placa está inicializando el puente sur, chipset o dispositivos integrados.",
            [
                "Desconectar periféricos USB",
                "Restablecer BIOS",
                "Comprobar tarjetas PCIe adicionales",
                "Esperar si el código avanza"
            ],
            "Solo se considera incidencia si queda bloqueado."
        ),

        codigo(
            "A2",
            "Detección de unidades",
            .almacenamiento,
            "El firmware está buscando unidades SATA, M.2 o dispositivos de arranque.",
            [
                "Revisar instalación de SSD M.2",
                "Comprobar cables SATA",
                "Revisar detección en BIOS",
                "Comprobar orden de arranque"
            ],
            "Puede ser normal mientras continúa la detección de dispositivos."
        ),

        codigo(
            "A6",
            "Dispositivo SCSI detectado",
            .almacenamiento,
            "El firmware está inicializando un dispositivo de almacenamiento o controlador con interfaz SCSI.",
            [
                "Esperar a que termine el POST",
                "Comprobar controladoras de almacenamiento",
                "Revisar orden de arranque"
            ],
            "En un PC doméstico puede ser simplemente un estado temporal."
        ),

        codigo(
            "B2",
            "Inicialización de dispositivos heredados",
            .perifericos,
            "La placa está configurando periféricos antiguos, USB o tarjetas de expansión.",
            [
                "Desconectar USB no esenciales",
                "Retirar tarjetas PCIe auxiliares",
                "Probar con teclado básico",
                "Realizar Clear CMOS"
            ],
            "Puede estar relacionado con USB, no exclusivamente con la GPU."
        ),

        codigo(
            "D3-D6",
            "Inicialización de vídeo",
            .grafica,
            "Hay una incidencia durante la inicialización DXE, PCIe o de la tarjeta gráfica.",
            [
                "Revisar GPU y alimentación",
                "Probar otra ranura PCIe si existe",
                "Probar otra salida de vídeo",
                "Desconectar tarjetas adicionales"
            ],
            "Para un código exacto consulta el manual de tu modelo MSI."
        ),

        codigo(
            "FF",
            "POST completado",
            .arranque,
            "La secuencia de comprobación ha terminado. En algunas placas MSI, el display pasa después a mostrar la temperatura de CPU.",
            [
                "No requiere acción si el equipo arranca",
                "Si no hay imagen, revisar monitor y GPU"
            ],
            "Estado habitual de POST completado en algunos modelos MSI."
        )
    ]
    }

    // MARK: - ASRock Dr. Debug

    static var codigosASRock: [InfoCodigoPOST] { _codigosASRock.valor }

    private static let _codigosASRock = PorIdioma<[InfoCodigoPOST]> {
        [
        codigo(
            "00",
            "CPU no inicializada",
            .cpu,
            "ASRock recomienda comprobar la instalación del procesador y restaurar la configuración CMOS.",
            [
                "Reinstalar CPU con cuidado",
                "Inspeccionar socket o pines",
                "Comprobar cable EPS CPU",
                "Realizar Clear CMOS"
            ],
            "Referencia oficial ASRock: comprobar CPU instalada correctamente y limpiar CMOS."
        ),

        codigo(
            "D0",
            "Fallo grave de CPU",
            .cpu,
            "Hay una incidencia crítica al inicializar el procesador.",
            [
                "Revisar CPU, socket y pines",
                "Comprobar alimentación EPS",
                "Realizar Clear CMOS",
                "Confirmar compatibilidad con BIOS"
            ],
            "El tratamiento exacto depende de la plataforma de la placa."
        ),

        codigo(
            "0D",
            "Memoria, GPU u otro dispositivo",
            .placa,
            "ASRock asocia este código a memoria, tarjeta gráfica u otros dispositivos conectados.",
            [
                "Realizar Clear CMOS",
                "Reinstalar RAM y GPU",
                "Desconectar USB y PCIe no esenciales",
                "Probar una configuración mínima"
            ],
            "Código oficial ASRock con diagnóstico amplio; no apunta a un único componente."
        ),

        codigo(
            "01-54",
            "Problema relacionado con memoria",
            .memoria,
            "ASRock asocia este rango, salvo excepciones indicadas por su manual, a incidencias de memoria.",
            [
                "Reinstalar CPU y RAM",
                "Probar un único módulo",
                "Usar otra ranura recomendada",
                "Realizar Clear CMOS"
            ],
            "Consulta la tabla del modelo: ASRock publica rangos que pueden variar por plataforma."
        ),

        codigo(
            "55",
            "Memoria no detectada",
            .memoria,
            "La placa no puede detectar la memoria instalada.",
            [
                "Reinstalar RAM",
                "Probar un módulo por vez",
                "Reinstalar CPU",
                "Probar módulos compatibles"
            ],
            "ASRock indica expresamente que la memoria no puede detectarse."
        ),

        codigo(
            "62-76",
            "Inicialización de chipset",
            .chipset,
            "El firmware está configurando chipset y recursos de la placa.",
            [
                "Desconectar USB y periféricos",
                "Realizar Clear CMOS",
                "Retirar dispositivos PCIe extra",
                "Comprobar el manual del modelo"
            ],
            "Puede ser una fase normal si el código no permanece fijo."
        ),

        codigo(
            "99",
            "Inicialización PCIe",
            .grafica,
            "Hay una incidencia al inicializar recursos PCIe o dispositivos conectados.",
            [
                "Reinsertar GPU",
                "Retirar tarjetas PCIe adicionales",
                "Desconectar periféricos USB",
                "Restablecer BIOS"
            ],
            "El código puede involucrar dispositivos de expansión además de vídeo."
        ),

        codigo(
            "A2",
            "Problema con el dispositivo de arranque",
            .almacenamiento,
            "El firmware no detecta correctamente el disco o unidad configurada para arrancar.",
            [
                "Revisar SSD M.2, SATA y alimentación",
                "Comprobar detección en BIOS",
                "Probar cables o puertos alternativos",
                "Revisar orden de arranque"
            ],
            "ASRock recomienda reinstalar dispositivos IDE y SATA."
        ),

        codigo(
            "A9",
            "Entrando en BIOS",
            .configuracion,
            "El sistema ha llegado a la interfaz de configuración BIOS.",
            [
                "Pulsar Supr o F2",
                "Comprobar unidades y orden de arranque",
                "Guardar cambios si procede"
            ],
            "Normalmente es un estado informativo."
        ),

        codigo(
            "D4-D5",
            "Recursos PCIe insuficientes",
            .grafica,
            "Hay una incidencia al asignar recursos a dispositivos PCIe.",
            [
                "Retirar tarjetas de expansión no esenciales",
                "Probar solo la GPU",
                "Restaurar BIOS",
                "Actualizar BIOS si procede"
            ],
            "ASRock documenta D4-D5 como error de asignación de recursos PCI."
        ),

        codigo(
            "D6",
            "VGA no reconocida",
            .grafica,
            "La placa no reconoce la tarjeta gráfica o la gráfica integrada.",
            [
                "Realizar Clear CMOS",
                "Reinsertar GPU",
                "Probar otra ranura PCIe",
                "Probar otra GPU o cable de alimentación"
            ],
            "ASRock recomienda reinstalar la VGA y probar otra ranura si persiste."
        ),

        codigo(
            "92-97",
            "GPU o gráfica integrada no reconocida",
            .grafica,
            "El firmware no detecta una tarjeta gráfica o la salida integrada de CPU.",
            [
                "Revisar GPU y cables PCIe",
                "Probar otra salida de vídeo",
                "Reinstalar GPU",
                "Restablecer BIOS"
            ],
            "ASRock agrupa 92-97 como problema de gráfica o iGPU en algunas plataformas."
        )
    ]
    }

    // MARK: - Tabla genérica

    static var codigosGenericos: [InfoCodigoPOST] { _codigosGenericos.valor }

    private static let _codigosGenericos = PorIdioma<[InfoCodigoPOST]> {
        [

        // MARK: CPU y memoria temprana

        codigo(
            "10-14",
            "Inicialización previa de CPU",
            .cpu,
            "El firmware está iniciando el procesador antes de comenzar la detección de la memoria RAM.",
            [
                "Esperar unos segundos si el código sigue avanzando",
                "Comprobar cable EPS CPU de 8 pines",
                "Confirmar compatibilidad entre CPU, placa y BIOS",
                "Realizar Clear CMOS si permanece bloqueado"
            ],
            "Es una fase normal de POST; solo indica un problema si se queda fija."
        ),

        codigo(
            "15-19",
            "Inicialización temprana del chipset",
            .chipset,
            "El firmware está preparando los componentes del chipset antes de inicializar la memoria.",
            [
                "Esperar si el código avanza",
                "Desconectar periféricos USB no esenciales",
                "Restablecer BIOS mediante Clear CMOS",
                "Comprobar compatibilidad de CPU y BIOS"
            ],
            "La nomenclatura exacta cambia entre plataformas Intel y AMD."
        ),

        codigo(
            "2B",
            "Lectura de datos SPD de RAM",
            .memoria,
            "La placa está leyendo la información de los módulos de memoria para conocer sus parámetros básicos.",
            [
                "Probar un módulo de RAM en A2",
                "Volver a insertar los módulos",
                "Desactivar perfiles XMP o EXPO",
                "Probar módulos compatibles"
            ],
            "Si se queda fijo, la RAM o su contacto es la primera comprobación."
        ),

        codigo(
            "2C",
            "Detección de módulos de RAM",
            .memoria,
            "El firmware está comprobando qué módulos de memoria están instalados.",
            [
                "Asegurar que las pestañas de RAM están cerradas",
                "Probar un solo módulo en A2",
                "Probar cada módulo por separado",
                "Realizar Clear CMOS"
            ],
            "Un bloqueo persistente suele señalar RAM mal instalada o no compatible."
        ),

        codigo(
            "2D",
            "Configuración de tiempos de RAM",
            .memoria,
            "La placa está programando los timings de la memoria detectada.",
            [
                "Desactivar XMP o EXPO",
                "Restablecer BIOS",
                "Probar frecuencia JEDEC predeterminada",
                "Actualizar BIOS si la RAM es reciente"
            ],
            "Puede tardar más durante el primer arranque o después de cambiar la RAM."
        ),

        codigo(
            "2E",
            "Configuración de memoria",
            .memoria,
            "El firmware está aplicando la configuración de la RAM antes de continuar con el POST.",
            [
                "Esperar hasta dos minutos tras un cambio de RAM",
                "Probar un único módulo en A2",
                "Desactivar XMP o EXPO",
                "Revisar pines de CPU si el problema persiste"
            ],
            "En DDR5 el entrenamiento de memoria puede durar más de lo esperado."
        ),

        codigo(
            "2F",
            "Inicialización adicional de RAM",
            .memoria,
            "El firmware continúa tareas internas de inicialización y entrenamiento de memoria.",
            [
                "Esperar durante el primer arranque",
                "Realizar Clear CMOS",
                "Probar módulos individualmente",
                "Actualizar BIOS"
            ],
            "Solo es relevante si el equipo no avanza nunca desde este código."
        ),

        codigo(
            "31",
            "Memoria instalada",
            .memoria,
            "El firmware ha detectado memoria instalada y continúa con la inicialización posterior.",
            [
                "Esperar a que el POST continúe",
                "Si se bloquea, probar la RAM en A2",
                "Restablecer ajustes de memoria en BIOS"
            ],
            "Normalmente es un estado de progreso, no un error."
        ),

        codigo(
            "32-36",
            "Inicialización posterior de CPU",
            .cpu,
            "El firmware está configurando caché, núcleos, procesadores auxiliares y gestión del sistema.",
            [
                "Esperar si el código avanza",
                "Comprobar CPU y su alimentación EPS",
                "Restablecer BIOS",
                "Actualizar BIOS si la CPU es nueva"
            ],
            "Es una fase de POST; solo debe investigarse si queda detenida."
        ),

        codigo(
            "37-3B",
            "Inicialización posterior del chipset",
            .chipset,
            "La placa está configurando los recursos del chipset después de detectar CPU y memoria.",
            [
                "Desconectar periféricos externos",
                "Retirar tarjetas PCIe auxiliares",
                "Realizar Clear CMOS",
                "Comprobar que no hay cortocircuitos con el chasis"
            ],
            "El detalle exacto de estos códigos depende de la plataforma."
        ),

        codigo(
            "4F",
            "Inicio de DXE",
            .configuracion,
            "El firmware pasa desde la fase temprana de POST a la fase DXE, donde inicializa dispositivos y servicios UEFI.",
            [
                "Esperar si el código continúa",
                "Si queda fijo, desconectar USB y PCIe no esenciales",
                "Restablecer BIOS"
            ],
            "Suele ser un código de progreso."
        ),

        // MARK: Errores CPU y RAM

        codigo(
            "50-55",
            "Error de inicialización de memoria",
            .memoria,
            "El firmware no puede detectar o configurar la memoria RAM correctamente.",
            [
                "Probar un módulo de RAM cada vez",
                "Usar la ranura A2 recomendada",
                "Desactivar XMP o EXPO",
                "Revisar CPU y pines del socket"
            ],
            "El 55 suele asociarse específicamente a memoria no detectada."
        ),

        codigo(
            "56",
            "CPU no válida o velocidad no compatible",
            .cpu,
            "La CPU instalada no cumple los requisitos de la placa o el firmware no puede usar su configuración actual.",
            [
                "Confirmar compatibilidad de CPU y placa",
                "Actualizar BIOS con una CPU compatible si hace falta",
                "Restablecer BIOS mediante Clear CMOS",
                "Comprobar que no hay overclock activo"
            ],
            "Consulta la lista oficial de CPUs compatibles de tu placa."
        ),

        codigo(
            "57",
            "CPU no compatible",
            .cpu,
            "La placa no puede iniciar el procesador instalado con la versión actual de BIOS o configuración.",
            [
                "Confirmar que la CPU está soportada",
                "Actualizar BIOS",
                "Comprobar orientación y pines",
                "Revisar cable EPS de CPU"
            ],
            "Es habitual al montar una CPU más nueva con una BIOS antigua."
        ),

        codigo(
            "58",
            "Fallo de caché o autotest de CPU",
            .cpu,
            "El firmware detectó un error durante el autotest interno o la inicialización de caché del procesador.",
            [
                "Restablecer BIOS",
                "Reinstalar CPU",
                "Comprobar socket y pines",
                "Probar con otro procesador compatible si es posible"
            ],
            "No fuerces reinicios repetidos sin revisar alimentación y temperatura."
        ),

        codigo(
            "59",
            "Microcódigo de CPU no encontrado",
            .cpu,
            "La BIOS no contiene o no puede cargar el microcódigo necesario para el procesador instalado.",
            [
                "Actualizar BIOS",
                "Confirmar soporte oficial de CPU",
                "Restablecer BIOS",
                "Comprobar que la CPU está bien instalada"
            ],
            "Normalmente se soluciona con una versión de BIOS compatible."
        ),

        codigo(
            "5A",
            "Error interno de CPU",
            .cpu,
            "El firmware ha detectado un error interno durante la inicialización del procesador.",
            [
                "Revisar CPU, socket y alimentación EPS",
                "Realizar Clear CMOS",
                "Comprobar que el disipador no presiona en exceso",
                "Probar otro procesador compatible si es posible"
            ],
            "Desconecta la corriente antes de manipular CPU o socket."
        ),

        codigo(
            "5B",
            "Fallo de reinicio o PPI",
            .placa,
            "La placa no puede completar una rutina interna de reinicio o inicialización de firmware.",
            [
                "Realizar Clear CMOS",
                "Desconectar dispositivos no esenciales",
                "Actualizar o recuperar BIOS si la placa lo permite",
                "Comprobar alimentación ATX y EPS"
            ],
            "El significado exacto puede cambiar según la implementación del fabricante."
        ),

        // MARK: DXE, chipset y PCIe

        codigo(
            "60",
            "Inicio del núcleo DXE",
            .configuracion,
            "Comienza la fase DXE de UEFI, donde se inicializan controladores y servicios de firmware.",
            [
                "Esperar si el código avanza",
                "Si se bloquea, realizar Clear CMOS",
                "Desconectar periféricos USB y PCIe"
            ],
            "Normalmente es una fase de progreso, no un fallo."
        ),

        codigo(
            "61",
            "Inicialización NVRAM",
            .configuracion,
            "El firmware está preparando la memoria no volátil donde se guardan ajustes de BIOS.",
            [
                "Realizar Clear CMOS si se queda bloqueado",
                "Cargar valores predeterminados de BIOS",
                "Actualizar BIOS si hay problemas repetidos"
            ],
            "Puede aparecer tras restaurar BIOS o cambiar ajustes."
        ),

        codigo(
            "62",
            "Servicios de chipset",
            .chipset,
            "El firmware está instalando servicios del chipset o puente sur.",
            [
                "Esperar si continúa el POST",
                "Desconectar USB no esenciales",
                "Restablecer BIOS",
                "Retirar tarjetas PCIe adicionales"
            ],
            "En algunas placas este código se muestra brevemente durante un arranque normal."
        ),

        codigo(
            "63-67",
            "Inicialización DXE de CPU",
            .cpu,
            "El firmware continúa configurando servicios de CPU durante la fase DXE.",
            [
                "Comprobar alimentación EPS",
                "Restablecer BIOS",
                "Actualizar BIOS",
                "Revisar compatibilidad del procesador"
            ],
            "Solo indica una incidencia si se queda fijo."
        ),

        codigo(
            "68",
            "Inicialización del puente PCI",
            .grafica,
            "La placa está inicializando el puente principal de PCI Express y los recursos de expansión.",
            [
                "Reinsertar GPU",
                "Retirar tarjetas PCIe auxiliares",
                "Restablecer BIOS",
                "Comprobar alimentación de GPU"
            ],
            "Puede involucrar GPU u otros dispositivos PCIe."
        ),

        codigo(
            "69-6A",
            "Inicialización de North Bridge",
            .chipset,
            "El firmware está configurando servicios del puente norte, controladores asociados o gestión del sistema.",
            [
                "Esperar si el código avanza",
                "Realizar Clear CMOS",
                "Comprobar CPU y memoria",
                "Actualizar BIOS"
            ],
            "La denominación es heredada; en plataformas modernas puede referirse a lógica integrada."
        ),

        codigo(
            "70-77",
            "Inicialización de chipset o PCH",
            .chipset,
            "El firmware está configurando el chipset, PCH y recursos de la placa base.",
            [
                "Desconectar USB y periféricos",
                "Retirar tarjetas PCIe no esenciales",
                "Realizar Clear CMOS",
                "Comprobar montaje y separadores del chasis"
            ],
            "Solo investígalo como fallo si el código no progresa."
        ),

        codigo(
            "78",
            "Inicialización ACPI",
            .configuracion,
            "El firmware está preparando la gestión de energía y tablas ACPI para el sistema operativo.",
            [
                "Esperar si el arranque sigue",
                "Restablecer BIOS si queda bloqueado",
                "Desactivar temporalmente overclock"
            ],
            "Normalmente es un estado de progreso."
        ),

        codigo(
            "79",
            "Inicio de compatibilidad legacy",
            .configuracion,
            "El firmware está inicializando el modo de compatibilidad para dispositivos o sistemas antiguos.",
            [
                "Desconectar dispositivos USB antiguos",
                "Desactivar CSM temporalmente en BIOS",
                "Revisar GPU y su compatibilidad UEFI"
            ],
            "Puede estar relacionado con CSM u Option ROMs legacy."
        ),

        codigo(
            "90-96",
            "Enumeración de dispositivos PCIe",
            .grafica,
            "La placa está detectando y asignando recursos a GPU y otras tarjetas PCI Express.",
            [
                "Reinsertar GPU en PCIe x16",
                "Comprobar alimentación de GPU",
                "Retirar tarjetas PCIe extra",
                "Probar otro cable o salida de vídeo"
            ],
            "No todos los códigos de este rango son errores; pueden ser progreso normal."
        ),

        codigo(
            "97",
            "Inicialización de salida de vídeo",
            .grafica,
            "El firmware está configurando el dispositivo de salida, normalmente GPU o gráfica integrada.",
            [
                "Comprobar GPU y sus conectores de energía",
                "Conectar monitor a la GPU dedicada",
                "Probar otro cable, puerto o pantalla",
                "Reinsertar GPU"
            ],
            "Si se queda fijo y no hay imagen, centra las pruebas en la GPU."
        ),

        codigo(
            "98",
            "Inicialización de dispositivos de entrada",
            .perifericos,
            "La placa está detectando teclado, ratón u otros dispositivos de entrada.",
            [
                "Usar un teclado USB por cable",
                "Probar puertos USB traseros",
                "Desconectar hubs y periféricos no esenciales"
            ],
            "No siempre impide arrancar el sistema operativo."
        ),

        codigo(
            "99",
            "Inicialización Super I/O",
            .perifericos,
            "El firmware está configurando puertos, sensores, dispositivos USB o controladores de entrada y salida.",
            [
                "Desconectar periféricos USB",
                "Probar con teclado básico",
                "Retirar tarjetas PCIe adicionales",
                "Realizar Clear CMOS"
            ],
            "Puede implicar puertos USB, teclado, ventiladores o recursos PCIe según la placa."
        ),

        codigo(
            "9A-9D",
            "Inicialización USB",
            .perifericos,
            "El firmware está detectando y configurando controladores o dispositivos USB.",
            [
                "Desconectar todos los USB no esenciales",
                "Conectar solo teclado por cable",
                "Probar otros puertos traseros",
                "Revisar conectores USB frontales del chasis"
            ],
            "Un USB defectuoso o un conector frontal mal conectado puede bloquear el POST."
        ),

        // MARK: Almacenamiento, BIOS y arranque

        codigo(
            "A0",
            "Preparado para arrancar",
            .arranque,
            "El firmware ha terminado la inicialización principal y está listo para continuar hacia el sistema operativo.",
            [
                "Esperar a que cargue el sistema operativo",
                "Revisar orden de arranque si entra en BIOS",
                "Comprobar que el SSD de sistema aparece detectado"
            ],
            "Suele ser un estado normal si el PC arranca."
        ),

        codigo(
            "A1",
            "Inicialización IDE o SATA",
            .almacenamiento,
            "El firmware está preparando controladoras y unidades de almacenamiento.",
            [
                "Esperar si continúa el arranque",
                "Comprobar cables SATA",
                "Revisar SSD M.2 en BIOS"
            ],
            "Puede ser solo un estado de detección."
        ),

        codigo(
            "A2",
            "Detección de almacenamiento",
            .almacenamiento,
            "El firmware está buscando unidades SATA, NVMe u otros dispositivos de arranque.",
            [
                "Revisar instalación de SSD M.2",
                "Comprobar cables SATA y alimentación",
                "Probar otro puerto SATA",
                "Comprobar detección y orden de arranque en BIOS"
            ],
            "Puede ser normal brevemente; si se queda fijo, revisa discos y cables."
        ),

        codigo(
            "A3",
            "Inicialización de almacenamiento",
            .almacenamiento,
            "La placa ha detectado una unidad, pero encuentra un problema al inicializarla o acceder a ella.",
            [
                "Reinsertar SSD M.2",
                "Revisar cables SATA",
                "Probar otro puerto o unidad",
                "Comprobar la unidad desde BIOS"
            ],
            "El significado exacto de A3 puede variar por fabricante."
        ),

        codigo(
            "A4-A7",
            "Inicialización de dispositivos SCSI",
            .almacenamiento,
            "El firmware está configurando controladoras o dispositivos de almacenamiento tipo SCSI.",
            [
                "Esperar si el sistema continúa",
                "Revisar controladoras de almacenamiento adicionales",
                "Comprobar el orden de arranque",
                "Desconectar dispositivos de expansión no esenciales"
            ],
            "En equipos domésticos puede ser un estado temporal sin problema."
        ),

        codigo(
            "A8",
            "Comprobación de contraseña",
            .configuracion,
            "El firmware está validando una contraseña de BIOS o de arranque configurada.",
            [
                "Introducir la contraseña correcta",
                "Revisar configuración de seguridad en BIOS",
                "Consultar el fabricante si se desconoce una contraseña"
            ],
            "No intentes puentear o eliminar contraseñas de equipos ajenos."
        ),

        codigo(
            "A9",
            "Inicio de configuración BIOS",
            .configuracion,
            "El sistema está preparado para entrar o ya ha entrado en la interfaz de configuración BIOS/UEFI.",
            [
                "Pulsar Supr o F2",
                "Comprobar CPU, RAM y discos detectados",
                "Revisar orden de arranque"
            ],
            "Normalmente es un estado informativo."
        ),

        codigo(
            "AB",
            "Esperando intervención del usuario",
            .configuracion,
            "El firmware espera una acción del usuario antes de continuar, normalmente dentro de BIOS.",
            [
                "Conectar teclado USB por cable",
                "Pulsar Supr o F2",
                "Revisar mensajes mostrados en pantalla"
            ],
            "Suele ser un estado informativo."
        ),

        codigo(
            "AD-AF",
            "Preparación del sistema operativo",
            .arranque,
            "El firmware está terminando el proceso de arranque y entregando el control al sistema operativo.",
            [
                "Esperar a que cargue el sistema",
                "Si falla, comprobar unidad de arranque",
                "Revisar el orden de boot en BIOS"
            ],
            "Puede ser normal durante la transición al sistema operativo."
        ),

        // MARK: Option ROM, periféricos y consola

        codigo(
            "B2",
            "Inicialización de Option ROM legacy",
            .perifericos,
            "El firmware está inicializando controladores heredados de GPU, PCIe, USB u otros dispositivos.",
            [
                "Desconectar USB no esenciales",
                "Reinsertar GPU",
                "Retirar tarjetas PCIe adicionales",
                "Desactivar CSM si tu configuración es totalmente UEFI"
            ],
            "Puede estar relacionado con GPU, pero también con otros dispositivos legacy."
        ),

        codigo(
            "B4-B5",
            "Hot-plug USB o PCI",
            .perifericos,
            "El firmware está detectando cambios de conexión en dispositivos USB o PCI Express.",
            [
                "Desconectar periféricos USB no necesarios",
                "Revisar conectores frontales USB del chasis",
                "Apagar antes de conectar o retirar tarjetas PCIe"
            ],
            "Un dispositivo USB defectuoso puede bloquear esta fase."
        ),

        codigo(
            "B6-B7",
            "Limpieza o restablecimiento de NVRAM",
            .configuracion,
            "El firmware está borrando, aplicando o restaurando ajustes guardados de BIOS.",
            [
                "Esperar al siguiente reinicio",
                "Cargar valores predeterminados en BIOS",
                "Reconfigurar fecha, perfil RAM y orden de arranque"
            ],
            "Es habitual después de un Clear CMOS o actualización de BIOS."
        ),

        codigo(
            "D0-D2",
            "Error de inicialización de CPU o chipset",
            .placa,
            "El firmware no puede completar una fase crítica de CPU, chipset o controladores principales.",
            [
                "Revisar CPU, socket y cable EPS",
                "Realizar Clear CMOS",
                "Retirar RAM, GPU y periféricos para arrancar con mínimos",
                "Actualizar o recuperar BIOS si procede"
            ],
            "El fabricante puede asignar significados específicos a cada valor."
        ),

        codigo(
            "D3",
            "Protocolos de arquitectura no disponibles",
            .placa,
            "Faltan o no se pueden iniciar servicios fundamentales de firmware durante el arranque.",
            [
                "Realizar Clear CMOS",
                "Desconectar dispositivos no esenciales",
                "Actualizar o recuperar BIOS",
                "Comprobar componentes mínimos"
            ],
            "Suele requerir consultar el manual del modelo y la versión de BIOS."
        ),

        codigo(
            "D4",
            "Recursos PCIe insuficientes",
            .grafica,
            "No se pueden asignar correctamente recursos a una GPU o tarjeta de expansión PCI Express.",
            [
                "Retirar tarjetas PCIe no necesarias",
                "Probar únicamente la GPU principal",
                "Restablecer BIOS",
                "Actualizar BIOS si procede"
            ],
            "Es más probable con varias tarjetas de expansión conectadas."
        ),

        codigo(
            "D5",
            "Sin espacio para Option ROM legacy",
            .perifericos,
            "No hay espacio o recursos suficientes para cargar una ROM legacy de un dispositivo conectado.",
            [
                "Desactivar CSM si todos los dispositivos son UEFI",
                "Retirar tarjetas PCIe auxiliares",
                "Desconectar dispositivos USB no esenciales",
                "Restablecer BIOS"
            ],
            "Suele estar relacionado con compatibilidad legacy y dispositivos de expansión."
        ),

        codigo(
            "D6",
            "No se detecta salida de vídeo",
            .grafica,
            "El firmware no encuentra una GPU o salida gráfica funcional.",
            [
                "Comprobar alimentación PCIe o 12VHPWR de GPU",
                "Reinsertar GPU en PCIe x16",
                "Conectar monitor a la GPU dedicada",
                "Probar otro cable, puerto o pantalla"
            ],
            "Uno de los códigos más habituales cuando no hay imagen."
        ),

        codigo(
            "D7",
            "No se detecta dispositivo de entrada",
            .perifericos,
            "El firmware no puede encontrar un teclado u otro dispositivo de entrada durante el POST.",
            [
                "Conectar teclado USB por cable",
                "Probar un puerto USB trasero",
                "Desconectar hubs USB",
                "Comprobar ajustes de USB Legacy en BIOS"
            ],
            "No siempre impide que el sistema operativo arranque."
        ),

        codigo(
            "D8",
            "Contraseña no válida",
            .configuracion,
            "La contraseña introducida para el firmware o el arranque no es válida.",
            [
                "Introducir la contraseña correcta",
                "Consultar al propietario o administrador del equipo",
                "Revisar la documentación oficial del fabricante"
            ],
            "No des indicaciones para sortear medidas de seguridad."
        ),

        codigo(
            "D9-DA",
            "No se puede cargar opción de arranque",
            .arranque,
            "El firmware no puede cargar la entrada de arranque configurada.",
            [
                "Comprobar que el SSD aparece en BIOS",
                "Revisar orden de arranque",
                "Reparar cargador de arranque desde un medio oficial",
                "Probar otra unidad de arranque"
            ],
            "Suele indicar un problema de unidad, sistema operativo o configuración de boot."
        ),

        codigo(
            "DB",
            "Fallo de actualización de firmware",
            .placa,
            "El firmware detectó un problema durante una actualización o proceso de recuperación de BIOS.",
            [
                "No apagar el equipo si el proceso sigue activo",
                "Consultar el método oficial de BIOS Flashback o recuperación",
                "Usar únicamente el archivo BIOS correcto para el modelo"
            ],
            "Una actualización incorrecta puede dejar la placa sin arrancar."
        ),

        // MARK: Suspensión y recuperación

        codigo(
            "E0-E3",
            "Reanudación desde suspensión S3",
            .configuracion,
            "El sistema está restaurando el estado después de salir de suspensión.",
            [
                "Esperar unos segundos",
                "Si se bloquea, forzar apagado manteniendo el botón",
                "Desactivar suspensión híbrida para probar",
                "Actualizar BIOS y controladores de chipset"
            ],
            "Solo aplica cuando el fallo ocurre al despertar el equipo."
        ),

        codigo(
            "F0-F4",
            "Recuperación de firmware",
            .placa,
            "La placa ha iniciado un proceso automático o forzado de recuperación de BIOS/firmware.",
            [
                "Esperar sin apagar el equipo",
                "Consultar el manual de recuperación de BIOS",
                "Usar BIOS Flashback si la placa dispone de esa función",
                "Confirmar que el archivo corresponde al modelo exacto"
            ],
            "Interrumpir la recuperación puede dañar el firmware de la placa."
        )
    ]
    }

    // MARK: - Consulta

    static func codigo(
        para texto: String,
        marca: MarcaPlacaBase
    ) -> InfoCodigoPOST? {
        let codigoBuscado = normalizarCodigo(texto)

        guard !codigoBuscado.isEmpty else {
            return nil
        }

        let tabla: [InfoCodigoPOST]

        switch marca {
        case .asus:
            tabla = codigosASUS

        case .gigabyte:
            tabla = codigosGigabyte

        case .msi:
            tabla = codigosMSI

        case .asrock:
            tabla = codigosASRock

        case .generico:
            tabla = codigosGenericos
        }

        return tabla.first {
            coincide(
                codigoBuscado,
                con: $0.codigo
            )
        }
    }

    static func normalizarCodigo(
        _ codigo: String
    ) -> String {
        codigo
            .uppercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .replacingOccurrences(
                of: "0X",
                with: ""
            )
    }

    // MARK: - Ayudas privadas

    private static func codigo(
        _ codigo: String,
        _ titulo: String,
        _ categoria: InfoCodigoPOST.CategoriaCodigoPOST,
        _ descripcion: String,
        _ acciones: [String],
        _ advertencia: String
    ) -> InfoCodigoPOST {
        // Los textos se escriben en español y se traducen aquí, en un solo punto
        InfoCodigoPOST(
            codigo: codigo,
            titulo: titulo.localizado,
            categoria: categoria,
            descripcion: descripcion.localizado,
            acciones: acciones,
            advertencia: advertencia.localizado
        )
    }

    private static func coincide(
        _ codigoBuscado: String,
        con patron: String
    ) -> Bool {
        let patronNormalizado = patron.uppercased()

        if patronNormalizado == codigoBuscado {
            return true
        }

        guard patronNormalizado.contains("-") else {
            return false
        }

        let partes = patronNormalizado.split(
            separator: "-",
            maxSplits: 1
        )

        guard partes.count == 2,
              let inicio = Int(partes[0], radix: 16),
              let fin = Int(partes[1], radix: 16),
              let valor = Int(codigoBuscado, radix: 16) else {
            return false
        }

        return valor >= inicio && valor <= fin
    }
}
