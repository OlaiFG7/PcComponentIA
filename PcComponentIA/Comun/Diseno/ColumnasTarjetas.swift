//
//  ColumnasTarjetas.swift
//  PcComponentIA
//

import SwiftUI

/// Columnas de las rejillas de tarjetas (Diccionario, Historial, Mis builds).
/// - iPhone: 2 columnas.
/// - iPad (ancho regular): tarjetas más anchas para que no queden tan estrechas como en un iPhone.
/// - Letra de accesibilidad: una sola columna para que los textos no se corten.
enum ColumnasTarjetas {
    static func columnas(
        sizeClass: UserInterfaceSizeClass?,
        tamanoTexto: DynamicTypeSize
    ) -> [GridItem] {
        if tamanoTexto.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 12)]
        }
        let minimo: CGFloat = sizeClass == .regular ? 220 : 150
        return [GridItem(.adaptive(minimum: minimo), spacing: 12)]
    }
}
