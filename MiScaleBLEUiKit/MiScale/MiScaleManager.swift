//
//  MiScaleManager.swift
//  KittyDocBLETest
//
//  Created by 곽명섭 on 2021/05/01.
//  Copyright © 2021 Myungsup. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol MiScaleManagerDelegate {//: NSObject {
    func onDeviceNotFound()
    func onDeviceConnected(peripheral: CBPeripheral) // 기기 연결됨
    func onDeviceDisconnected()
    
//    @optional
    func onBluetoothNotAccessible() // BLE Off or No Permission... etc.
    func onDevicesFound(peripherals: [PeripheralData])
    func onSyncCompleted()
    func onConnectionFailed()
    func onServiceFound()// 장비에 필요한 서비스/캐랙터리스틱을 모두 찾음. 그냥 연결만하면 서비스 접근시 크래시
    func onSysCmdResponse(data: Data)
    func onSyncProgress(progress: Int)
    func onReadBattery(percent: Int)
    func onDfuTargFound(peripheral: CBPeripheral)
}

class MiScaleManager: NSObject {
    // Declare class instance property
    public static let shared = MiScaleManager()
     // Declare an initializer
     // Because this class is singleton only one instance of this class can be created

    public static let KEY_DEVICE = String("device")
    public static let KEY_NAME = String("name")
    public static let KEY_DICTIONARY = String("miscale_dictionary")
    
    // queue 예약작업 명령들
    public static let COMMAND_FACTORY_RESET = String("factory_reset")
    public static let COMMAND_BATTERY = String("battery")

    var delegate: MiScaleManagerDelegate?
    var commandQueue: [String] = [String]()// 연결 후 실행할 명령 큐
    var foundDevices: [PeripheralData] = [PeripheralData]()

    var peripheral: CBPeripheral?
    var manager: CBCentralManager?
    var bodyScaleCharacteristic: CBCharacteristic?
    var firmwareVersion: String
    var maxRSSI : Int32 = 0
    
    private var _isConnected : Bool = false
    private var _isRequiredServicesFound : Bool  = false// 필요 서비스들 모두 찾았는가?
    // https://medium.com/ios-development-with-swift/%ED%94%84%EB%A1%9C%ED%8D%BC%ED%8B%B0-get-set-didset-willset-in-ios-a8f2d4da5514 참고: Getter & Setter
    public var isConnected: Bool {
        get {
            return self._isConnected
        }
        set(isConnected) {
            self._isConnected = isConnected
        }
    }
    public var isRequiredServicesFound: Bool {
        get {
            return self._isRequiredServicesFound
        }
        set(isRequiredServicesFound) {
            self._isRequiredServicesFound = isRequiredServicesFound
        }
    }

    private override init() {
        self.delegate = nil
        self.maxRSSI = 0

        self._isConnected = false
        self._isRequiredServicesFound = false

        self.peripheral = nil
        self.manager = nil
        self.bodyScaleCharacteristic = nil
        self.firmwareVersion = String()
    }
    
    func resetCharacteristics() {
        self.bodyScaleCharacteristic = nil
    }
    
    func removeDevices() { // 앱에서 장비를 지움
        self.disconnect()
        self.removePeripheral()
        self.resetCharacteristics()
        self.foundDevices.removeAll()
    }
    
    func disconnect() { // 연결만 끊음
        self.isRequiredServicesFound = false
        self.isConnected = false
        
        if (self.peripheral != nil && self.manager != nil) {
            self.manager!.cancelPeripheralConnection(self.peripheral!)
            // 연결 끊으면 해당 기기 자동연결하지 않도록
            self.removePeripheral()
        }
    }
    
    func getSavedDeviceName() -> String {
        let dict: Dictionary = UserDefaults.standard.dictionary(forKey: MiScaleManager.KEY_DICTIONARY)!
        return dict[MiScaleManager.KEY_NAME] as! String
    }

    func savedDeviceInfo() -> Dictionary<String, Any> {
        let dict: Dictionary = UserDefaults.standard.dictionary(forKey: MiScaleManager.KEY_DICTIONARY)! //string(forKey: DeviceManager.KEY_DICTIONARY)
        return dict
    }

