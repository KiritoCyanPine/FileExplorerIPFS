//
//  Extention+PartialFetching.swift
//  Extention
//
//  Created by Debasish Nandi on 14/06/23.
//

import Foundation
//import os
//import FileProvider
//import ipfs_api
//
//extension FileProviderExtension : NSFileProviderPartialContentFetching {
//    func fetchPartialContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion, request: NSFileProviderRequest, minimalRange requestedRange: NSRange, aligningTo alignment: Int, options: NSFileProviderFetchContentsOptions = [], completionHandler: @escaping (URL?, NSFileProviderItem?, NSRange, NSFileProviderMaterializationFlags, Error?) -> Void) -> Progress {
//        
//        print("Partial : itemIdentifier ", itemIdentifier )
//        print("Partial : requestedVersion ", requestedVersion)
//        print("Partial : request ", request)
//        print("Partial : requestedRange ",requestedRange)
//        print("Partial : alignment ",alignment)
//        print("Partial : options ", options)
//        
//        
//        return self.item(for: itemIdentifier, request: request) { item, error in
//            guard error == nil  else {
//                return
//            }
//
//            Task{
//                do {
//                    let data = try await FilesRead(filepath: "/ipfsFolder/"+itemIdentifier.rawValue)
//                    let dataURL = self.makeTemporaryURL("fetchedContents")
//                    let returnedLength = NSRange(location: 0, length: data.count)
//                    
//                    try data.write(to: dataURL)
//                    completionHandler(dataURL, item, returnedLength,[], nil)
//                } catch let error {
//                    completionHandler(nil, nil, NSRange(location: 0, length: 0),[], error)
//                }
//            }
//        }
//    }
//    
//    
//}
