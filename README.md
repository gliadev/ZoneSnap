# ZoneSnap

**Gestor de ventanas para macOS** inspirado en *FancyZones* (PowerToys). Define
zonas a tu gusto en cada monitor y acopla ventanas a ellas con el ratón o con el
teclado.

Su rasgo diferencial: un editor de **subdivisión recursiva** — eliges una zona y
la partes en columnas o filas **sin romper** el resto del diseño.

<!-- TODO (Adolfo): captura principal del editor -->
<!-- ![ZoneSnap](docs/screenshots/hero.png) -->

---

## ✨ Características

- **Editor de zonas recursivo:** selecciona una zona y subdivídela en columnas/filas;
  el resto del diseño no se toca. Anidación libre.
- **Separadores arrastrables:** ajusta el tamaño de las zonas arrastrando sus bordes.
- **Unir:** colapsa una subdivisión para volver a juntar zonas.
- **Perfiles portables:** guarda distribuciones (p. ej. *dev*, *cine*) y aplícalas en
  cualquier monitor — se adaptan solas a la resolución.
- **Snapping por arrastre:** mantén **⇧⌃** y arrastra una ventana; aparece el overlay
  de zonas y al soltar se acopla (incluido *span* sobre dos zonas).
- **Atajos de teclado:** mueve la ventana activa a una zona o navega entre ellas.
- **Multi-monitor:** cada monitor guarda su propia distribución.
- **Persistencia local:** tus zonas y perfiles se guardan y recuperan solos.

---

## 📋 Requisitos

- **macOS 14+** (Sonoma o posterior).
- **Permiso de Accesibilidad** — necesario para mover ventanas de otras apps
  (Ajustes → Privacidad y seguridad → Accesibilidad). La app lo solicita la primera
  vez que intentas mover una ventana.

---

## 🎮 Cómo se usa

### Crear y editar zonas
1. Abre el editor desde el icono de la **barra de menús**.
2. Elige el **monitor** en el selector.
3. Haz **clic** en una zona para seleccionarla.
4. Sube **Columnas** o **Filas** para subdividir *esa* zona. Repite sobre las
   sub-zonas para anidar.
5. Arrastra los **separadores** para redimensionar; pulsa **Unir** para deshacer una
   subdivisión, o **Limpiar** para volver a una sola zona.
6. Todo se **auto-guarda** por monitor.

<!-- TODO (Adolfo): captura del editor con una zona subdividida -->

### Perfiles
- **Perfil → Guardar como perfil…** guarda la distribución actual con un nombre.
- Aplícalo desde el menú **Perfil** en cualquier monitor (se adapta a su resolución).

### Mover ventanas
- **Botón "Mover ventana activa aquí":** selecciona una zona y pulsa el botón.
- **Arrastre:** mantén **⇧⌃** mientras arrastras una ventana; suéltala sobre la zona.
- **Teclado:** ver atajos abajo.

---

## ⌨️ Atajos de teclado

| Atajo | Acción |
|-------|--------|
| `⌃⌥1` … `⌃⌥9` | Mueve la ventana activa a la zona N (orden de lectura) |
| `⌃⌥←` / `⌃⌥→` | Zona anterior / siguiente (con vuelta al principio) |
| `⇧⌃` + arrastrar ventana | Muestra el overlay de zonas y acopla al soltar |

> Los atajos requieren el permiso de Accesibilidad y se activan al abrir el editor.

---

## 🏗️ Arquitectura

App nativa con **cero dependencias externas** (solo frameworks de Apple).

- **Swift 6.2** (strict concurrency) · **SwiftUI** + **AppKit**.
- Capas: **Domain** (modelos y lógica pura) → **Persistence** (`Codable` + `FileManager`)
  → **WindowManagement** (CoreGraphics / Accessibility API) → **UI** (SwiftUI).
- El editor se modela como un **árbol de subdivisión (BSP)**: cada zona es una hoja
  que puede partirse en una sub-rejilla. Por eso subdividir es local y reversible.
- Estado compartido con clases `@Observable` (`@MainActor`); lógica pura testeada con
  **Swift Testing**.

```
ZoneSnap/
├── Domain/          # ZoneNode, BSPCalculator, Zone, ZoneGrid, atajos…
├── Persistence/     # Repositorio de configuración (zones.json)
├── WindowManagement/# Detección y movimiento de ventanas (CGWindow, AXUIElement)
└── UI/              # Editor, overlay, view models
```

---

## ⚠️ Limitaciones conocidas

- La distribución es **por monitor**, no por escritorio/Space de Mission Control
  (macOS no expone una API pública para Spaces).
- Algunas apps pueden resistirse a ser movidas vía Accessibility API.

---

## 🛠️ Desarrollo

Abrir `ZoneSnap.xcodeproj` en Xcode y compilar/testear (`⌘B` / `⌘U`).
Requiere Xcode con SDK de macOS 14+.

---

## 📝 Licencia

MIT.

---

## 👤 Créditos

Desarrollado por **Adolfo** como proyecto de portfolio y herramienta personal.

<!-- Última actualización: 2026-06-16 -->
