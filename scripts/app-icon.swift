//
//  app-icon.swift
//  ZoneSnap — generador del icono de la app (no entra en el bundle).
//
//  Dibuja el icono con CoreGraphics siguiendo el estilo de macOS: squircle con
//  gradiente azul→índigo, sombra suave y, como glifo, un "split asimétrico" de
//  zonas blancas (una grande + dos apiladas) que evoca el reparto de ventanas.
//
//  Uso:  swift app-icon.swift <salida.png> [lado_px]   (por defecto 1024)
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Parámetros

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "app-icon.png"
let side = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 1024 : 1024
let S = CGFloat(side)

guard let context = CGContext(
    data: nil, width: side, height: side,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("error: no se pudo crear el contexto\n".utf8))
    exit(1)
}

// Todo el dibujo se hace en un espacio normalizado de 1024 puntos y se escala.
context.scaleBy(x: S / 1024, y: S / 1024)
let canvas: CGFloat = 1024

// MARK: - Squircle (forma del icono)

// macOS: el cuerpo del icono ocupa ~82% del lienzo, con sombra y márgenes.
let bodySide: CGFloat = 824
let bodyOrigin = (canvas - bodySide) / 2
let bodyRect = CGRect(x: bodyOrigin, y: bodyOrigin, width: bodySide, height: bodySide)
let bodyRadius = bodySide * 0.2237 // radio continuo aproximado de macOS
let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil)

// Sombra suave bajo el cuerpo.
context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -18),
    blur: 40,
    color: NSColor.black.withAlphaComponent(0.28).cgColor
)
context.addPath(bodyPath)
context.setFillColor(NSColor.black.cgColor)
context.fillPath()
context.restoreGState()

// Gradiente azul→índigo recortado al squircle.
context.saveGState()
context.addPath(bodyPath)
context.clip()
let colorSpace = CGColorSpaceCreateDeviceRGB()
let top = CGColor(red: 0.42, green: 0.58, blue: 0.96, alpha: 1)    // azul claro
let bottom = CGColor(red: 0.24, green: 0.34, blue: 0.82, alpha: 1) // índigo
if let gradient = CGGradient(colorsSpace: colorSpace, colors: [top, bottom] as CFArray, locations: [0, 1]) {
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: bodyRect.minX, y: bodyRect.maxY),
        end: CGPoint(x: bodyRect.maxX, y: bodyRect.minY),
        options: []
    )
}
context.restoreGState()

// MARK: - Glifo: split asimétrico de zonas

// Área interior donde viven las zonas (con respiro respecto al borde del cuerpo).
let inset: CGFloat = bodySide * 0.26
let g = bodyRect.insetBy(dx: inset, dy: inset)
let gap = g.width * 0.07            // separación entre zonas (las "líneas")
let zoneRadius = g.width * 0.07
let leftWidth = g.width * 0.56 - gap / 2
let rightX = g.minX + g.width * 0.56 + gap / 2
let rightWidth = g.maxX - rightX
let halfHeight = (g.height - gap) / 2

func zone(_ rect: CGRect) {
    let path = CGPath(roundedRect: rect, cornerWidth: zoneRadius, cornerHeight: zoneRadius, transform: nil)
    context.addPath(path)
    context.fillPath()
}

context.setFillColor(NSColor.white.cgColor)
// Zona grande (izquierda).
zone(CGRect(x: g.minX, y: g.minY, width: leftWidth, height: g.height))
// Zona derecha-arriba (origen CG abajo-izquierda → "arriba" = mayor y).
zone(CGRect(x: rightX, y: g.minY + halfHeight + gap, width: rightWidth, height: halfHeight))
// Zona derecha-abajo.
zone(CGRect(x: rightX, y: g.minY, width: rightWidth, height: halfHeight))

// MARK: - Guardar PNG

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("error: no se pudo renderizar\n".utf8))
    exit(1)
}
let bitmap = NSBitmapImageRep(cgImage: image)
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: no se pudo codificar el PNG\n".utf8))
    exit(1)
}
do {
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("✓ Icono generado (\(side)px): \(outputPath)")
} catch {
    FileHandle.standardError.write(Data("error: no se pudo escribir \(outputPath): \(error)\n".utf8))
    exit(1)
}
