//
//  BLEProvider.swift
//  BLEScanner
//
//  Created by Daniel Günther on 23.04.20.
//  Copyright © 2020 Daniel Günther. All rights reserved.
//  email: d.guenther@tum.de
//

import UIKit
import CoreBluetooth

extension String {
   func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }

    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}


let const_filter_array = [CBUUID(string: "3737"),CBUUID(string: "3838"),CBUUID(string: "3939")]
let ble_manager = BLEManager()


// Log status to console
func status(of: String, value: String){
    print(of + ": " + value)
}

func getPath(file: String) -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0].appendingPathComponent(file)
}

func getDateString() -> String{
    let dateFormatter : DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss"
    return dateFormatter.string(from: Date())
}


class BLEManager: UIViewController, CBCentralManagerDelegate, ObservableObject{
    @Published var captureStatus = "unknown"
    private var centralManager: CBCentralManager!
    private var peripheralStorage = [UUID: CBPeripheral]()
    private var restartDelay: Int = 4
    private var enableRestart = false
    private var filter = true
    private var path : URL? = nil
    private var work : DispatchWorkItem? = nil
    
    func set(restartDelay: Int, enableRestart: Bool, filter: Bool){
        self.restartDelay = restartDelay
        self.enableRestart = enableRestart
        self.filter = filter
    }
    
    func start(){
        captureStatus = "launching"
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        let file = getDateString() + "_capture"
        path = getPath(file: file+".txt")
        do{
            try file.appendLineToURL(fileURL: getPath(file: "captures.txt"))
            try "".write(to: path!, atomically: false, encoding: .utf8)
        }catch{}
    }
    
    func stop(){
        captureStatus = "stopping"
        if(work != nil){
            work!.cancel()
        }
        if(centralManager.isScanning){
            centralManager.stopScan()
        }
        centralManager = nil
    }
    
    func restart(){
        if(centralManager.isScanning){
            centralManager.stopScan()
        }
        startScan()
    }
    
    func startScan(){
        var filter_array = [CBUUID]()
        if(filter){
            filter_array = const_filter_array
        }
        centralManager.scanForPeripherals(withServices: filter_array, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        if(enableRestart){
            work = DispatchWorkItem(block: {
                self.restart()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.init(restartDelay/1000), execute: work!)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Launch successful
            status(of: "CentralBluetooth", value: "online")
            captureStatus = "online"
            startScan()
        } else {
            // Possibly the permission was denied, state would then be .unauthorized
            status(of: "CentralBluetooth", value: "not ready")
            captureStatus = "failed! please make sure bluethooth is on and click stop then start again"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if(advertisementData["kCBAdvDataServiceUUIDs"] != nil){
            let uuid = ((advertisementData["kCBAdvDataServiceUUIDs"]! as! NSArray)[0] as! CBUUID).uuidString
            let unknowTime = (advertisementData["kCBAdvDataTimestamp"] as! NSNumber)
            var saveString = uuid+","
            saveString += String(Date().timeIntervalSince1970)+","
            saveString += String(unknowTime as! Double)+","
            saveString += String(RSSI as! Int)
            do{
                try saveString.appendLineToURL(fileURL: path!)
            }catch{
                status(of: "File", value: "write failed")
            }
            
        }
    }

    func getData(sync: [String: Any]) -> [String: Any]{
        var result = [String: Any]()
        for filename in sync["toSync"] as! [String] {
            do {
                let tmp = try String(contentsOf: getPath(file: String(filename + ".txt")), encoding: .utf8)
                result[String(filename)] = tmp.split(separator: "\n")
            }
            catch { print("caught: \(error)")}
        }
        return result
    }
    
    func getWhich() -> [String: Any]{
        do {
            return ["captures": (try String(contentsOf: getPath(file: "captures.txt"), encoding: .utf8)).split(separator: "\n")]
        }
        catch {
            print("caught: \(error)")
            return [String: Any]() }
    }
    
    func deleteAll(){
        do {
            let captures = (try String(contentsOf: getPath(file: "captures.txt"), encoding: .utf8)).split(separator: "\n")
        
            for filename in captures {
                do {
                    try FileManager.default.removeItem(at: getPath(file: String(filename + ".txt")))
                }catch {
                    print("inner caught: \(error)")}
            }
            try FileManager.default.removeItem(at: getPath(file: String("captures.txt")))
        }catch {
            print("caught: \(error)")}
    }
}
