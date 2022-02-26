//
//  MiScaleUUID.swift
//  KittyDocBLEUIKit
//
//  Created by 곽명섭 on 2021/04/25.
//

import Foundation
import CoreBluetooth

class MiScaleUUID: NSObject {

    public static let BodyScaleServiceUUID = CBUUID(string: "0x181D")
    public static let BodyScaleCharUUID = CBUUID(string: "0x2A9D")
    public static let GENERIC_ACCESS_UUID = CBUUID(string: "0x1800")
    
    public static let DEVICE_NAME_UUID = CBUUID(string: "0x2a00") // READ WRITE handle=3
    public static let APPEARANCE_UUID = CBUUID(string: "0x2a01") // READ handle=5
    public static let Peripheral_Privacy_Flag = CBUUID(string: "0x2a02") // READ WRITE handle=7
    public static let Peripheral_Preferred_Connection_Parameters = CBUUID(string: "0x2a04") // READ handle=9
    public static let Reconnection_UUID = CBUUID(string: "0x2a03") // READ WRITE NO RESPONSE WRITE handle=11
    
    public static let GENERIC_ATTRIBUTE_UUID = CBUUID(string: "0x1801")
    
    public static let Service_Changed_UUID = CBUUID(string: "0x2a05") // READ INDICATE handle=14
    
    public static let DEVICE_INFO_UUID = CBUUID(string: "0x180A")
    
    public static let Serial_Number_String = CBUUID(string: "0x2A25") // READ handle=18
    public static let HW_REVISION_CHAR_UUID = CBUUID(string: "0x2A27") // READ handle=22
    public static let SW_REVISION_CHAR_UUID = CBUUID(string: "0x2A28") // READ handle=20
    public static let System_ID = CBUUID(string: "0x2A23") // READ handle=24
    public static let PnP_ID = CBUUID(string: "0x2A50") // READ handle=26
    
    public static let BODY_COMPOSITION_UUID = CBUUID(string: "0x181B")
    
    public static let Current_Time = CBUUID(string: "0x2A2B") // READ WRITE handle=29
    public static let Body_Composition_Feature = CBUUID(string: "0x2A9B") // READ handle=31 // Apparently not used
    public static let Body_Composition_Measurement = CBUUID(string: "0x2A9C") // INDICATE handle=33
    public static let Body_Composition_History = CBUUID(string: "00002a2f-0000-3512-2118-0009af100700") // WRITE NOTIFY handle=36
    
    public static let Huami_Configuration_Service = CBUUID(string: "00001530-0000-3512-2118-0009AF100700")
    
    public static let DFU_Control_Point = CBUUID(string: "00001531-0000-3512-2118-0009AF100700") // WRITE NOTIFY handle=40
    public static let DFU_Packet = CBUUID(string: "00001532-0000-3512-2118-0009AF100700") // WRITE NO RESPONSE handle=43
    //public static let Peripheral_Preferred_Connection_Parameters = CBUUID(string: "0x2A04") // READ WRITE NOTIFY handle=45
    public static let Scale_Configuration = CBUUID(string: "00001542-0000-3512-2118-0009AF100700") // READ WRITE NOTIFY handle=48
    public static let Battery_UUID = CBUUID(string: "00001543-0000-3512-2118-0009AF100700") // READ WRITE NOTIFY handle=51

}


//Custom services/chars

