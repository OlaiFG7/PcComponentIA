//
//  PcComponentIAApp.swift
//  PcComponentIA
//

import SwiftUI
import SwiftData

@main
struct PcComponentIAApp: App {

    @StateObject private var settings = AppSettings()
    @StateObject private var checklist = GestorChecklist()
    @StateObject private var gestorDiagnosticos = GestorDiagnosticos()

    @AppStorage("onboardingCompletado")
    private var onboardingCompletado = false

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BuildSD.self,
            ComponenteBuildSD.self,
            RegistroDiagnosticoSD.self,
            CapturaHistorialSD.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("No se pudo crear el ModelContainer de SwiftData: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if onboardingCompletado {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(settings)
            .environmentObject(checklist)
            .environmentObject(gestorDiagnosticos)
            .preferredColorScheme(settings.esquemaColor)
            .onAppear {
                let context = sharedModelContainer.mainContext
                AlmacenBuilds.defaultContext = context
                AlmacenHistorial.defaultContext = context
                gestorDiagnosticos.setContext(context)
                MigrationManager.shared.performMigrationIfNeeded(context: context)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