    func connectPeripheral() {
        print("[+]connectPeripheral()")
        self.isRequiredServicesFound = false
        self.resetCharacteristics()
        guard (self.peripheral != nil && self.manager != nil) else {
            print("self.peripheral == nil || self.manager == nil!(connectPeripheral)")
            guard self.delegate?.onConnectionFailed() != nil else {
                print("self.delegate?.onConnectionFailed() == nil!(connectPeripheral)")
                return
            }
            return
        }
        self.manager!.connect(self.peripheral!, options: nil)
        print("[-]connectPeripheral()")
    }

    func removePeripheral() {
        self.isRequiredServicesFound = false
        self.peripheral = nil
        self.resetCharacteristics()
        self.foundDevices.removeAll() // self.foundDevices?.removeAllObjects()
        
        UserDefaults.standard.removeObject(forKey: MiScaleManager.KEY_DICTIONARY)
        UserDefaults.standard.synchronize()
    }

    func savedDeviceUUIDString() -> String? {
//        return nil
        let dict: Dictionary? = UserDefaults.standard.dictionary(forKey: MiScaleManager.KEY_DICTIONARY)
        guard (dict != nil) else {
            print("\(MiScaleManager.KEY_DICTIONARY) does not exist!")
            return nil
        }
        
        let uuid: String? = dict![MiScaleManager.KEY_DEVICE] as? String
        return uuid
    }

    func setSavedDeviceUUIDString(uuid: String) {
        var dict: Dictionary = Dictionary<String, Any>()
        
        dict[MiScaleManager.KEY_DEVICE] = uuid
        dict[MiScaleManager.KEY_NAME] = "miscale"// puppydoc
        
        UserDefaults.standard.setValue(dict, forKey: MiScaleManager.KEY_DICTIONARY)
    }
    
    func connectPeripheral(uuid: String, name: String) { // 지정한 UUID의 장비로 연결
        var dict: Dictionary = Dictionary<String, Any>()

        dict[MiScaleManager.KEY_DEVICE] = uuid
        dict[MiScaleManager.KEY_NAME] = name
        UserDefaults.standard.setValue(dict, forKey: MiScaleManager.KEY_DICTIONARY)
        
        self.reestablishConnection()
    }
    
    func reestablishConnection() { // 저장된 장비에 다시 연결
        self.isRequiredServicesFound = false
        
        self.resetCharacteristics()
//        let centralQueue: DispatchQueue = DispatchQueue(label: "devicemanager")
//        self.manager = CBCentralManager(delegate: self, queue: centralQueue)
        self.manager = CBCentralManager(delegate: self, queue: nil)//DispatchQueue.main
    }

    func scanPeripheral() { // KittyDoc 서비스를 가진 장비를 스캔
        print("[+]scanPeripheral()")
        // 기존 장비 지우기
        self.removePeripheral()
        self.resetCharacteristics()
        self.foundDevices.removeAll()
        
        let centralQueue: DispatchQueue = DispatchQueue(label: "devicemanager")
        self.manager = CBCentralManager(delegate: self, queue: centralQueue)
//        self.manager = CBCentralManager(delegate: self, queue: nil)
        
        DispatchQueue.background(delay: 30.0, background: nil) {// Stop scanning after deadine
            print("DispatchQueue.main.asyncAfter(deadline: .now() + 11)")
            self.manager?.stopScan()
            if (!self.isConnected || !self.isRequiredServicesFound) {
                if (self.foundDevices.count == 0) {
                    guard self.delegate?.onDeviceNotFound() != nil else {
                        print("self.delegate?.onDeviceNotFound() == nil!(scanPeripheral)")
                        return
                    }
                } else {
                    var miScaleDevices: Array = Array<PeripheralData>()
                    for device in self.foundDevices {
                        if device.peripheral != nil {
                            print("miScaleDevices.append(\(device.peripheral!.name ?? "Unknown"))")
                            miScaleDevices.append(device)
                        }
                    }

                    self.foundDevices.removeAll()
                    self.foundDevices.append(contentsOf: miScaleDevices)
                    self.foundDevices.sort { (obj1: PeripheralData, obj2: PeripheralData) -> Bool in
                        return obj1.rssi > obj2.rssi // 신호 강한 것이 앞으로...
                    }
                    print("foundDevices : \(self.foundDevices)")
                    guard self.delegate?.onDevicesFound(peripherals: self.foundDevices) != nil else {
                        print("self.delegate?.onDevicesFound(:) == nil!(scanPeripheral)")
                        return
                    }
                }
            }
        }
        print("[-]scanPeripheral()")
    }
}

