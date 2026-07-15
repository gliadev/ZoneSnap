//
//  ZoneCell.swift
//  ZoneSnap
//
//  UI — una zona del editor: rectángulo numerado y seleccionable.
//

import AppKit
import SwiftUI

/// Representa una zona en la preview del monitor. Es un `Button` para soportar
/// click; detecta Shift vía `NSEvent.modifierFlags` para selección múltiple.
struct ZoneCell: View {
    let number: Int
    let isSelected: Bool
    /// Callback con `extending == true` si se mantenía Shift. `nil` = no interactivo.
    let onSelect: ((_ extending: Bool) -> Void)?

    var body: some View {
        Button {
            onSelect?(NSEvent.modifierFlags.contains(.shift))
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(isSelected ? 0.45 : 0.16))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.accentColor, lineWidth: isSelected ? 3 : 1.5)
                }
                .overlay {
                    Text(number, format: .number)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(3)
        }
        .buttonStyle(.plain)
        .disabled(onSelect == nil)
        .accessibilityLabel("Zona \(number)")
        .accessibilityHint(onSelect == nil ? "" : "Toca dos veces para seleccionarla y dividirla")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
