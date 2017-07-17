//
//  AirPlayDeviceHandler.swift
//  jmc
//
//  Created by John Moody on 7/17/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import CoreAudio
import CoreFoundation

class AirPlayDestination: NSObject {
    
    var name: String
    var id: UInt32

    init(id: UInt32, airPlayDevice: UInt32) {
        self.id = id
        var sourceID: UInt32 = 0
        var nameAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDataSourceNameForIDCFString, mScope: kAudioObjectPropertyScopeOutput, mElement: kAudioObjectPropertyElementMaster)
        var value: CFString = "" as CFString
        var audioValueTranslation = AudioValueTranslation(mInputData: &sourceID, mInputDataSize: UInt32(MemoryLayout<UInt32>.size), mOutputData: &value, mOutputDataSize: UInt32(MemoryLayout<CFString>.size))
        var propsize = UInt32(MemoryLayout<AudioValueTranslation>.size)
        AudioObjectGetPropertyData(airPlayDevice, &nameAddr, 0, nil, &propsize, &audioValueTranslation)
        self.name = value as String
    }
    
}

class AirPlayDeviceHandler: NSObject {
    
    var outputs = [AirPlayDestination]()
    var device: UInt32 = 0
    
    
    override init() {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeWildcard, mElement: kAudioObjectPropertyElementWildcard)
        var propsize: UInt32 = 0
        AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &propsize)
        var deviceIDs = [UInt32](repeating: 0, count: Int(propsize))
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &propsize, &deviceIDs)
        
        var transportTypeAddr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyTransportType, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var transportType: UInt32 = 0
        
        for device in deviceIDs {
            AudioObjectGetPropertyData(device, &transportTypeAddr, 0, nil, &propsize, &transportType)
            print(transportType)
            if transportType == kAudioDeviceTransportTypeAirPlay {
                self.device = device
                print("found device")
            }
        }
        super.init()
        self.getAirPlayOutputs()
        print(outputs)
    }
    
    func getAirPlayOutputs() {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDataSources, mScope: kAudioDevicePropertyScopeOutput, mElement: kAudioObjectPropertyElementWildcard)
        var propsize: UInt32 = 0
        AudioObjectGetPropertyDataSize(self.device, &addr, 0, nil, &propsize)
        var sourceIDs = [UInt32](repeating: 0, count: Int(propsize))
        AudioObjectGetPropertyData(self.device, &addr, 0, nil, &propsize, &sourceIDs)
        for source in sourceIDs {
            outputs.append(AirPlayDestination(id: source, airPlayDevice: self.device))
        }
    }

}
