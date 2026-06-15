//
//  GridCell.swift
//  ZoneSnap
//
//  Domain — celda de la rejilla, identificada por (fila, columna).
//

import Foundation

/// Una celda de la rejilla base, antes de aplicar fusiones. Identifica su
/// posición por fila y columna (índices, origen arriba-izquierda). Es estable
/// frente a mover líneas (redimensionar), no frente a añadir/quitar líneas.
struct GridCell: Codable, Sendable, Hashable {
    let row: Int
    let col: Int

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}
