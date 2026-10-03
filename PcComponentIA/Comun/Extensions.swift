//
//  Extensions.swift
//  PcComponentIA
//
//  Created by Olai Fernandez Garcia on 19/07/2026.
//

import Foundation

extension Double {
    public var formatoEuro: String {
        formatted(
            .currency(code: "EUR")
                .locale(Locale(identifier: "es_ES"))
                .precision(.fractionLength(0))
        )
    }
}

extension String {
    public var safeDouble: Double? {
        var cleanString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove currency symbols and common letters
        cleanString = cleanString.replacingOccurrences(of: "€", with: "")
        cleanString = cleanString.replacingOccurrences(of: "$", with: "")
        cleanString = cleanString.replacingOccurrences(of: "£", with: "")
        cleanString = cleanString.replacingOccurrences(of: "EUR", with: "", options: .caseInsensitive)
        cleanString = cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let hasComma = cleanString.contains(",")
        let hasDot = cleanString.contains(".")
        
        if hasComma && hasDot {
            if let commaIndex = cleanString.lastIndex(of: ","),
               let dotIndex = cleanString.lastIndex(of: ".") {
                if commaIndex > dotIndex {
                    // Comma is decimal separator, dot is thousands separator (Spanish/European style)
                    cleanString = cleanString.replacingOccurrences(of: ".", with: "")
                    cleanString = cleanString.replacingOccurrences(of: ",", with: ".")
                } else {
                    // Dot is decimal separator, comma is thousands separator (US style)
                    cleanString = cleanString.replacingOccurrences(of: ",", with: "")
                }
            }
        } else if hasComma || hasDot {
            // Solo hay un tipo de separador. Un precio nunca lleva 3 decimales, así que si aparece
            // varias veces o le siguen exactamente 3 cifras ("1.299", "1,299", "1.299.000") son miles;
            // si no ("12,5", "19.99"), es la coma o el punto decimal.
            let separador: Character = hasComma ? "," : "."
            let partes = cleanString.split(separator: separador, omittingEmptySubsequences: false)
            let sonMiles = partes.count > 2 || (partes.count == 2 && partes[1].count == 3)
            cleanString = sonMiles
                ? partes.joined()
                : cleanString.replacingOccurrences(of: String(separador), with: ".")
        }
        
        return Double(cleanString)
    }
}

extension Build {
    public var advertenciaPCIe: String? {
        let nVMEs = componentes.filter {
            let name = $0.nombre.lowercased()
            return $0.categoria == "Almacenamiento" && (name.contains("nvme") || name.contains("m.2") || name.contains("m2"))
        }
        
        let satas = componentes.filter {
            let name = $0.nombre.lowercased()
            return name.contains("sata") || name.contains("hdd")
        }
        
        let tieneGPU = componentes.contains {
            let name = $0.nombre.lowercased()
            return $0.categoria == "GPU" || name.contains("gpu") || name.contains("gráfica") || name.contains("rtx") || name.contains("rx") || name.contains("radeon") || name.contains("nvidia")
        }
        
        if nVMEs.count >= 2 && (tieneGPU || !satas.isEmpty) {
            return L("Ojo: si conectas el segundo NVMe en la ranura M2_2, tu puerto SATA_1 quedará desactivado o tu tarjeta gráfica bajará de x16 a x8.")
        }
        
        return nil
    }
}
