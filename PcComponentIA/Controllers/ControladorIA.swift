//
//  ControladorIA.swift
//  PcComponentIA
//

import Foundation
import Combine
import FoundationModels

struct MensajeChat: Identifiable, Codable, Equatable {
    var id = UUID()
    let texto: String
    let esUsuario: Bool
    var fecha: Date = Date()
}

struct ConversacionChat: Identifiable, Codable, Equatable {
    var id = UUID()
    var titulo: String = "Nueva conversación"
    var mensajes: [MensajeChat] = []
    var fechaActualizacion: Date = Date()
}

final class AlmacenConversaciones {

    static let clave = "conversacionesChatIA"

    static func guardar(
        _ conversaciones: [ConversacionChat]
    ) {
        guard let datos = try? JSONEncoder().encode(conversaciones) else {
            return
        }

        UserDefaults.standard.set(datos, forKey: clave)
    }

    static func cargar() -> [ConversacionChat] {
        guard
            let datos = UserDefaults.standard.data(forKey: clave),
            let conversaciones = try? JSONDecoder().decode(
                [ConversacionChat].self,
                from: datos
            )
        else {
            return []
        }

        return conversaciones.sorted {
            $0.fechaActualizacion > $1.fechaActualizacion
        }
    }
}

enum RetencionHistorial: Int, CaseIterable, Identifiable {
    case nunca = 0
    case dias7 = 7
    case dias30 = 30
    case dias90 = 90

    var id: Int {
        rawValue
    }

    var etiqueta: String {
        switch self {
        case .nunca:
            return "No eliminar automáticamente"

        case .dias7:
            return "Cada 7 días"

        case .dias30:
            return "Cada 30 días"

        case .dias90:
            return "Cada 90 días"
        }
    }
}

@MainActor
final class ControladorIA: ObservableObject {

    @Published var conversaciones: [ConversacionChat]
    @Published var conversacionActualID: UUID?
    @Published var estaPensando = false

    @Published var retencion: RetencionHistorial {
        didSet {
            UserDefaults.standard.set(
                retencion.rawValue,
                forKey: "retencionHistorialChatIA"
            )

            aplicarRetencion()
        }
    }

    private var session: LanguageModelSession?
    private var tareaRespuesta: Task<Void, Never>?
    private var solicitudActivaID: UUID?

    private let maximoConversaciones = 100
    private let maximoMensajesPorConversacion = 150

    private let instrucciones = """
    Eres un asistente técnico especializado en hardware de PC y ensamblaje.
    Responde siempre basándote en el componente exacto que el usuario menciona.
    Por ejemplo, si dice RTX 5090, responde sobre la RTX 5090 y no sobre otra generación.
    Sé breve, claro, útil y directo en español.
    """

    init() {
        let conversacionesGuardadas = AlmacenConversaciones.cargar()

        self.conversaciones = conversacionesGuardadas

        let valorGuardado = UserDefaults.standard.integer(
            forKey: "retencionHistorialChatIA"
        )

        self.retencion = RetencionHistorial(
            rawValue: valorGuardado
        ) ?? .nunca

        aplicarRetencion()

        if conversaciones.isEmpty {
            nuevaConversacion()
        } else {
            conversacionActualID = conversaciones.first?.id
        }
    }

    deinit {
        tareaRespuesta?.cancel()
    }

    // MARK: - Conversación actual

    var mensajes: [MensajeChat] {
        guard let id = conversacionActualID else {
            return []
        }

        return conversaciones.first(
            where: { $0.id == id }
        )?.mensajes ?? []
    }

    // MARK: - Sesión IA

    private func obtenerSesionActiva() -> LanguageModelSession {
        if let session {
            return session
        }

        let nuevaSesion = LanguageModelSession(
            instructions: instrucciones
        )

        session = nuevaSesion
        return nuevaSesion
    }

    private func cancelarRespuestaEnCurso() {
        tareaRespuesta?.cancel()
        tareaRespuesta = nil
        solicitudActivaID = nil
        estaPensando = false
    }

    // MARK: - Persistencia

    private func limitarHistorial() {
        conversaciones = conversaciones
            .sorted {
                $0.fechaActualizacion > $1.fechaActualizacion
            }
            .prefix(maximoConversaciones)
            .map { conversacion in
                var copia = conversacion

                if copia.mensajes.count > maximoMensajesPorConversacion {
                    copia.mensajes = Array(
                        copia.mensajes.suffix(
                            maximoMensajesPorConversacion
                        )
                    )
                }

                return copia
            }

        if
            let actual = conversacionActualID,
            !conversaciones.contains(where: { $0.id == actual })
        {
            conversacionActualID = conversaciones.first?.id
        }
    }

    private func guardarConversaciones() {
        limitarHistorial()
        AlmacenConversaciones.guardar(conversaciones)
    }

