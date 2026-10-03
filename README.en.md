# PcComponentIA

[Español](README.md) · **English**

An iPhone and iPad app (SwiftUI) that **recognises PC components with the camera** and explains what they are, what they do and how to install them. Built to help people learn about, build or troubleshoot a home PC.

Everything runs **on device**: detection uses a custom Core ML model and the assistant uses Apple's Foundation Models.

> Work in progress. Minimum target **iOS / iPadOS 27.0**; tested on iPadOS 27.2 beta with Xcode 27.0 beta.

<!--
  SCREENSHOTS (pending). Save them in docs/capturas/ and uncomment this block.

<p align="center">
  <img src="docs/capturas/escaner.png" width="230" alt="Scanner detecting components">
  <img src="docs/capturas/ficha.png" width="230" alt="Component sheet">
  <img src="docs/capturas/inicio.png" width="230" alt="Home screen">
</p>
-->

---

## Contents

1. [Motivation](#motivation)
2. [How I built it](#how-i-built-it)
3. [What I learned](#what-i-learned)
4. [Features](#features)
5. [Requirements and running the app](#requirements-and-running-the-app)
6. [Component detector](#component-detector)
7. [AI assistant](#ai-assistant)
8. [Project structure](#project-structure)
9. [Stored data](#stored-data)
10. [Extending the app](#extending-the-app)
11. [Limitations and next steps](#limitations-and-next-steps)
12. [Data credits](#data-credits)
13. [Author](#author)
14. [License](#license)

---

## Motivation

Building or repairing a PC for the first time is intimidating: there are dozens of similar-looking connectors, and one cable in the wrong place can stop the computer from booting. I wanted an app that, just by pointing the camera, would tell you **what each part is and how it connects**, explained for a beginner.

It was also the perfect excuse to **learn iOS development and artificial intelligence through a real project**, end to end: a complete SwiftUI app, a vision model I trained myself and an AI assistant that runs on the device.

---

## How I built it

PcComponentIA is a personal project I have taken from start to finish: the idea, the app design, the data, training the model and testing on a real device.

**AI-assisted development.** I wrote part of the code and developed the rest with AI assistants (Claude, Gemini and Codex). I decided what to build and how each screen should behave, and I reviewed, adapted and tested what was generated. I also used Gemini and Codex as code reviewers — even having each one review the other's work — and checked every issue they raised before fixing it.

**Fixing and polishing the interface.** A large part of the work was testing the app over and over on the iPad and fixing interface bugs: detection boxes misaligned when rotating the device, flickering, screens reloading too often, text and navigation. Many of these bugs only showed up when actually using the app, not in the simulator.

**My own data and model.** The detector is not a generic downloaded model: I built it myself, in several versions.

1. **Model 1:** 84 of my own photos of components, labelled by hand.
2. **Model 2:** I extended the dataset with public datasets. I reviewed the classes photo by photo because the originals had mistakes: for example, "CPU" meant the whole tower in one dataset, and some "radiators" were actually heatsinks.
3. **Model 3:** almost 4,000 images and 30 classes. I found and removed leaks between training and test (near-identical frames from the same video that inflated the metrics) and dropped classes without enough photos.
4. **Model 4:** 8,670 images and 25 classes, with thousands of new photos from public datasets reviewed one by one. I merged the two sockets into `Socket_CPU` and removed from the detector the parts that are better explained in the 3D viewer or the diagrams.

I measured every version on a test set to compare them honestly: from **4.7% to 28.7% mAP@50**. But the numbers do not tell the whole story: model 4 only gains one point on the test set, yet on the iPad it works much better than model 3 (see [Component detector](#component-detector)).

**Product decisions.** Among others:
- everything works offline, on the device itself;
- parts the camera cannot recognise (tiny connectors, the pump of a liquid cooler) are explained from the visible part they connect to;
- which classes to keep and which to drop, based on the available data.

---

## What I learned

- **Training a vision model end to end.** Preparing and labelling data, training with Create ML and comparing versions on a fair test. The biggest lesson: **data matters more than the algorithm**. Reviewing labels and removing duplicates improved the model more than any parameter tweak.
- **SwiftUI and iOS development on a real device.** Camera with AVFoundation, Vision, Core ML, SwiftData and Foundation Models. And debugging what only fails on the iPad: rotation, performance or the device heating up.
- **Working with AI without losing control.** Using AI assistants to code faster, while still deciding what gets built, reviewing what they propose and using a second AI to double-check issues. The responsibility for the result is still mine.

---

## Features

**Scanner**
- Real-time detection with the rear camera (AVFoundation + Vision + Core ML).
- Stabilised boxes (no flickering) that glide between frames and match the real frame size, in portrait and landscape.
- **Analyse a photo from the library** (even without camera permission).
- Freeze the image, torch, gentle haptic when a part is recognised, and an AR-style visual guide over the motherboard.
- Capture history with configurable retention (7, 30 or 90 days).

**Learn**
- Dictionary with 69 sheets on components, connectors and ports: description, installation guide, difficulty, time and, for some, a real photo.
- **3D viewer** (RealityKit) for the graphics card, motherboard, RAM, M.2 SSD and power supply: the camera zooms into each connector and shows a bubble explaining it.
- **Interactive 2D connector diagrams** for the rest (e.g. sound card).
- **"Connects to / Related"** section on every sheet.
- Separate list of the components the AI can detect.

**Build and troubleshoot**
- *Build* manager: components, prices, tags, notes and budget; add parts from the scanner or the dictionary; share as text or image.
- **Compatibility and power draw**: CPU/motherboard socket, DDR4/DDR5, video output and recommended PSU, worked out from the part names.
- Persistent assembly checklist, **one per build**.
- Troubleshooting by LEDs (Q-LED), POST codes and **beep codes** (AMI and Award), with history.

**Assistant**
- Technical chat with Foundation Models: streamed answers, context from the build or part you are viewing, clear error messages and a "Retry" button.

**System**
- **iPad**: sidebar with every section (`NavigationSplitView`).
- **Siri and Shortcuts**: "Scan a component with PcComponentIA", "How's my build going in PcComponentIA?"…
- **Spanish and English.**
- Onboarding, workshop (dark) / light mode, animations that respect "Reduce Motion", and VoiceOver labels.

---

## Requirements and running the app

| | |
| --- | --- |
| Xcode | 27.0 beta or later |
| Target | iOS / iPadOS 27.0 (`IPHONEOS_DEPLOYMENT_TARGET = 27.0`) |
| Device | A physical device is recommended: the simulator has no real camera |
| Assistant | A device that supports Apple Intelligence, with it turned on and the model downloaded |

1. Open `PcComponentIA.xcodeproj`.
2. Choose the **PcComponentIA** scheme and your iPhone/iPad as the destination.
3. In *Signing & Capabilities*, select your **Team**.
4. `Cmd + R`. The first time, the device will ask you to enable **Developer Mode** and trust the developer.

---

## Component detector

### Current model

`PcComponentIA/ML/PcComponentDetector4.mlmodel`

| Training | |
| --- | --- |
| Tool | **Create ML** (Object Detection), **Full Network** algorithm |
| Hardware | **MacBook Air M2**, locally; about 5 hours |
| Iterations | 6,300 (*snapshot* chosen from several; the *loss* went from ~12 to 2.0) |
| Images | **8,670** in total |
| Split | 8,045 training and 625 test |
| Classes | 25 |

No test image is a near-duplicate of a training image. This was checked by comparing the visual fingerprint of every test image with all the training images.

- **mAP@50 on the test set:**

| Model | mAP@50 |
| --- | --- |
| Model 1 (original, 84 own photos) | 4.7% |
| Model 2 (Transfer Learning, 761 photos) | 14.2% |
| Model 3 (3,988 photos, 30 classes) | 27.5% |
| **Model 4 (current, 8,670 photos, 25 classes)** | **28.7%** |

Model 4 was evaluated on its own test set (625 photos, 25 classes), so the comparison with model 3 is approximate.

**Why it works better than 28.7% suggests.** On the iPad, model 4 recognises parts with much more confidence than model 3. There are reasons for the gap with the number:
- **It finds almost everything (recall):** it detects 89% of CPUs, 96% of sockets and motherboards and 84-85% of M.2 drives and hard drives.
- **Large parts score well on AP@50**, which also requires the box to be in the right place: 75% for the CPU, 68% for the socket, 58% for M.2 and 53% for the hard drive.
- **Incomplete labels:** the photos come from several datasets and each one labelled only its own parts. If a hard-drive photo shows an unlabelled keyboard and the model detects it correctly, the test counts it as a mistake. That is what sinks classes like the mouse: it finds it 59% of the time, but its AP@50 is 2.5%.
- **Small classes or few test photos:** ports and slots are hard for any model, and classes like the radiator have only 4 boxes in the test set. Since mAP is the average over classes, each one weighs the same.
- **The app filters out noise:** it only shows detections with confidence ≥ 0.55, and the stabiliser discards those that appear in a single frame.

To choose the model I compared two *snapshots* on the test set: iteration 4,440 scored 26.7% and iteration 6,300 scored 28.7%, so training longer did not overfit.

### What it detects (25 classes)

The class keys are in Spanish because they are the same keys the app uses for its sheets.

| Group | Classes |
| --- | --- |
| Motherboard | `Placa_Base`, `Socket_CPU`, `Ranura_RAM`, `Ranura_PCIe_x16`, `Ranura_M2`, `Conector_ATX_24p`, `Conector_EPS_8p` |
| Components | `CPU`, `GPU`, `Modulo_RAM`, `Fuente_Alimentacion`, `HDD`, `SSD_SATA`, `M2_SSD_NVMe`, `Caja_PC` |
| Cooling | `Disipador_Aire`, `Ventilador_Caja`, `Radiador`, `Bloque_refrigeracion_liquida` |
| Ports | `Puerto_USB_A`, `Puerto_USB_C`, `Puerto_Ethernet` |
| Peripherals | `Monitor`, `Teclado`, `Raton` |

The model's class keys match those in `DatosHardware.swift`, so every detection opens its sheet directly.

Dropped from the detector for lack of photos: `Bomba_Liquida`, `Conector_SYS_FAN`, DisplayPort and the PCIe/12VHPWR cables. Their sheets are still in the dictionary.

### How it works in the app

```text
Camera (AVFoundation, 720p)
  └─ CameraViewController ──► DetectionStabilizer ──► ScannerView
       captures frames         · model loaded once,          · draws the boxes
       and limits to ~5/s        off the main thread         · opens the sheet (DatosHardware)
                               · smooths boxes across frames · saves to history
```

- **Confidence thresholds:** 0.55 to accept a detection and 0.60 to show it.
- **Thermal state:** if the device gets hot, the analysis rate drops and, in extreme cases, so does the resolution.

---

## AI assistant

`Funciones/Asistente/ControladorIA.swift` uses `FoundationModels` (`LanguageModelSession`), entirely on device.

- Specialised in PC hardware; it answers in the device's language (Spanish or English).
- Saved conversations, with a message limit and configurable retention.
- It only works when Apple Intelligence is available: a supported device, turned on, a supported language/region and the model downloaded.

---

## Project structure

Organised by feature: each folder under `Funciones/` ("features") groups the screens, logic and data for that part of the app.

```text
PcComponentIA/
├── App/                    Launch, root view (sidebar on iPad) and Siri shortcuts
├── Funciones/
│   ├── Inicio/             Home screen and onboarding
│   ├── Escaner/            Camera, detector (Vision + Core ML), scanner and AR guide
│   ├── Componentes/        Dictionary, sheets, 2D diagrams, 3D viewer and photos
│   ├── Builds/             My builds, compatibility and power draw, sharing
│   ├── Montaje/            Assembly checklist (one per build)
│   ├── Diagnostico/        LEDs, POST codes, beep codes and troubleshooting history
│   ├── Asistente/          Chat with Foundation Models
│   └── Historial/          Capture history and its retention
├── Comun/
│   ├── Datos/              SwiftData models and migration from UserDefaults
│   ├── Diseno/             Animations, grids and shared UI components
│   ├── AppSettings.swift
│   ├── Extensions.swift
│   └── Localizacion.swift  App language (Spanish/English) and live switching
├── ML/                     PcComponentDetector4.mlmodel
├── Modelos3D/              USDZ models for the 3D viewer
├── Assets/                 Icons, colours and sheet photos
├── Localizable.xcstrings   Interface and content translations (Spanish → English)
└── PrivacyInfo.xcprivacy   Privacy manifest (no tracking, no data collected)
Creditos/
└── CREDITOS_COMMONS.json   Author and license of every Wikimedia Commons photo used
```

---

## Stored data

Everything is stored **only on the device**.

| What | Where |
| --- | --- |
| Builds and their components | SwiftData (`BuildSD`, `ComponenteBuildSD`) |
| Saved troubleshooting results | SwiftData (`RegistroDiagnosticoSD`) |
| Scanner capture history | SwiftData (`CapturaHistorialSD`, photos in external storage) |
| Chat conversations | UserDefaults (`conversacionesChatIA`) |
| Assembly checklist | UserDefaults (`checklistMontajePCComponentIA`, plus one key per build) |
| Settings (workshop mode, retention, onboarding) | UserDefaults / `@AppStorage` |

`MigrationManager` moves the old data that lived in UserDefaults (builds, troubleshooting results and captures) to SwiftData once.

---

## Extending the app

**Add a sheet to the dictionary**
1. Add an entry to `DatosHardware.swift` with its key (e.g. `"Tarjeta_Red"`).
2. If relevant, add its related parts in `ComponentesRelacionados.swift`.
3. Add the English translation in `Localizable.xcstrings`.

**Make a new component detectable**
1. Retrain the model with that class, using exactly the same key as in `DatosHardware.swift`.
2. Replace the `.mlmodel` in `ML/` and update the class name generated by Xcode in `DetectionStabilizer.swift`.
3. Add the key to `ComponentesDetectables.claves`.

**Add a connector diagram**
- Add an entry to `EsquemasComponentes.todos`, with shapes and points in 0–1 coordinates. The view does not need to change.

**Add a 3D model**
1. Copy the `.usdz` into `Modelos3D/` (with a license that allows its use, and its credit).
2. Add an entry to `ModelosPiezas3D.todos` with the connectors in 0–1 coordinates within the model. When it exists, the sheet's button becomes "View in 3D".

**Add a photo to a sheet**
- An image named `foto_<key>` in `Assets` and its author/license in `FotosFichas.creditos`.

---

## Limitations and next steps

- **Uneven detector accuracy:** large parts (CPU, socket, M.2, hard drives, PSU) work well, but `Modulo_RAM`, `Raton` and liquid cooling are still weak. The next step (model 5): **refine the labels of the current photos**, completing the missing ones in photos from mixed datasets (model 4 itself can propose the boxes, which would then only need checking), and **gather more photos of the parts it detects worst**: RAM modules, mice, radiators, liquid-cooling blocks, USB ports and GPUs. `Pila_CMOS`, `Puerto_SATA`, `Puerto_HDMI` and `Protector_IO` are no longer detected; they are explained in their sheets, diagrams and the 3D viewer.
- **3D viewer:** the selectable points for each connector need adjusting so they sit exactly on the connector they explain in each model. Some motherboard connectors are not explained yet: points need adding for all of them.
- **Ports in the detector:** small ports (`Puerto_USB_A`, `Puerto_USB_C`, `Puerto_Ethernet`) are the ones it detects worst. One option for model 5 is to remove them from the detector, as was done with HDMI and SATA, and explain them in the 3D viewer instead.
- **Approximate compatibility check:** it is inferred from the names the user types; if a model is not recognised, the app says so instead of guessing.
- **No widgets or iCloud:** they require the paid developer account (App Groups / CloudKit).
- The scanner needs a physical device, and the assistant needs Apple Intelligence.
- Only the compatibility logic has been tested, manually; there are no automated tests yet.

---

## Data credits

The detector was trained with my own photos and these public datasets. The classes were reviewed and mapped to the app's keys.

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

**Wikimedia Commons**: 178 photos under CC BY, CC BY-SA and CC0 licenses. The author, license and link for each one are in [`Creditos/CREDITOS_COMMONS.json`](Creditos/CREDITOS_COMMONS.json).

**Inside the app**
- Photo on the CMOS battery sheet: "CMOS Battery, Motherboard" by Kent Madsen, [CC BY-SA 2.0](https://commons.wikimedia.org/wiki/File:CMOS_Battery,_Motherboard.jpg).
- 3D models from [Sketchfab](https://sketchfab.com), all licensed CC BY 4.0:
  - [GeForce RTX 3080 Graphics Card](https://sketchfab.com/3d-models/geforce-rtx-3080-graphics-card-8b947ee1bf7a4e3d8ffa1c24893ac160) — _surovic_
  - [MotherBoard + Components](https://sketchfab.com/3d-models/motherboard-components-3bc94057328243d4b341a55f59160f8a) — Daniel Cardona
  - [RAM-Hynix553-8a-24GB(DDR5S)](https://sketchfab.com/3d-models/ram-hynix553-8a-24gbddr5s-a5285af98b9b49d78472eb76ed2d730d) — Apple
  - [SSD NoName m.2 256gb](https://sketchfab.com/3d-models/ssd-noname-m2-256gb-ac3e66d1e3bf46dc8684a3e4abae584b) — Хлюпич
  - [M1000 inspired by Corsair HX1000](https://sketchfab.com/3d-models/m1000-inspired-by-corsair-hx1000-free-6d122273398b446a876600401ba08b55) — Igor.Jop

---

## Author

**Olai Fernández García**, final-year **Computer Engineering** student at the University of Oviedo.

- LinkedIn: [Olai Fernández García](https://www.linkedin.com/in/olai-fernandez-garcia-a12897222/)
- GitHub: [@OlaiFG7](https://github.com/OlaiFG7)

---

## License

© 2026 Olai Fernández García. **All rights reserved.** You may view the content, but you may not copy it, reuse it or publish the app without permission. Third-party data used for training keeps its original licenses. Details in [`LICENSE`](LICENSE).