extension MiScaleManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[+] centralManagerDidUpdateState()")
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
            //fallthrough
        case .resetting:
            print("central.state is .resetting")
            //fallthrough
        case .unsupported:
            print("central.state is .unsupported")
            //fallthrough
        case .unauthorized:
            print("central.state is .unauthorised")
            //fallthrough
        case .poweredOff:
            print("central.state is .poweredOff")
            // 연결할 수 없음
            guard self.delegate?.onBluetoothNotAccessible() != nil else {
                print("self.delegate?.onBluetoothNotAccessible() == nil!(centralManagerDidUpdateState)")
                return
            }
        case .poweredOn:
            print("central.state is .poweredOn") //print("DeviceManager will scan IoT Device")
            // User Defaults에 저장된게 있으면 다시 연결
            if self.savedDeviceUUIDString() == nil {
                print("deviceManager.savedDeviceUUIDString() == nil")
                self.maxRSSI = -100
                self.peripheral = nil
                guard self.manager == central else {
                    print("self.manager != central!(centralManagerDidUpdateState)")
                    return
                }
                //central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
                //central.scanForPeripherals(withServices: [PeripheralUUID.SYNC_SERVICE_UUID, PeripheralUUID.GENERAL_SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
                central.scanForPeripherals(withServices: [MiScaleUUID.BodyScaleServiceUUID], options: nil)// withServices에 nil을 줄 경우 모든 BLE 기기를 탐색, options에 nil을 줄 경우 중복 탐색 가능성이 있다.
                                
                DispatchQueue.background(delay: 29.0, background: nil) { // 10초 동안 KittyDoc 기기를 검색. 못찾은 상태라면 타임아웃 처리.
                    print("DispatchQueue.main.asyncAfter(deadline: .now() + 10)")
                    if (!self.isConnected || !self.isRequiredServicesFound) {
                        self.manager?.stopScan()
                        if self.foundDevices.isEmpty {
                            print("No Devices Found!")
                            // No devices 메시지
                            guard self.delegate?.onConnectionFailed() != nil else {
                                print("self.delegate?.onConnectionFailed() == nil!(centralManagerDidUpdateState3)")
                                return
                            }
                        } else {
                            print("Found some KittyDoc Devices!")
                        }
                    }
                }
            } else { // deviceManager.savedDeviceUUIDString() != nil
                print("deviceManager.savedDeviceUUIDString() != nil")
//                let uuid: CBUUID? = CBUUID(string: self.savedDeviceUUIDString() ?? "")
                let uuid: UUID? = UUID(uuidString: self.savedDeviceUUIDString() ?? "")
                // 안드 mac 형식이면 nil 이 된다?

                var peripherals = [CBPeripheral]()

                if uuid != nil {
//                    peripherals = central.retrievePeripherals(withIdentifiers: [uuid!.UUIDValue!])
                    peripherals = central.retrievePeripherals(withIdentifiers: [uuid!])
                    print("peripherals: \(peripherals)")
                }
                if peripherals.count > 0 {
                    self.peripheral = peripherals[0]
                    self.peripheral!.delegate = self
                    central.connect(self.peripheral!, options: nil)

                    // 장비연결 안되는 경우 대비. 10초 내로 필요 서비스를 다 찾으면 아무것도 안하고 못찾은 상태라면 타임아웃 처리.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        print("DispatchQueue.main.asyncAfter(deadline: .now() + 10)")
                        if (!self.isConnected || !self.isRequiredServicesFound) {
                            print("Timeout. Cancel connection.")
                            if self.peripheral != nil {
                                central.cancelPeripheralConnection(self.peripheral!)
                            }
                           // 연결 실패 메시지 보여주기... 실패 팝업?
                            guard self.delegate?.onConnectionFailed() != nil else {
                                print("self.delegate?.onConnectionFailed() == nil!(centralManagerDidUpdateState1)")
                                return
                            }
                        }
                    }
                } else {
                    // 연결할 수 있는 장비가 없음
                    guard self.delegate?.onConnectionFailed() != nil else {
                        print("self.delegate?.onConnectionFailed() == nil!(centralManagerDidUpdateState2)")
                        return
                    }
                }
            }
        @unknown default:
            fatalError("Fatal Error in iPhone!")
        }
        print("[-] centralManagerDidUpdateState()")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("[+] centralManager(didDiscover)")
        
        guard self.manager == central else {
            print("self.manager != central!(didDiscoverPeripheral)")
            return
        }
        //print("didDiscovorPeripheral : \(advertisementData["kCBAdvDataLocalName"] ?? "-"), RSSI : \(RSSI.intValue)")
        //print("discovoredPeripheral : \(advertisementData), RSSI : \(RSSI.intValue)")

        let advData = advertisementData["kCBAdvDataServiceData"] as! Dictionary<CBUUID, Any>// as! NSDictionary
        let parsedAdvData = advData[MiScaleUUID.BodyScaleServiceUUID] as! Data
        //parsedAdvData[0] 02, 82: 측정 중 / 22: 측정 완료
        print("\nparsedAdvData.count: \(parsedAdvData.count)")
        print("data: [", terminator: " ")
