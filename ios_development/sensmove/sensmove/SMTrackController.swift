//
//  SMTrackController.swift
//  sensmove
//
//  Created by RIEUX Alexandre on 24/05/2015.
//  Copyright (c) 2015 ___alexprod___. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation
import SceneKit

class SMTrackController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, SMChronometerDelegate {
    
    @IBOutlet weak var timeCountdown: UILabel?
    @IBOutlet weak var stopSessionButton: UIButton?
    @IBOutlet weak var liveTrackGraph: SMLiveForcesTrack!
    @IBOutlet weak var jumpCounter: UILabel!
    @IBOutlet weak var stepCounter: UILabel!
    
    var chronometer: SMChronometer?
    var trackSessionService: SMTrackSessionService = SMTrackSessionService.sharedInstance
    let dataProcessingService: SMDataProcessing = SMDataProcessing()
    
    /// Current central manager
    var centralManager: CBCentralManager?

    /// Temporary string data, string is delimited by $ character
    var tmpDatasString: String = ""

    /// Set whenever string is built
    dynamic var blockDataCompleted: NSData!
    
    /// current discovered peripheral
    private var currentPeripheral: CBPeripheral?
    

    var bluetoothBuffer: SMBluetoothDatasBuffer = SMBluetoothDatasBuffer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Trigger new session when opening track controller
        self.trackSessionService.createNewSession()
        self.chronometer = SMChronometer()
        self.chronometer?.delegate = self
        self.chronometer?.startChronometer()


        self.centralManager = CBCentralManager(delegate: self, queue: nil)

        /**
        *   Observe blockDataCompleted property of current class then update forces values 
        *   of current session
        */
        RACObserve(self, "blockDataCompleted").subscribeNext { (datas) -> Void in
            if let data: NSData = datas as? NSData{
                let jsonObject: JSON = JSON(data: data)
                self.trackSessionService.updateCurrentSession(self.dataProcessingService.removeNoise(jsonObject))
            }
            
        }
        
        // Initialize graph charts for each sensors
        self.liveTrackGraph.initializeCharts()

        // Initialize RACObserve on each sensors
        self.liveTrackGraph.initializeForceObserver()

        self.uiInitialize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func uiInitialize() {
        
        self.jumpCounter.textColor = SMColor.orange()
        self.stepCounter.textColor = SMColor.orange()
        
        self.stopSessionButton?.backgroundColor = SMColor.red()
        self.stopSessionButton?.setTitleColor(SMColor.whiteColor(), forState: UIControlState.Normal)
    }

    /**
    *
    *   Delegate method triggered every second
    *   :param: String new time string formated
    *
    */
    func updateChronometer(newTime: String) {
        self.timeCountdown?.text = newTime
    }
    
    @IBAction func stopSessionAction(sender: AnyObject) {
//        self.centralManager?.cancelPeripheralConnection(self.currentPeripheral)

        self.chronometer?.stopChronometer()
        let elapsedTime = self.chronometer?.getElapsedTime()
        self.trackSessionService.stopCurrentSession(elapsedTime!)

        let resultController: UIViewController = self.storyboard?.instantiateViewControllerWithIdentifier("resumeController") as! UIViewController
        self.navigationController?.presentViewController(resultController, animated: false, completion: nil)
    }

    /// MARK: Central manager delegates methods
    
    /// Triggered whenever bluetooth state change, verify if it's power is on then scan for peripheral
    func centralManagerDidUpdateState(central: CBCentralManager!){
        if(centralManager?.state == CBCentralManagerState.PoweredOn) {
            self.centralManager?.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(bool: true)])
            printLog(self, "centralManagerDidUpdateState", "Scanning")
        }
    }

    /// Connect to peripheral from name
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if (peripheral.name != nil) {
            if(self.currentPeripheral != peripheral && peripheral.name == insoleName){
                self.currentPeripheral = peripheral
                
                self.centralManager?.connectPeripheral(peripheral, options: nil)
            }
        }
    }

    /// Triggered when device is connected to peripheral, check for services
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        self.centralManager?.stopScan()
        
        peripheral.delegate = self
        
        if peripheral.services == nil {
            peripheral.discoverServices([uartServiceUUID()])
        }
        
    }

    /// Check characteristic from service, discover characteristic from common UUID
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {

        if((error) != nil) {
            printLog(error, "didDiscoverServices", "Error when discovering services")
            return
        }
        
        for service in peripheral.services as! [CBService] {
            if service.characteristics != nil {
                printLog(service.characteristics, "didDiscoverServices", "Characteristics already known")
            }
            if service.UUID.isEqual(uartServiceUUID()) {
                peripheral.discoverCharacteristics([txCharacteristicUUID(), rxCharacteristicUUID()], forService: service)
            }
        }
    }

    /// Notify peripheral that characteristic is discovered
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {

        printLog(service.characteristics, "didDiscoverCharacteristicsForService", "Discover characteristique")
        
        if service.UUID.isEqual(uartServiceUUID()) {
            for characteristic in service.characteristics as! [CBCharacteristic] {
                if characteristic.UUID.isEqual(txCharacteristicUUID()) || characteristic.UUID.isEqual(rxCharacteristicUUID()) {

                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }

    /// Check update for characteristic and call didReceiveDatasFromBle method
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {

        if let dataBlock = bluetoothBuffer.addValue(characteristic.value) {
            self.blockDataCompleted = dataBlock
        }

    }

}
