//
//  FileProviderExtension.swift
//  Extention
//
//  Created by Debasish Nandi on 07/06/23.
//

import FileProvider
import Foundation
import ipfs_api

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

class FileProviderExtension: NSObject, NSFileProviderReplicatedExtension {
    let domain: NSFileProviderDomain
    var manager: NSFileProviderManager
    
    let temporaryDirectoryURL: URL
    
    required init(domain: NSFileProviderDomain) {
        // TODO: The containing application must create a domain using `NSFileProviderManager.add(_:, completionHandler:)`. The system will then launch the application extension process, call `FileProviderExtension.init(domain:)` to instantiate the extension for that domain, and call methods on the instance.
        self.domain = domain
        manager = NSFileProviderManager(for: domain)!
        
        do {
            temporaryDirectoryURL = try manager.temporaryDirectoryURL()
        } catch {
            fatalError("failed to get temporary directory: \(error)")
        }
        
        super.init()
    }
    
    func invalidate() {
        // TODO: cleanup any resources
    }
    
    func item(for identifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) -> Progress {
        // resolve the given identifier to a record in the model
        
        // TODO: implement the actual lookup
        print(request)
        print("ident: ", identifier)
        Task {
            
            if identifier == .rootContainer || identifier == .trashContainer || identifier == .workingSet{
                completionHandler(Item(identifier: identifier ), nil)
                return
            }
            
            var fpath = "/"
            
            fpath += identifier.rawValue
            

            
            let Filestat = try await FilesStat(filepath: fpath)
            var f = File(Name: identifier.rawValue, Hash: Filestat.Hash, Size: Filestat.Size, type: Filestat.`Type` == "directory" ? 1:0)
            var parrawid = identifier.rawValue.components(separatedBy: "/").dropLast().joined(separator: "/")
            var parentIdentifier = NSFileProviderItemIdentifier(parrawid)
            if parrawid == "" {
                parentIdentifier = .rootContainer
            }
            
            completionHandler(Item(fileItem: f,parentItem: parentIdentifier), nil)
            return
//            let fileslist = try await FilesList(filepath: fpath)
// //            let fileslist = try await FilesList(filepath: "/ipfsFolder")
//            guard let list = fileslist.Entries else {
//                completionHandler(Item(identifier: identifier), nil)
//                return
//            }
//
//            let file = list.first { file in
//                if file.Name == identifier.rawValue{
//                    return true
//                }
//                return false
//            }
//
//            if let file = file {
//                completionHandler(Item(fileItem: file), nil)
//            }else {
//                completionHandler(Item(identifier: identifier ), nil)
//            }
        }
        return Progress()
    }
    
    func fetchContents(for itemIdentifier: NSFileProviderItemIdentifier, version requestedVersion: NSFileProviderItemVersion?, request: NSFileProviderRequest, completionHandler: @escaping (URL?, NSFileProviderItem?, Error?) -> Void) -> Progress {
        // TODO: implement fetching of the contents for the itemIdentifier at the specified version
        
//        let file = "output.txt"
//
//        var result = ""
//
//        var fileURL:URL = URL(fileURLWithPath: "")
//
//        //if you get access to the directory
//        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//
//            //prepare file url
//            fileURL = dir.appendingPathComponent(file)
//
//            do {
//                let str = "Hello Cydrive.... Hola!\n"
//                try str.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
//                result = try String(contentsOf: fileURL, encoding: .utf8)
//            }
//            catch {/* handle if there are any errors */}
//        }
//
//        print(result)
//
//        if fileURL.baseURL == URL(fileURLWithPath: "").baseURL {
//            completionHandler(nil, nil, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
//            return Progress()
//        }
        
        return self.item(for: itemIdentifier, request: request) { item, err in
            // working code for opening the file after the reference
//             completionHandler(fileURL, item, nil)
            
//            code down to attempt to open the file without downloading it
//            let err2 = NSError.fileProviderErrorForNonExistentItem(withIdentifier: itemIdentifier)
//            let err3 = NSError.fileProviderErrorForRejectedDeletion(of: item!)
//            completionHandler(nil, item, nil)
            print(item as Any, err as Any)
            
            Task{
                do {
                    print(item as Any)
                    let fp = "/"+(item?.itemIdentifier.rawValue)!
                    let data = try await FilesRead(filepath: fp)
                    let dataURL = self.makeTemporaryURL("fetchedContents")
                    
                    try data.write(to: dataURL)
                    completionHandler(dataURL, item, nil)
                } catch let error {
                    completionHandler(nil, item, error)
                }
            }
            
        
        }
    }
    
