//
//  BotonCircular.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 09/07/2026.
//

//
// BotonCircular.swift
// PcComponentIA
//

import SwiftUI

struct BotonCircular: View {
    let icono: String
    var activo: Bool = false
    var colorActivo: Color = .orange
    var tamano: CGFloat = 38
    let accion: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            accion()
        }) {
            Image(systemName: icono)
                .font(.system(size: tamano * 0.42, weight: .semibold))
                .foregroundColor(activo ? colorActivo : .white)
                .frame(width: tamano, height: tamano)
                .background(.ultraThinMaterial)
                .background(activo ? colorActivo.opacity(0.18) : Color.black.opacity(0.15))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }
}

struct EtiquetaPill: View {
    let texto: String
    var color: Color = .cyan
    var icono: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icono {
                Image(systemName: icono).font(.system(size: 10, weight: .bold))
            }
            Text(texto)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .background(color.opacity(0.35))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
    }
}
