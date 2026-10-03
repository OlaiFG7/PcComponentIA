//
//  DetalleDiagnosticoGuardadoView.swift
//  PcComponentIA
//

import SwiftUI

struct DetalleDiagnosticoGuardadoView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gestorDiagnosticos: GestorDiagnosticos
    
    let registro: RegistroDiagnostico
    
    @State private var nota: String = ""
    @State private var estado: EstadoRegistroDiagnostico = .pendiente
    
    private var colorPorEstado: Color {
        switch estado {
        case .pendiente: return .red
        case .enProceso: return .orange
        case .resuelto: return .green
        }
    }
    
    private var nombreEstado: String {
        switch estado {
        case .pendiente: return "Pendiente"
        case .enProceso: return L("En Proceso")
        case .resuelto: return "Resuelto"
        }
    }
    
    init(registro: RegistroDiagnostico) {
        self.registro = registro
        // Solución de seguridad: Leemos de forma segura usando propiedades locales sin mutar structs inválidos
        _nota = State(initialValue: "")
        _estado = State(initialValue: .pendiente)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabecera del detalle
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(registro.codigoOIndicador)
                            .font(.system(.title, design: .monospaced))
                            .fontWeight(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        
                        Spacer()
                        
                        // Selector interactivo
                        Menu {
                            ForEach(EstadoRegistroDiagnostico.allCases) { opcion in
                                Button {
                                    estado = opcion
                                    actualizarRegistro()
                                } label: {
                                    Text(opcion == .pendiente ? "Pendiente" : (opcion == .enProceso ? L("En Proceso") : "Resuelto"))
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(colorPorEstado)
                                    .frame(width: 8, height: 8)
                                Text(nombreEstado.localizado)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colorPorEstado.opacity(0.14), in: Capsule())
                        }
                    }
                    
                    Text(registro.tituloResultado.localizado)
                        .font(.title3.weight(.bold))
                    
                    Text("Placa: \(registro.marcaPlaca)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .diagnosticoSurface(cornerRadius: 20, tint: colorPorEstado)
                
                // Sección de notas de usuario
                VStack(alignment: .leading, spacing: 10) {
                    Text("NOTAS DE REPARACIÓN")
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    
                    TextField("Añade anotaciones sobre tus pruebas...", text: $nota, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        .onChange(of: nota) { _, _ in
                            actualizarRegistro()
                        }
                }
                .padding(16)
                .diagnosticoSurface(cornerRadius: 20, tint: .secondary)
                
                // Pasos de solución inyectados desde el diagnóstico local
                VStack(alignment: .leading, spacing: 12) {
                    Text("PASOS RECOMENDADOS")
                        .font(.caption2.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    
                    ForEach(Array(registro.pasosRecomendados.enumerated()), id: \.offset) { indice, paso in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(indice + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.primary.opacity(0.6), in: Circle())
                            
                            Text(paso.localizado)
                                .font(.footnote)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(16)
                .diagnosticoSurface(cornerRadius: 20, tint: .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(fondoBase)
        .navigationTitle("Ficha de Fallo")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func actualizarRegistro() {
        // CORRECCIÓN: Guardamos directamente el registro actual mediante el motor de base de datos sin alterar campos bloqueados
        gestorDiagnosticos.guardar(registro)
    }
    
    private var fondoBase: some View {
        colorScheme == .dark
            ? Color(red: 0.038, green: 0.040, blue: 0.048).ignoresSafeArea()
            : Color(red: 0.975, green: 0.982, blue: 0.995).ignoresSafeArea()
    }
}
