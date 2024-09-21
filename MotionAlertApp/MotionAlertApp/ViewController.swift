//
//  ViewController.swift
//  MotionAlertApp
//
//  Created by Kai Garcia on 9/21/24.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // MARK: - Bluetooth Variables
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    
    // Define the UART Service UUID (Nordic UART Service)
    let uartServiceCBUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    let uartTxCharacteristicCBUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX Characteristic
    let uartRxCharacteristicCBUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // RX Characteristic

    var uartTxCharacteristic: CBCharacteristic?
    var uartRxCharacteristic: CBCharacteristic?
    
    var isLocked = false

    // MARK: - UI Outlets
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var alertLabel: UILabel!
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize central manager with self as delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Set initial UI states
        statusLabel.text = "Initializing Bluetooth..."
        alertLabel.text = ""
        lockButton.setTitle("Lock", for: .normal)
    }
    
    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusLabel.text = "Bluetooth is On. Scanning..."
            // Start scanning for UART Service
            centralManager.scanForPeripherals(withServices: [uartServiceCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff:
            statusLabel.text = "Bluetooth is Off."
            alertLabel.text = ""
        case .resetting:
            statusLabel.text = "Bluetooth is Resetting."
        case .unauthorized:
            statusLabel.text = "Bluetooth Unauthorized."
        case .unsupported:
            statusLabel.text = "Bluetooth Unsupported."
        case .unknown:
            statusLabel.text = "Bluetooth State Unknown."
        @unknown default:
            statusLabel.text = "Bluetooth State Undefined."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Assuming your Arduino BLE device has a name, e.g., "ArduinoNanoESP32"
        if let name = peripheral.name, name == "ArduinoNanoESP32" {
            // Stop scanning to conserve resources
            centralManager.stopScan()
            
            // Save reference to the peripheral and set delegate
            connectedPeripheral = peripheral
            connectedPeripheral?.delegate = self
            
            // Connect to the peripheral
            centralManager.connect(peripheral, options: nil)
            
            statusLabel.text = "Connecting to \(name)..."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusLabel.text = "Connected to \(peripheral.name ?? "Device")"
        
        // Discover services
        peripheral.discoverServices([uartServiceCBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusLabel.text = "Failed to connect."
        print("Failed to connect to peripheral: \(error?.localizedDescription ?? "Unknown error")")
        
        // Optionally, restart scanning
        centralManager.scanForPeripherals(withServices: [uartServiceCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusLabel.text = "Disconnected."
        if let error = error {
            print("Disconnected with error: \(error.localizedDescription)")
        }
        
        // Optionally, restart scanning
        centralManager.scanForPeripherals(withServices: [uartServiceCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    // MARK: - CBPeripheralDelegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == uartServiceCBUUID {
                // Discover characteristics for UART Service
                peripheral.discoverCharacteristics([uartTxCharacteristicCBUUID, uartRxCharacteristicCBUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == uartTxCharacteristicCBUUID {
                uartTxCharacteristic = characteristic
                // Subscribe to notifications on TX Characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribed to TX Characteristic")
            }
            
            if characteristic.uuid == uartRxCharacteristicCBUUID {
                uartRxCharacteristic = characteristic
                print("RX Characteristic Ready")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        if let message = String(data: data, encoding: .utf8) {
            print("Received: \(message)")
            
            if message.contains("Movement Detected") && isLocked {
                DispatchQueue.main.async {
                    self.alertLabel.text = "Movement Detected!"
                }
                // Optionally, trigger a local notification
            } else {
                DispatchQueue.main.async {
                    self.alertLabel.text = ""
                }
            }
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func lockButtonPressed(_ sender: UIButton) {
        isLocked.toggle()
        let buttonTitle = isLocked ? "Unlock" : "Lock"
        lockButton.setTitle(buttonTitle, for: .normal)
        
        // Clear alert label when unlocked
        if !isLocked {
            alertLabel.text = ""
        }
    }
}

