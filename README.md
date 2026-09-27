# PcComponentIA

PcComponentIA es una app SwiftUI en español para identificar, aprender y documentar componentes de PC durante el montaje, mantenimiento o diagnóstico de un equipo. La app combina cámara, detección local con Core ML, un diccionario técnico, checklist de montaje, diagnósticos, builds guardadas y un asistente de IA especializado en hardware.

El proyecto está en desarrollo activo y se está probando con macOS 27 beta 3 e iPadOS 27 beta 3.

## Estado del Proyecto

- App iOS/iPadOS creada con SwiftUI.
- Desarrollada actualmente en macOS 27 beta 3.
- Probada con iPadOS 27 beta 3.
- Target principal: `PcComponentIA`.
- Interfaz y contenido técnico en español.
- Detección basada en un modelo Core ML local incluido en el proyecto.

## Funcionalidades

- Escáner de componentes en tiempo real usando la cámara.
- Detección local con AVFoundation, Vision y Core ML.
- Vista separada para componentes detectables por la IA.
- Diccionario completo de componentes, conectores, ranuras y conceptos de hardware.
- Fichas técnicas con descripción, guía de montaje o uso, dificultad y tiempo estimado.
- Guía visual tipo AR sobre la imagen de la placa base para orientar instalaciones.
- Checklist persistente para seguir el montaje completo de un PC.
- Historial de escaneos.
- Historial de chats con retención configurable.
- Diagnóstico de LEDs y errores comunes de PC.
- Historial de diagnósticos guardados.
- Gestor de builds con componentes, etiquetas, notas y presupuesto.
- Asistente técnico con Foundation Models.
- Onboarding inicial.
- Modo taller oscuro y modo claro.

## Componentes Detectables

La lógica de componentes detectables está separada en:

```text
PcComponentIA/PcComponentIA/View/ComponentesDetectablesView.swift
```

Este archivo contiene:

- `ComponentesDetectables.claves`: conjunto de claves que el modelo puede detectar actualmente.
- `ComponentesDetectables.diccionario`: filtro del diccionario general para mostrar solo detectables.
- `ComponentesDetectables.total`: contador usado por el Home.
- `ComponentesDetectablesView`: pantalla que reutiliza `DiccionarioView` con colores propios para la sección Detectables.

La idea es que esta lista crezca en el futuro conforme el modelo Core ML aprenda o incluya más clases. Para añadir nuevos detectables, normalmente basta con:

1. Añadir la clave al modelo o confirmar que el modelo ya la devuelve.
2. Asegurar que existe esa misma clave en `DatosHardware.swift`.
3. Añadir la clave a `ComponentesDetectables.claves`.

Detectables actuales:

- `Socket_Intel`
- `Socket_AMD`
- `CPU`
- `Ranura_PCIe_x16`
- `Ranura_RAM`
- `Pila_CMOS`
- `Protector_IO`
- `GPU`
- `Modulo_RAM`
- `Fuente_Alimentacion`
- `HDD`
- `SSD_SATA`
- `M2_SSD_NVMe`
- `Ranura_M2`
- `Puerto_SATA`
- `Ventilador_Caja`
- `Disipador_Aire`
- `Radiador`
- `Bloque_refrigeracion_liquida`
- `Bomba_Liquida`
- `Conector_ATX_24p`
- `Conector_EPS_8p`
- `Conector_SYS_FAN`
- `Placa_Base`, `Caja_PC`, `Puerto_HDMI`, `Puerto_Ethernet`, `Puerto_USB_A`, `Puerto_USB_C` (necesitan el modelo reentrenado con `~/Proyectos/DatosPC`; el modelo actual no las detecta)

El modelo actual (`Pc component detector 1.mlmodel`) todavía devuelve los nombres antiguos del dataset (`Bloque_CPU`, `Discos_HDD`, `RAM`...). `ScannerView.buscarInformacion` los traduce con su tabla de alias. El dataset (`~/Proyectos/DatosPC`) ya usa estas mismas claves, así que un modelo reentrenado las devolverá directamente.

## Arquitectura General

La app sigue una estructura SwiftUI sencilla, con datos compartidos desde `PcComponentIAApp` mediante `@StateObject` y `@EnvironmentObject`.

```text
PcComponentIA/
├── App/
│   └── PcComponentIAApp.swift
├── Components/
│   ├── BotonCircular.swift
│   └── NavigationSwipeBackFix.swift
├── Controllers/
│   ├── CameraViewController.swift
│   └── ControladorIA.swift
├── Diagnosticos/
│   ├── AlmacenDiagnosticos.swift
│   ├── DetalleDiagnosticoGuardadoView.swift
│   ├── HistorialDiagnosticosView.swift
│   └── RegistroDiagnostico.swift
├── ML/
│   └── Pc component detector 1.mlmodel
├── Models/
│   ├── DatosHardware.swift
│   ├── DiagnosticoLED.swift
│   └── Modelos.swift
├── Settings/
│   ├── AjustesHistorialEscaneos.swift
│   └── AppSettings.swift
└── View/
    ├── ChatIAView.swift
    ├── ChecklistMontaje.swift
    ├── ComponentesDetectablesView.swift
    ├── DetalleBuildView.swift
    ├── DetalleComponenteView.swift
    ├── DiagnosticoLedView.swift
    ├── DiccionarioView.swift
    ├── FlowLayout.swift
    ├── HistorialChatsView.swift
    ├── HistorialView.swift
    ├── HomeView.swift
    ├── MisBuildsView.swift
    ├── OnboardingView.swift
    ├── ScannerView.swift
    └── VisualizadorARView.swift
```

