# PcComponentIA

App para iPhone y iPad (SwiftUI) que **reconoce componentes de PC con la cámara** y explica qué son, para qué sirven y cómo se montan. Pensada para aprender, montar o diagnosticar un PC de casa.

Todo funciona **en el dispositivo**: la detección usa un modelo Core ML propio y el asistente usa los Foundation Models de Apple.

> Proyecto en desarrollo. Destino mínimo **iOS / iPadOS 27.0**; probado en iPadOS 27.2 beta con Xcode 27.0 beta.

---

## Índice

1. [Cómo lo desarrollé](#cómo-lo-desarrollé)
2. [Funcionalidades](#funcionalidades)
3. [Requisitos y ejecución](#requisitos-y-ejecución)
4. [Detector de componentes](#detector-de-componentes)
5. [Asistente de IA](#asistente-de-ia)
6. [Estructura del proyecto](#estructura-del-proyecto)
7. [Datos guardados](#datos-guardados)
8. [Cómo ampliar la app](#cómo-ampliar-la-app)
9. [Limitaciones y próximos pasos](#limitaciones-y-próximos-pasos)
10. [Créditos de los datos](#créditos-de-los-datos)
11. [Licencia](#licencia)

---

## Cómo lo desarrollé

PcComponentIA es un proyecto personal que he llevado de principio a fin: la idea, el diseño de la app, los datos, el entrenamiento del modelo y las pruebas en un dispositivo real.

**Desarrollo con ayuda de IA.** He escrito parte del código y el resto lo he desarrollado con asistentes de IA (Claude y Gemini). Yo decidí qué construir y cómo debía comportarse cada pantalla, y revisé, adapté y probé lo que se generaba. Además usé a Gemini como segundo revisor del código, contrastando cada error que señalaba antes de corregirlo.

**Corrección y pulido de la interfaz.** Buena parte del trabajo ha sido probar la app una y otra vez en el iPad y corregir errores de interfaz: cajas de detección descuadradas al girar el dispositivo, parpadeos, pantallas que se recargaban de más, textos y navegación. Muchos de estos errores solo aparecían al usar la app de verdad, no en el simulador.

**Datos y modelo propios.** El detector no es un modelo genérico descargado: lo he construido yo, en tres versiones.

1. **Modelo 1:** 84 fotos propias de componentes etiquetadas a mano.
2. **Modelo 2:** amplié el dataset con conjuntos públicos. Revisé las clases foto a foto, porque había errores en los originales: por ejemplo, "CPU" significaba la torre entera en un dataset, o había "radiadores" que eran disipadores.
3. **Modelo 3:** casi 4.000 imágenes y 30 clases. Detecté y eliminé fugas entre entrenamiento y test (fotogramas casi idénticos de un mismo vídeo que inflaban las métricas) y retiré las clases sin fotos suficientes.

Cada versión la medí con el mismo test para comparar de forma honesta: del **4,7 % al 27,5 % de mAP@50**. Las pruebas en el iPad sacaron problemas que no se veían en los números, como una GPU con luces RGB confundida con un teclado, que marcan el siguiente paso.

**Decisiones de producto.** Entre otras:
- que todo funcione sin conexión, en el propio dispositivo;
- que las piezas que la cámara no puede reconocer (conectores diminutos, la bomba de una refrigeración líquida) se expliquen desde la pieza visible con la que se conectan;
- qué clases mantener y cuáles retirar según los datos disponibles.

---

## Funcionalidades

**Escáner**
- Detección en tiempo real con la cámara trasera (AVFoundation + Vision + Core ML).
- Cajas estabilizadas (sin parpadeos) y ajustadas al tamaño real del fotograma, en vertical y en horizontal.
- Congelar la imagen, linterna y guía visual tipo AR sobre la placa base.
- Historial de capturas con retención configurable (7, 30 o 90 días).

**Aprender**
- Diccionario con 69 fichas de componentes, conectores y puertos: descripción, guía de montaje, dificultad y tiempo.
- Sección **"Se conecta con / Relacionado"** en cada ficha. Explica también piezas que la cámara no detecta (p. ej. el cabezal SYS_FAN desde el ventilador de caja).
- Lista separada de componentes que la IA puede detectar.

**Montar y diagnosticar**
- Checklist de montaje persistente.
- Diagnóstico por LEDs, pitidos y síntomas, con historial.
- Gestor de *builds*: componentes, precios, etiquetas, notas y presupuesto.

**Asistente**
- Chat técnico en español con Foundation Models, con historial de conversaciones.

**General**
- Onboarding inicial y modo taller (oscuro) / claro.

---

## Requisitos y ejecución

| | |
| --- | --- |
| Xcode | 27.0 beta o posterior |
| Destino | iOS / iPadOS 27.0 (`IPHONEOS_DEPLOYMENT_TARGET = 27.0`) |
| Dispositivo | Físico recomendado: el simulador no tiene cámara real |
| Asistente | Dispositivo compatible con Apple Intelligence, activado y con el modelo descargado |

1. Abre `PcComponentIA.xcodeproj`.
2. Elige el esquema **PcComponentIA** y tu iPhone/iPad como destino.
3. En *Signing & Capabilities* selecciona tu **Team**.
4. `Cmd + R`. La primera vez el dispositivo pedirá activar el **Modo desarrollador** y confiar en el desarrollador.

La app pide permiso de cámara con el texto:
*"Necesitamos acceder a la cámara para poder escanear e identificar los componentes de tu PC en tiempo real."*

---

## Detector de componentes

### Modelo actual

`PcComponentIA/ML/PcComponentDetector3.mlmodel`

| Entrenamiento | |
| --- | --- |
| Herramienta | **Create ML** (Object Detection), algoritmo **Full Network** |
| Equipo | **MacBook Air M2**, en local; unas 3,5 horas |
| Iteraciones | 6.000 (el *loss* bajó de ~13 a 2,3 y se estabilizó) |
| Imágenes | **3.988** en total, 12.611 cajas etiquetadas |
| Reparto | 3.457 de entrenamiento y 531 de test |
| Clases | 30 |

Ninguna imagen de test es un duplicado casi idéntico de otra de entrenamiento. Se comprobó comparando la huella visual de cada imagen de test con todas las de entrenamiento.
- **mAP@50 en test** (misma evaluación para los tres modelos):

| Modelo | mAP@50 |
| --- | --- |
| Modelo 1 (original, 84 fotos propias) | 4,7 % |
| Modelo 2 (Transfer Learning, 761 fotos) | 14,2 % |
| **Modelo 3 (actual)** | **27,5 %** |

### Qué detecta (30 clases)

| Grupo | Clases |
| --- | --- |
| Placa base | `Placa_Base`, `Socket_Intel`, `Socket_AMD`, `Ranura_RAM`, `Ranura_PCIe_x16`, `Ranura_M2`, `Puerto_SATA`, `Conector_ATX_24p`, `Conector_EPS_8p`, `Pila_CMOS`, `Protector_IO` |
| Componentes | `CPU`, `GPU`, `Modulo_RAM`, `Fuente_Alimentacion`, `HDD`, `SSD_SATA`, `M2_SSD_NVMe`, `Caja_PC` |
| Refrigeración | `Disipador_Aire`, `Ventilador_Caja`, `Radiador`, `Bloque_refrigeracion_liquida` |
| Puertos | `Puerto_USB_A`, `Puerto_USB_C`, `Puerto_HDMI`, `Puerto_Ethernet` |
| Periféricos | `Monitor`, `Teclado`, `Raton` |

Las claves del modelo coinciden con las de `DatosHardware.swift`. Por eso cada detección abre directamente su ficha.

Se retiraron del detector por falta de fotos: `Bomba_Liquida`, `Conector_SYS_FAN`, DisplayPort y los cables PCIe/12VHPWR. Sus fichas siguen en el diccionario.

### Cómo funciona en la app

```text
Cámara (AVFoundation, 720p)
  └─ CameraViewController ──► DetectionStabilizer ──► ScannerView
       captura fotogramas      · modelo cargado 1 vez,       · dibuja las cajas
       y limita a ~5/s           fuera del hilo principal    · abre la ficha (DatosHardware)
                               · suaviza cajas entre frames  · guarda en el historial
```

- **Umbrales de confianza:** 0,55 para aceptar una detección y 0,60 para mostrarla.
- **Estado térmico:** si el dispositivo se calienta, baja la frecuencia de análisis y, en caso extremo, la resolución.

---

## Asistente de IA

`Controllers/ControladorIA.swift` usa `FoundationModels` (`LanguageModelSession`), todo en el dispositivo.

- Especializado en hardware de PC y en español.
- Conversaciones guardadas, con límite de mensajes y retención configurable.
- Solo funciona si Apple Intelligence está disponible: dispositivo compatible, activado, idioma/región admitidos y modelo descargado.

---

## Estructura del proyecto

```text
PcComponentIA/
├── App/
│   └── PcComponentIAApp.swift         Punto de entrada, contenedor SwiftData y migración inicial
├── Controllers/
│   ├── CameraViewController.swift     Cámara, orientación, linterna y captura de fotos
│   ├── DetectionStabilizer.swift      Inferencia con Vision + Core ML y suavizado de cajas
│   └── ControladorIA.swift            Asistente con Foundation Models
├── ML/
│   └── PcComponentDetector3.mlmodel   Detector de componentes (30 clases)
├── Models/
│   ├── DatosHardware.swift            Fichas de los componentes (fuente de todo el contenido técnico)
│   ├── ComponentesRelacionados.swift  Qué piezas se conectan con cuáles
│   ├── EsquemasComponentes.swift      Datos de los esquemas interactivos de conectores
│   ├── DiagnosticoLED.swift           Base de conocimiento de LEDs, pitidos y errores
│   ├── SwiftDataModels.swift          Modelos persistentes (builds, diagnósticos, capturas)
│   ├── MigrationManager.swift         Migración única de UserDefaults a SwiftData
│   └── Modelos.swift                  Tipos compartidos (builds, categorías…)
├── View/                              Pantallas
│   ├── HomeView.swift                 Inicio, accesos rápidos y estadísticas
│   ├── ScannerView.swift              Escáner, cajas, congelado y detalle
│   ├── VisualizadorARView.swift       Guía visual sobre la placa base
│   ├── DetalleComponenteView.swift    Tarjeta de detalle de una detección
│   ├── DiccionarioView.swift          Diccionario genérico (completo o filtrado)
│   ├── ComponentesDetectablesView.swift  Lista de clases que detecta el modelo
│   ├── ChecklistMontaje.swift         Checklist de montaje
│   ├── DiagnosticoLedView.swift       Diagnóstico guiado
│   ├── MisBuildsView.swift            Lista de builds
│   ├── DetalleBuildView.swift         Edición de una build
│   ├── ChatIAView.swift               Chat con el asistente
│   ├── HistorialChatsView.swift       Conversaciones guardadas
│   ├── HistorialView.swift            Historial de capturas del escáner
│   ├── OnboardingView.swift           Bienvenida
│   └── FlowLayout.swift               Layout auxiliar
├── Diagnosticos/                      Guardado, detalle y enlaces de diagnósticos
├── Components/                        Piezas de interfaz reutilizables
│   ├── SeccionRelacionados.swift      Sección desplegable "Se conecta con"
│   ├── BotonCircular.swift
│   └── NavigationSwipeBackFix.swift
├── Settings/                          Ajustes de la app y retención de historiales
└── Extensions.swift
Creditos/
└── CREDITOS_COMMONS.json              Autor y licencia de cada foto de Wikimedia Commons usada
```

---

## Datos guardados

Todo se guarda **solo en el dispositivo**.

| Qué | Dónde |
| --- | --- |
| Builds y sus componentes | SwiftData (`BuildSD`, `ComponenteBuildSD`) |
| Diagnósticos guardados | SwiftData (`RegistroDiagnosticoSD`) |
| Historial de capturas del escáner | SwiftData (`CapturaHistorialSD`, fotos en almacenamiento externo) |
| Conversaciones del chat | UserDefaults (`conversacionesChatIA`) |
| Checklist de montaje | UserDefaults (`checklistMontajePCComponentIA`) |
| Ajustes (modo taller, retenciones, onboarding) | UserDefaults / `@AppStorage` |

`MigrationManager` pasa una única vez a SwiftData los datos antiguos que estaban en UserDefaults (builds, diagnósticos y capturas).

---

## Cómo ampliar la app

**Añadir una ficha al diccionario**
1. Añade una entrada a `DatosHardware.swift` con su clave (p. ej. `"Tarjeta_Red"`).
2. Si procede, añade sus piezas relacionadas en `ComponentesRelacionados.swift`.

**Hacer detectable un componente nuevo**
1. Reentrena el modelo con esa clase, usando exactamente la misma clave que en `DatosHardware.swift`.
2. Sustituye el `.mlmodel` en `ML/` y actualiza en `DetectionStabilizer.swift` el nombre de la clase que genera Xcode.
3. Añade la clave a `ComponentesDetectables.claves`.

**Añadir un esquema de conectores**
- Añade una entrada a `EsquemasComponentes.todos`, con las formas y los puntos en coordenadas de 0 a 1. La vista no hay que tocarla.

---

## Limitaciones y próximos pasos

- **Precisión desigual:** las ranuras y los conectores de la placa van bien, pero `Puerto_SATA`, `Protector_IO`, `Modulo_RAM`, `Radiador` y `Raton` tienen pocos aciertos. En la prueba real a veces confunde una GPU con luces RGB con un teclado. Siguiente paso: más fotos de las clases más flojas.
- **Esquema interactivo de conectores:** los datos (gráfica, placa base y tarjeta de sonido) ya están en `EsquemasComponentes.swift`; falta la vista animada y el botón "Ver conectores".
- **iOS 27.2 y chat:** subir el destino a 27.2 cuando haya SDK (Xcode 27.2) y adaptar el asistente a las novedades de Foundation Models en iOS 27.
- El escáner necesita un dispositivo físico, y el asistente, Apple Intelligence.
- No hay tests automáticos.

---

## Créditos de los datos

El detector se entrenó con fotos propias y con estos conjuntos de datos públicos. Las clases se revisaron y se tradujeron a las claves de la app.

**Roboflow Universe** (CC BY 4.0)
- [PC Components](https://universe.roboflow.com/disassembly/pc-components-2ugi7) — Disassembly
- [components detection](https://universe.roboflow.com/bullshits/components-detection) — Bullshits
- [PC](https://universe.roboflow.com/u-ju3pv/pc-7jyvc) — U
- [PC Ports](https://universe.roboflow.com/ports-gmmmp/pc-ports) — Ports
- [merged_motherboard_yolo](https://universe.roboflow.com/pokalokaopa-qv69g/merged_motherboard_yolo) — pokalokaopa
- [My First Project](https://universe.roboflow.com/detgeyjred/my-first-project-seshc) — detgeyjred
- [Computer Hardware Identification](https://universe.roboflow.com/hardentify/computer-hardware-identification) — Hardentify
- [Is This Monitor? Keyboard? Mouse?](https://universe.roboflow.com/asen-oxbum/is-this-monitor-keyboard-mouse) — Asen
- [keyboard-mouse-monitor](https://universe.roboflow.com/nogada/keyboard-mouse-monitor) — nogada

**Wikimedia Commons**: 178 fotos con licencias CC BY, CC BY-SA y CC0. El autor, la licencia y el enlace de cada una están en [`Creditos/CREDITOS_COMMONS.json`](Creditos/CREDITOS_COMMONS.json).

---

## Licencia

© 2026 Olai Fernández García. **Todos los derechos reservados.** Se puede consultar el contenido, pero no copiarlo, reutilizarlo ni publicar la app sin autorización. Los datos de terceros usados para el entrenamiento mantienen sus licencias originales. Detalles en [`LICENSE`](LICENSE).
