//
//  CompatibilidadBuild.swift
//  PcComponentIA
//
//  Comprobaciones de compatibilidad y estimación de consumo de una build.
//  Los componentes son texto libre, así que se deduce lo que se puede a partir del nombre
//  ("Ryzen 5 7600", "MSI B650", "Corsair 750W"...). Si algo no se reconoce, no se inventa:
//  se avisa de que no se pudo comprobar.
//

import Foundation

struct AvisoCompatibilidad: Identifiable, Equatable {
    enum Nivel: Int, Comparable {
        case correcto, info, advertencia, error
        static func < (a: Nivel, b: Nivel) -> Bool { a.rawValue < b.rawValue }
    }

    let id = UUID()
    let nivel: Nivel
    let titulo: String
    let detalle: String

    static func == (a: AvisoCompatibilidad, b: AvisoCompatibilidad) -> Bool {
        a.nivel == b.nivel && a.titulo == b.titulo && a.detalle == b.detalle
    }
}

struct EstimacionConsumo: Equatable {
    let cpu: Int?
    let gpu: Int?
    let resto: Int
    /// Fuente indicada en la build (vatios), si se reconoce.
    let fuente: Int?

    var total: Int { (cpu ?? 0) + (gpu ?? 0) + resto }

    /// Fuente recomendada: consumo con un 40 % de margen, redondeado a 50 W.
    var fuenteRecomendada: Int {
        let conMargen = Double(total) * 1.4
        return max(450, Int((conMargen / 50).rounded(.up)) * 50)
    }
}

enum CompatibilidadBuild {

    enum Socket: String {
        case am4 = "AM4", am5 = "AM5", lga1200 = "LGA1200", lga1700 = "LGA1700", lga1851 = "LGA1851"
        /// Mismo zócalo físico, pero las placas de 6.ª-7.ª gen. (100/200) y 8.ª-9.ª (300) no son compatibles entre sí
        case lga1151 = "LGA1151 (6.ª-7.ª gen.)", lga1151v2 = "LGA1151 (8.ª-9.ª gen.)"

        /// Tipo de memoria que admiten las placas de este socket (nil si hay de los dos tipos).
        var memoria: String? {
            switch self {
            case .am4: return "DDR4"
            case .am5, .lga1851: return "DDR5"
            case .lga1200, .lga1151, .lga1151v2: return "DDR4"
            case .lga1700: return nil
            }
        }
    }

    // MARK: - Análisis

