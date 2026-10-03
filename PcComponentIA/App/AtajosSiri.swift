//
//  AtajosSiri.swift
//  PcComponentIA
//
//  Acciones para Siri, Spotlight y la app Atajos (App Intents).
//  No necesitan cuenta de desarrollador de pago ni ningún permiso especial.
//

import AppIntents
import Combine
import SwiftUI

// MARK: - Navegación pedida desde fuera de la app

/// Siri o Atajos piden abrir una sección; la raíz de la app la abre al recibirla.
@MainActor
final class NavegadorApp: ObservableObject {
    static let shared = NavegadorApp()
    @Published var seccionSolicitada: SeccionApp?
    private init() {}
}

// MARK: - Abrir secciones

struct AbrirEscanerIntent: AppIntent {
    static let title: LocalizedStringResource = "Escanear un componente"
    static let description = IntentDescription("Abre la cámara para reconocer piezas de PC.")
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavegadorApp.shared.seccionSolicitada = .escaner
        return .result()
    }
}

struct AbrirDiagnosticoIntent: AppIntent {
    static let title: LocalizedStringResource = "Diagnosticar el arranque"
    static let description = IntentDescription("Abre el diagnóstico por LEDs, códigos POST y pitidos.")
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavegadorApp.shared.seccionSolicitada = .diagnostico
        return .result()
    }
}

struct AbrirAsistenteIntent: AppIntent {
    static let title: LocalizedStringResource = "Preguntar al asistente"
    static let description = IntentDescription("Abre el asistente de hardware.")
    static let supportedModes: IntentModes = .foreground

    @MainActor
    func perform() async throws -> some IntentResult {
        NavegadorApp.shared.seccionSolicitada = .asistente
        return .result()
    }
}

// MARK: - Progreso del montaje (sin abrir la app)

struct ProgresoMontajeIntent: AppIntent {
    static let title: LocalizedStringResource = "Progreso del montaje"
    static let description = IntentDescription("Dice cuántos pasos del montaje llevas hechos.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let gestor = GestorChecklist()
        let total = gestor.pasosRequeridos
        let hechos = gestor.completados
        let nombre = gestor.nombreBuildActiva.map { L(" de «\($0)»") } ?? ""

        let texto: String
        if hechos == 0 {
            texto = L("Aún no has empezado el montaje\(nombre). Son \(total) pasos.")
        } else if hechos >= total {
            texto = L("¡Montaje\(nombre) terminado! Has completado los \(total) pasos.")
        } else {
            let siguiente = gestor.pasos.first { $0.estado == .pendiente }?.nombre
            texto = L("Llevas \(hechos) de \(total) pasos del montaje\(nombre).")
                + (siguiente.map { L(" El siguiente: \($0.localizado).") } ?? "")
        }
        return .result(dialog: IntentDialog(stringLiteral: texto))
    }
}

// MARK: - Frases de Siri

struct AtajosPcComponentIA: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AbrirEscanerIntent(),
            phrases: [
                "Escanea un componente con \(.applicationName)",
                "Escanear pieza con \(.applicationName)",
                "Abre el escáner de \(.applicationName)",
            ],
            shortTitle: "Escanear",
            systemImageName: "camera.viewfinder"
        )
        AppShortcut(
            intent: AbrirDiagnosticoIntent(),
            phrases: [
                "Diagnostica el arranque con \(.applicationName)",
                "Mi PC no arranca \(.applicationName)",
            ],
            shortTitle: "Diagnóstico",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: AbrirAsistenteIntent(),
            phrases: [
                "Pregunta al asistente de \(.applicationName)",
                "Abre el asistente de \(.applicationName)",
            ],
            shortTitle: "Asistente",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: ProgresoMontajeIntent(),
            phrases: [
                "¿Cómo va mi montaje en \(.applicationName)?",
                "Progreso del montaje en \(.applicationName)",
            ],
            shortTitle: "Progreso",
            systemImageName: "checklist"
        )
    }
}