    private func aplicarRetencion() {
        guard retencion != .nunca else {
            return
        }

        guard let limite = Calendar.current.date(
            byAdding: .day,
            value: -retencion.rawValue,
            to: .now
        ) else {
            return
        }

        let conversacionesFiltradas = conversaciones.filter {
            $0.fechaActualizacion >= limite
        }

        guard conversacionesFiltradas.count != conversaciones.count else {
            return
        }

        conversaciones = conversacionesFiltradas
        guardarConversaciones()
    }

    // MARK: - Gestión de conversaciones

    // FUNCIÓN REEMPLAZADA: Controla de forma inteligente la duplicación de salas vacías
    func nuevaConversacion() {
        // Si la conversación actual no tiene mensajes,
        // reutilízala en lugar de crear otra vacía.
        if let idActual = conversacionActualID,
           let conversacionActual = conversaciones.first(
                where: { $0.id == idActual }
           ),
           conversacionActual.mensajes.isEmpty {
            return
        }

        cancelarRespuestaEnCurso()

        let nueva = ConversacionChat(
            id: UUID(),
            titulo: "Nueva conversación",
            mensajes: [],
            fechaActualizacion: .now
        )

        conversaciones.insert(nueva, at: 0)
        conversacionActualID = nueva.id
        session = nil

        guardarConversaciones()
    }

    func seleccionarConversacion(_ id: UUID) {
        let existe = conversaciones.contains(where: { $0.id == id })
        guard existe else {
            return
        }

        cancelarRespuestaEnCurso()

        conversacionActualID = id
        session = nil
    }

    func eliminarConversacion(_ id: UUID) {
        cancelarRespuestaEnCurso()

        conversaciones.removeAll { $0.id == id }

        if conversacionActualID == id {
            conversacionActualID = conversaciones
                .sorted {
                    $0.fechaActualizacion > $1.fechaActualizacion
                }
                .first?
                .id
        }

        if conversaciones.isEmpty {
            nuevaConversacion()
        } else {
            guardarConversaciones()
        }
    }

    func borrarHistorial() {
        guard
            let id = conversacionActualID,
            let indice = conversaciones.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        cancelarRespuestaEnCurso()

        conversaciones[indice].mensajes.removeAll()
        conversaciones[indice].titulo = "Nueva conversación"
        conversaciones[indice].fechaActualizacion = .now

        session = nil
        guardarConversaciones()
    }

    func borrarTodoElHistorial() {
        cancelarRespuestaEnCurso()

        conversaciones.removeAll()
        conversacionActualID = nil
        session = nil

        nuevaConversacion()
    }

    // MARK: - Consulta IA

    func consultarIA(pregunta: String) {
        let textoLimpio = pregunta.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !textoLimpio.isEmpty else {
            return
        }

        if conversacionActualID == nil {
            nuevaConversacion()
        }

        guard
            let id = conversacionActualID,
            let indice = conversaciones.firstIndex(
                where: { $0.id == id }
            )
        else {
            return
        }

        cancelarRespuestaEnCurso()

        conversaciones[indice].mensajes.append(
            MensajeChat(
                texto: textoLimpio,
                esUsuario: true
            )
        )

        if conversaciones[indice].titulo == "Nueva conversación" {
            conversaciones[indice].titulo = tituloParaConversacion(
                textoLimpio
            )
        }

        conversaciones[indice].fechaActualizacion = .now
        guardarConversaciones()

        estaPensando = true

        let solicitudID = UUID()
        solicitudActivaID = solicitudID

        let sesionSegura = obtenerSesionActiva()

        tareaRespuesta = Task { [weak self] in
            do {
                let respuesta = try await sesionSegura.respond(
                    to: textoLimpio
                )

                guard !Task.isCancelled else {
                    return
                }

                self?.recibirRespuesta(
                    respuesta.content,
                    para: id,
                    solicitudID: solicitudID
                )
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                self?.recibirRespuesta(
                    "⚠️ No he podido responder. Intenta reformular la pregunta.",
                    para: id,
                    solicitudID: solicitudID
                )
            }
        }
    }

    private func recibirRespuesta(
        _ texto: String,
        para conversacionID: UUID,
        solicitudID: UUID
    ) {
        guard solicitudActivaID == solicitudID else {
            return
        }

        defer {
            estaPensando = false
            solicitudActivaID = nil
            tareaRespuesta = nil
        }

        guard let indice = conversaciones.firstIndex(
            where: { $0.id == conversacionID }
        ) else {
            return
        }

        conversaciones[indice].mensajes.append(
            MensajeChat(
                texto: texto,
                esUsuario: false
            )
        )

        conversaciones[indice].fechaActualizacion = .now
        guardarConversaciones()
    }

    // MARK: - Título

    private func tituloParaConversacion(
        _ texto: String
    ) -> String {
        let tituloLimpio = texto
            .replacingOccurrences(
                of: "\n",
                with: " "
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let limite = 44

        guard tituloLimpio.count > limite else {
            return tituloLimpio
        }

        let indiceFinal = tituloLimpio.index(
            tituloLimpio.startIndex,
            offsetBy: limite
        )

        return "\(tituloLimpio[..<indiceFinal])…"
    }
}