//        for i in 0..<3 {
//            print("\(String(format: "%02X", parsedAdvData[i]))", terminator: " ")
//        }
        for data in parsedAdvData {
            print("\(String(format: "%02X", data))", terminator: " ")
        }
        print("], Weight :", terminator: " ")
        let weight = ((Double(parsedAdvData[1]) + Double(parsedAdvData[2]) * 256.0)) * 0.005
        print("\(weight)")

        //Keys : "kCBAdvDataRxSecondaryPHY", "kCBAdvDataServiceUUIDs", "kCBAdvDataLocalName", "kCBAdvDataRxPrimaryPHY", "kCBAdvDataIsConnectable", "kCBAdvDataTimestamp", "kCBAdvDataServiceData", "kCBAdvDataManufacturerData"
        //["kCBAdvDataRxPrimaryPHY": 0, "kCBAdvDataServiceData": {181D = {length = 10, bytes = 0x823c00b207020d0a0014};}, "kCBAdvDataIsConnectable": 1, "kCBAdvDataRxSecondaryPHY": 0, "kCBAdvDataTimestamp": 642100287.671932, "kCBAdvDataServiceUUIDs": <__NSArrayM 0x282e0d8f0>( 181D ) , "kCBAdvDataLocalName": MI SCALE2, "kCBAdvDataManufacturerData": <57017087 9e2850bc>], RSSI : -61

        var found: Bool = false
        let rssi: Int = RSSI.intValue
        for i in 0..<self.foundDevices.count {
            if (self.foundDevices[i].peripheral!.isEqual(peripheral) && rssi < 0) {
                found = true
                // rssi 업데이트. 가끔 127이라는 엉뚱한 값이 나와서 음수인 경우만 처리? => overflow
                self.foundDevices[i].rssi = self.foundDevices[i].rssi < rssi ? rssi : self.foundDevices[i].rssi
                break
            }
        }

        // add
        if (!found && rssi < 0) {// not found and rssi < 0
            var peripheralData = PeripheralData()
            peripheralData.peripheral = peripheral
            peripheralData.rssi = rssi
            self.foundDevices.append(peripheralData)
            print("Adding \(peripheralData.peripheral?.name ?? "Unknown") to foundDevices")
        }
        self.foundDevices.sort { (obj1: PeripheralData, obj2: PeripheralData) -> Bool in
            return obj1.rssi > obj2.rssi // 신호 강한 것이 앞으로...
        }
        //print("[-] centralManager(didDiscover)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[+] centralManager(didConnect)")
        // User defaults에 저장
        var dict: Dictionary = Dictionary<String, Any>()
        dict[MiScaleManager.KEY_DEVICE] = peripheral.identifier.uuidString
        dict[MiScaleManager.KEY_NAME] = peripheral.name
        UserDefaults.standard.setValue(dict, forKey: MiScaleManager.KEY_DICTIONARY)
        UserDefaults.standard.synchronize()
        isConnected = true
        
        print("Saved device \(dict[MiScaleManager.KEY_DEVICE] ?? "-") to UserDefaults!")
        
        if peripheral == self.peripheral {
            print("Connected! \(peripheral)")
            self.peripheral = peripheral;
            self.peripheral!.delegate = self;
            self.peripheral!.discoverServices(nil)// nil을 인자로 주면 모든 서비스를 탐색한다.
        }
        print("[-] centralManager(didConnect)")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[+] centralManager(didFailToConnect)")
        
        print("Failed to Connect to KittyDoc Device!\n\tError: \(error?.localizedDescription ?? "-")")
        isConnected = false
