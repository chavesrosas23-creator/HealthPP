import SwiftUI

struct ContentView: View {
    @EnvironmentObject var ble: BLEManager

    var body: some View {
        NavigationView {
            List {
                Section("Conexión") {
                    HStack {
                        Image(systemName: ble.isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                            .foregroundColor(ble.isConnected ? .green : .secondary)
                        VStack(alignment: .leading) {
                            Text(ble.deviceName ?? "Sin reloj")
                            Text(ble.status).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    if ble.isConnected {
                        Button("Leer ahora") { ble.readNow() }
                        Button("Desconectar", role: .destructive) { ble.disconnect() }
                    } else {
                        Button("Buscar reloj") { ble.startScan() }
                    }
                }

                Section("Datos de salud") {
                    row("Pasos", ble.data?.steps.map { "\($0)" })
                    row("Sueño", ble.data?.sleepHours.map { String(format: "%.1f h", $0) })
                    if let date = ble.lastUpdate {
                        Text("Actualizado: \(date.formatted(date: .omitted, time: .standard))")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("HealthPP")
        }
    }

    private func row(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "—").foregroundColor(.secondary)
        }
    }
}