## Pantallas Principales

| Archivo | Responsabilidad |
| --- | --- |
| `HomeView.swift` | Pantalla principal, accesos rápidos, resumen de checklist y estadísticas. |
| `ScannerView.swift` | Escáner con cámara, detecciones, congelado de imagen, detalle y guía visual. |
| `ComponentesDetectablesView.swift` | Lista filtrada de componentes detectables por IA. |
| `DiccionarioView.swift` | Vista genérica para mostrar componentes y conexiones desde un diccionario. |
| `DetalleComponenteView.swift` | Detalle técnico de un componente detectado o seleccionado. |
| `VisualizadorARView.swift` | Superposición visual para guiar la colocación de componentes. |
| `ChecklistMontaje.swift` | Checklist interactiva del montaje del PC. |
| `ChatIAView.swift` | Chat técnico usando Foundation Models. |
| `HistorialChatsView.swift` | Historial de conversaciones del asistente. |
| `HistorialView.swift` | Historial de capturas o escaneos. |
| `MisBuildsView.swift` | Lista y gestión de builds guardadas. |
| `DetalleBuildView.swift` | Edición y detalle de una build. |
| `DiagnosticoLedView.swift` | Diagnóstico guiado por LEDs, síntomas y errores. |
| `HistorialDiagnosticosView.swift` | Historial de diagnósticos guardados. |
| `OnboardingView.swift` | Flujo inicial de bienvenida. |

## Modelo Core ML

El modelo incluido está en:

```text
PcComponentIA/PcComponentIA/ML/Pc component detector 1.mlmodel
```

`CameraViewController` carga ese modelo, lo convierte a `VNCoreMLModel` y procesa frames de vídeo con Vision. La inferencia ocurre localmente en el dispositivo.

Detalles relevantes:

- Usa la cámara trasera con AVFoundation.
- Procesa frames en colas separadas para no bloquear la interfaz.
- Aplica confianza mínima para filtrar detecciones.
- Mantiene detecciones estables para evitar parpadeos en pantalla.
- Limita el número de cajas visibles.
- Permite linterna y captura congelada para revisar un componente.

## IA con Foundation Models

`ControladorIA.swift` gestiona el asistente técnico usando `FoundationModels` y `LanguageModelSession`.

El asistente está orientado a:

- Resolver dudas de hardware.
- Responder en español.
- Mantener conversaciones guardadas.
- Limitar historial y mensajes por conversación.
- Aplicar retención configurable.

La disponibilidad depende del sistema:

- El dispositivo debe ser compatible con Apple Intelligence.
- Apple Intelligence debe estar activo.
- La región y el idioma deben permitir el uso del modelo.
- Los recursos del modelo del sistema deben estar descargados.

## Persistencia Local

La app usa `UserDefaults` con modelos `Codable` para datos ligeros.

| Dato | Clave |
| --- | --- |
| Builds guardadas | `misBuildsGuardados` |
| Checklist de montaje | `checklistMontajePCComponentIA` |
| Version de checklist | `checklistMontajeVersionPCComponentIA` |
| Conversaciones del chat | `conversacionesChatIA` |
| Retención del chat | `retencionHistorialChatIA` |
| Diagnósticos guardados | `historialDiagnosticosPC` |
| Onboarding completado | `onboardingCompletado` |
| Tema / modo taller | `modoTaller` |

## Requisitos de Desarrollo

- macOS 27 beta 3.
- Xcode compatible con los SDK beta usados por el proyecto.
- iPadOS 27 beta 3 para pruebas en iPad.
- Dispositivo físico recomendado para probar cámara, linterna y detección real.
- Apple Intelligence disponible para probar el asistente con Foundation Models.

El target actual tiene `IPHONEOS_DEPLOYMENT_TARGET` configurado en `26.5`.

## Permisos

La app solicita permiso de cámara para escanear componentes.

Texto configurado:

```text
Necesitamos acceder a la cámara para poder escanear e identificar los componentes de tu PC en tiempo real.
```

## Ejecución

1. Abre el proyecto en Xcode.
2. Selecciona el esquema `PcComponentIA`.
3. Elige un destino iPhone, iPad o simulador compatible.
4. Para validar el escáner, usa un dispositivo físico.
5. Ejecuta con `Cmd + R`.

## Notas Para Seguir Desarrollando

- `DatosHardware.swift` es la fuente principal del contenido técnico.
- `ComponentesDetectablesView.swift` concentra qué elementos puede detectar la IA ahora mismo.
- `DiccionarioView.swift` debe seguir siendo genérica para poder reutilizarse con el diccionario completo o con subconjuntos filtrados.
- `HomeView.swift` solo debería coordinar accesos, resumen y estadísticas, evitando contener listas largas de datos.
- Si crece mucho la persistencia, puede convenir migrar de `UserDefaults` a SwiftData u otro almacenamiento estructurado.

## Limitaciones Actuales

- El escáner completo necesita cámara física; el simulador no valida la captura real.
- El chat depende de Foundation Models y Apple Intelligence.
- La lista de detectables depende de las clases que realmente devuelva el modelo Core ML.
- El proyecto no incluye targets de test visibles en la estructura actual.
