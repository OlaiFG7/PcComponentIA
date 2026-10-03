//
//  CompartirBuild.swift
//  PcComponentIA
//
//  Compartir una build como texto o como imagen-resumen.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Texto

extension Build {
    /// Resumen en texto plano, apto para mensajería o foros.
    var resumenParaCompartir: String {
        var lineas = [L("🖥️ \(nombre.isEmpty ? "Mi build" : nombre)")]
        if etiqueta != L("Sin etiqueta") {
            lineas.append(L("Tipo: \(etiqueta)"))
        }
        lineas.append("")

        for componente in componentes {
            var linea = L("• \(componente.categoria): \(componente.nombre)")
            if let precio = componente.precio.safeDouble {
                linea += L(" — \(precio.formatoEuro)")
            }
            lineas.append(linea)
        }

        lineas.append("")
        lineas.append(L("Total: \(precioTotal.formatoEuro)"))
        if presupuestoNumerico > 0 {
            lineas.append(L("Presupuesto: \(presupuestoNumerico.formatoEuro)"))
        }
        lineas.append("")
        lineas.append(L("Hecho con PcComponentIA"))
        return lineas.joined(separator: "\n")
    }
}

// MARK: - Imagen

/// Se genera la imagen solo cuando el usuario elige compartirla, no al abrir la pantalla.
struct BuildComoImagen: Transferable {
    let build: Build

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { elemento in
            await MainActor.run {
                let renderer = ImageRenderer(content: TarjetaBuildCompartible(build: elemento.build))
                renderer.scale = 3
                return renderer.uiImage?.pngData() ?? Data()
            }
        }
        .suggestedFileName { "\($0.build.nombre.isEmpty ? "Build" : $0.build.nombre).png" }
    }
}

/// Tarjeta que se dibuja en la imagen compartida (fondo propio, sin depender del tema).
struct TarjetaBuildCompartible: View {
    let build: Build

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "pc")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(build.nombre.isEmpty ? L("Mi build") : build.nombre)
                        .font(.title3.weight(.bold))
                    if build.etiqueta != L("Sin etiqueta") {
                        Text(build.etiqueta.localizado)
                            .font(.caption.weight(.semibold))
                            .opacity(0.8)
                    }
                }
            }

            VStack(spacing: 8) {
                ForEach(build.componentes) { componente in
                    HStack(alignment: .firstTextBaseline) {
                        Text(componente.categoria.localizado)
                            .font(.caption.weight(.bold))
                            .opacity(0.75)
                            .frame(width: 96, alignment: .leading)
                        Text(componente.nombre)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        if let precio = componente.precio.safeDouble {
                            Text(precio.formatoEuro)
                                .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            }
            .padding(14)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(build.precioTotal.formatoEuro)
                    .font(.title2.weight(.bold).monospacedDigit())
            }

            Text("Hecho con PcComponentIA")
                .font(.caption2.weight(.semibold))
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(width: 390)
        .background(
            LinearGradient(
                colors: [.blue, .indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Menú

/// Botón de la barra con las dos formas de compartir.
struct MenuCompartirBuild: View {
    let build: Build

    var body: some View {
        Menu {
            ShareLink(item: build.resumenParaCompartir) {
                Label("Compartir como texto", systemImage: "text.alignleft")
            }
            ShareLink(
                item: BuildComoImagen(build: build),
                preview: SharePreview(
                    build.nombre.isEmpty ? L("Mi build") : build.nombre,
                    image: Image(systemName: "pc")
                )
            ) {
                Label("Compartir como imagen", systemImage: "photo")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Compartir build")
        .disabled(build.componentes.isEmpty)
    }
}
