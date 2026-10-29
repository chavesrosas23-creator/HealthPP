import Foundation
import CoreBluetooth

/// Datos de salud que envía el reloj (JSON por BLE).
struct HealthData: Codable {
    var steps: Int?
    var sleepHours: Double?

    enum CodingKeys: String, CodingKey {
        case steps
        case sleepHours = "sleep_hours"
    }
}

/// Cliente BLE: busca el reloj (que hace de servidor GATT) y lee la característica.
final class BLEManager: NSObject, ObservableObject {
    // Deben coincidir con HealthSyncService.kt del reloj
    static let serviceUUID = CBUUID(string: "0000181A-0000-1000-8000-00805F9B34FB")
    static let characteristicUUID = CBUUID(string: "00002A37-0000-1000-8000-00805F9B34FB")

    @Published var status: String = "Inicializando Bluetooth…"
    @Published var data: HealthData?
    @Published var deviceName: String?
    @Published var lastUpdate: Date?
    @Published var isConnected = false

    private var central: CBCentralManager!
    private var watch: CBPeripheral?
    private var characteristic: CBCharacteristic?
    private var timer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard central.state == .poweredOn else { return }
        status = "Buscando el reloj…"
        central.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)
    }

    func disconnect() {
        timer?.invalidate()
        if let watch { central.cancelPeripheralConnection(watch) }
    }

    func readNow() {
        guard let watch, let characteristic else { return }
        watch.readValue(for: characteristic)
    }

    private func startPolling() {
        timer?.invalidate()
        readNow()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.readNow()
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn: startScan()
        case .poweredOff: status = "Bluetooth apagado"
        case .unauthorized: status = "Sin permiso de Bluetooth (revisa Ajustes)"
        case .unsupported: status = "Bluetooth no soportado"
        default: status = "Bluetooth no disponible"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        central.stopScan()
        watch = peripheral
        peripheral.delegate = self
        deviceName = peripheral.name ?? "Galaxy Watch"
        status = "Conectando con \(deviceName ?? "reloj")…"
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        status = "Conectado"
        peripheral.discoverServices([Self.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        status = "Error al conectar: \(error?.localizedDescription ?? "desconocido")"
        startScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        timer?.invalidate()
        status = "Desconectado, reintentando…"
        startScan()
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            status = "Servicio de salud no encontrado"
            return
        }
        peripheral.discoverCharacteristics([Self.characteristicUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let c = service.characteristics?.first(where: { $0.uuid == Self.characteristicUUID }) else {
            status = "Característica no encontrada"
            return
        }
        characteristic = c
        startPolling()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let raw = characteristic.value else { return }
        if let decoded = try? JSONDecoder().decode(HealthData.self, from: raw) {
            data = decoded
            lastUpdate = Date()
        } else {
            status = "Datos recibidos con formato inesperado"
        }
    }
}
