//
//  Defaults.swift
//  Extention
//
//  Created by Debasish Nandi on 03/07/23.
//

import Foundation

internal let defaultValues: [String: Any] = ["responseDelay": 0.0,
                                             "errorRate": 0.0,
                                             "batchSize": 200,
                                             "accountQuota": 0,
                                             "ignoreAuthentication": true,
                                             "skipThumbnailUpload": false,
                                             "contentStoredInline": false,
                                             "ignoreContentVersionOnDeletion": false,
                                             "trashDisabled": false,
                                             "syncChildrenBeforeParentMove": true,
                                             "uploadNewFilesInChunks": true,
                                             "supportBRM": true,
                                             "minFileSizeForBRM": 256,
                                             "unalignedBRMResponse": false,
                                             "BRMChunkSizeMB": 5]

public extension UserDefaults {
    static var sharedContainerDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.FruitBasket") else {
            fatalError("could not access shared user defaults")
        }
        defaults.register(defaults: defaultValues)
        return defaults
    }
    
    var minSizeFileForBRM: Int {
        return integer(forKey: "minFileSizeForBRM")
    }
    
    var isUnalignedBRMResponse: Bool {
        let ret = bool(forKey: "unalignedBRMResponse")
        set(false, forKey: "unalignedBRMResponse")
        return ret
    }
    
    var BRMChunkSize: Int {
        return integer(forKey: "BRMChunkSizeMB") * 1_048_576 // Convert into bytes.
    }
}
