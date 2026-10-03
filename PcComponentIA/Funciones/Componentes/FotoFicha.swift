//
//  FotoFicha.swift
//  PcComponentIA
//
//  Fotos reales en las fichas, con el crédito que exige su licencia.
//  Para añadir una: imagen "foto_<clave>" en Assets y su entrada en `FotosFichas.creditos`.
//

import SwiftUI

struct CreditoFoto {
    let autor: String
    let licencia: String
    let url: URL
}

enum FotosFichas {
    static let creditos: [String: CreditoFoto] = [
        "Pila_CMOS": CreditoFoto(
            autor: "Kent Madsen",
            licencia: "CC BY-SA 2.0",
            url: URL(string: "https://commons.wikimedia.org/wiki/File:CMOS_Battery,_Motherboard.jpg")!
        ),
    ]
}

/// Foto de la pieza con su crédito debajo. Si la pieza no tiene foto, no ocupa sitio.
struct FotoFicha: View {
    let clave: String

    var body: some View {
        if let credito = FotosFichas.creditos[clave], UIImage(named: "foto_\(clave)") != nil {
            VStack(alignment: .leading, spacing: 6) {
                Image("foto_\(clave)")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityLabel("Foto real de \(clave.replacingOccurrences(of: "_", with: " "))")

                Link(destination: credito.url) {
                    Text("Foto: \(credito.autor) · \(credito.licencia) · Wikimedia Commons")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .underline()
                }
                .accessibilityLabel("Crédito de la foto: \(credito.autor), licencia \(credito.licencia). Abre la página original.")
            }
        }
    }
}