    static func analizar(_ build: Build) -> (avisos: [AvisoCompatibilidad], consumo: EstimacionConsumo) {
        let cpu = primero(build, "CPU")
        let placa = primero(build, "Placa base")
        let gpu = primero(build, "GPU")
        let fuente = primero(build, "Fuente")
        let rams = build.componentes.filter { $0.categoria == "RAM" }.map(\.nombre)

        var avisos: [AvisoCompatibilidad] = []

        // CPU ↔ placa base
        let socketCPU = cpu.flatMap(socket(deCPU:))
        let socketPlaca = placa.flatMap(socket(dePlaca:))
        switch (socketCPU, socketPlaca) {
        case let (c?, p?) where c == p:
            avisos.append(.init(nivel: .correcto, titulo: L("Procesador y placa compatibles"),
                                detalle: L("Ambos usan el socket \(c.rawValue).")))
        case let (c?, p?):
            avisos.append(.init(nivel: .error, titulo: L("El procesador no encaja en la placa"),
                                detalle: L("El procesador usa \(c.rawValue) y la placa \(p.rawValue). Hace falta cambiar uno de los dos.")))
        case (nil, _?) where cpu != nil, (_?, nil) where placa != nil:
            avisos.append(.init(nivel: .info, titulo: L("No se pudo comprobar el socket"),
                                detalle: L("Escribe el modelo completo (p. ej. «Ryzen 5 7600» o «MSI B650 Tomahawk») para comprobarlo.")))
        default:
            break
        }

        // Memoria
        let socketReferencia = socketPlaca ?? socketCPU
        let tiposRAM = Set(rams.compactMap(tipoMemoria(de:)))
        if tiposRAM.count > 1 {
            avisos.append(.init(nivel: .error, titulo: L("Mezcla de DDR4 y DDR5"),
                                detalle: L("Los módulos DDR4 y DDR5 no pueden usarse juntos.")))
        } else if let tipo = tiposRAM.first {
            let requerido = socketReferencia?.memoria ?? placa.flatMap(tipoMemoria(de:))
            if let requerido, requerido != tipo {
                avisos.append(.init(nivel: .error, titulo: L("La memoria no es compatible"),
                                    detalle: L("Esta plataforma usa \(requerido) y la RAM elegida es \(tipo). No entra en la ranura.")))
            } else if let requerido {
                avisos.append(.init(nivel: .correcto, titulo: L("Memoria compatible"),
                                    detalle: L("La plataforma usa \(requerido), igual que la RAM elegida.")))
            } else if socketReferencia == .lga1700 {
                avisos.append(.init(nivel: .info, titulo: L("Revisa el tipo de memoria de la placa"),
                                    detalle: L("En Intel 12.ª-14.ª generación hay placas DDR4 y DDR5. Comprueba que la tuya sea \(tipo).")))
            }
        }

        // Gráficos
        // Solo se avisa si se sabe seguro que la CPU no tiene gráficos (nil = modelo no reconocido)
        if gpu == nil, let cpu, tieneGraficosIntegrados(cpu) == false {
            avisos.append(.init(nivel: .error, titulo: L("Sin salida de vídeo"),
                                detalle: L("Este procesador no tiene gráficos integrados y la build no tiene tarjeta gráfica: el monitor no mostrará imagen.")))
        }

        // Consumo
        let consumo = EstimacionConsumo(
            cpu: cpu.flatMap(consumo(deCPU:)),
            gpu: gpu.flatMap(consumo(deGPU:)),
            resto: 75,
            fuente: fuente.flatMap(vatios(de:))
        )
        if let vatiosFuente = consumo.fuente {
            if Double(vatiosFuente) < Double(consumo.total) * 1.1 {
                avisos.append(.init(nivel: .error, titulo: L("La fuente se queda corta"),
                                    detalle: L("Consumo estimado: \(consumo.total) W. Se recomienda al menos \(consumo.fuenteRecomendada) W.")))
            } else if vatiosFuente < consumo.fuenteRecomendada {
                avisos.append(.init(nivel: .advertencia, titulo: L("Fuente justa"),
                                    detalle: L("Funcionará, pero con poco margen. Lo recomendable son \(consumo.fuenteRecomendada) W.")))
            } else {
                avisos.append(.init(nivel: .correcto, titulo: L("Fuente suficiente"),
                                    detalle: L("\(vatiosFuente) W para un consumo estimado de \(consumo.total) W.")))
            }
        }

        return (avisos.sorted { $0.nivel > $1.nivel }, consumo)
    }

    // MARK: - Reconocimiento por nombre

    private static func primero(_ build: Build, _ categoria: String) -> String? {
        build.componentes.first { $0.categoria == categoria }?.nombre
    }

