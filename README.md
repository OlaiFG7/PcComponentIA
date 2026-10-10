# PcComponentIA

**Español** · [English](README.en.md)

App para iPhone y iPad (SwiftUI) que **reconoce componentes de PC con la cámara** y explica qué son, para qué sirven y cómo se montan. Pensada para aprender, montar o diagnosticar un PC de casa.

Todo funciona **en el dispositivo**: la detección usa un modelo Core ML propio y el asistente usa los Foundation Models de Apple.

> Proyecto en desarrollo. Destino mínimo **iOS / iPadOS 27.0**; probado en iPadOS 27.2 beta con Xcode 27.0 beta.

<!--
  CAPTURAS (pendiente). Guardarlas en docs/capturas/ y descomentar este bloque.
  Recomendadas: 1) escáner detectando piezas en una placa, 2) ficha de un componente con
  "Se conecta con", 3) inicio, 4) chat con el asistente, 5) diagnóstico por LEDs.
  Un GIF o vídeo corto del escáner en acción es lo que más luce.

<p align="center">
  <img src="docs/capturas/escaner.png" width="230" alt="Escáner detectando componentes">
  <img src="docs/capturas/ficha.png" width="230" alt="Ficha de un componente">
  <img src="docs/capturas/inicio.png" width="230" alt="Pantalla de inicio">
</p>
-->

---

## Índice

