//
//  Defaults.swift
//  Extention
//
//  Created by Debasish Nandi on 03/07/23.
//

import Foundation

internal let defaultValues: [String: Any] = ["KBSize":1024,
                                             "MBSize":1_048_576,
                                             "ByteSize": MemoryLayout<UInt8>.size,
                                             "DefaultChunkSize":8*4_194_304,]

public extension UserDefaults {
    static var sharedContainerDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.FruitBasket") else {
            fatalError("could not access shared user defaults")
        }
        defaults.register(defaults: defaultValues)
        return defaults
    }
    
    var defaultChunkSize: Int {
        return integer(forKey: "DefaultChunkSize")
    }
}
