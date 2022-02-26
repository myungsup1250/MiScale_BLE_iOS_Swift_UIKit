//
//  CBUUIDExtension.swift
//  KittyDocBLEUIKit
//
//  Created by 곽명섭 on 2021/01/24.
//

import CoreBluetooth

extension CBUUID {
    var UUIDValue: UUID? {
        get {
            guard self.data.count == MemoryLayout<uuid_t>.size else { return nil }
            return self.data.withUnsafeBytes {
                (pointer: UnsafeRawBufferPointer) -> UUID in
                let uuid = pointer.load(as: uuid_t.self)
                return UUID(uuid: uuid)
            }
        }
    }
}

//    public extension UUID {
//        internal var bytes : [UInt8] {
//            let (u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16) = self.uuid
//            return [u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16]     }
//        internal var data : Data { Data(bytes) }
//    }
