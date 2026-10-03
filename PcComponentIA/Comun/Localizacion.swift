//
//  Localizacion.swift
//  PcComponentIA
//
//  La app está escrita en español (idioma base) y traducida al inglés en Localizable.xcstrings.
//  El idioma se puede cambiar desde la propia app (Idioma.cambiar) sin reiniciarla:
//  - Los textos de la interfaz (Text("…"), Button("…")…) siguen el locale del entorno,
//    que la raíz de la app fija con Idioma.locale.
//  - El resto pasa por L() o .localizado, que buscan en la traducción del idioma elegido.
//  - El contenido fijo (fichas, diagnósticos…) se guarda en PorIdioma y se recalcula al cambiar.
//

import Foundation

/// Contenido fijo (fichas, diagnósticos, esquemas…): el literal se añade solo al catálogo de
/// traducciones al compilar y se devuelve en el idioma elegido para la app.
func L(_ texto: String.LocalizationValue) -> String {
    String(localized: texto, bundle: Idioma.bundle, locale: Idioma.locale)
}

extension String {
    /// Para textos que la app también usa como identificador y guarda en español
    /// (etiquetas y categorías de las builds, pasos del checklist…): se traducen solo al mostrarlos,
    /// así los datos guardados funcionan igual en cualquier idioma.
    var localizado: String {
        Idioma.bundle.localizedString(forKey: self, value: self, table: "Localizable")
    }
}

enum Idioma {
    /// Clave de UserDefaults con el idioma elegido en la app ("es" o "en").
    static let claveGuardado = "idiomaApp"
    static let disponibles = ["es", "en"]

    /// Idioma en que se muestra la app: el elegido en ella o, si no se ha elegido,
    /// el que iOS escogió para la app según el idioma del dispositivo.
    static var codigo: String {
        if let elegido = UserDefaults.standard.string(forKey: claveGuardado),
           disponibles.contains(elegido) {
            return elegido
        }
        let preferido = Bundle.main.preferredLocalizations.first ?? "es"
        return disponibles.first { preferido.hasPrefix($0) } ?? "es"
    }

    static var locale: Locale { Locale(identifier: codigo) }

    static var esEspanol: Bool { codigo == "es" }

    /// Nombre del idioma en que debe responder el asistente.
    static var nombreParaAsistente: String {
        esEspanol ? "español" : "English"
    }

    /// Nombre de cada idioma escrito en ese mismo idioma, para el selector.
    static func nombre(de codigo: String) -> String {
        codigo == "en" ? "English" : "Español"
    }

    /// Cambia el idioma de la app. También lo guarda donde iOS lo lee (el mismo ajuste que
    /// Ajustes > PcComponentIA > Idioma), así los elementos del sistema lo usan al volver a abrirla.
    static func cambiar(a nuevo: String) {
        guard disponibles.contains(nuevo) else { return }
        UserDefaults.standard.set(nuevo, forKey: claveGuardado)
        UserDefaults.standard.set([nuevo], forKey: "AppleLanguages")
    }

    /// Carpeta de traducciones (es.lproj / en.lproj) del idioma actual.
    static var bundle: Bundle {
        let actual = codigo
        if let guardado = bundles[actual] { return guardado }
        let encontrado = Bundle.main.path(forResource: actual, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
        bundles[actual] = encontrado
        return encontrado
    }

    private static var bundles: [String: Bundle] = [:]
}

/// Contenido fijo que depende del idioma: se crea la primera vez que se usa y se vuelve
/// a crear solo si el idioma de la app ha cambiado desde entonces.
final class PorIdioma<Valor> {
    private let crear: () -> Valor
    private var guardado: (idioma: String, valor: Valor)?

    init(_ crear: @escaping () -> Valor) {
        self.crear = crear
    }

    var valor: Valor {
        let idioma = Idioma.codigo
        if let guardado, guardado.idioma == idioma {
            return guardado.valor
        }
        let nuevo = crear()
        guardado = (idioma, nuevo)
        return nuevo
    }
}