    /// Primer número de 3-5 cifras tras el texto (p. ej. "7600" en "Ryzen 5 7600X").
    private static func numeroModelo(_ texto: String) -> Int? {
        guard let rango = texto.range(of: #"\d{3,5}"#, options: .regularExpression) else { return nil }
        return Int(texto[rango])
    }

    static func socket(deCPU nombre: String) -> Socket? {
        let t = nombre.lowercased()
        if let explicito = socketExplicito(t) { return explicito }

        if t.contains("ryzen") || t.contains("amd") {
            guard let n = numeroModelo(t) else { return nil }
            let serie = n / 1000
            if (7...9).contains(serie) { return .am5 }
            if (1...5).contains(serie) { return .am4 }
            return nil
        }
        if t.contains("ultra") {
            return .lga1851
        }
        if t.contains("intel") || t.range(of: #"\bi[3579]\b|\bi[3579]-"#, options: .regularExpression) != nil {
            guard let n = numeroModelo(t) else { return nil }
            // 4 cifras (i7-9700 → 9.ª) o 5 cifras (i5-12400 → 12.ª): la generación son los millares
            let generacion = n / 1000
            if (12...14).contains(generacion) { return .lga1700 }
            if (10...11).contains(generacion) { return .lga1200 }
            if (8...9).contains(generacion) { return .lga1151v2 }
            if (6...7).contains(generacion) { return .lga1151 }
        }
        return nil
    }

    static func socket(dePlaca nombre: String) -> Socket? {
        let t = nombre.lowercased()
        if let explicito = socketExplicito(t) { return explicito }

        let chipsets: [(String, Socket)] = [
            ("a620", .am5), ("b650", .am5), ("x670", .am5), ("b840", .am5), ("b850", .am5), ("x870", .am5),
            ("a320", .am4), ("b350", .am4), ("x370", .am4), ("b450", .am4), ("x470", .am4),
            ("a520", .am4), ("b550", .am4), ("x570", .am4),
            ("h610", .lga1700), ("b660", .lga1700), ("h670", .lga1700), ("z690", .lga1700),
            ("b760", .lga1700), ("h770", .lga1700), ("z790", .lga1700),
            ("h810", .lga1851), ("b860", .lga1851), ("z890", .lga1851),
            ("h410", .lga1200), ("b460", .lga1200), ("h470", .lga1200), ("z490", .lga1200),
            ("h510", .lga1200), ("b560", .lga1200), ("h570", .lga1200), ("z590", .lga1200),
            ("h310", .lga1151v2), ("b360", .lga1151v2), ("b365", .lga1151v2), ("h370", .lga1151v2),
            ("z370", .lga1151v2), ("z390", .lga1151v2),
            ("h110", .lga1151), ("b150", .lga1151), ("h170", .lga1151), ("z170", .lga1151),
            ("b250", .lga1151), ("h270", .lga1151), ("z270", .lga1151),
        ]
        return chipsets.first { t.contains($0.0) }?.1
    }

    private static func socketExplicito(_ t: String) -> Socket? {
        let compacto = t.replacingOccurrences(of: " ", with: "")
        if compacto.contains("am5") { return .am5 }
        if compacto.contains("am4") { return .am4 }
        if compacto.contains("1851") { return .lga1851 }
        if compacto.contains("lga1700") { return .lga1700 }
        if compacto.contains("lga1200") { return .lga1200 }
        return nil
    }

    static func tipoMemoria(de nombre: String) -> String? {
        let t = nombre.lowercased()
        if t.contains("ddr5") { return "DDR5" }
        if t.contains("ddr4") { return "DDR4" }
        return nil
    }

    /// nil si el modelo no se reconoce: así no se afirma nada que no se sepa.
    static func tieneGraficosIntegrados(_ nombreCPU: String) -> Bool? {
        let t = nombreCPU.lowercased()
        guard let socket = socket(deCPU: t) else { return nil }
        if t.contains("ryzen") {
            // Ryzen 7000+ llevan gráficos básicos (salvo los "F"); en AM4 solo los "G"
            if socket == .am5 { return !t.hasSuffix("f") }
            return t.range(of: #"\d{4}g"#, options: .regularExpression) != nil
        }
        // Intel: los modelos terminados en F / KF no tienen gráficos integrados
        return t.range(of: #"\d{3,5}k?f\b"#, options: .regularExpression) == nil
    }

    /// Vatios de la fuente: "750W", "850 W", "1000w"...
    static func vatios(de nombre: String) -> Int? {
        guard let rango = nombre.range(of: #"(\d{3,4})\s?w\b"#, options: [.regularExpression, .caseInsensitive])
        else { return nil }
        return Int(nombre[rango].filter(\.isNumber))
    }

    /// Consumo típico bajo carga del procesador (aproximado por gama).
    static func consumo(deCPU nombre: String) -> Int? {
        let t = nombre.lowercased()
        if t.contains("x3d") { return 120 }
        if t.contains("ryzen 9") { return 170 }
        if t.contains("ryzen 7") { return 120 }
        if t.contains("ryzen 5") { return 90 }
        if t.contains("ryzen 3") { return 65 }
        if t.contains("ultra 9") || t.contains("i9") { return 250 }
        if t.contains("ultra 7") || t.contains("i7") { return 200 }
        if t.contains("ultra 5") || t.contains("i5") { return 150 }
        if t.contains("i3") { return 90 }
        return nil
    }

    /// Consumo típico de la tarjeta gráfica (potencia de placa del fabricante, aproximada).
    static func consumo(deGPU nombre: String) -> Int? {
        let t = nombre.lowercased().replacingOccurrences(of: " ", with: "")
        let tabla: [(String, Int)] = [
            ("5090", 575), ("5080", 360), ("5070ti", 300), ("5070", 250), ("5060ti", 180), ("5060", 145),
            ("4090", 450), ("4080", 320), ("4070ti", 285), ("4070super", 220), ("4070", 200),
            ("4060ti", 165), ("4060", 115),
            ("3090", 350), ("3080", 320), ("3070", 220), ("3060ti", 200), ("3060", 170), ("3050", 130),
            ("9070xt", 304), ("9070", 220), ("9060xt", 160),
            ("7900xtx", 355), ("7900xt", 315), ("7800xt", 263), ("7700xt", 245), ("7600xt", 190), ("7600", 165),
            ("6950xt", 335), ("6900xt", 300), ("6800xt", 300), ("6800", 250), ("6700xt", 230),
            ("6650xt", 180), ("6600xt", 160), ("6600", 132),
            ("b580", 190), ("a770", 225), ("a750", 225),
        ]
        return tabla.first { t.contains($0.0) }?.1
    }
}
