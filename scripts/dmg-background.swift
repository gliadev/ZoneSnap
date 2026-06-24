//
//  dmg-background.swift
//  ZoneSnap — tooling de distribución (no entra en el bundle de la app).
//
//  Genera el fondo del DMG de instalación con CoreGraphics: degradado suave,
//  título y una flecha que invita a arrastrar la app a /Applications.
//
//  Uso:  swift dmg-background.swift <salida.png>
//  Lienzo: 600×400 px (Finder trata el PNG como puntos 1:1, sin densidad @2x),
//  por lo que debe coincidir exactamente con el área de contenido de la ventana.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Parámetros

let scale: CGFloat = 1
let logicalSize = CGSize(width: 600, height: 400)
let pixelSize = CGSize(width: logicalSize.width * scale, height: logicalSize.height * scale)

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "dmg-background.png"

// MARK: - Contexto

guard let context = CGContext(
    data: nil,
    width: Int(pixelSize.width),
    height: Int(pixelSize.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("error: no se pudo crear el contexto\n".utf8))
    exit(1)
}

context.scaleBy(x: scale, y: scale) // a partir de aquí dibujamos en puntos lógicos

// MARK: - Fondo (degradado vertical suave)

let colorSpace = CGColorSpaceCreateDeviceRGB()
let top = CGColor(red: 0.16, green: 0.20, blue: 0.30, alpha: 1)
let bottom = CGColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 1)
if let gradient = CGGradient(colorsSpace: colorSpace, colors: [top, bottom] as CFArray, locations: [0, 1]) {
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: logicalSize.height),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
}

// MARK: - Texto (AppKit dibuja en el contexto actual)

let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.current = graphicsContext

func draw(_ text: String, font: NSFont, color: NSColor, centerY: CGFloat) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    let attributed = NSAttributedString(string: text, attributes: attributes)
    let size = attributed.size()
    let rect = CGRect(x: 0, y: centerY - size.height / 2, width: logicalSize.width, height: size.height)
    attributed.draw(in: rect)
}

// CoreGraphics tiene el origen abajo-izquierda: y alto = parte superior.
draw("Instalar ZoneSnap",
     font: .systemFont(ofSize: 30, weight: .bold),
     color: .white,
     centerY: logicalSize.height - 70)

draw("Arrastra el icono a la carpeta Aplicaciones",
     font: .systemFont(ofSize: 15, weight: .regular),
     color: NSColor.white.withAlphaComponent(0.7),
     centerY: logicalSize.height - 110)

// MARK: - Flecha (entre los dos iconos, a su misma altura)

// Los iconos se sitúan (vía AppleScript) en y lógico ≈ 215 desde arriba.
// Aquí el origen es abajo-izquierda → y = alto − 215.
let arrowY = logicalSize.height - 215
let arrowStart = CGPoint(x: 245, y: arrowY)
let arrowEnd = CGPoint(x: 355, y: arrowY)
let headLength: CGFloat = 22
let headHalf: CGFloat = 13

context.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
context.setFillColor(NSColor.white.withAlphaComponent(0.85).cgColor)
context.setLineWidth(5)
context.setLineCap(.round)

context.move(to: arrowStart)
context.addLine(to: CGPoint(x: arrowEnd.x - headLength, y: arrowEnd.y))
context.strokePath()

context.move(to: arrowEnd)
context.addLine(to: CGPoint(x: arrowEnd.x - headLength, y: arrowEnd.y + headHalf))
context.addLine(to: CGPoint(x: arrowEnd.x - headLength, y: arrowEnd.y - headHalf))
context.closePath()
context.fillPath()

NSGraphicsContext.current = nil

// MARK: - Guardar PNG

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("error: no se pudo renderizar la imagen\n".utf8))
    exit(1)
}

let bitmap = NSBitmapImageRep(cgImage: image)
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("error: no se pudo codificar el PNG\n".utf8))
    exit(1)
}

do {
    try data.write(to: URL(fileURLWithPath: outputPath))
    print("✓ Fondo generado: \(outputPath)")
} catch {
    FileHandle.standardError.write(Data("error: no se pudo escribir \(outputPath): \(error)\n".utf8))
    exit(1)
}