    func createItem(basedOn itemTemplate: NSFileProviderItem, fields: NSFileProviderItemFields, contents url: URL?, options: NSFileProviderCreateItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: a new item was created on disk, process the item's creation
        
        print("Cr: itemTemplate :: ", itemTemplate , itemTemplate.filename)
        print("Cr: fields :: ",fields)
        print("Cr: url :: ",url ?? "Error URL EMPTY!!")
        print("Cr: options :: ",options)
        print("Cr: request :: ",request)
        
        guard let cType = itemTemplate.contentType else{
            completionHandler(itemTemplate, [],false,NSFileProviderError(NSFileProviderError.Code.noSuchItem))
            return Progress()
        }
        
        switch cType{
        case .folder:
            // create a folder with the given path name
            print("Creation : create a folder")
        default:
            print("Creation : create a file")
        }
        
        completionHandler(itemTemplate, [], false, nil)
        return Progress()
    }
    
    func modifyItem(_ item: NSFileProviderItem, baseVersion version: NSFileProviderItemVersion, changedFields: NSFileProviderItemFields, contents newContents: URL?, options: NSFileProviderModifyItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (NSFileProviderItem?, NSFileProviderItemFields, Bool, Error?) -> Void) -> Progress {
        // TODO: an item was modified on disk, process the item's modification
        completionHandler(item, [], false, nil)
        //        completionHandler(nil, [], false, NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func deleteItem(identifier: NSFileProviderItemIdentifier, baseVersion version: NSFileProviderItemVersion, options: NSFileProviderDeleteItemOptions = [], request: NSFileProviderRequest, completionHandler: @escaping (Error?) -> Void) -> Progress {
        // TODO: an item was deleted on disk, process the item's deletion
        
        completionHandler(NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:]))
        return Progress()
    }
    
    func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier, request: NSFileProviderRequest) throws -> NSFileProviderEnumerator {
        
        var container = containerItemIdentifier
        
        if containerItemIdentifier == .rootContainer{
            container = NSFileProviderItemIdentifier("/")
        }
        
        return FileProviderEnumerator(enumeratedItemIdentifier: container)
    }
}

extension FileProviderExtension {
    func makeTemporaryURL(_ purpose: String, _ ext: String? = nil) -> URL {
        if let ext = ext {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString).\(ext)")
        } else {
            return temporaryDirectoryURL.appendingPathComponent("\(purpose)-\(UUID().uuidString)")
        }
    }
    
    func adjustRequestedRange(requestedRange: NSRange, alignment: Int, fileSize: Int) -> NSRange {
        guard fileSize != 0, requestedRange.location >= 0, requestedRange.length > 0 else {
            return NSRange(location: 0, length: -1)
        }
        
        var extent: NSRange
        let alignedStart = requestedRange.location & ~(alignment - 1)
        let length = requestedRange.location + requestedRange.length - alignedStart
        var alignedLength = ((length + alignment - 1) & ~(alignment - 1))
        if alignedLength < UserDefaults.sharedContainerDefaults.BRMChunkSize {
            alignedLength = UserDefaults.sharedContainerDefaults.BRMChunkSize
        }
        
        let alignedEnd = alignedStart + alignedLength
        
        if fileSize <= UserDefaults.sharedContainerDefaults.minSizeFileForBRM {
            //Materialize the entire file.
            extent = NSRange(location: 0, length: -1)
        } else if fileSize > alignedStart && fileSize >= alignedEnd {
            extent = NSRange(location: alignedStart, length: alignedLength)
            if UserDefaults.sharedContainerDefaults.isUnalignedBRMResponse {
                extent.location += 5
                extent.length -= 5
            }
        } else if fileSize > alignedStart && fileSize < alignedEnd {
            //Trim the end of the file.
            extent = NSRange(location: alignedStart, length: fileSize - alignedStart)
        } else {
            //Materialize the entire file.
            extent = NSRange(location: 0, length: -1)
        }
        
        return extent
    }
}