//        pred = 0;
        guard self.delegate?.onConnectionFailed() != nil else {
            print("self.delegate?.onConnectionFailed() == nil!(didFailToConnect)")
            return
        }
        print("[-] centralManager(didFailToConnect)")
    }

    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        print(" [+]centralManager(connectionEventDidOccur)")
        if peripheral == self.peripheral {
            print("Connection event occurred [ \(String(describing: event)) ]")
        }
        print(" [-]centralManager(connectionEventDidOccur)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[+] centralManager(didDisconnectPeripheral)")
        
        print("didDisconnectPeripheral error : \(error?.localizedDescription ?? "-")")
        isConnected = false
        isRequiredServicesFound = false
//        pred = 0;
        // 기존 장비 지우고 -> 장비에서 연결 끊은 경우 지워지면 안됨. 앱에서 끊는 경우에만 지우자.
//        [self removePeripheral];
        
        guard self.delegate?.onDeviceDisconnected() != nil else {
            print("self.delegate?.onDeviceDisconnected() == nil!(didDisconnectPeripheral)")
            return
        }

        print("[-] centralManager(didDisconnectPeripheral)")
    }

}

extension MiScaleManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("[+] centralManager(didDiscoverServices)")
                
        guard let services = peripheral.services else {
            print("There is no Service at all!(didDiscoverServices)")
            return
        }
        //print(peripheral.state) // 1 service exist
        print("Discovered <\(services.count)> Services") // 1 service exist
        //peripheral.canSendWriteWithoutResponse == true
        guard peripheral == self.peripheral else {
            print("peripheral != self.peripheral!(didDiscoverServices)")
            return
        }
        for service: CBService in services {
            print("Discovered service : <\(service.uuid), \(service.uuid.uuidString)>")
//            if service.uuid.isEqual(PeripheralUUID.SYNC_SERVICE_UUID) {
//                //print("Sync Service Found!")
//                isSyncServiceFound = true
//            }
            // Now kick off discovery of characteristics
            self.peripheral!.discoverCharacteristics(nil, for: service)
        }
