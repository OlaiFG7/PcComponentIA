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

    /// Idioma elegido en la app ("" = el del dispositivo). Al cambiar, la interfaz se vuelve a crear.
    @AppStorage(Idioma.claveGuardado)
    private var idiomaApp = ""

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
            Group {
                if onboardingCompletado {
                    // En iPad, barra lateral; en iPhone, la navegación de siempre
                    RaizAppView()
                        .id(idiomaApp)
                } else {
                    NavigationStack {
                        OnboardingView()
                    }
                    .id(idiomaApp)
                }
            }
            .environment(\.locale, Idioma.locale)
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
