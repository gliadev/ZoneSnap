#!/bin/bash
#
# build-dmg.sh — Empaqueta ZoneSnap en un DMG de instalación pulido.
#
# Compila la app en Release, genera un fondo con flecha y monta un DMG con la
# app a la izquierda y un alias a /Applications a la derecha, listo para
# arrastrar. Solo herramientas nativas (xcodebuild, hdiutil, osascript, swift).
#
# Uso:   scripts/build-dmg.sh [version]
#        version → opcional, p. ej. 1.0.0 (por defecto: la del proyecto o "dev")
#
# Firma: usa la identidad de SIGN_IDENTITY (por defecto la de desarrollo de
# Adolfo). Una firma estable es imprescindible para que el permiso de
# Accesibilidad persista entre reinstalaciones. Para no firmar: SIGN_IDENTITY=""
#
set -euo pipefail

# --- Rutas --------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT="$PROJECT_ROOT/ZoneSnap.xcodeproj"
SCHEME="ZoneSnap"
APP_NAME="ZoneSnap"
VERSION="${1:-dev}"

# Identidad de firma (override con la variable de entorno SIGN_IDENTITY).
SIGN_IDENTITY="${SIGN_IDENTITY-Apple Development: Adolfo Gomez (4WM754T5R6)}"

BUILD_DIR="$PROJECT_ROOT/.tmp/dmg-build"
DERIVED="$BUILD_DIR/DerivedData"
STAGE="$BUILD_DIR/stage"            # contenido que irá dentro del DMG
DIST_DIR="$PROJECT_ROOT/dist"
VOL_NAME="$APP_NAME"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
TMP_DMG="$BUILD_DIR/${APP_NAME}-rw.dmg"
BG_PNG="$BUILD_DIR/dmg-background.png"

echo "▶︎ Limpiando trabajo previo…"
rm -rf "$BUILD_DIR"
mkdir -p "$DERIVED" "$STAGE" "$DIST_DIR"

# --- 1. Compilar Release ------------------------------------------------------
# El proyecto usa firma automática: dejamos que xcodebuild firme con la cuenta
# configurada. La firma final estable se garantiza re-firmando la copia (paso 2).
echo "▶︎ Compilando $APP_NAME (Release)…"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    -destination "generic/platform=macOS" \
    clean build \
    > "$BUILD_DIR/xcodebuild.log" 2>&1 \
    || { echo "✗ Falló la compilación. Revisa $BUILD_DIR/xcodebuild.log"; tail -20 "$BUILD_DIR/xcodebuild.log"; exit 1; }

APP_PATH="$DERIVED/Build/Products/Release/$APP_NAME.app"
[ -d "$APP_PATH" ] || { echo "✗ No se encontró $APP_PATH"; exit 1; }
echo "  ✓ App compilada: $APP_PATH"

# --- 2. Preparar el contenido del DMG -----------------------------------------
echo "▶︎ Preparando contenido…"
cp -R "$APP_PATH" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

# Re-firmar la copia para garantizar una firma íntegra y estable dentro del DMG.
if [ -n "$SIGN_IDENTITY" ]; then
    echo "▶︎ Firmando la app…"
    codesign --force --deep --options runtime \
        --sign "$SIGN_IDENTITY" "$STAGE/$APP_NAME.app" \
        > "$BUILD_DIR/codesign.log" 2>&1 \
        || { echo "✗ Falló la firma. Revisa $BUILD_DIR/codesign.log"; tail -10 "$BUILD_DIR/codesign.log"; exit 1; }
    codesign --verify --strict "$STAGE/$APP_NAME.app" \
        && echo "  ✓ Firma verificada" \
        || { echo "✗ La firma no verifica"; exit 1; }
fi

echo "▶︎ Generando fondo…"
swift "$SCRIPT_DIR/dmg-background.swift" "$BG_PNG"
mkdir -p "$STAGE/.background"
cp "$BG_PNG" "$STAGE/.background/background.png"

# --- 3. Crear DMG temporal de lectura/escritura -------------------------------
echo "▶︎ Creando DMG temporal…"
hdiutil create \
    -srcfolder "$STAGE" \
    -volname "$VOL_NAME" \
    -fs HFS+ \
    -format UDRW \
    -ov \
    "$TMP_DMG" > /dev/null

echo "▶︎ Montando para dar formato…"
MOUNT_DIR="/Volumes/$VOL_NAME"
hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
DEVICE="$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" | grep -E '^/dev/' | head -1 | awk '{print $1}')"
sleep 2

# --- 4. Diseño de la ventana (Finder vía AppleScript) -------------------------
echo "▶︎ Aplicando diseño de la ventana…"
osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- Alto = 400 (imagen) + 28 (barra de título) para que el área de
        -- contenido encaje exactamente con el fondo de 600×400.
        set the bounds of container window to {200, 150, 800, 578}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set background picture of viewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {150, 215}
        set position of item "Applications" of container window to {450, 215}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync

# --- 5. Convertir a DMG final comprimido y de solo lectura --------------------
echo "▶︎ Finalizando DMG…"
hdiutil detach "$DEVICE" >/dev/null 2>&1 || hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
sleep 1
rm -f "$DMG_PATH"
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH" > /dev/null
rm -f "$TMP_DMG"

echo ""
echo "✅ DMG listo: $DMG_PATH"
echo "   Tamaño: $(du -h "$DMG_PATH" | cut -f1)"