//Body Composition Measurement (00002a9c-0000-1000-8000-00805f9b34fb)
//It is used as notifications
//
//If notified, you'll receive the same weight data as in advertisements
//
//Body Measurement History (00002a2f-0000-3512-2118-0009af100700)
//This is the main characteristic, it gives the measurement history The device id is randomly chosen at first start of mi fit, the scale keep track of where each device is so it doesn't send all the data each time, and don't skip any data either
//
//Get data size
//Send 0x01 [device id] Si no response or response lenght is less than 3 or reponse[0] it not 1, send 0x03 Data size = response[1] and response[2], send 0x03 to end
//
//Get data
//Register to notifications and send 0x02 Get all notifications and send 0x03 at the end Each notifications should have the same data as the advertisements If you have as much data as indicated by the get data size command, send 0x04 [device id] to update your history position If registering to notifications or sending the 0x02 failed, send 0x03 anyway
//
//Scale configuration (00001542-0000-3512-2118-0009af100700)
//There's several commands there, but nothing really special. No idea what's the "one foot measure" but it seems useless.
//
//Set unit
//Send 0x06 0x04 0x00 [unit] where [unit] is 0x00 for SI, 0x01 for imperial and 0x02 for catty
//
//Enable Partial measures
//Send 0x06 0x10 0x00 [!enable] and you should receive a response that is 0x16 0x06 0x10 0x00 0x01
//
//Erase history record
//Send 0x06 0x12 0x00 0x00, you should receive a response that is 0x16 0x06 0x12 0x00 0x01
//
//Enable LED display
//Send 0x04 0x02 to enable, 0x04 0x03 to disable
//
//Calibrate
//Send 0x06 0x05 0x00 0x00
//
//Self test
//Send 0x04 0x01 to enable 0x04 0x04 to disable
//
//Set Sandglass Mode
//Send 0x06 [mode] 0x00 where mode is an uint16 that equals 0x000A or 0x000B
//
//Get Sandglass Mode
//Read and if mode is set, it is equal to 0x03 0x00
//
//Start One Foot Measure
//Register to notifications and send 0x06 0x0f 0x00 0x00 You should get a notification like 0x06 0x0f 0x00 [flags] [time]*2 The only known flags are finished (0x02) and measuring (0x01) Time is inverted (time = (time[1] << 8) | time[0]) and multiplied by 100 This feature seems pretty useless
//
//Stop One Foot Measure
//Send 0x06 0x11 0x00 0x00
//
//Date and time (00002a2b-0000-1000-8000-00805f9b34fb)
//You can read and write it, format: year[0], year[1], month, day, hour, min, sec, 0x00, 0x00
//
//Battery (00001543-0000-3512-2118-0009af100700)
//Two uint8, if both equals 0x01, then it's a low battery alert, simple as that.
//
//Advertisement
//The scale also works using advertisement packets, with a adType 0xff (OEM data) that is unknown yet, and a adType 0x16 (Service Data) that have this format:
//
//Data is 17 bytes long, with the first 4 bytes being an UUID, the other 13 bytes are the payload
//
//Payload format (year, impedance and weight are little endian):
//
//bytes 0 and 1: control bytes
//bytes 2 and 3: year
//byte 4: month
//byte 5: day
//byte 6: hours
//byte 7: minutes
//byte 8: seconds
//bytes 9 and 10: impedance
//bytes 11 and 12: weight (*100 for pounds and catty, *200 for kilograms)
//Control bytes format (LSB first):
//
//bit 0: unused
//bit 1: unused
//bit 2: unused
//bit 3: unused
//bit 4: unused
//bit 5: partial data
//bit 6: unused
//bit 7: weight sent in pounds
//bit 8: finished (is there any load on the scale)
//bit 9: weight sent in catty
//bit 10: weight stabilised
//bit 11: unused
//bit 12: unused
//bit 13: unused
//bit 14: impedance stabilized
//bit 15: unused


//class test: NSObject {
//    public static let _ = CBUUID(string:"00001800-0000-1000-8000-00805f9b34fb")// Generic Access
//    public static let _ = CBUUID(string:"00002a00-0000-1000-8000-00805f9b34fb")// Device Name
//    public static let _ = CBUUID(string:"00002a01-0000-1000-8000-00805f9b34fb")// Appearance
//    public static let _ = CBUUID(string:"00002a02-0000-1000-8000-00805f9b34fb")//Peripheral Privacy Flag
//    public static let _ = CBUUID(string:"00002a04-0000-1000-8000-00805f9b34fb")// Peripheral Preferred Connection Parameters
//    public static let _ = CBUUID(string:"00002a03-0000-1000-8000-00805f9b34fb")// Reconnection Address
//    public static let _ = CBUUID(string:"00001801-0000-1000-8000-00805f9b34fb")// Generic Attribute
//    public static let _ = CBUUID(string:"00002a05-0000-1000-8000-00805f9b34fb")// Service Changed
//    public static let _ = CBUUID(string:"0000180a-0000-1000-8000-00805f9b34fb")// Device Information
//    public static let _ = CBUUID(string:"00002a25-0000-1000-8000-00805f9b34fb")//Serial Number String
//    public static let _ = CBUUID(string:"00002a28-0000-1000-8000-00805f9b34fb")//Software Revision String
//    public static let _ = CBUUID(string:"00002a27-0000-1000-8000-00805f9b34fb")//Hardware Revision String
//    public static let _ = CBUUID(string:"00002a23-0000-1000-8000-00805f9b34fb")//System ID
//    public static let _ = CBUUID(string:"00002a50-0000-1000-8000-00805f9b34fb")//PnP ID
//    public static let _ = CBUUID(string:"0000181b-0000-1000-8000-00805f9b34fb")//Body Composition
//    public static let _ = CBUUID(string:"00002a2b-0000-1000-8000-00805f9b34fb")//Current Time
//    public static let _ = CBUUID(string:"00002a9b-0000-1000-8000-00805f9b34fb")//Body Composition Feature
//    public static let _ = CBUUID(string:"00002a9c-0000-1000-8000-00805f9b34fb")//Body Composition Measurement
//    public static let _ = CBUUID(string:"00002a2f-0000-3512-2118-0009af100700")//Body Composition History
//    public static let _ = CBUUID(string:"00001530-0000-3512-2118-0009af100700")//Huami Configuration Service
//    public static let _ = CBUUID(string:"00001531-0000-3512-2118-0009af100700")//DFU Control point
//    public static let _ = CBUUID(string:"00001532-0000-3512-2118-0009af100700")//DFU Packet
//    public static let _ = CBUUID(string:"00002a04-0000-1000-8000-00805f9b34fb")//Peripheral Preferred Connection Parameters
//    public static let _ = CBUUID(string:"00001542-0000-3512-2118-0009af100700")//Scale configuration
//    public static let _ = CBUUID(string:"00001543-0000-3512-2118-0009af100700")//Battery
//}