//        if isSyncServiceFound {
//            //@@@
//            // Found KittyDoc
//            guard self.delegate?.onDeviceConnected(peripheral: peripheral) != nil else {
//                print("self.delegate?.onDeviceConnected(:) == nil!(didDiscoverServices)")
//                return
//            }
//        }
        print("[-] centralManager(didDiscoverServices)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("[+]didDiscoverCharacteristicsForService")
        
        guard let characteristics = service.characteristics else {
            print("There is no Characteristic at all!(didDiscoverCharacteristicsFor)")
            return
        }

        if service.uuid.isEqual(MiScaleUUID.BodyScaleServiceUUID) { // 0xFFFA
            searchSyncRequiredCharacteristics(service: service)
        }
        // Searches essential Services & Characteristics
        //print("Found \(characteristics.count) characteristics")
        
        for characteristic in characteristics {
            //print("\(characteristic.uuid)", terminator: " ")//(\(characteristic.uuid.uuidString))")
//            if characteristic.properties.contains(.write) {
//                print("characteristic has write property!")
//            }
//            if characteristic.properties.contains(.writeWithoutResponse) {
//                print("characteristic has writeWithoutResponse property!")
//            }
//            if characteristic.properties.contains(.read) {
//                print("characteristic has read property!")
//                peripheral.readValue(for: characteristic)
//            }
//            if characteristic.properties.contains(.notify) {
//                print("characteristic has notify property!")
//                peripheral.setNotifyValue(true, for: characteristic)
//            }

            // DEVICE_INFO_UUID (firmware version)
            if service.uuid.isEqual(MiScaleUUID.DEVICE_INFO_UUID) && characteristic.uuid.isEqual(MiScaleUUID.SW_REVISION_CHAR_UUID) { // 0x180A,0x2A28
                print("[+] peripheral.readvalue() <SW_REVISION_CHAR_UUID>")
                guard self.peripheral == peripheral else {
                    print("self.peripheral != peripheral!(didDiscoverCharacteristicsFor)")
                    return
                }
                peripheral.readValue(for: characteristic)
            }

            // BodyScaleServiceCBUUID // 0x181D, 00002a2f-0000-3512-2118-0009af100700
            if service.uuid.isEqual(MiScaleUUID.BodyScaleServiceUUID) && characteristic.uuid.isEqual(MiScaleUUID.BodyScaleCharUUID) {
                self.bodyScaleCharacteristic = characteristic
            }

            //
//            if service.uuid.isEqual(MiScaleUUID.DEVICE_INFO_SERVICE_UUID) && characteristic.uuid.isEqual(MiScaleUUID.SW_REVISION_CHAR_UUID) { // 0x180A,0x2A28
//
//            }
//
//            peripheral.discoverDescriptors(for: characteristic)
        }
        
        print("[-]didDiscoverCharacteristicsForService")
    }
    
    func searchSyncRequiredCharacteristics(service: CBService) {
        print("[+] searchSyncRequiredCharacteristics()")

        self.bodyScaleCharacteristic = nil
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Found characteristic \(characteristic.uuid)")
                if characteristic.uuid.isEqual(MiScaleUUID.BodyScaleCharUUID) {
                    print("characteristic for Mi Scale found!")
                    self.bodyScaleCharacteristic = characteristic
                }
            }
        }
        print("[-] searchSyncRequiredCharacteristics()")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("\n[+] didUpdateValueForCharacteristic peripheral = \(peripheral.identifier.uuidString), \(characteristic.uuid), \(characteristic.value!)")
        
        guard let data = characteristic.value else {
            print("characteristic.value is empty!(didUpdateValueForCharacteristic)")
            return
        }
        let bytes = [UInt8](data)
        
        guard error == nil else {
            print("Error in Notification state: \(String(describing: error))")
            return
       }
        guard bytes.count > 0 else {
            print("char.value is Empty!")
            return
        }

        if characteristic.uuid.isEqual(MiScaleUUID.SW_REVISION_CHAR_UUID) {
            // SW Revision
            self.firmwareVersion = String(data: data, encoding: String.Encoding.ascii)!
            print("FirmwareVersion : \(self.firmwareVersion)")
        }

        if (self.bodyScaleCharacteristic != nil && !self.firmwareVersion.isEmpty && !self.isRequiredServicesFound) {
            guard self.delegate?.onServiceFound() != nil else {
                print("self.delegate?.onServiceFound() == nil!(didUpdateValueForCharacteristic)")
                return
            }
            self.isRequiredServicesFound = true
        }
        //print("[-] didUpdateValueForCharacteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Error in writing to Characteristic \(characteristic.uuid) and Error : \(error?.localizedDescription ?? "-")")
        } else {
            //print("didWriteValueForCharacteristic \(characteristic.uuid) and Value : \(characteristic.value ?? Data())")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristics: CBCharacteristic, error: Error?) {
//        print("[+] didDiscoverDescriptorsForCharacteristic")
////Client Characteristic Configuration descriptors must be configured using setNotifyValue:forCharacteristic:'
//        guard let descriptors = characteristics.descriptors else {
//            return
//        }
//
//        print("Found \(descriptors.count) descriptors \(descriptors)")
//        for descriptor in descriptors {
//            if descriptor.characteristic.properties.contains(.write) {
//                peripheral.writeValue(Data([0x01]), for: descriptor)
//                print("writeValue(0x01) done")
//            }
//            if descriptor.characteristic.properties.contains(.writeWithoutResponse) {
//                peripheral.writeValue(Data([0x01]), for: descriptor)
//                print("writeValue(0x01) done")
//            }
//            if descriptor.characteristic.properties.contains(.read) {
//                peripheral.readValue(for: descriptor)
//                print(".readValue() from [ \(descriptor.uuid) ]")
//                print("and the data is [ \(String(describing: descriptor.value)) ]")
//            }
//            if descriptor.characteristic.properties.contains(.notify) {
//                peripheral.setNotifyValue(true, for: characteristics.self)
//            }
//        }
//
//        print("[-] didDiscoverDescriptorsForCharacteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
//        let data = descriptor.value
//
//        print("Update descriptor Raw Data : \(data!)")
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        let data = descriptor.value

        print("Write descriptor Raw Data : \(data!)")
    }

}
