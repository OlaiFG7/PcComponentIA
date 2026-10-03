//
//  ControladorIA.swift
//  PcComponentIA
//

import Foundation
import Combine
import FoundationModels

struct MensajeChat: Identifiable, Codable, Equatable {
    var id = UUID()
    /// Variable porque la respuesta del asistente se va escribiendo en directo.
    var texto: String
    let esUsuario: Bool
    var fecha: Date = Date()
    /// Opcional para poder leer conversaciones guardadas antes de existir este campo.
    var esError: Bool? = nil
}

/// Lo que el usuario estaba viendo al abrir el asistente (una build, una pieza...).
/// Se envía al modelo junto a cada pregunta, pero no se muestra como mensaje.
struct ContextoChat: Equatable {
    let titulo: String
    let texto: String
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
            return L("No eliminar automáticamente")

        case .dias7:
            return L("Cada 7 días")

        case .dias30:
            return L("Cada 30 días")

        case .dias90:
            return L("Cada 90 días")
        }
    }
}

@MainActor
final class ControladorIA: ObservableObject {

    @Published var conversaciones: [ConversacionChat]
    @Published var conversacionActualID: UUID?
    @Published var estaPensando = false
    @Published var contexto: ContextoChat?

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

    /// Las instrucciones van en el idioma de la app para que el modelo responda en ese idioma.
    private var instrucciones: String {
        if Idioma.esEspanol {
            return """
            Eres un asistente técnico especializado en hardware de PC y ensamblaje.
            Responde siempre basándote en el componente exacto que el usuario menciona.
            Por ejemplo, si dice RTX 5090, responde sobre la RTX 5090 y no sobre otra generación.
            Sé breve, claro, útil y directo en español.
            """
        }
        return """
        You are a technical assistant specialised in PC hardware and building PCs.
        Always answer about the exact component the user mentions.
        For example, if they say RTX 5090, answer about the RTX 5090 and not another generation.
        Be brief, clear, helpful and direct, in English.
        """
    }

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
        enviar(pregunta, añadirMensajeUsuario: true)
    }

    /// Vuelve a enviar la última pregunta tras un error.
    func reintentar() {
        guard
            let id = conversacionActualID,
            let indice = conversaciones.firstIndex(where: { $0.id == id }),
            let ultimaPregunta = conversaciones[indice].mensajes.last(where: \.esUsuario)
        else {
            return
        }

        // Se quitan los mensajes de error que haya tras la última pregunta
        while let ultimo = conversaciones[indice].mensajes.last, ultimo.esError == true {
            conversaciones[indice].mensajes.removeLast()
        }
        enviar(ultimaPregunta.texto, añadirMensajeUsuario: false)
    }

    private func enviar(_ pregunta: String, añadirMensajeUsuario: Bool) {
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

        if añadirMensajeUsuario {
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
        }

        conversaciones[indice].fechaActualizacion = .now
        guardarConversaciones()

        // Sin Apple Intelligence no hay modelo: se explica en lugar de fallar sin más
        if case .unavailable(let motivo) = SystemLanguageModel.default.availability {
            añadirError(Self.textoNoDisponible(motivo), en: id)
            return
        }

        estaPensando = true

        let solicitudID = UUID()
        solicitudActivaID = solicitudID

        let sesionSegura = obtenerSesionActiva()
        let prompt = construirPrompt(textoLimpio)

        tareaRespuesta = Task { [weak self] in
            do {
                // La respuesta llega por partes y se va mostrando según se escribe
                let flujo = sesionSegura.streamResponse(to: prompt)
                var idRespuesta: UUID?

                for try await parcial in flujo {
                    guard !Task.isCancelled, let self else { return }
                    idRespuesta = self.actualizarRespuesta(
                        parcial.content,
                        idMensaje: idRespuesta,
                        conversacion: id,
                        solicitudID: solicitudID
                    )
                }

                guard !Task.isCancelled else { return }
                self?.terminarRespuesta(solicitudID: solicitudID)
            } catch {
                guard !Task.isCancelled, let self else {
                    return
                }

                guard self.solicitudActivaID == solicitudID else { return }
                self.terminarRespuesta(solicitudID: solicitudID)
                self.añadirError(self.textoError(error), en: id)
            }
        }
    }

    private func construirPrompt(_ pregunta: String) -> String {
        guard let contexto else { return pregunta }
        return """
        Información de la app sobre lo que el usuario está viendo (úsala si es relevante, no la repitas entera):
        \(contexto.texto)

        Pregunta del usuario: \(pregunta)
        """
    }

    /// Crea el mensaje del asistente con el primer trozo y lo va actualizando.
    private func actualizarRespuesta(
        _ texto: String,
        idMensaje: UUID?,
        conversacion conversacionID: UUID,
        solicitudID: UUID
    ) -> UUID? {
        guard solicitudActivaID == solicitudID,
              let indice = conversaciones.firstIndex(where: { $0.id == conversacionID })
        else {
            return idMensaje
        }

        if let idMensaje,
           let posicion = conversaciones[indice].mensajes.firstIndex(where: { $0.id == idMensaje }) {
            conversaciones[indice].mensajes[posicion].texto = texto
            return idMensaje
        }

        estaPensando = false
        let mensaje = MensajeChat(texto: texto, esUsuario: false)
        conversaciones[indice].mensajes.append(mensaje)
        return mensaje.id
    }

    private func terminarRespuesta(solicitudID: UUID) {
        guard solicitudActivaID == solicitudID else { return }
        estaPensando = false
        solicitudActivaID = nil
        tareaRespuesta = nil
        guardarConversaciones()
    }

    private func añadirError(_ texto: String, en conversacionID: UUID) {
        guard let indice = conversaciones.firstIndex(where: { $0.id == conversacionID }) else { return }
        conversaciones[indice].mensajes.append(
            MensajeChat(texto: texto, esUsuario: false, esError: true)
        )
        conversaciones[indice].fechaActualizacion = .now
        guardarConversaciones()
    }

    private func textoError(_ error: Error) -> String {
        // iOS 27 sustituye LanguageModelSession.GenerationError por LanguageModelError
        guard let error = error as? LanguageModelError else {
            return L("⚠️ No he podido responder. Inténtalo de nuevo.")
        }
        switch error {
        case .contextSizeExceeded:
            // La sesión ya no admite más texto: la siguiente pregunta empieza una sesión nueva
            session = nil
            return L("⚠️ La conversación es demasiado larga para recordarla entera. Pulsa «Reintentar»: seguiré sin el principio de la charla.")
        case .guardrailViolation, .refusal:
            return L("⚠️ No puedo responder a esa pregunta. Prueba a formularla de otra manera.")
        case .unsupportedLanguageOrLocale:
            return L("⚠️ Ese idioma no está disponible en el modelo del dispositivo.")
        case .rateLimited, .timeout:
            return L("⚠️ El modelo está ocupado ahora mismo. Espera unos segundos y pulsa «Reintentar».")
        default:
            return L("⚠️ No he podido responder. Inténtalo de nuevo.")
        }
    }

    private static func textoNoDisponible(_ motivo: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch motivo {
        case .deviceNotEligible:
            return L("⚠️ Este dispositivo no es compatible con Apple Intelligence, que es lo que usa el asistente.")
        case .appleIntelligenceNotEnabled:
            return L("⚠️ Activa Apple Intelligence en Ajustes > Apple Intelligence y Siri para usar el asistente.")
        case .modelNotReady:
            return L("⚠️ El modelo de Apple Intelligence se está descargando. Vuelve a intentarlo en unos minutos.")
        @unknown default:
            return L("⚠️ El asistente no está disponible ahora mismo.")
        }
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
