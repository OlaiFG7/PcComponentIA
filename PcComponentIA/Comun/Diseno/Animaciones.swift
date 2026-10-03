//
//  Animaciones.swift
//  PcComponentIA
//
//  Efectos de animación comunes para que todas las pantallas se muevan igual.
//  Los modificadores de este archivo respetan "Reducir movimiento"
//  (Ajustes > Accesibilidad > Movimiento); `Animaciones.muelle` es solo la curva.
//

import SwiftUI

enum Animaciones {
    /// Muelle suave usado en apariciones y cambios de estado.
    static let muelle = Animation.spring(response: 0.42, dampingFraction: 0.82)
    /// Retardo entre tarjetas consecutivas en la entrada escalonada.
    static let pasoEscalonado = 0.045
    /// A partir de esta posición ya no se añade más retardo (listas largas).
    static let maxEscalonado = 10
}

// MARK: - Entrada escalonada

private struct AparicionEscalonada: ViewModifier {
    let indice: Int

    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reducirMovimiento ? 0 : 18)
            .scaleEffect(visible || reducirMovimiento ? 1 : 0.97)
            .onAppear {
                guard !visible else { return }
                let retardo = Double(min(indice, Animaciones.maxEscalonado)) * Animaciones.pasoEscalonado
                withAnimation(
                    reducirMovimiento
                        ? .easeOut(duration: 0.2)
                        : Animaciones.muelle.delay(retardo)
                ) {
                    visible = true
                }
            }
    }
}

// MARK: - Efecto al hacer scroll

private struct EfectoScrollTarjeta: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reducirMovimiento

    func body(content: Content) -> some View {
        if reducirMovimiento {
            content
        } else {
            content.scrollTransition(.interactive, axis: .vertical) { vista, fase in
                vista
                    .scaleEffect(fase.isIdentity ? 1 : 0.94)
                    .opacity(fase.isIdentity ? 1 : 0.55)
                    .blur(radius: fase.isIdentity ? 0 : 1.5)
            }
        }
    }
}

extension View {
    /// La vista aparece subiendo y difuminándose, con un retardo según su posición en la lista.
    func aparicionEscalonada(indice: Int = 0) -> some View {
        modifier(AparicionEscalonada(indice: indice))
    }

    /// Las tarjetas que entran o salen por el borde del scroll se encogen y se difuminan un poco.
    func efectoScrollTarjeta() -> some View {
        modifier(EfectoScrollTarjeta())
    }
}