1. [Motivación](#motivación)
2. [Cómo lo desarrollé](#cómo-lo-desarrollé)
3. [Qué he aprendido](#qué-he-aprendido)
4. [Funcionalidades](#funcionalidades)
5. [Novedades de la última versión](#novedades-de-la-última-versión)
6. [Requisitos y ejecución](#requisitos-y-ejecución)
7. [Detector de componentes](#detector-de-componentes)
8. [Asistente de IA](#asistente-de-ia)
9. [Estructura del proyecto](#estructura-del-proyecto)
10. [Datos guardados](#datos-guardados)
11. [Cómo ampliar la app](#cómo-ampliar-la-app)
12. [Limitaciones y próximos pasos](#limitaciones-y-próximos-pasos)
13. [Créditos de los datos](#créditos-de-los-datos)
14. [Autor](#autor)
15. [Licencia](#licencia)

---

## Motivación

Montar o reparar un PC por primera vez intimida: hay decenas de conectores parecidos, y un cable mal puesto puede hacer que el equipo no arranque. Quería una app que, con solo apuntar la cámara, te dijera **qué es cada pieza y cómo se conecta**, explicado para alguien que empieza.

A la vez, era la excusa perfecta para **aprender desarrollo iOS e inteligencia artificial con un proyecto real**, de principio a fin: una app completa en SwiftUI, un modelo de visión entrenado por mí y un asistente de IA que funciona en el propio dispositivo.

---

## Cómo lo desarrollé

PcComponentIA es un proyecto personal que he llevado de principio a fin: la idea, el diseño de la app, los datos, el entrenamiento del modelo y las pruebas en un dispositivo real.

**Desarrollo con ayuda de IA.** He escrito parte del código y el resto lo he desarrollado con asistentes de IA (Claude, Gemini y Codex). Yo decidí qué construir y cómo debía comportarse cada pantalla, y revisé, adapté y probé lo que se generaba. Además usé a Gemini y a Codex como revisores del código, incluso revisando cada uno el trabajo del otro, y contrasté cada error que señalaban antes de corregirlo.

**Corrección y pulido de la interfaz.** Buena parte del trabajo ha sido probar la app una y otra vez en el iPad y corregir errores de interfaz: cajas de detección descuadradas al girar el dispositivo, parpadeos, pantallas que se recargaban de más, textos y navegación. Muchos de estos errores solo aparecían al usar la app de verdad, no en el simulador.

**Datos y modelo propios.** El detector no es un modelo genérico descargado: lo he construido yo, en cuatro versiones.

1. **Modelo 1:** 84 fotos propias de componentes etiquetadas a mano.
2. **Modelo 2:** amplié el dataset con conjuntos públicos. Revisé las clases foto a foto, porque había errores en los originales: por ejemplo, "CPU" significaba la torre entera en un dataset, o había "radiadores" que eran disipadores.
3. **Modelo 3:** casi 4.000 imágenes y 30 clases. Detecté y eliminé fugas entre entrenamiento y test (fotogramas casi idénticos de un mismo vídeo que inflaban las métricas) y retiré las clases sin fotos suficientes.
4. **Modelo 4:** 8.670 imágenes y 25 clases, con miles de fotos nuevas de datasets públicos revisados uno a uno. Uní los dos sockets en `Socket_CPU` y saqué del detector las piezas que se explican mejor en el visor 3D o en los esquemas.

Cada versión la medí con el mismo test para comparar de forma honesta: del **4,7 % al 28,7 % de mAP@50**. Pero los números no lo cuentan todo: el modelo 4 solo sube un punto en el test y, en el iPad, funciona bastante mejor que el 3 (ver [Detector de componentes](#detector-de-componentes)).

**Decisiones de producto.** Entre otras:
- que todo funcione sin conexión, en el propio dispositivo;
- que las piezas que la cámara no puede reconocer (conectores diminutos, la bomba de una refrigeración líquida) se expliquen desde la pieza visible con la que se conectan;
- qué clases mantener y cuáles retirar según los datos disponibles.

---

## Qué he aprendido

- **Entrenar un modelo de visión de principio a fin.** Preparar y etiquetar datos, entrenar con Create ML y comparar versiones con un test justo. La mayor lección: **los datos pesan más que el algoritmo**. Revisar etiquetas y quitar duplicados mejoró el modelo más que cualquier ajuste.
- **SwiftUI y desarrollo iOS en un dispositivo real.** Cámara con AVFoundation, Vision, Core ML, SwiftData y Foundation Models. Y depurar lo que solo falla en el iPad: la rotación, el rendimiento o el calor del dispositivo.
- **Trabajar con IA sin perder el control.** Usar asistentes de IA para programar más rápido, pero decidiendo yo qué se hace, revisando lo que proponen y usando a una segunda IA para contrastar errores. La responsabilidad del resultado sigue siendo mía.

---

## Funcionalidades

**Escáner**
- Detección en tiempo real con la cámara trasera (AVFoundation + Vision + Core ML).
- Cajas estabilizadas (sin parpadeos) que se deslizan entre fotogramas y ajustadas al tamaño real del fotograma, en vertical y en horizontal.
- **Analizar una foto de la galería** (también sin permiso de cámara).
- Congelar la imagen, linterna, vibración suave al reconocer una pieza y guía visual tipo AR sobre la placa base.
- Historial de capturas con retención configurable (7, 30 o 90 días).

**Aprender**
- Diccionario con 69 fichas de componentes, conectores y puertos: descripción, guía de montaje, dificultad, tiempo y, en algunas, foto real. Con **niveles Básico, Intermedio y Experto** y un **glosario de siglas**.
- **Visor 3D** (RealityKit) de la gráfica, la placa base, la RAM, el SSD M.2 y la fuente: la cámara se acerca a cada conector y muestra una burbuja con su explicación.
- **"¿Cuál es cuál?"**: comparador de conectores parecidos, con dibujos y avisos.
- **Esquemas interactivos 2D** de conectores para el resto (p. ej. tarjeta de sonido).
- Sección **"Se conecta con / Relacionado"** en cada ficha.
- Lista separada de componentes que la IA puede detectar.

**Montar y diagnosticar**
- Gestor de *builds*: componentes, precios, etiquetas, notas y presupuesto; añadir piezas desde el escáner o el diccionario; compartir como texto o imagen.
- **Compatibilidad y consumo**: socket CPU/placa, DDR4/DDR5, salida de vídeo y fuente recomendada a partir de los nombres de las piezas.
- **Guías de montaje animadas** para el procesador y el disipador, la RAM y la gráfica.
- Checklist de montaje persistente, **uno por build**.
- Diagnóstico por LEDs (Q-LED), códigos POST y **pitidos** (AMI y Award), con historial.

**Asistente**
- Chat técnico con Foundation Models que responde en el idioma del dispositivo: respuestas en directo, contexto de la build o pieza que estás viendo, errores explicados y botón "Reintentar".

**Sistema**
- **iPad**: barra lateral con todas las secciones (`NavigationSplitView`).
- **Siri y Atajos**: "Escanea un componente con PcComponentIA", "¿Cómo va mi montaje en PcComponentIA?"…
- **Español e inglés** (catálogo `Localizable.xcstrings`).
- Onboarding, modo taller (oscuro) / claro, animaciones que respetan "Reducir movimiento" y etiquetas de VoiceOver.

---

## Novedades de la última versión

Versión de octubre de 2026. El objetivo ha sido que la app enseñe mejor, no solo que detecte: más formas de ver cómo es cada pieza y cómo se monta.

**Guías de montaje (nuevo apartado)**
- Guías paso a paso de los tres puntos más delicados: **procesador y disipador** (9 pasos), **memoria RAM** (5) y **tarjeta gráfica** (6).
- Cada paso lleva un **dibujo animado** hecho con `Canvas`, el texto y, cuando hay riesgo, un aviso. La del procesador se adapta al socket: Intel LGA, AMD AM5 o AMD AM4.
- Al terminar, se marcan desde la propia guía los pasos correspondientes del checklist.

**Piezas en 3D (nuevo apartado)**
- Todos los modelos 3D reunidos en una galería, además del botón de cada ficha.
- **Visor 3D corregido:** los puntos de la placa base flotaban por delante del modelo, porque este incluye los módulos de RAM montados y falseaba la altura. Ahora cada punto está sobre su pieza y la cámara mira la placa de frente.
- La placa base pasa de 15 a **23 conectores** explicados, con una fila deslizable para elegirlos y un dibujo de la forma del conector en la burbuja.
- **"¿Cuál es cuál?":** 12 comparaciones de conectores que se confunden (HDMI y DisplayPort, EPS y PCIe, RGB y ARGB, sockets de Intel y AMD, tamaños de placa, cables de la fuente…), con dibujos vectoriales y avisos en las parejas que pueden causar daños.

**Diccionario**
- **Niveles Básico, Intermedio y Experto:** quien empieza ve solo las 17 piezas principales; el resto se muestra al subir de nivel. Al buscar se ignora el nivel.
- **Glosario de siglas** con 35 términos (PWM, XMP, VRM, NVMe…), cada uno explicado en una frase.

**Escáner**
- Filtro de **cajas repetidas**: si el modelo marca el mismo objeto varias veces, se queda solo con la detección más fiable.
- Al detectar una CPU o un socket ya se ofrece marcar su paso del checklist (la clase unificada del modelo 4 no estaba contemplada).

**Interfaz**
- **Bienvenida rehecha:** seis páginas con tres puntos concretos cada una, que ya cuentan las funciones recientes.
- En iPad, Inicio muestra el botón que abre y cierra la barra lateral; el botón de idioma indica el idioma activo.
- Correcciones de la versión en inglés (nombres y buscador del diccionario, ficha del escáner).

Para colocar los puntos del visor 3D sin depender del dispositivo usé una herramienta propia: dibuja cada modelo USDZ desde tres vistas con una cuadrícula y los puntos encima. Las revisiones de Codex y Gemini se contrastaron una a una antes de aplicar nada.

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

`PcComponentIA/ML/PcComponentDetector4.mlmodel`

| Entrenamiento | |
| --- | --- |
| Herramienta | **Create ML** (Object Detection), algoritmo **Full Network** |
| Equipo | **MacBook Air M2**, en local; unas 5 horas |
| Iteraciones | 6.300 (*snapshot* elegido entre varios; el *loss* bajó de ~12 a 2,0) |
| Imágenes | **8.670** en total |
| Reparto | 8.045 de entrenamiento y 625 de test |
| Clases | 25 |

Ninguna imagen de test es un duplicado casi idéntico de otra de entrenamiento. Se comprobó comparando la huella visual de cada imagen de test con todas las de entrenamiento.

- **mAP@50 en test:**

| Modelo | mAP@50 |
| --- | --- |
| Modelo 1 (original, 84 fotos propias) | 4,7 % |
| Modelo 2 (Transfer Learning, 761 fotos) | 14,2 % |
| Modelo 3 (3.988 fotos, 30 clases) | 27,5 % |
| **Modelo 4 (actual, 8.670 fotos, 25 clases)** | **28,7 %** |

El modelo 4 se evaluó con su propio test (625 fotos y 25 clases), así que la comparación con el 3 es orientativa.

**Por qué funciona mejor de lo que dice el 28,7 %.** En el iPad el modelo 4 reconoce las piezas con mucha más seguridad que el 3. La diferencia con el número tiene explicación:
- **Encuentra casi todo (recall):** detecta el 89 % de las CPU, el 96 % de los sockets y de las placas base y el 84-85 % de los M.2 y discos duros.
- **Las piezas grandes puntúan bien en AP@50**, que además exige que la caja esté bien colocada: 75 % la CPU, 68 % el socket, 58 % el M.2 y 53 % el disco duro.
- **Etiquetas incompletas:** las fotos vienen de varios datasets y cada uno etiquetó solo sus piezas. Si en una foto de discos duros aparece un teclado sin etiquetar y el modelo lo detecta bien, el test lo cuenta como fallo. Es lo que hunde clases como el ratón: lo encuentra el 59 % de las veces, pero su AP@50 es del 2,5 %.
- **Clases pequeñas o con pocas fotos de test:** puertos y ranuras son difíciles para cualquier modelo, y clases como el radiador solo tienen 4 cajas en el test. Como el mAP es la media de las clases, cada una pesa lo mismo.
- **En la app se filtra el ruido:** solo se muestran detecciones con confianza ≥ 0,55, y el estabilizador descarta las que aparecen en un solo fotograma.

Para elegir el modelo comparé dos *snapshots* con el test: el de la iteración 4.440 dio un 26,7 % y el de la 6.300, un 28,7 %, así que entrenar más no lo sobreajustó.

### Qué detecta (25 clases)

| Grupo | Clases |
| --- | --- |
| Placa base | `Placa_Base`, `Socket_CPU`, `Ranura_RAM`, `Ranura_PCIe_x16`, `Ranura_M2`, `Conector_ATX_24p`, `Conector_EPS_8p` |
| Componentes | `CPU`, `GPU`, `Modulo_RAM`, `Fuente_Alimentacion`, `HDD`, `SSD_SATA`, `M2_SSD_NVMe`, `Caja_PC` |
| Refrigeración | `Disipador_Aire`, `Ventilador_Caja`, `Radiador`, `Bloque_refrigeracion_liquida` |
| Puertos | `Puerto_USB_A`, `Puerto_USB_C`, `Puerto_Ethernet` |
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

`Funciones/Asistente/ControladorIA.swift` usa `FoundationModels` (`LanguageModelSession`), todo en el dispositivo.

- Especializado en hardware de PC; responde en el idioma del dispositivo (español o inglés).
- Conversaciones guardadas, con límite de mensajes y retención configurable.
- Solo funciona si Apple Intelligence está disponible: dispositivo compatible, activado, idioma/región admitidos y modelo descargado.

---

## Estructura del proyecto

Organizado por funcionalidad: cada carpeta de `Funciones/` reúne las pantallas, la lógica y los datos de esa parte de la app.

```text
PcComponentIA/
├── App/                    Arranque, raíz (barra lateral en iPad) y atajos de Siri
├── Funciones/
│   ├── Inicio/             Pantalla de inicio y bienvenida
│   ├── Escaner/            Cámara, detector (Vision + Core ML), escáner y guía AR
│   ├── Componentes/        Diccionario, fichas, niveles, glosario, esquemas 2D, visor 3D y comparador
│   ├── Builds/             Mis builds, compatibilidad y consumo, compartir
│   ├── Montaje/            Checklist (uno por build) y guías de montaje animadas
│   ├── Diagnostico/        LEDs, códigos POST, pitidos e historial de diagnósticos
│   ├── Asistente/          Chat con Foundation Models
│   └── Historial/          Historial de capturas y su retención
├── Comun/
│   ├── Datos/              Modelos de SwiftData y migración desde UserDefaults
│   ├── Diseno/             Animaciones, rejillas y componentes de interfaz compartidos
│   ├── AppSettings.swift
│   ├── Extensions.swift
│   └── Localizacion.swift  Idioma de la app (español/inglés) y cambio en directo
├── ML/                     PcComponentDetector4.mlmodel
├── Modelos3D/              Modelos USDZ del visor 3D
├── Assets/                 Iconos, colores y fotos de las fichas
├── Localizable.xcstrings   Traducciones de la interfaz y del contenido (español → inglés)
└── PrivacyInfo.xcprivacy   Manifiesto de privacidad (sin rastreo ni datos recogidos)
Creditos/
└── CREDITOS_COMMONS.json   Autor y licencia de cada foto de Wikimedia Commons usada
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
| Checklist de montaje | UserDefaults (`checklistMontajePCComponentIA`, más una clave por build) |
| Ajustes (modo taller, retenciones, onboarding) | UserDefaults / `@AppStorage` |

`MigrationManager` pasa una única vez a SwiftData los datos antiguos que estaban en UserDefaults (builds, diagnósticos y capturas).

---

## Cómo ampliar la app

**Añadir una ficha al diccionario**
1. Añade una entrada a `DatosHardware.swift` con su clave (p. ej. `"Tarjeta_Red"`).
2. Si procede, añade sus piezas relacionadas en `ComponentesRelacionados.swift`.
3. Añade la traducción al inglés en `Localizable.xcstrings`.

**Hacer detectable un componente nuevo**
1. Reentrena el modelo con esa clase, usando exactamente la misma clave que en `DatosHardware.swift`.
2. Sustituye el `.mlmodel` en `ML/` y actualiza en `DetectionStabilizer.swift` el nombre de la clase que genera Xcode.
3. Añade la clave a `ComponentesDetectables.claves`.

**Añadir un esquema de conectores**
- Añade una entrada a `EsquemasComponentes.todos`, con las formas y los puntos en coordenadas de 0 a 1. La vista no hay que tocarla.

**Añadir un modelo 3D**
1. Copia el `.usdz` en `Modelos3D/` (con licencia que permita su uso y su crédito).
2. Añade una entrada a `ModelosPiezas3D.todos` con los conectores en coordenadas de 0 a 1 dentro del modelo. Si existe, el botón de la ficha pasa a "Ver en 3D".

**Añadir una foto a una ficha**
- Imagen `foto_<clave>` en `Assets` y su autor/licencia en `FotosFichas.creditos`.

---

## Limitaciones y próximos pasos

- **Precisión desigual del detector:** las piezas grandes (CPU, socket, M.2, discos duros, fuente) van bien, pero `Modulo_RAM`, `Raton` y la refrigeración líquida siguen flojos. El siguiente paso (modelo 5): **ajustar mejor las etiquetas de las fotos actuales**, completando las que faltan en las fotos de datasets mezclados (el propio modelo 4 puede proponer las cajas y solo habría que validarlas), y **reunir más fotos de los componentes que peor detecta**: módulos de RAM, ratón, radiador, bloque de líquida, puertos USB y GPU. `Pila_CMOS`, `Puerto_SATA`, `Puerto_HDMI` y `Protector_IO` ya no se detectan; se explican en sus fichas, en los esquemas y en el visor 3D.
- **Próximas funciones:** primer arranque guiado (qué comprobar al encender, BIOS, XMP), buscador global en Inicio y texto distinto por nivel dentro de cada ficha (ahora los niveles solo filtran qué fichas se ven).
- **Visor 3D:** en el modelo de la placa no se distinguen con seguridad algunos conectores (PCIe x4, USB-C frontal), así que no están señalados.
- **Puertos en el detector:** los puertos pequeños (`Puerto_USB_A`, `Puerto_USB_C`, `Puerto_Ethernet`) son los que peor detecta. Una opción para el modelo 5 es quitarlos del detector, como ya se hizo con HDMI y SATA, y explicarlos en el visor 3D.
- **Compatibilidad orientativa:** se deduce de los nombres que escribe el usuario; si un modelo no se reconoce, la app lo dice en lugar de suponer.
- **Sin widgets ni iCloud:** requieren la cuenta de desarrollador de pago (App Groups / CloudKit).
- El escáner necesita un dispositivo físico, y el asistente, Apple Intelligence.
- Solo hay pruebas manuales de la lógica de compatibilidad; faltan tests automáticos.

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

**Dentro de la app**
- Foto de la ficha de la pila CMOS: «CMOS Battery, Motherboard» de Kent Madsen, [CC BY-SA 2.0](https://commons.wikimedia.org/wiki/File:CMOS_Battery,_Motherboard.jpg).
- Modelos 3D de [Sketchfab](https://sketchfab.com), todos con licencia CC BY 4.0:
  - [GeForce RTX 3080 Graphics Card](https://sketchfab.com/3d-models/geforce-rtx-3080-graphics-card-8b947ee1bf7a4e3d8ffa1c24893ac160) — _surovic_
  - [MotherBoard + Components](https://sketchfab.com/3d-models/motherboard-components-3bc94057328243d4b341a55f59160f8a) — Daniel Cardona
  - [RAM-Hynix553-8a-24GB(DDR5S)](https://sketchfab.com/3d-models/ram-hynix553-8a-24gbddr5s-a5285af98b9b49d78472eb76ed2d730d) — Apple
  - [SSD NoName m.2 256gb](https://sketchfab.com/3d-models/ssd-noname-m2-256gb-ac3e66d1e3bf46dc8684a3e4abae584b) — Хлюпич
  - [M1000 inspired by Corsair HX1000](https://sketchfab.com/3d-models/m1000-inspired-by-corsair-hx1000-free-6d122273398b446a876600401ba08b55) — Igor.Jop

---

## Autor

**Olai Fernández García**, estudiante de último curso de **Ingeniería Informática** en la Universidad de Oviedo.

- LinkedIn: [Olai Fernández García](https://www.linkedin.com/in/olai-fernandez-garcia-a12897222/)
- GitHub: [@OlaiFG7](https://github.com/OlaiFG7)

---

## Licencia

© 2026 Olai Fernández García. **Todos los derechos reservados.** Se puede consultar el contenido, pero no copiarlo, reutilizarlo ni publicar la app sin autorización. Los datos de terceros usados para el entrenamiento mantienen sus licencias originales. Detalles en [`LICENSE`](LICENSE).
