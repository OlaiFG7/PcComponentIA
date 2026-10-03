//
//  EnlacesDiagnostico.swift
//  PcComponentIA
//

import Foundation

struct EnlaceDiagnostico: Identifiable, Equatable {

    let id = UUID()
    let titulo: String
    let componenteClave: String?
    let pasoChecklist: String?

    var tieneComponente: Bool {
        componenteClave != nil
    }

    var tieneChecklist: Bool {
        pasoChecklist != nil
    }
}

enum EnlacesDiagnostico {

    static func enlace(
        para accion: String,
        categoria: InfoCodigoPOST.CategoriaCodigoPOST? = nil
    ) -> EnlaceDiagnostico {
        let texto = normalizar(accion)

        if contiene(texto, ["pcie", "12vhpwr", "12v 2x6"]) &&
            contiene(texto, ["alimentacion", "cable", "energia", "gpu", "grafica"]) {
            return crear(
                accion,
                componente: "GPU",
                paso: "Conectar alimentación PCIe o 12VHPWR a GPU"
            )
        }

        if contiene(texto, ["gpu", "grafica", "vga", "video", "salida de video", "pcie x16"]) ||
            categoria == .grafica {
            return crear(
                accion,
                componente: "GPU",
                paso: "Instalar tarjeta gráfica dedicada GPU"
            )
        }

        if contiene(texto, ["monitor", "pantalla", "cable o pantalla", "salida de video"]) {
            return crear(
                accion,
                paso: "Conectar pantalla, teclado y cable de corriente"
            )
        }

        if contiene(texto, ["eps", "cpu 8 pines", "alimentacion eps", "cable eps", "conector eps"]) {
            return crear(
                accion,
                componente: "Conector_EPS_8p",
                paso: "Conectar cable EPS CPU de 8 pines"
            )
        }

        if contiene(texto, ["socket", "pines", "orientacion de la cpu", "procesador", "cpu"]) ||
            categoria == .cpu {
            return crear(
                accion,
                componente: "CPU_Intel",
                paso: "Instalar CPU en el socket de la placa base"
            )
        }

        if contiene(texto, ["disipador", "refrigeracion", "temperatura", "presiona en exceso"]) {
            return crear(
                accion,
                componente: "Disipador_Aire",
                paso: "Montar disipador o refrigeración de CPU"
            )
        }

        if contiene(texto, ["cpu_fan", "cpu fan", "ventilador cpu"]) {
            return crear(
                accion,
                componente: "Conector_SYS_FAN",
                paso: "Conectar cable CPU_FAN al disipador"
            )
        }

        if contiene(texto, ["ram", "memoria", "modulo", "modulos", "a2", "xmp", "expo", "jedec", "qvl", "ranura"]) ||
            categoria == .memoria {
            return crear(
                accion,
                componente: contiene(texto, ["ranura", "slot", "slots", "a2"]) ? "Ranura_RAM" : "Modulo_RAM",
                paso: "Instalar módulos de memoria RAM"
            )
        }

        if contiene(texto, ["m.2", "m2", "nvme"]) {
            return crear(
                accion,
                componente: "M2_SSD_NVMe",
                paso: "Instalar SSD M.2 NVMe"
            )
        }

        if contiene(texto, ["sata de datos", "cable sata", "puerto sata"]) {
            return crear(
                accion,
                componente: "Puerto_SATA",
                paso: "Conectar cable SATA de datos"
            )
        }

        if contiene(texto, ["ssd", "hdd", "disco", "unidad", "almacenamiento", "controladora"]) ||
            categoria == .almacenamiento {
            return crear(
                accion,
                componente: contiene(texto, ["hdd", "sata"]) ? "SSD_SATA" : "M2_SSD_NVMe",
                paso: contiene(texto, ["hdd", "sata"]) ? "Instalar SSD SATA o disco duro HDD" : "Instalar SSD M.2 NVMe"
            )
        }

        if contiene(texto, ["orden de arranque", "boot", "sistema operativo", "arranque"]) ||
            categoria == .arranque {
            return crear(
                accion,
                componente: "BIOS_UEFI",
                paso: contiene(texto, ["sistema operativo", "controladores"]) ? "Instalar sistema operativo y controladores" : "Encender PC y comprobar POST o BIOS"
            )
        }

        if contiene(texto, ["bios", "uefi", "clear cmos", "cmos", "flashback", "valores predeterminados", "cargar valores", "restaurar bios", "actualizar bios"]) ||
            categoria == .configuracion {
            return crear(
                accion,
                componente: contiene(texto, ["cmos"]) ? "Pila_CMOS" : "BIOS_UEFI",
                paso: "Encender PC y comprobar POST o BIOS"
            )
        }

        if contiene(texto, ["atx", "24 pines", "alimentacion atx"]) {
            return crear(
                accion,
                componente: "Conector_ATX_24p",
                paso: "Conectar cable ATX de 24 pines"
            )
        }

        if contiene(texto, ["placa", "motherboard", "chasis", "separadores", "cortocircuitos", "montaje"]) ||
            categoria == .placa || categoria == .chipset {
            return crear(
                accion,
                componente: "Placa_Base",
                paso: "Montar placa base dentro de la caja"
            )
        }

        if contiene(texto, ["teclado", "raton", "usb", "periferico", "perifericos"]) ||
            categoria == .perifericos {
            return crear(
                accion,
                paso: "Conectar pantalla, teclado y cable de corriente"
            )
        }

        return crear(accion)
    }

    static func enlaces(
        para acciones: [String],
        categoria: InfoCodigoPOST.CategoriaCodigoPOST? = nil
    ) -> [EnlaceDiagnostico] {
        acciones.map { accion in
            enlace(
                para: accion,
                categoria: categoria
            )
        }
    }

    private static func crear(
        _ titulo: String,
        componente: String? = nil,
        paso: String? = nil
    ) -> EnlaceDiagnostico {
        EnlaceDiagnostico(
            titulo: titulo,
            componenteClave: componente,
            pasoChecklist: paso
        )
    }

    private static func contiene(
        _ texto: String,
        _ patrones: [String]
    ) -> Bool {
        patrones.contains { patron in
            texto.contains(normalizar(patron))
        }
    }

    private static func normalizar(_ texto: String) -> String {
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
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
