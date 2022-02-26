//
//  DispatchQueueExtension.swift
//  KittyDocBLEUIKit
//
//  Created by 곽명섭 on 2021/01/31.
//

import Foundation

extension DispatchQueue {// Reference : https://stackoverflow.com/questions/24056205/how-to-use-background-thread-in-swift

    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
//    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
//        print("This is run on the background queue")
//
//        DispatchQueue.main.async {
//            print("This is run on the main queue, after the previous code in outer block")
//        }
//    }
}
